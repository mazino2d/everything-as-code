resource "google_project" "this" {
  name            = coalesce(var.name, var.project_id)
  project_id      = var.project_id
  billing_account = var.billing_account_id
}

resource "google_project_service" "this" {
  for_each = toset(var.services)

  project            = google_project.this.project_id
  service            = each.value
  disable_on_destroy = false
}
