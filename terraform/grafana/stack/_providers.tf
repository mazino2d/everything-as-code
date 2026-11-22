terraform {
  required_version = "~> 1.14"

  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "~> 3.16"
    }
  }

  backend "gcs" {
    bucket = "mazino2d-as-se1-dev-tfstate"
    prefix = "state/grafana/stack"
  }
}

provider "grafana" {
  cloud_access_policy_token = var.grafana_cloud_access_policy_token
}
