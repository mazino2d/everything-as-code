output "firebase" {
  description = "Firebase app IDs for `flutterfire configure` in sim-split's dev flavour."
  value = {
    project_id      = google_firebase_project.this.project
    android_app_id  = google_firebase_android_app.sim_split.app_id
    web_app_id      = google_firebase_web_app.sim_split.app_id
    web_api_key     = data.google_firebase_web_app_config.sim_split.api_key
    web_auth_domain = data.google_firebase_web_app_config.sim_split.auth_domain
    hosting_url     = "https://${google_firebase_hosting_site.default.site_id}.web.app"
  }
}

output "firebase_deployer" {
  description = "Values for sim-split's google-github-actions/auth step when deploying to dev; the github stack sets them as DEV_* repo variables."
  value = {
    workload_identity_provider = google_iam_workload_identity_pool_provider.sim_split.name
    service_account            = google_service_account.gha_firebase_deployer.email
  }
}

output "app_check" {
  description = "Public App Check values for sim-split's dev builds; the github stack sets the site key as a repo variable."
  value = {
    recaptcha_site_key = google_recaptcha_enterprise_key.web.name
    enforced           = var.app_check_enforced
  }
}
