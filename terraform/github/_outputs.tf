output "argocd_public_key" {
  value = tls_private_key.argocd.public_key_openssh
}

output "argocd_private_key_pem" {
  value     = tls_private_key.argocd.private_key_pem
  sensitive = true
}
