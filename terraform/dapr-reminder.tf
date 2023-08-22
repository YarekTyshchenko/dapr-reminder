resource "kubernetes_namespace" "dapr-reminder" {
  metadata {
    name = "dapr-reminder"
  }
}

locals {
  namespace = kubernetes_namespace.dapr-reminder.metadata.0.name
}

resource "kubernetes_secret" "dapr-secrets" {
  depends_on = [
    helm_release.rabbitmq,
    helm_release.postgres
  ]
  metadata {
    namespace = local.namespace
    name      = "dapr-secrets"
  }

  data = {
    "rabbitmq-pubsub-cs" : "amqp://admin:${random_password.rabbitmq_admin_password.result}@rabbitmq.rabbitmq.svc.cluster.local:5672"
    "postgres-statestore-cs" : "host=postgresql.postgres.svc.cluster.local port=5432 user=dapr password=${random_password.postgres_dapr_password.result} database=dapr"
  }
}

resource "kubectl_manifest" "statestore" {
  depends_on = [
    helm_release.dapr
  ]
  yaml_body = yamlencode({
    "apiVersion" = "dapr.io/v1alpha1"
    "kind"       = "Component"
    "metadata" = {
      "name"      = "statestore"
      "namespace" = local.namespace
    }
    "spec" = {
      "metadata" = [
        {
          "name" = "connectionString"
          "secretKeyRef" = {
            "name" = kubernetes_secret.dapr-secrets.metadata.0.name
            "key"  = "postgres-statestore-cs"
          }
        },
        {
          "name"  = "actorStateStore"
          "value" = "true"
        },
      ]
      "type"    = "state.postgresql"
      "version" = "v1"
    }
  })
}

resource "kubectl_manifest" "pubsub" {
  depends_on = [
    helm_release.dapr
  ]
  yaml_body = yamlencode({
    "apiVersion" = "dapr.io/v1alpha1"
    "kind"       = "Component"
    "metadata" = {
      "name"      = "pubsub"
      "namespace" = local.namespace
    }
    "spec" = {
      "metadata" = [
        {
          "name" = "connectionString"
          "secretKeyRef" = {
            "name" = kubernetes_secret.dapr-secrets.metadata.0.name
            "key"  = "rabbitmq-pubsub-cs"
          }
        },
        {
          "name"  = "deletedWhenUnused"
          "value" = false
        },
        {
          "name"  = "deliveryMode"
          "value" = 2
        },
        {
          "name"  = "enableDeadLetter"
          "value" = true
        },
        {
          "name"  = "prefetchCount"
          "value" = "100"
        }
      ]
      "type"    = "pubsub.rabbitmq"
      "version" = "v1"
    }
  })
}

resource "kubernetes_deployment" "dapr-reminder" {
  depends_on = [
    kubectl_manifest.statestore,
    kubectl_manifest.pubsub
  ]
  lifecycle {
    ignore_changes = []
  }
  metadata {
    name      = "dapr-reminder"
    namespace = local.namespace

    labels = {
      app = "dapr-reminder"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "dapr-reminder"
      }
    }

    template {
      metadata {
        labels = {
          app = "dapr-reminder"
        }

        annotations = {
          "dapr.io/enabled"  = "true"
          "dapr.io/app-id"   = "dapr-reminder"
          "dapr.io/app-port" = "80"
        }
      }

      spec {
        container {
          name              = "dapr-reminder"
          image             = "yarekt/dapr-reminder"
          image_pull_policy = "Always"
        }
      }
    }
  }
}

resource "kubernetes_service" "dapr-reminder" {
  metadata {
    name      = "dapr-reminder"
    namespace = local.namespace
    labels = {
      app = "dapr-reminder"
    }
  }

  spec {
    type = "ClusterIP"

    port {
      name        = "http"
      protocol    = "TCP"
      port        = 80
      target_port = "80"
    }

    selector = {
      app = "dapr-reminder"
    }
  }
}
