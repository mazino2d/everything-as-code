resource "infisical_group" "this" {
  name     = var.name
  org_role = var.org_role
}

resource "infisical_group_membership" "this" {
  for_each = toset(var.member_usernames)
  group_id = infisical_group.this.id
  username = each.value
}
