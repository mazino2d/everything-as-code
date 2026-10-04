# The project must cost nothing at SimSplit's scale (~100 users). Billing
# account admins get emails at 50 % and 100 %; every update also goes to
# Pub/Sub, where the kill switch (kill_switch.tf) unlinks billing at 100 %.
resource "google_pubsub_topic" "billing_alerts" {
  project = module.project.project_id
  name    = "billing-alerts"
}

resource "google_pubsub_topic_iam_member" "billing_alerts_publisher" {
  project = module.project.project_id
  topic   = google_pubsub_topic.billing_alerts.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:billing-budget-alert@system.gserviceaccount.com"
}

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

  threshold_rules {
    threshold_percent = 1.0
    spend_basis       = "FORECASTED_SPEND"
  }

  all_updates_rule {
    pubsub_topic                   = google_pubsub_topic.billing_alerts.id
    schema_version                 = "1.0"
    disable_default_iam_recipients = false
  }

  depends_on = [google_pubsub_topic_iam_member.billing_alerts_publisher]
}
