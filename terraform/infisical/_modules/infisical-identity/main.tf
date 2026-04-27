terraform {
  required_providers {
    infisical = {
      source  = "infisical/infisical"
      version = "~> 0.12"
    }
  }
}

data "infisical_identity_details" "current" {}

resource "infisical_identity" "this" {
  name   = var.name
  org_id = data.infisical_identity_details.current.organization.id
  role   = var.role
}

resource "infisical_identity_universal_auth" "this" {
  identity_id          = infisical_identity.this.id
  access_token_ttl     = var.access_token_ttl
  access_token_max_ttl = var.access_token_max_ttl
}

resource "infisical_identity_universal_auth_client_secret" "this" {
  for_each    = { for s in var.client_secrets : s.name => s }
  identity_id = infisical_identity.this.id
  description = each.value.description
}
