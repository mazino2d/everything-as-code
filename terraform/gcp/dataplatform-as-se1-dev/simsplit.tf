# sim-split's raw data for the dev warehouse. The telemetry endpoint in
# simsplit-as-se1-dev writes error reports and usage events here; data-platform's
# dlt load adds the Firestore copy from simsplit-as-se1-dev, and the fake source
# (dlt/sources/simsplit_fake.py) adds synthetic rows so dashboards have data.
# The tables match dataplatform-as-se1-prd/simsplit.tf; change both together.
# Unlike prd, partitions expire after two years, so storage cannot grow forever
# and there is no storage alert.

resource "google_bigquery_dataset" "simsplit_raw" {
  project     = module.project.project_id
  dataset_id  = "simsplit_raw"
  location    = local.region
  description = "sim-split dev raw data: telemetry from the dev endpoint, Firestore copy from dlt, fake rows."

  max_time_travel_hours = "48"
}

resource "google_bigquery_table" "simsplit_error_reports" {
  project    = module.project.project_id
  dataset_id = google_bigquery_dataset.simsplit_raw.dataset_id
  table_id   = "error_reports"

  time_partitioning {
    type          = "DAY"
    field         = "received_at"
    expiration_ms = 63072000000 # 730 days
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
    type          = "DAY"
    field         = "received_at"
    expiration_ms = 63072000000 # 730 days
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

# The dev endpoint's service account, created by the gcp-simsplit-as-se1-dev
# workspace; until that workspace has applied its telemetry, the grant is left out.
data "terraform_remote_state" "simsplit" {
  backend = "remote"

  config = {
    organization = "mazino2d-everything-as-code"
    workspaces = {
      name = "gcp-simsplit-as-se1-dev"
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
