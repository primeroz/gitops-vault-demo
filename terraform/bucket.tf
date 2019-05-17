# Create the storage bucket
resource "google_storage_bucket" "vault" {
  name          = "vault-storage-${random_id.random.hex}"
  project       = "${data.google_project.project.project_id}"
  force_destroy = true
  storage_class = "MULTI_REGIONAL"
  location      = "${var.bucket_location}"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }

    condition {
      num_newer_versions = 1
    }
  }

  depends_on = ["null_resource.services_wait"]
}
