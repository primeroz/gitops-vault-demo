# gitops-vault-demo
A demo of vault on GKE managed through flux

## PREREQUISTIES

* A Google Cloud Platform project with billing enabled
* Gcloud service account for terraform in the project
  * EDITOR
	* STORAGE ADMIN
	* PROJECT IAM ADMIN
	* CLOUD KMS ADMIN
	* ROLE Administrator
* SERVICE USAGE API
  * https://console.developers.google.com/apis/library/serviceusage.googleapis.com?project=<YOURPROJECT>
	* should not be needed on new projects


## NOTES

* All terraform state is local - be careful
* All secrets are unencrypted - They are just placeholder, be careful
* Roles are not the most secure ever
