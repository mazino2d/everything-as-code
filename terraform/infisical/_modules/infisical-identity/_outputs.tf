output "id" {
  value = infisical_identity.this.id
}

output "name" {
  value = infisical_identity.this.name
}

output "client_id" {
  value = try(values(infisical_identity_universal_auth_client_secret.this)[0].client_id, null)
}

output "client_secrets" {
  value     = { for k, v in infisical_identity_universal_auth_client_secret.this : k => v.client_secret }
  sensitive = true
}
