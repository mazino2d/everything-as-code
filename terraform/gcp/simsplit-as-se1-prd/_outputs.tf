output "firebase" {
  description = "Firebase app IDs for `flutterfire configure` in sim-split."
  value = {
    project_id      = google_firebase_project.this.project
    android_app_id  = google_firebase_android_app.sim_split.app_id
    apple_app_id    = google_firebase_apple_app.sim_split.app_id
    web_app_id      = google_firebase_web_app.sim_split.app_id
    web_api_key     = data.google_firebase_web_app_config.sim_split.api_key
    web_auth_domain = data.google_firebase_web_app_config.sim_split.auth_domain
    hosting_url     = "https://${google_firebase_hosting_site.default.site_id}.web.app"
  }
}

output "firebase_deployer" {
  description = "Values for sim-split's google-github-actions/auth step in the Firebase deploy workflow."
  value = {
    workload_identity_provider = google_iam_workload_identity_pool_provider.sim_split.name
    service_account            = google_service_account.gha_firebase_deployer.email
  }
}

output "play_publisher" {
  description = "Values for sim-split's google-github-actions/auth step in the Android release workflow; invite the email in Play Console."
  value = {
    workload_identity_provider = google_iam_workload_identity_pool_provider.sim_split.name
    service_account            = google_service_account.gha_play_publisher.email
  }
}

output "app_check" {
  description = "Public App Check values for sim-split; the github stack sets the site key as a repo variable."
  value = {
    recaptcha_site_key = google_recaptcha_enterprise_key.web.name
    enforced           = var.app_check_enforced
  }
}

output "telemetry" {
  description = "R-4 telemetry endpoint: its URL for the app, its service account for the warehouse grant, and the values for sim-split's deploy workflow."
  value = {
    url                        = google_cloud_run_v2_service.telemetry.uri
    service_account            = google_service_account.telemetry.email
    image_repository           = "${google_artifact_registry_repository.telemetry.location}-docker.pkg.dev/${google_artifact_registry_repository.telemetry.project}/${google_artifact_registry_repository.telemetry.repository_id}"
    workload_identity_provider = google_iam_workload_identity_pool_provider.sim_split.name
    deployer_service_account   = google_service_account.gha_telemetry_deployer.email
  }
}
