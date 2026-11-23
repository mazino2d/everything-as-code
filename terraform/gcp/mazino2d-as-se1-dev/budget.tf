# GKE Autopilot on Spot and the free-tier VM should stay around this. Billing
# account admins get an email at 50 % and 100 % of the budget; there is no kill
# switch, since unlinking billing would stop the cluster and the VM.
resource "google_billing_budget" "this" {
  billing_account = local.billing_account_id
  display_name    = "${local.project_id} monthly"

  budget_filter {
    projects               = ["projects/${module.project.project_number}"]
    credit_types_treatment = "INCLUDE_ALL_CREDITS"
  }

  # No currency_code: it must match the billing account's currency.
  amount {
    specified_amount {
      units = var.budget_amount
    }
  }

  threshold_rules {
    threshold_percent = 0.5
  }

  threshold_rules {
    threshold_percent = 1.0
  }

  # The Billing Budgets API is enabled by module.project in the same apply.
  depends_on = [module.project]
}
