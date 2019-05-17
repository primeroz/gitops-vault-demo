# Enable required services on the project
resource "google_project_service" "service" {
  count   = "${length(var.project_services)}"
  project = "${data.google_project.project.project_id}"
  service = "${element(var.project_services, count.index)}"

  # Do not disable the service on destroy. On destroy, we are going to
  # destroy the project, but we need the APIs available to destroy the
  # underlying resources.
  disable_on_destroy = false
}

resource "null_resource" "services_wait" {
  triggers = {
    services_ids = "${join(",", google_project_service.service.*.id)}"
  }

  provisioner "local-exec" {
    command = "sleep 30"
  }
}
