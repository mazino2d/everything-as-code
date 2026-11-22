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
    prefix = "state/grafana/dashboard"
  }
}

# Reads outputs from the grafana-stack workspace — no manual token copying required.
# Terraform Cloud evaluates terraform_remote_state (built-in provider) before user-defined
# providers, so the SA token can be referenced directly in the grafana provider block.
data "terraform_remote_state" "grafana_stack" {
  backend = "gcs"


  config = {
    bucket = "mazino2d-as-se1-dev-tfstate"
    prefix = "state/grafana/stack"
  }
}

provider "grafana" {
  url  = data.terraform_remote_state.grafana_stack.outputs.grafana_stack_url
  auth = data.terraform_remote_state.grafana_stack.outputs.grafana_mazino2d_sa_token
}
