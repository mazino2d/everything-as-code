# sim-split R-9 notifications service (services/crm): sends push notifications
# for group activity, settle reminders and campaigns. Its config is code in
# sim-split's crm/ folder, baked into the image; sim-split's crm_deploy.yml
# ships new images. Nothing calls it from the internet: Eventarc (activity
# entries), Cloud Tasks (batch flush) and Cloud Scheduler (tick) invoke it as
# the crm service account. The dev copy is simsplit-as-se1-dev/crm.tf. Every limit here is a cost guard: the backend must
# stay at $0. Plan: sim-split docs/implementations/R-9-notifications-crm.md.

resource "google_artifact_registry_repository" "crm" {
  project       = module.project.project_id
  location      = local.region
  repository_id = "crm"
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

resource "google_service_account" "crm" {
  project      = module.project.project_id
  account_id   = "crm-sender"
  display_name = "sim-split notifications service"
}

resource "google_cloud_run_v2_service" "crm" {
  project  = module.project.project_id
  name     = "crm"
  location = local.region
  # Reachable by URL, but only callers with run.invoker (below) get through.
  ingress = "INGRESS_TRAFFIC_ALL"

  template {
    service_account                  = google_service_account.crm.email
    timeout                          = "300s"
    max_instance_request_concurrency = 20

    # Scale to zero, never more than one instance: calm limits and the send
    # ledger stay simple, and a burst of events cannot fan out into cost.
    scaling {
      min_instance_count = 0
      max_instance_count = 1
    }

    containers {
      # Placeholder until sim-split's crm_deploy.yml pushes the real image.
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
        name  = "CRM_ENV"
        value = "prd"
      }
      env {
        name  = "FIREBASE_PROJECT_ID"
        value = module.project.project_id
      }
      env {
        name  = "CRM_TASKS_QUEUE"
        value = google_cloud_tasks_queue.crm_flush.id
      }
      env {
        name  = "CRM_SENDS_DATASET"
        value = "dataplatform-as-se1-prd.simsplit_raw"
      }
      env {
        name  = "CRM_TRAITS_TABLE"
        value = "dataplatform-as-se1-prd.simsplit_crm.user_traits"
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

# Eventarc, Cloud Tasks and Cloud Scheduler all call the service as the crm
# account; no one else may invoke it.
resource "google_cloud_run_v2_service_iam_member" "crm_invoker" {
  project  = google_cloud_run_v2_service.crm.project
  location = google_cloud_run_v2_service.crm.location
  name     = google_cloud_run_v2_service.crm.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.crm.email}"
}

# R-9 P3: reads groups, members, activity, preferences and devices, keeps
# its server-only state (crm_pending, crm_sends, crm_deferred), deletes
# devices whose token FCM rejects, and sends pushes.
resource "google_project_iam_member" "crm_sender" {
  for_each = toset([
    "roles/datastore.user",
    "roles/firebasecloudmessaging.admin",
    # Audience queries run in this project, against the warehouse's
    # simsplit_crm dataset (granted in dataplatform-as-se1-*/simsplit.tf).
    "roles/bigquery.jobUser",
  ])

  project = module.project.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.crm.email}"
}

# Group activity: one event per new activity entry. The service reads the
# entry from Firestore, so the protobuf payload is never decoded.
resource "google_project_iam_member" "crm_event_receiver" {
  project = module.project.project_id
  role    = "roles/eventarc.eventReceiver"
  member  = "serviceAccount:${google_service_account.crm.email}"
}

resource "google_eventarc_trigger" "crm_activity" {
  project  = module.project.project_id
  name     = "crm-activity"
  location = local.region

  matching_criteria {
    attribute = "type"
    value     = "google.cloud.firestore.document.v1.created"
  }
  matching_criteria {
    attribute = "database"
    value     = "(default)"
  }
  matching_criteria {
    attribute = "document"
    value     = "groups/{groupId}/activity/{entryId}"
    operator  = "match-path-pattern"
  }

  event_data_content_type = "application/protobuf"
  service_account         = google_service_account.crm.email

  destination {
    cloud_run_service {
      service = google_cloud_run_v2_service.crm.name
      region  = local.region
      path    = "/events"
    }
  }

  depends_on = [google_project_iam_member.crm_event_receiver]
}

# Batched group activity: the service schedules one flush task per group and
# window. Cloud Tasks is free under 1 M operations a month.
resource "google_cloud_tasks_queue" "crm_flush" {
  project  = module.project.project_id
  name     = "crm-flush"
  location = local.region

  rate_limits {
    max_dispatches_per_second = 5
    max_concurrent_dispatches = 5
  }

  retry_config {
    max_attempts  = 5
    min_backoff   = "10s"
    max_backoff   = "300s"
    max_doublings = 4
  }
}

resource "google_cloud_tasks_queue_iam_member" "crm_enqueuer" {
  project  = google_cloud_tasks_queue.crm_flush.project
  location = google_cloud_tasks_queue.crm_flush.location
  name     = google_cloud_tasks_queue.crm_flush.name
  role     = "roles/cloudtasks.enqueuer"
  member   = "serviceAccount:${google_service_account.crm.email}"
}

# Tasks carry an OIDC token for the crm account itself.
resource "google_service_account_iam_member" "crm_act_as_self" {
  service_account_id = google_service_account.crm.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.crm.email}"
}

# Schedules and campaigns: one tick every 15 minutes (Cloud Scheduler's free
# tier is three jobs per billing account; this stack and prd use one each).
resource "google_cloud_scheduler_job" "crm_tick" {
  project   = module.project.project_id
  name      = "crm-tick"
  region    = local.region
  schedule  = "*/15 * * * *"
  time_zone = "Etc/UTC"

  # No retry: the next tick comes 15 minutes later anyway (the API's default
  # retry_count is already 0, so no retry_config block).
  attempt_deadline = "300s"

  http_target {
    http_method = "POST"
    uri         = "${google_cloud_run_v2_service.crm.uri}/tick"

    oidc_token {
      service_account_email = google_service_account.crm.email
      audience              = google_cloud_run_v2_service.crm.uri
    }
  }
}

# Deploys new images from sim-split's crm_deploy.yml, only from jobs in the
# prd GitHub Environment (crm_apply.yml runs it from main after a repo
# admin's "crm apply" on a green PR).
resource "google_service_account" "gha_crm_deployer" {
  project      = module.project.project_id
  account_id   = "gha-crm-deployer"
  display_name = "GitHub Actions sim-split crm deployer"
}

resource "google_service_account_iam_member" "gha_crm_deployer_wif" {
  service_account_id = google_service_account.gha_crm_deployer.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.environment/prd"
}

resource "google_artifact_registry_repository_iam_member" "gha_crm_deployer" {
  project    = google_artifact_registry_repository.crm.project
  location   = google_artifact_registry_repository.crm.location
  repository = google_artifact_registry_repository.crm.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.gha_crm_deployer.email}"
}

resource "google_cloud_run_v2_service_iam_member" "gha_crm_deployer" {
  project  = google_cloud_run_v2_service.crm.project
  location = google_cloud_run_v2_service.crm.location
  name     = google_cloud_run_v2_service.crm.name
  role     = "roles/run.developer"
  member   = "serviceAccount:${google_service_account.gha_crm_deployer.email}"
}

# A new revision runs as the crm service account.
resource "google_service_account_iam_member" "gha_crm_deployer_act_as" {
  service_account_id = google_service_account.crm.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.gha_crm_deployer.email}"
}

# Errors in the notifications service (including stale traits, which stop
# scheduled sends) email the maintainer, at most once an hour.
resource "google_monitoring_alert_policy" "crm_errors" {
  project      = module.project.project_id
  display_name = "sim-split crm errors"
  combiner     = "OR"

  conditions {
    display_name = "The crm service logged an error"
    condition_matched_log {
      filter = <<-EOT
        resource.type="cloud_run_revision"
        resource.labels.service_name="${google_cloud_run_v2_service.crm.name}"
        severity>=ERROR
      EOT
      label_extractors = {
        kind = "EXTRACT(jsonPayload.kind)"
      }
    }
  }

  alert_strategy {
    notification_rate_limit {
      period = "3600s"
    }
    auto_close = "1800s"
  }

  notification_channels = [google_monitoring_notification_channel.maintainer.id]
}
