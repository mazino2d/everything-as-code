terraform {
  required_providers {
    infisical = {
      source  = "infisical/infisical"
      version = "~> 0.12"
    }
  }
}

data "infisical_organizations" "current" {}

resource "infisical_identity" "this" {
  name   = var.name
  org_id = data.infisical_organizations.current.organizations[0].id
  role   = var.role
}

resource "infisical_identity_universal_auth" "this" {
  identity_id          = infisical_identity.this.id
  access_token_ttl     = var.access_token_ttl
  access_token_max_ttl = var.access_token_max_ttl
}
