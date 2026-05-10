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
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
  }

  cloud {
    organization = "mazino2d-everything-as-code"

    workspaces {
      name = "k8s-mazino2d-as-se1-dev"
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

provider "google" {
  credentials = data.terraform_remote_state.gcp.outputs.k8s_tf_sa_key_json
}

data "google_client_config" "this" {}

locals {
  gke_host    = "https://${data.terraform_remote_state.gcp.outputs.gke_cluster_endpoint}"
  gke_ca_cert = base64decode(data.terraform_remote_state.gcp.outputs.gke_cluster_ca_cert)
  gke_token   = data.google_client_config.this.access_token
}

provider "kubernetes" {
  host                   = local.gke_host
  cluster_ca_certificate = local.gke_ca_cert
  token                  = local.gke_token
}

provider "kubectl" {
  host                   = local.gke_host
  cluster_ca_certificate = local.gke_ca_cert
  token                  = local.gke_token
  load_config_file       = false
}

provider "helm" {
  kubernetes {
    host                   = local.gke_host
    cluster_ca_certificate = local.gke_ca_cert
    token                  = local.gke_token
  }
}

