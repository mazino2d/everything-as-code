terraform {
  required_version = "~> 1.14"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.36"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.0"
    }
  }

  cloud {
    organization = "mazino2d-everything-as-code"

    workspaces {
      name = "k8s"
    }
  }
}

data "terraform_remote_state" "gcp" {
  backend = "remote"

  config = {
    organization = "mazino2d-everything-as-code"
    workspaces = {
      name = "gcp-mazino2d-as-se1-dev"
    }
  }
}

locals {
  kube_config = data.terraform_remote_state.gcp.outputs.kube_config_dev
}

provider "kubernetes" {
  host                   = local.kube_config.cluster_endpoint
  cluster_ca_certificate = base64decode(local.kube_config.ca_cert_b64)
  client_certificate     = base64decode(local.kube_config.client_cert_b64)
  client_key             = base64decode(local.kube_config.client_key_b64)
}

provider "kubectl" {
  host                   = local.kube_config.cluster_endpoint
  cluster_ca_certificate = base64decode(local.kube_config.ca_cert_b64)
  client_certificate     = base64decode(local.kube_config.client_cert_b64)
  client_key             = base64decode(local.kube_config.client_key_b64)
  load_config_file       = false
}

provider "helm" {
  kubernetes {
    host                   = local.kube_config.cluster_endpoint
    cluster_ca_certificate = base64decode(local.kube_config.ca_cert_b64)
    client_certificate     = base64decode(local.kube_config.client_cert_b64)
    client_key             = base64decode(local.kube_config.client_key_b64)
  }
}

