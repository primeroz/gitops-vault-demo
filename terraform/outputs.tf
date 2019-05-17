output "project" {
  value = "${data.google_project.project.project_id}"
}

output "region" {
  value = "${var.region}"
}

output "kms_region" {
  value = "${google_kms_key_ring.vault.location}"
}

output "kms_key_ring" {
  value = "${google_kms_key_ring.vault.name}"
}

output "kms_crypto_key" {
  value = "${google_kms_crypto_key.vault.name}"
}

output "gcs_bucket_name" {
  value = "${google_storage_bucket.vault.name}"
}
