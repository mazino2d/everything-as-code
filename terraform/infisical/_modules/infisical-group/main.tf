terraform {
  required_providers {
    infisical = {
      source  = "infisical/infisical"
      version = "~> 0.12"
    }
  }
}

resource "infisical_group" "this" {
  name = var.name
  slug = var.slug
  role = var.role
}
