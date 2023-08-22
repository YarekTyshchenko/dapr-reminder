resource "kubernetes_namespace" "dapr-system" {
  metadata {
    name = "dapr-system"
  }
}

resource "helm_release" "dapr" {
  repository = "https://dapr.github.io/helm-charts/"
  chart      = "dapr"
  name       = "dapr"
  namespace  = kubernetes_namespace.dapr-system.metadata.0.name
  version    = "1.11.2"

  set {
    name = "global.mtls.enabled"
    value = false
  }
}
