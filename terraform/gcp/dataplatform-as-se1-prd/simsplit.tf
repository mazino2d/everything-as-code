# R-4: sim-split's raw data in the warehouse. The telemetry endpoint in
# simsplit-as-se1-prd writes error reports and usage events here through the
# BigQuery Storage Write API; data-platform's dlt load adds the Firestore copy
# (users, groups, members, expenses, settlements, activity) to the same dataset.
# Nothing expires: reports and events are kept indefinitely.

resource "google_bigquery_dataset" "simsplit_raw" {
  project     = module.project.project_id
  dataset_id  = "simsplit_raw"
  location    = local.region
  description = "sim-split raw data: telemetry from the endpoint, Firestore copy from dlt."

  # The minimum: a deleted user's rows stay readable for at most 2 days after
  # the daily load removes them (R-4 AC11).
  max_time_travel_hours = "48"
}

resource "google_bigquery_table" "simsplit_error_reports" {
  project    = module.project.project_id
  dataset_id = google_bigquery_dataset.simsplit_raw.dataset_id
  table_id   = "error_reports"

  time_partitioning {
    type  = "DAY"
    field = "received_at"
  }
  clustering = ["report_id"]

  schema = jsonencode([
    { name = "received_at", type = "TIMESTAMP", mode = "REQUIRED" },
    { name = "report_id", type = "STRING", mode = "REQUIRED" },
    { name = "session_id", type = "STRING", mode = "NULLABLE" },
    { name = "client_time", type = "TIMESTAMP", mode = "NULLABLE" },
    { name = "platform", type = "STRING", mode = "NULLABLE" },
    { name = "os", type = "STRING", mode = "NULLABLE" },
    { name = "app_version", type = "STRING", mode = "NULLABLE" },
    { name = "language", type = "STRING", mode = "NULLABLE" },
    { name = "signed_in", type = "BOOLEAN", mode = "NULLABLE" },
    { name = "online", type = "BOOLEAN", mode = "NULLABLE" },
    { name = "error_type", type = "STRING", mode = "NULLABLE" },
    { name = "message", type = "STRING", mode = "NULLABLE" },
    { name = "stack", type = "STRING", mode = "NULLABLE" },
    { name = "count", type = "INTEGER", mode = "NULLABLE" },
    {
      name = "breadcrumbs", type = "RECORD", mode = "REPEATED",
      fields = [
        { name = "time", type = "TIMESTAMP", mode = "NULLABLE" },
        { name = "kind", type = "STRING", mode = "NULLABLE" },
        { name = "name", type = "STRING", mode = "NULLABLE" },
      ]
    },
  ])
}

resource "google_bigquery_table" "simsplit_usage_events" {
  project    = module.project.project_id
  dataset_id = google_bigquery_dataset.simsplit_raw.dataset_id
  table_id   = "usage_events"

  time_partitioning {
    type  = "DAY"
    field = "received_at"
  }
  clustering = ["uid", "name"]

  schema = jsonencode([
    { name = "received_at", type = "TIMESTAMP", mode = "REQUIRED" },
    { name = "uid", type = "STRING", mode = "REQUIRED" },
    { name = "session_id", type = "STRING", mode = "REQUIRED" },
    { name = "client_time", type = "TIMESTAMP", mode = "NULLABLE" },
    { name = "kind", type = "STRING", mode = "REQUIRED" },
    { name = "name", type = "STRING", mode = "REQUIRED" },
    { name = "screen", type = "STRING", mode = "NULLABLE" },
    { name = "result", type = "STRING", mode = "NULLABLE" },
    { name = "duration_ms", type = "INTEGER", mode = "NULLABLE" },
    { name = "platform", type = "STRING", mode = "NULLABLE" },
    { name = "app_version", type = "STRING", mode = "NULLABLE" },
    { name = "language", type = "STRING", mode = "NULLABLE" },
    { name = "online", type = "BOOLEAN", mode = "NULLABLE" },
  ])
}

# The endpoint's service account, created by the gcp-simsplit-as-se1-prd
# workspace; until that workspace has applied, the grant is left out.
data "terraform_remote_state" "simsplit" {
  backend = "remote"

  config = {
    organization = "mazino2d-everything-as-code"
    workspaces = {
      name = "gcp-simsplit-as-se1-prd"
    }
  }

  defaults = {
    telemetry = null
  }
}

locals {
  simsplit_telemetry = data.terraform_remote_state.simsplit.outputs.telemetry
}

resource "google_bigquery_dataset_iam_member" "simsplit_telemetry" {
  count = local.simsplit_telemetry != null ? 1 : 0

  project    = module.project.project_id
  dataset_id = google_bigquery_dataset.simsplit_raw.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${local.simsplit_telemetry.service_account}"
}

# Nothing is deleted, so storage only grows: email the maintainer at 80 % of
# BigQuery's 10 GiB of free storage, the trigger to aggregate or archive.
resource "google_monitoring_notification_channel" "maintainer" {
  project      = module.project.project_id
  display_name = "Maintainer email"
  type         = "email"
  labels = {
    email_address = local.alert_email
  }
}

resource "google_monitoring_alert_policy" "storage" {
  project      = module.project.project_id
  display_name = "Warehouse storage above 8 GiB"
  combiner     = "OR"

  conditions {
    display_name = "Stored bytes across all datasets"
    condition_threshold {
      filter          = "resource.type = \"bigquery_dataset\" AND metric.type = \"bigquery.googleapis.com/storage/stored_bytes\""
      comparison      = "COMPARISON_GT"
      threshold_value = 8589934592
      duration        = "0s"

      aggregations {
        alignment_period     = "3600s"
        per_series_aligner   = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_SUM"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.maintainer.id]
}
