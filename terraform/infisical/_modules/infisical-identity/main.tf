resource "infisical_identity" "this" {
  name = var.name
  role = var.org_role
}

resource "infisical_identity_universal_auth" "this" {
  identity_id          = infisical_identity.this.id
  access_token_ttl     = var.access_token_ttl
  access_token_max_ttl = var.access_token_max_ttl
}
