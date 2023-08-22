terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
    dns = {
      source = "hashicorp/dns"
      version = "3.3.2"
    }
    kubectl = {
      source = "gavinbunney/kubectl"
      version = "1.14.0"
    }
  }
}

provider "helm" {
  repository_config_path = "${path.module}/.helm/repositories.yaml"
  repository_cache       = "${path.module}/.helm"

  kubernetes {
    config_path = var.kubernetes_config_path
    config_context = var.kubernetes_config_context
  }
}
provider "kubectl" {
  config_path = var.kubernetes_config_path
  config_context = var.kubernetes_config_context
}
provider "kubernetes" {
  config_path = var.kubernetes_config_path
  config_context = var.kubernetes_config_context
}

variable "kubernetes_config_path" {
  type = string
  description = "Path to your kubernetes config file"
  default = "~/.kube/config"
}

variable "kubernetes_config_context" {
  type = string
  description = "Context to use from your kubernetes config file"
  default = "kind-kind"
}
