resource "google_container_cluster" "vault" {
  provider = "google-beta"

  name     = "vault"
  project  = "${data.google_project.project.project_id}"
  location = "${var.region}"

  network    = "${google_compute_network.vault-network.self_link}"
  subnetwork = "${google_compute_subnetwork.vault-subnetwork.self_link}"

  // Can't have zero nodes... so create one per zone then remove with remove_default_node_pool
  initial_node_count       = 1    // This is per-zone in the region specified above
  remove_default_node_pool = true

  min_master_version = "${data.google_container_engine_versions.versions.latest_master_version}"

  node_version = "${data.google_container_engine_versions.versions.latest_master_version}"

  logging_service    = "${var.kubernetes_logging_service}"
  monitoring_service = "${var.kubernetes_monitoring_service}"

  # Disable legacy ACLs. The default is false, but explicitly marking it false
  # here as well.
  enable_legacy_abac = false

  # Configure various addons
  addons_config {
    # Disable the Kubernetes dashboard, which is often an attack vector. The
    # cluster can still be managed via the GKE UI.
    kubernetes_dashboard {
      disabled = true
    }

    http_load_balancing {
      disabled = true
    }

    # Enable network policy configurations (like Calico).
    network_policy_config {
      disabled = false
    }
  }

  # Disable basic authentication and cert-based authentication.
  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = false
    }
  }

  # Enable network policy configurations (like Calico) - for some reason this
  # has to be in here twice.
  network_policy {
    provider = "CALICO"
    enabled  = true
  }

  pod_security_policy_config {
    enabled = true
  }

  # Set the maintenance window.
  maintenance_policy {
    daily_maintenance_window {
      start_time = "${var.kubernetes_daily_maintenance_window}"
    }
  }

  # Allocate IPs in our subnetwork
  ip_allocation_policy {
    cluster_secondary_range_name  = "${google_compute_subnetwork.vault-subnetwork.secondary_ip_range.0.range_name}"
    services_secondary_range_name = "${google_compute_subnetwork.vault-subnetwork.secondary_ip_range.1.range_name}"
  }

  # Specify the list of CIDRs which can access the master's API
  master_authorized_networks_config {
    cidr_blocks = ["${var.kubernetes_master_authorized_networks}"]
  }

  # Configure the cluster to be private (not have public facing IPs)
  private_cluster_config {
    # This field is misleading. This prevents access to the master API from
    # any external IP. While that might represent the most secure
    # configuration, it is not ideal for most setups. As such, we disable the
    # private endpoint (allow the public endpoint) and restrict which CIDRs
    # can talk to that endpoint.
    enable_private_endpoint = false

    enable_private_nodes   = true
    master_ipv4_cidr_block = "${var.kubernetes_masters_ipv4_cidr}"
  }

  depends_on = [
    "null_resource.services_wait",
    "google_kms_crypto_key_iam_member.vault",
    "google_storage_bucket_iam_member.vault",
    "google_project_iam_member.sa",
    "google_project_iam_member.sa-custom",
    "google_compute_router_nat.vault-nat",
  ]
}
