output "state_bucket" {
  value = google_storage_bucket.tfstate.name
}

output "workload_identity_provider" {
  value = google_iam_workload_identity_pool_provider.everything_as_code.name
}
