resource "tls_private_key" "argocd" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "github_repository_deploy_key" "argocd" {
  title      = "argocd-mazino2d-as-se1-dev"
  repository = "everything-as-code"
  key        = tls_private_key.argocd.public_key_openssh
  read_only  = true
}
