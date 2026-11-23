data "terraform_remote_state" "gcp" {
  backend = "gcs"

  config = {
    bucket = "mazino2d-as-se1-eac-tfstate"
    prefix = "state/gcp/mazino2d-as-se1-dev"
  }
}

data "terraform_remote_state" "github" {
  backend = "gcs"

  config = {
    bucket = "mazino2d-as-se1-eac-tfstate"
    prefix = "state/github"
  }
}

data "terraform_remote_state" "infisical" {
  backend = "gcs"

  config = {
    bucket = "mazino2d-as-se1-eac-tfstate"
    prefix = "state/infisical"
  }
}
