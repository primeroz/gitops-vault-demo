# Create an external NAT IP
resource "google_compute_address" "vault-nat" {
  count   = 2
  name    = "vault-nat-external-${count.index}"
  project = "${data.google_project.project.project_id}"
  region  = "${var.region}"

  depends_on = [
    "null_resource.services_wait",
  ]
}

# Create a network for GKE
resource "google_compute_network" "vault-network" {
  name                    = "vault-network"
  project                 = "${data.google_project.project.project_id}"
  auto_create_subnetworks = false

  depends_on = [
    "null_resource.services_wait",
  ]
}

# Create subnets
resource "google_compute_subnetwork" "vault-subnetwork" {
  name          = "vault-subnetwork"
  project       = "${data.google_project.project.project_id}"
  network       = "${google_compute_network.vault-network.self_link}"
  region        = "${var.region}"
  ip_cidr_range = "${var.kubernetes_network_ipv4_cidr}"

  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "k8s-pods"
    ip_cidr_range = "${var.kubernetes_pods_ipv4_cidr}"
  }

  secondary_ip_range {
    range_name    = "k8s-svcs"
    ip_cidr_range = "${var.kubernetes_services_ipv4_cidr}"
  }
}

# Create a NAT router so the nodes can reach DockerHub, etc
resource "google_compute_router" "vault-router" {
  name    = "vault-router"
  project = "${data.google_project.project.project_id}"
  region  = "${var.region}"
  network = "${google_compute_network.vault-network.self_link}"

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "vault-nat" {
  name    = "vault-nat-1"
  project = "${data.google_project.project.project_id}"
  router  = "${google_compute_router.vault-router.name}"
  region  = "${var.region}"

  nat_ip_allocate_option = "MANUAL_ONLY"
  nat_ips                = ["${google_compute_address.vault-nat.*.self_link}"]

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = "${google_compute_subnetwork.vault-subnetwork.self_link}"
    source_ip_ranges_to_nat = ["PRIMARY_IP_RANGE", "LIST_OF_SECONDARY_IP_RANGES"]

    secondary_ip_range_names = [
      "${google_compute_subnetwork.vault-subnetwork.secondary_ip_range.0.range_name}",
      "${google_compute_subnetwork.vault-subnetwork.secondary_ip_range.1.range_name}",
    ]
  }
}
