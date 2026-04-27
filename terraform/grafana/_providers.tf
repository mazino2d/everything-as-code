terraform {
  required_version = "~> 1.14"

  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "~> 3.16"
    }
    infisical = {
      source  = "infisical/infisical"
      version = "~> 0.12"
    }
  }

  cloud {
    organization = "mazino2d-everything-as-code"

    workspaces {
      name = "grafana"
    }
  }
}

provider "grafana" {
  cloud_access_policy_token = var.grafana_cloud_access_policy_token
}

provider "infisical" {
  host          = "https://app.infisical.com"
  client_id     = data.terraform_remote_state.infisical.outputs.cicd_client_id
  client_secret = data.terraform_remote_state.infisical.outputs.cicd_grafana_client_secret
}
