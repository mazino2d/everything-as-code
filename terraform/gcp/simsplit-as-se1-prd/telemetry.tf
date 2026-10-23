# R-4 telemetry endpoint: sim-split sends error reports and usage events to this
# Cloud Run service, which logs error reports to Cloud Logging (alerts below) and
# writes everything to the simsplit_raw dataset in dataplatform-as-se1-prd. Its
# code and deploy workflow live in mazino2d/sim-split (services/telemetry).
# Every limit here is a cost guard: the backend must stay at $0.

resource "google_artifact_registry_repository" "telemetry" {
  project       = module.project.project_id
  location      = local.region
  repository_id = "telemetry"
  format        = "DOCKER"

  # Stay far inside the free 0.5 GB of storage.
  cleanup_policies {
    id     = "keep-latest-2"
    action = "KEEP"
    most_recent_versions {
      keep_count = 2
    }
  }

  cleanup_policies {
    id     = "delete-older"
    action = "DELETE"
    condition {
      tag_state = "ANY"
    }
  }
}

resource "google_service_account" "telemetry" {
  project      = module.project.project_id
  account_id   = "telemetry"
  display_name = "sim-split telemetry endpoint"
}

resource "google_cloud_run_v2_service" "telemetry" {
  project  = module.project.project_id
  name     = "telemetry"
  location = local.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account                  = google_service_account.telemetry.email
    timeout                          = "10s"
    max_instance_request_concurrency = 80

    # Scale to zero, never more than one instance: the endpoint's in-memory
    # per-install caps are exact, and a flood cannot fan out into more cost.
    scaling {
      min_instance_count = 0
      max_instance_count = 1
    }

    containers {
      # Placeholder until sim-split's deploy workflow pushes the real image.
      image = "us-docker.pkg.dev/cloudrun/container/hello"

      resources {
        limits = {
          cpu    = "1"
          memory = "256Mi"
        }
        # Request-based billing: CPU only while a request is in flight.
        cpu_idle          = true
        startup_cpu_boost = false
      }

      env {
        name  = "FIREBASE_PROJECT_ID"
        value = module.project.project_id
      }
      env {
        name  = "BIGQUERY_PROJECT_ID"
        value = "dataplatform-as-se1-prd"
      }
      env {
        name  = "BIGQUERY_DATASET"
        value = "simsplit_raw"
      }
    }
  }

  # sim-split's deploy workflow owns the image and the revision metadata.
  lifecycle {
    ignore_changes = [
      client,
      client_version,
      template[0].containers[0].image,
      template[0].labels,
      template[0].annotations,
    ]
  }
}

# The app calls it directly; the service itself rejects requests without a
# valid App Check token (and a Firebase ID token for usage events).
resource "google_cloud_run_v2_service_iam_member" "telemetry_public" {
  project  = google_cloud_run_v2_service.telemetry.project
  location = google_cloud_run_v2_service.telemetry.location
  name     = google_cloud_run_v2_service.telemetry.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Deploys new images from sim-split's telemetry workflow on main.
resource "google_service_account" "gha_telemetry_deployer" {
  project      = module.project.project_id
  account_id   = "gha-telemetry-deployer"
  display_name = "GitHub Actions sim-split telemetry deployer"
}

resource "google_service_account_iam_member" "gha_telemetry_deployer_wif" {
  service_account_id = google_service_account.gha_telemetry_deployer.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/mazino2d/sim-split"
}

resource "google_artifact_registry_repository_iam_member" "gha_telemetry_deployer" {
  project    = google_artifact_registry_repository.telemetry.project
  location   = google_artifact_registry_repository.telemetry.location
  repository = google_artifact_registry_repository.telemetry.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.gha_telemetry_deployer.email}"
}

resource "google_cloud_run_v2_service_iam_member" "gha_telemetry_deployer" {
  project  = google_cloud_run_v2_service.telemetry.project
  location = google_cloud_run_v2_service.telemetry.location
  name     = google_cloud_run_v2_service.telemetry.name
  role     = "roles/run.developer"
  member   = "serviceAccount:${google_service_account.gha_telemetry_deployer.email}"
}

# A new revision runs as the telemetry service account.
resource "google_service_account_iam_member" "gha_telemetry_deployer_act_as" {
  service_account_id = google_service_account.telemetry.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.gha_telemetry_deployer.email}"
}

# Alerts come from Cloud Logging only: the endpoint logs one ERROR line per
# error report. Log-match policies return no points; Cloud Monitoring charges
# $0.35 a month per policy from September 2027 at the earliest.
resource "google_monitoring_notification_channel" "maintainer" {
  project      = module.project.project_id
  display_name = "Maintainer email"
  type         = "email"
  labels = {
    email_address = local.alert_email
  }
}

resource "google_monitoring_alert_policy" "error_reports" {
  project      = module.project.project_id
  display_name = "sim-split error reports"
  combiner     = "OR"

  conditions {
    display_name = "An error report arrived"
    condition_matched_log {
      filter = <<-EOT
        resource.type="cloud_run_revision"
        resource.labels.service_name="${google_cloud_run_v2_service.telemetry.name}"
        jsonPayload.kind="error_report"
        severity=ERROR
      EOT
      label_extractors = {
        error_type  = "EXTRACT(jsonPayload.error_type)"
        platform    = "EXTRACT(jsonPayload.platform)"
        app_version = "EXTRACT(jsonPayload.app_version)"
      }
    }
  }

  # A burst of reports sends one email an hour, not hundreds.
  alert_strategy {
    notification_rate_limit {
      period = "3600s"
    }
    auto_close = "1800s"
  }

  documentation {
    mime_type = "text/markdown"
    content   = "Find the reports in Logs Explorer (`jsonPayload.kind=\"error_report\"`) or in BigQuery `dataplatform-as-se1-prd.simsplit_raw.error_reports`, by `report_id`."
  }

  notification_channels = [google_monitoring_notification_channel.maintainer.id]
}

# data-platform's daily dlt load copies groups, members, expenses, settlements,
# activity and users from Firestore into the warehouse (R-4). The service
# account is created by the gcp-dataplatform-as-se1-prd stack.
resource "google_project_iam_member" "gha_data_platform_firestore" {
  project = module.project.project_id
  role    = "roles/datastore.viewer"
  member  = "serviceAccount:gha-data-platform@dataplatform-as-se1-prd.iam.gserviceaccount.com"
}
