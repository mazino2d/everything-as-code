data "terraform_remote_state" "infisical" {
  backend = "remote"

  config = {
    organization = "mazino2d-everything-as-code"
    workspaces = {
      name = "infisical"
    }
  }
}
