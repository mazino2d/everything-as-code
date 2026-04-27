module "everything_as_code" {
  source = "./_modules/infisical-project"
  name   = "everything-as-code"
  slug   = "everything-as-code"

  identities = [
    { name = "github-actions", id = module.github_actions.id, role = "developer" },
  ]

  groups = [
    { name = "admins", id = module.admins.id, role = "admin" },
  ]
}
