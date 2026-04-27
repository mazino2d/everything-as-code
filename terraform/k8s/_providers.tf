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

provider "kubernetes" {
  config_content = base64decode(var.k3s_kubeconfig)
}
