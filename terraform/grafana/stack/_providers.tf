terraform {
  required_version = "~> 1.14"

  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "~> 3.16"
    }
  }

  cloud {
    organization = "mazino2d-everything-as-code"

    workspaces {
      name = "grafana-stack"
    }
  }
}

provider "grafana" {
  cloud_access_policy_token = var.grafana_cloud_access_policy_token
}
