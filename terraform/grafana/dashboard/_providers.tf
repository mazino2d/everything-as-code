terraform {
  required_version = "~> 1.14"

  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "~> 3.16"
    }
  }

  backend "gcs" {
    bucket = "mazino2d-as-se1-eac-tfstate"
    prefix = "state/grafana/dashboard"
  }
}

# URL and SA token come from terraform/grafana/stack's state, so no token is
# copied by hand; that stack must have applied first.
data "terraform_remote_state" "grafana_stack" {
  backend = "gcs"

  config = {
    bucket = "mazino2d-as-se1-eac-tfstate"
    prefix = "state/grafana/stack"
  }
}

provider "grafana" {
  url  = data.terraform_remote_state.grafana_stack.outputs.grafana_stack_url
  auth = data.terraform_remote_state.grafana_stack.outputs.grafana_mazino2d_sa_token
}
