terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.8.0"
    }
  }
}

provider "kubernetes" {
  host             = var.kube_host
  token            = var.kube_token
  insecure         = var.kube_insecure
}
