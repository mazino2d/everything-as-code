module "admins" {
  source = "./_modules/infisical-group"
  name   = "admins"
  slug   = "admins"
  role   = "admin"
}
