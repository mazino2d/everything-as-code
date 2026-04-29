data "terraform_remote_state" "k8s" {
  backend = "remote"

  config = {
    organization = "mazino2d-everything-as-code"
    workspaces = {
      name = "k8s"
    }
  }
}

resource "github_repository_deploy_key" "argocd" {
  title      = "argocd-mazino2d-as-se1-dev"
  repository = "everything-as-code"
  key        = data.terraform_remote_state.k8s.outputs.argocd_public_key
  read_only  = true
}
