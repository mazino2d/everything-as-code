module "secret_tree" {
  source                    = "./_modules/infisical-secret-tree"
  project_id                = module.everything_as_code.id
  environments              = ["dev", "staging", "prod"]
  remote_state_organization = var.remote_state_organization
  tree                      = yamldecode(file("${path.module}/secret_tree.yaml")).tree
}
