resource "infisical_project" "this" {
  name = var.name
  slug = var.slug
}

resource "infisical_project_identity" "this" {
  for_each    = { for i in var.identities : i.slug => i }
  project_id  = infisical_project.this.id
  identity_id = each.value.id
  roles       = [{ role = each.value.role }]
}

resource "infisical_project_group" "this" {
  for_each   = { for g in var.groups : g.id => g }
  project_id = infisical_project.this.id
  group_id   = each.value.id
  roles      = [{ role = each.value.role }]
}
