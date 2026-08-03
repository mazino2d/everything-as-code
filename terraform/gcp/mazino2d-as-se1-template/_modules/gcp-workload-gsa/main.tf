locals {
  raw_account_id = lower("gsa-${var.namespace}-${var.app_name}")
  sanitised_account_id = replace(local.raw_account_id, "/[^a-z0-9-]/", "-")
  compacted_account_id = replace(local.sanitised_account_id, "/-+/", "-")
  trimmed_account_id   = trim(local.compacted_account_id, "-")
  account_id           = trimsuffix(substr(local.trimmed_account_id, 0, 30), "-")

  bucket_role_bindings = {
    for item in flatten([
      for bucket_name, roles in var.bucket_roles : [
        for role in roles : {
          key    = "${bucket_name}:${role}"
          bucket = bucket_name
          role   = role
        }
      ]
    ]) : item.key => item
  }
}

resource "google_service_account" "this" {
  project      = var.project_id
  account_id   = local.account_id
  display_name = "${var.namespace}-${var.app_name} workload service account"
}

resource "google_project_iam_member" "project_roles" {
  for_each = toset(var.project_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.this.email}"
}

resource "google_storage_bucket_iam_member" "bucket_roles" {
  for_each = local.bucket_role_bindings

  bucket = each.value.bucket
  role   = each.value.role
  member = "serviceAccount:${google_service_account.this.email}"
}

resource "google_service_account_key" "this" {
  count = var.create_sa_key ? 1 : 0

  service_account_id = google_service_account.this.name
}
