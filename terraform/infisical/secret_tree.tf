module "secret_tree" {
  source              = "./_modules/infisical-secret-tree"
  project_id          = module.everything_as_code.id
  environments        = ["dev"]
  remote_state_bucket = local.remote_state_bucket
  tree                = yamldecode(file("${path.module}/secret_tree.yaml")).tree
}
