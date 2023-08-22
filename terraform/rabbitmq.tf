resource "kubernetes_namespace" "rabbitmq" {
  metadata {
    name = "rabbitmq"
  }
}

resource "random_password" "rabbitmq_admin_password" {
  length  = 40
  special = false
}

resource "random_password" "erlang_cookie" {
  length  = 255
  special = false
}

resource "helm_release" "rabbitmq" {
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "rabbitmq"
  name       = "rabbitmq"
  namespace  = kubernetes_namespace.rabbitmq.metadata.0.name
  version    = "12.0.0"
  wait = true

  values = [jsonencode({
    replicaCount: 1
    auth: {
      username: "admin"
      password: random_password.rabbitmq_admin_password.result
      erlangCookie: random_password.erlang_cookie.result
    }
  })]
}
