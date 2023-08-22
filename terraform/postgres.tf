resource "kubernetes_namespace" "postgres" {
  metadata {
    name = "postgres"
  }
}

resource "random_password" "postgres_dapr_password" {
  length  = 40
  special = false
}

resource "helm_release" "postgres" {
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "postgresql"
  name       = "postgresql"
  namespace  = kubernetes_namespace.postgres.metadata.0.name
  version    = "12.8.5"
  wait = true

  values = [jsonencode({
    auth : {
      username : "dapr"
      password : random_password.postgres_dapr_password.result
      database : "dapr"
    }
  })]
}
