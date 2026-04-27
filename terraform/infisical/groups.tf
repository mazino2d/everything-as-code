module "admins" {
  source   = "./_modules/infisical-group"
  name     = "admins"
  org_role = "admin"

  member_usernames = [
    "mazino2d@gmail.com",
  ]
}
