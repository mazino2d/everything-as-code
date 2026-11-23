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
      version = "~> 2.4"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 7.19"
    }
  }

  backend "gcs" {
    bucket = "mazino2d-as-se1-eac-tfstate"
    prefix = "state/k8s/mazino2d-as-se1-dev"
  }
}

# Application Default Credentials: in CI the workload identity of
# terraform@mazino2d-as-se1-dev (.github/workflows/terraform.yml), locally your own login.
provider "google" {}

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

