output "data_platform_ci" {
  description = "Values for data-platform's google-github-actions/auth step; the github stack sets them as repo variables."
  value = {
    project_id                 = module.project.project_id
    workload_identity_provider = google_iam_workload_identity_pool_provider.data_platform.name
    service_account            = google_service_account.gha_data_platform.email
  }
}
