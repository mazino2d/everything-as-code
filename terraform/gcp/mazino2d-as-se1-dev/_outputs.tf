output "vm_free_ip" {
  description = "Ephemeral public IP of the free-tier VM."
  value       = module.vm_free.ip
}

output "velero_bucket_name" {
  description = "Velero backup bucket name."
  value       = google_storage_bucket.velero_backups.name
}

output "velero_bucket_url" {
  description = "Velero backup bucket URL."
  value       = google_storage_bucket.velero_backups.url
}

output "gke_connect_cmd" {
  description = "Command to configure kubectl for the GKE cluster."
  value       = "gcloud container clusters get-credentials ${google_container_cluster.this.name} --region ${google_container_cluster.this.location} --project ${module.project.project_id}"
}

output "gke_cluster_endpoint" {
  description = "GKE cluster API endpoint."
  value       = google_container_cluster.this.endpoint
  sensitive   = true
}

output "gke_cluster_ca_cert" {
  description = "GKE cluster CA certificate (base64)."
  value       = google_container_cluster.this.master_auth[0].cluster_ca_certificate
  sensitive   = true
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

output "gha_k8s_power_sa_email" {
  description = "Service account impersonated by the k8s-power workflow."
  value       = google_service_account.gha_k8s_power.email
}
