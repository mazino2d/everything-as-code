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

output "argocd_public_key" {
  value = tls_private_key.argocd.public_key_openssh
}

output "argocd_private_key_pem" {
  value     = tls_private_key.argocd.private_key_pem
  sensitive = true
}
