resource "random_id" "random" {
  byte_length = "4"
}

data "google_project" "project" {
  project_id = "${var.project_id}"
}

# Get latest cluster version
data "google_container_engine_versions" "versions" {
  depends_on = ["null_resource.services_wait"]
  project    = "${data.google_project.project.project_id}"
  location   = "${var.region}"
}
