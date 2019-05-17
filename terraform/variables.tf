variable "project_id" {
  type        = "string"
  description = "The project into which to deploy the resources"
}

variable "kms_location" {
  type        = "string"
  description = "Location for the kms resources"
  default     = "europe"
}

variable "bucket_location" {
  type        = "string"
  description = "Location for the bucket resources"
  default     = "EU"
}

variable "region" {
  type    = "string"
  default = "europe-west4"

  description = <<EOF
Region in which to create the cluster
EOF
}

variable "kubernetes_instance_type" {
  type    = "string"
  default = "n1-standard-2"

  description = <<EOF
Instance type to use for the nodes.
EOF
}

variable "kubernetes_nodes_per_zone" {
  type    = "string"
  default = "1"

  description = <<EOF
Number of nodes to deploy in each zone of the Kubernetes cluster. For example,
if there are 4 zones in the region and num_nodes_per_zone is 2, 8 total nodes
will be created.
EOF
}

variable "node_pool_disk_size" {
  type        = "string"
  description = "The size of the disks attached to node pool VMs"
  default     = "10"
}

variable "node_pool_disk_config" {
  type        = "string"
  description = "The type of disks attached to the node pool VMs (i.e. pd-standard or pd-ssd)"
  default     = "pd-ssd"
}

variable "initial_node_count" {
  type        = "string"
  description = "The number of nodes to create upon node pool creation. This is number of nodes PER ZONE!"
  default     = "1"
}

variable "min_node_count" {
  type        = "string"
  description = "The minimum number of nodes the pool can scale down to. This is number of nodes PER ZONE!"
  default     = "1"
}

variable "max_node_count" {
  type        = "string"
  description = "The maximum number of nodes the pool can scale up to. This is number of nodes PER ZONE!"
  default     = "1"
}

variable "auto_repair" {
  type        = "string"
  description = "Whether the nodes should attempt to repair themselves if an issue occurs"
  default     = "false"
}

variable "auto_upgrade" {
  type        = "string"
  description = "Whether the nodes should have their GKE Kubernetes version upgraded automatically"
  default     = "false"
}

variable "node_labels" {
  type        = "map"
  description = "Key-value map of Kubernetes-accessible labels to add to the nodes"
  default     = {}
}

variable "node_tags" {
  type        = "list"
  description = "List of GCP network tags to add to the nodes"
  default     = []
}

variable "kubernetes_daily_maintenance_window" {
  type    = "string"
  default = "03:00"

  description = <<EOF
Maintenance window for GKE.
EOF
}

variable "service_account_iam_roles" {
  type = "list"

  default = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
  ]
}

variable "service_account_custom_iam_roles" {
  type = "list"

  default = [
    "roles/iam.serviceAccountAdmin",
    "roles/iam.serviceAccountKeyAdmin",
    "roles/resourcemanager.projectIamAdmin",
  ]

  description = <<EOF
List of arbitrary additional IAM roles to attach to the service account on
the Vault nodes.
EOF
}

variable "project_services" {
  type = "list"

  default = [
    "cloudkms.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "container.googleapis.com",
    "compute.googleapis.com",
    "dns.googleapis.com",
    "iam.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "serviceusage.googleapis.com",
    "servicemanagement.googleapis.com",
  ]
}

variable "storage_bucket_roles" {
  type = "list"

  default = [
    "roles/storage.legacyBucketReader",
    "roles/storage.objectAdmin",
  ]
}

variable "kubernetes_logging_service" {
  type    = "string"
  default = "logging.googleapis.com/kubernetes"

  description = <<EOF
Name of the logging service to use. By default this uses the new Stackdriver
GKE beta.
EOF
}

variable "kubernetes_monitoring_service" {
  type    = "string"
  default = "monitoring.googleapis.com/kubernetes"

  description = <<EOF
Name of the monitoring service to use. By default this uses the new
Stackdriver GKE beta.
EOF
}

variable "kubernetes_network_ipv4_cidr" {
  type    = "string"
  default = "10.0.96.0/22"

  description = <<EOF
IP CIDR block for the subnetwork. This must be at least /22 and cannot overlap
with any other IP CIDR ranges.
EOF
}

variable "kubernetes_pods_ipv4_cidr" {
  type    = "string"
  default = "10.0.92.0/22"

  description = <<EOF
IP CIDR block for pods. This must be at least /22 and cannot overlap with any
other IP CIDR ranges.
EOF
}

variable "kubernetes_services_ipv4_cidr" {
  type    = "string"
  default = "10.0.88.0/22"

  description = <<EOF
IP CIDR block for services. This must be at least /22 and cannot overlap with
any other IP CIDR ranges.
EOF
}

variable "kubernetes_masters_ipv4_cidr" {
  type    = "string"
  default = "10.0.82.0/28"

  description = <<EOF
IP CIDR block for the Kubernetes master nodes. This must be exactly /28 and
cannot overlap with any other IP CIDR ranges.
EOF
}

variable "kubernetes_master_authorized_networks" {
  type = "list"

  default = [
    {
      display_name = "Anyone"
      cidr_block   = "0.0.0.0/0"
    },
  ]

  description = <<EOF
List of CIDR blocks to allow access to the master's API endpoint. This is
specified as a slice of objects, where each object has a display_name and
cidr_block attribute:

[
  {
    display_name = "My range"
    cidr_block   = "1.2.3.4/32"
  },
  {
    display_name = "My other range"
    cidr_block   = "5.6.7.0/24"
  }
]

The default behavior is to allow anyone (0.0.0.0/0) access to the endpoint.
You should restrict access to external IPs that need to access the cluster.
EOF
}

variable "flux_bootstrap_enabled" {
  default = "false"
}

variable "flux_bootstrap_git_poll_interval" {
  default = "1m"
}

variable "flux_bootstrap_sync_interval" {
  default = "5m"
}

variable "flux_bootstrap_git_url" {
  default = ""
}

variable "flux_bootstrap_git_branch" {
  default = ""
}

variable "flux_bootstrap_git_paths" {
  default = []
  type    = "list"
}

variable "flux_bootstrap_git_label" {
  default = "flux-sync-bootstrap-dev"
}

variable "flux_bootstrap_ssh_private_key" {
  description = "SSH Private key for flux"
}

variable "flux_bootstrap_sync_garbage_collection" {
  default = "true"
}

variable "flux_bootstrap_instance_name" {
  default = "bootstrap"
}

variable "flux_bootstrap_disable_registry_scan" {
  default = "true"
}

variable "flux_bootstrap_wait_seconds_at_start" {
  default = "30"
}

variable "sealed_secrets_enabled" {
  default = "false"
}

variable "sealed_secrets_crt" {
  description = "Sealed Secrets controller SSL CRT"
}

variable "sealed_secrets_key" {
  description = "Sealed Secrets controller SSL KEY"
}

variable "sealed_secrets_controller_version" {
  default = "v0.7.0"
}

variable "flux_image" {
  default = "docker.io/weaveworks/flux"
}

variable "flux_version" {
  default = "0.12.2"
}
