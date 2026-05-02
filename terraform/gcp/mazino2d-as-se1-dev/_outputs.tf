output "kube_config_dev" {
  description = "K3s cluster configuration for kubeconfig generation"
  value       = module.vm-dev.kube_config
  sensitive   = true
}

output "free_tier_gcs_bucket_name" {
  description = "Always-free tier GCS bucket name"
  value       = google_storage_bucket.free_tier.name
}

output "free_tier_gcs_bucket_url" {
  description = "Always-free tier GCS bucket URL"
  value       = google_storage_bucket.free_tier.url
}

output "workload_gsa" {
  description = "Per-workload GSA metadata and optional JSON key."
  value = {
    for workload_name, workload in module.workload_gsa : workload_name => {
      namespace             = workload.namespace
      app_name              = workload.app_name
      service_account_email = workload.service_account_email
      key_json              = workload.private_key_json
    }
  }
  sensitive = true
}
