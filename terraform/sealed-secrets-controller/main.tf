locals {
  labels = {
    part-of  = "sealed-secrets"
    app      = "sealed-secrets"
    instance = "${var.instance == "" ? "main" : var.instance }"
  }

  enabled   = "${var.enabled}"
  basename  = "${var.instance == "" ? "sealed-secrets" : format("sealed-secrets%s",var.instance)}"
  namespace = "sealed-secrets"
}

resource "null_resource" "dependency_getter" {
  provisioner "local-exec" {
    command = "echo ${length(var.dependencies)}"
  }
}

resource "null_resource" "dependency_setter" {
  depends_on = [
    # List resource(s) that will be constructed last within the module.
    "kubernetes_deployment.controller",
  ]
}

resource "kubernetes_namespace" "ns" {
  count      = "${local.enabled == "true" ? 1 : 0}"
  depends_on = ["null_resource.dependency_getter"]

  metadata {
    annotations {
      name = "${local.namespace}"
    }

    labels = "${local.labels}"
    name   = "${local.namespace}"
  }
}

# kubectl apply - Terraform doesn't yet support CRDs
data "template_file" "crd" {
  count    = "${local.enabled == "true" ? 1 : 0}"
  template = "${file("${path.module}/crd.yaml")}"
}

resource "null_resource" "crd" {
  count = "${local.enabled == "true" ? 1 : 0}"

  #triggers {  #  deployment                   = "${md5(google_container_cluster.vault.endpoint)}"  #}

  provisioner "local-exec" {
    command = <<EOF
gcloud container clusters get-credentials "${var.cluster_name}" --region="${var.cluster_region}" --project="${var.cluster_project}"
CONTEXT="gke_${var.cluster_project}_${var.cluster_region}_${var.cluster_name}"
echo '${data.template_file.crd.rendered}' | kubectl apply --context="$CONTEXT" -n ${kubernetes_namespace.ns.metadata.0.name} -f -
EOF
  }
}

resource "kubernetes_service_account" "controller" {
  count = "${local.enabled == "true" ? 1 : 0}"

  metadata {
    name      = "${local.basename}-controller"
    namespace = "${kubernetes_namespace.ns.metadata.0.name}"

    labels = "${local.labels}"
  }
}

resource "kubernetes_role" "psp" {
  count = "${local.enabled == "true" ? 1 : 0}"

  metadata {
    name      = "${local.basename}-psp-unprivileged-addon"
    namespace = "${kubernetes_namespace.ns.metadata.0.name}"
    labels    = "${local.labels}"
  }

  rule = [
    {
      api_groups     = ["policy"]
      resources      = ["podsecuritypolicies"]
      resource_names = ["gce.unprivileged-addon"]
      verbs          = ["use"]
    },
  ]
}

resource "kubernetes_role_binding" "psp" {
  count = "${local.enabled == "true" ? 1 : 0}"

  metadata {
    name      = "${local.basename}-psp-unprivileged-addon"
    labels    = "${local.labels}"
    namespace = "${kubernetes_namespace.ns.metadata.0.name}"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "${kubernetes_role.psp.metadata.0.name}"
  }

  subject {
    kind      = "Group"
    name      = "system:serviceaccounts:${kubernetes_namespace.ns.metadata.0.name}"
    namespace = "${kubernetes_namespace.ns.metadata.0.name}"
  }
}

resource "kubernetes_cluster_role" "controller" {
  count = "${local.enabled == "true" ? 1 : 0}"

  metadata {
    name   = "${local.basename}-unsealer"
    labels = "${local.labels}"
  }

  rule = [
    {
      api_groups = [""]
      resources  = ["secrets"]
      verbs      = ["create", "update", "delete"]
    },
    {
      api_groups = ["bitnami.com"]
      resources  = ["sealedsecrets"]
      verbs      = ["get", "list", "watch"]
    },
  ]
}

resource "kubernetes_cluster_role_binding" "controller" {
  count = "${local.enabled == "true" ? 1 : 0}"

  metadata {
    name   = "${local.basename}-controller"
    labels = "${local.labels}"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "${kubernetes_cluster_role.controller.metadata.0.name}"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "${kubernetes_service_account.controller.metadata.0.name}"
    namespace = "${kubernetes_namespace.ns.metadata.0.name}"
  }
}

resource "kubernetes_role" "controller" {
  count = "${local.enabled == "true" ? 1 : 0}"

  metadata {
    name      = "${local.basename}-controller"
    labels    = "${local.labels}"
    namespace = "${kubernetes_namespace.ns.metadata.0.name}"
  }

  rule {
    api_groups     = [""]
    resources      = ["secrets"]
    resource_names = ["${local.basename}-key"]
    verbs          = ["get"]
  }

  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["create"]
  }
}

resource "kubernetes_role_binding" "controller" {
  count = "${local.enabled == "true" ? 1 : 0}"

  metadata {
    name      = "${local.basename}-controller"
    labels    = "${local.labels}"
    namespace = "${kubernetes_namespace.ns.metadata.0.name}"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "${kubernetes_role.controller.metadata.0.name}"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "${kubernetes_service_account.controller.metadata.0.name}"
    namespace = "${kubernetes_namespace.ns.metadata.0.name}"
  }
}

resource "kubernetes_secret" "controller" {
  count = "${local.enabled == "true" ? 1 : 0}"

  metadata {
    name      = "${local.basename}-key"
    namespace = "${kubernetes_namespace.ns.metadata.0.name}"

    labels = "${local.labels}"
  }

  data {
    "tls.crt" = "${var.tls_crt}"
    "tls.key" = "${var.tls_key}"
  }

  type = "kubernetes.io/tls"
}

resource "kubernetes_deployment" "controller" {
  count      = "${local.enabled == "true" ? 1 : 0}"
  depends_on = ["kubernetes_secret.controller", "null_resource.crd", "kubernetes_role_binding.psp"]

  metadata {
    name      = "${local.basename}-controller"
    namespace = "${kubernetes_namespace.ns.metadata.0.name}"

    labels = "${merge(map("name","${local.basename}-controller"), local.labels)}"
  }

  spec {
    replicas = 1

    selector {
      match_labels {
        name = "${local.basename}-controller"
      }
    }

    template {
      metadata {
        labels = "${merge(map("name","${local.basename}-controller"), local.labels)}"
      }

      spec {
        service_account_name = "${kubernetes_service_account.controller.metadata.0.name}"

        volume = [
          {
            name = "${kubernetes_service_account.controller.default_secret_name}"

            secret = {
              secret_name = "${kubernetes_service_account.controller.default_secret_name}"
            }
          },
        ]

        container {
          image = "quay.io/bitnami/sealed-secrets-controller:${var.controller_version}"
          name  = "sealed-secrets-controller"

          command = ["controller"]

          port = [
            {
              name           = "http"
              container_port = 8080
            },
          ]

          readiness_probe {
            http_get {
              path = "/healthz"
              port = 8080
            }
          }

          liveness_probe {
            http_get {
              path = "/healthz"
              port = 8080
            }
          }

          security_context {
            read_only_root_filesystem  = true
            run_as_non_root            = true
            run_as_user                = 1001
            allow_privilege_escalation = false
          }

          volume_mount = [
            {
              name       = "${kubernetes_service_account.controller.default_secret_name}"
              mount_path = "/var/run/secrets/kubernetes.io/serviceaccount"
              read_only  = true
            },
          ]

          resources {
            requests {
              cpu    = "25m"
              memory = "64Mi"
            }

            limits {
              cpu    = "150m"
              memory = "256Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_network_policy" "sealed-secrets" {
  metadata {
    name      = "${local.basename}-controller"
    namespace = "${kubernetes_namespace.ns.metadata.0.name}"
  }

  spec {
    pod_selector {
      match_expressions {
        key      = "name"
        operator = "In"
        values   = ["${local.basename}-controller"]
      }
    }

    ingress = [
      {
        ports = [
          {
            port     = "8080"
            protocol = "TCP"
          },
        ]
      },
    ]

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_service" "controller" {
  count = "${local.enabled == "true" ? 1 : 0}"

  metadata {
    name      = "${local.basename}-controller"
    namespace = "${kubernetes_namespace.ns.metadata.0.name}"

    labels = "${merge(map("name","${local.basename}-controller"), local.labels)}"
  }

  spec {
    selector {
      name     = "${kubernetes_deployment.controller.metadata.0.labels.name}"
      instance = "${kubernetes_deployment.controller.metadata.0.labels.instance}"
    }

    port {
      port = 8080
    }

    type = "ClusterIP"
  }
}

output "depended_on" {
  value = "${null_resource.dependency_setter.id}"
}
