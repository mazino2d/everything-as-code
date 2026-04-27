terraform {
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "~> 3.16"
    }
  }
}

resource "grafana_cloud_stack" "this" {
  name        = var.stack_name
  slug        = var.stack_slug
  region_slug = var.stack_region_slug
}

resource "grafana_cloud_access_policy" "metrics_push" {
  region       = var.stack_region_slug
  name         = "${var.stack_slug}-metrics-push"
  display_name = "${var.stack_slug} Alloy metrics push"

  scopes = ["metrics:write"]

  realms {
    type       = "stack"
    identifier = grafana_cloud_stack.this.id
  }
}

resource "grafana_cloud_access_policy_token" "alloy" {
  region           = var.stack_region_slug
  access_policy_id = grafana_cloud_access_policy.metrics_push.policy_id
  name             = "${var.stack_slug}-alloy"
  display_name     = "${var.stack_slug} Alloy token"
}
