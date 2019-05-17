resource "google_kms_key_ring" "vault" {
  name     = "${random_id.random.hex}"
  location = "${var.kms_location}"
  project  = "${data.google_project.project.project_id}"

  depends_on = ["null_resource.services_wait"]
}

resource "google_kms_crypto_key" "vault" {
  name            = "vault"
  key_ring        = "${google_kms_key_ring.vault.id}"
  rotation_period = "604800s"
}
