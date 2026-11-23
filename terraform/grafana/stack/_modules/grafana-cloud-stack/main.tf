terraform {
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "~> 3.16"
    }
  }
}

# The stack itself is made by hand in Grafana Cloud; Terraform only reads it.
data "grafana_cloud_stack" "this" {
  slug = var.stack_slug
}

locals {
  stack = data.grafana_cloud_stack.this
}

resource "grafana_cloud_access_policy" "metrics_push" {
  region       = var.stack_region_slug
  name         = "${var.stack_slug}-metrics-push"
  display_name = "${var.stack_slug} Alloy metrics push"

  scopes = ["metrics:write", "logs:write", "traces:write"]

  realm {
    type       = "stack"
    identifier = local.stack.id
  }
}

resource "grafana_cloud_access_policy_token" "alloy" {
  region           = var.stack_region_slug
  access_policy_id = grafana_cloud_access_policy.metrics_push.policy_id
  name             = "${var.stack_slug}-alloy"
  display_name     = "${var.stack_slug} Alloy token"
}

resource "grafana_cloud_stack_service_account" "terraform" {
  stack_slug = var.stack_slug
  name       = "terraform"
  role       = "Admin"
}

resource "grafana_cloud_stack_service_account_token" "terraform" {
  stack_slug         = var.stack_slug
  name               = "terraform"
  service_account_id = grafana_cloud_stack_service_account.terraform.id
}
