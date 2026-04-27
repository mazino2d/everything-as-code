module "everything_as_code" {
  source = "./_modules/infisical-project"
  name   = "everything-as-code"
  slug   = "everything-as-code"

  identities = [
    { id = module.github_actions.id, slug = "github-actions", role = "developer" },
  ]

  groups = [
    { id = module.admins.id, role = "admin" },
  ]
}
