# Hard cap: unlinks billing from the project once actual cost reaches the
# budget. Every Blaze service (Firestore, Auth, Hosting) stops until billing is
# linked again by re-running apply on this stack (see _docs/setup.md).
# Budget notifications can lag actual spend by hours, so this caps runaway cost
# rather than guaranteeing zero.
data "archive_file" "billing_kill_switch" {
  type        = "zip"
  source_dir  = "${path.module}/_functions/billing_kill_switch"
  output_path = "${path.module}/.terraform/billing_kill_switch.zip"
}

# us-central1 keeps the source bucket inside the Cloud Storage free tier.
resource "google_storage_bucket" "functions_source" {
  project                     = module.project.project_id
  name                        = "${local.project_id}-functions-source"
  location                    = "US-CENTRAL1"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = true
}

resource "google_storage_bucket_object" "billing_kill_switch" {
  bucket = google_storage_bucket.functions_source.name
  name   = "billing_kill_switch-${data.archive_file.billing_kill_switch.output_md5}.zip"
  source = data.archive_file.billing_kill_switch.output_path
}

# Builds the function image; new projects no longer give the default compute
# service account these roles.
resource "google_service_account" "functions_build" {
  project      = module.project.project_id
  account_id   = "functions-build"
  display_name = "Cloud Functions build"
}

resource "google_project_iam_member" "functions_build" {
  for_each = toset([
    "roles/cloudbuild.builds.builder",
    "roles/logging.logWriter",
    "roles/artifactregistry.writer",
    "roles/storage.objectViewer",
  ])

  project = module.project.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.functions_build.email}"
}

# Runs the function and its Pub/Sub trigger. Project Billing Manager is the
# narrowest role that can unlink the project from its billing account.
resource "google_service_account" "billing_kill_switch" {
  project      = module.project.project_id
  account_id   = "billing-kill-switch"
  display_name = "Billing kill switch"
}

resource "google_project_iam_member" "billing_kill_switch" {
  for_each = toset([
    "roles/billing.projectManager",
    "roles/run.invoker",
    "roles/eventarc.eventReceiver",
  ])

  project = module.project.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.billing_kill_switch.email}"
}

resource "google_cloudfunctions2_function" "billing_kill_switch" {
  project  = module.project.project_id
  name     = "billing-kill-switch"
  location = local.region

  build_config {
    runtime         = "python312"
    entry_point     = "stop_billing"
    service_account = google_service_account.functions_build.id

    source {
      storage_source {
        bucket = google_storage_bucket.functions_source.name
        object = google_storage_bucket_object.billing_kill_switch.name
      }
    }
  }

  service_config {
    max_instance_count    = 1
    available_memory      = "256M"
    timeout_seconds       = 60
    ingress_settings      = "ALLOW_INTERNAL_ONLY"
    service_account_email = google_service_account.billing_kill_switch.email
    environment_variables = {
      PROJECT_ID = local.project_id
    }
  }

  event_trigger {
    trigger_region        = local.region
    event_type            = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic          = google_pubsub_topic.billing_alerts.id
    retry_policy          = "RETRY_POLICY_RETRY"
    service_account_email = google_service_account.billing_kill_switch.email
  }

  depends_on = [
    google_project_iam_member.functions_build,
    google_project_iam_member.billing_kill_switch,
  ]
}
