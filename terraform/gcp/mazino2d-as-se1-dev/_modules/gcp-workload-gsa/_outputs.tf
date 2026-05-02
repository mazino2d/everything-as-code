output "namespace" {
  value = var.namespace
}

output "app_name" {
  value = var.app_name
}

output "service_account_email" {
  value = google_service_account.this.email
}

output "private_key_json" {
  value     = var.create_sa_key ? base64decode(google_service_account_key.this[0].private_key) : null
  sensitive = true
}
