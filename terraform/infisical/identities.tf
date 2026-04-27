module "github_actions" {
  source   = "./_modules/infisical-identity"
  name     = "github-actions"
  org_id   = var.infisical_org_id
  role     = "no-access"
}
