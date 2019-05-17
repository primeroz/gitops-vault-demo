resource "google_container_node_pool" "pool" {
  project    = "${var.project_id}"
  location   = "${var.region}"
  name       = "std-pool"
  cluster    = "${google_container_cluster.vault.name}"
  node_count = "${var.initial_node_count}"
  version    = "${data.google_container_engine_versions.versions.latest_master_version}"

  // Node workload metadata config requires that we use the beta provider
  provider = "google-beta"

  node_config {
    machine_type    = "${var.kubernetes_instance_type}"
    service_account = "${google_service_account.sa.email}"

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    # Set metadata on the VM to supply more entropy
    metadata {
      google-compute-enable-virtio-rng = "true"
      disable-legacy-endpoints         = "true"
    }

    # Protect node metadata
    workload_metadata_config {
      node_metadata = "SECURE"
    }

    disk_size_gb = "${var.node_pool_disk_size}"
    disk_type    = "${var.node_pool_disk_config}"

    labels = "${merge(
      map(
        "cluster", "${google_container_cluster.vault.name}",
        "node-pool", "std-pool",
        "service", "vault"
      ),
      var.node_labels
    )}"

    tags = [
      "${concat(
        list(
          "std-pool",
          "${google_container_cluster.vault.name}"
        ),
        var.node_tags
      )}",
    ]
  }

  autoscaling {
    min_node_count = "${var.min_node_count}"
    max_node_count = "${var.max_node_count}"
  }

  management {
    auto_repair  = "${var.auto_repair}"
    auto_upgrade = "${var.auto_upgrade}"
  }
}
