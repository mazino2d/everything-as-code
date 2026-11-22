output "project_id" {
  value      = google_project.this.project_id
  depends_on = [google_project_service.this]
}

output "project_number" {
  value = google_project.this.number
}
