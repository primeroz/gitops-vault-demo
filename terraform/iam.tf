# Create the vault service account
resource "google_service_account" "sa" {
  depends_on   = ["null_resource.services_wait"]
  account_id   = "vault-${random_id.random.hex}"
  display_name = "Vault Project Node Pool service account"
  project      = "${data.google_project.project.project_id}"
}

# Add the service account to the project
resource "google_project_iam_member" "sa" {
  count   = "${length(var.service_account_iam_roles)}"
  project = "${data.google_project.project.project_id}"
  role    = "${element(var.service_account_iam_roles, count.index)}"
  member  = "serviceAccount:${google_service_account.sa.email}"
}

# Add user-specified roles
resource "google_project_iam_member" "sa-custom" {
  count   = "${length(var.service_account_custom_iam_roles)}"
  project = "${data.google_project.project.project_id}"
  role    = "${element(var.service_account_custom_iam_roles, count.index)}"
  member  = "serviceAccount:${google_service_account.sa.email}"
}

# Create a custom IAM role with the most minimal set of permissions for the
# KMS auto-unsealer. Once hashicorp/vault#5999 is merged, this can be replaced
# with the built-in roles/cloudkms.cryptoKeyEncrypterDecryptor role.
resource "google_project_iam_custom_role" "vault-seal-kms" {
  depends_on  = ["null_resource.services_wait"]
  project     = "${data.google_project.project.project_id}"
  role_id     = "kmsEncrypterDecryptorViewer"
  title       = "KMS Encrypter Decryptor Viewer"
  description = "KMS crypto key permissions to encrypt, decrypt, and view key data"

  permissions = [
    "cloudkms.cryptoKeyVersions.useToEncrypt",
    "cloudkms.cryptoKeyVersions.useToDecrypt",

    # This is required until hashicorp/vault#5999 is merged. The auto-unsealer
    # attempts to read the key, which requires this additional permission.
    "cloudkms.cryptoKeys.get",
  ]
}

# Grant service account access to the key
resource "google_kms_crypto_key_iam_member" "vault" {
  crypto_key_id = "${google_kms_crypto_key.vault.id}"
  role          = "projects/${data.google_project.project.project_id}/roles/${google_project_iam_custom_role.vault-seal-kms.role_id}"
  member        = "serviceAccount:${google_service_account.sa.email}"
}

resource "google_storage_bucket_iam_member" "vault" {
  count  = "${length(var.storage_bucket_roles)}"
  bucket = "${google_storage_bucket.vault.name}"
  role   = "${element(var.storage_bucket_roles, count.index)}"
  member = "serviceAccount:${google_service_account.sa.email}"
}
