terraform {
  required_version = "~> 1.14"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.36"
    }
  }

  cloud {
    organization = "mazino2d-everything-as-code"

    workspaces {
      name = "k8s"
    }
  }
}

locals {
  kubeconfig = yamldecode(base64decode(var.k3s_kubeconfig))
}

provider "kubernetes" {
  host                   = local.kubeconfig.clusters[0].cluster.server
  cluster_ca_certificate = base64decode(local.kubeconfig.clusters[0].cluster["certificate-authority-data"])
  client_certificate     = base64decode(local.kubeconfig.users[0].user["client-certificate-data"])
  client_key             = base64decode(local.kubeconfig.users[0].user["client-key-data"])
}
