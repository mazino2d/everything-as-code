locals {
  workload_tree = yamldecode(file("${path.module}/workload_gsa.yaml")).workloads

  workloads = merge([
    for namespace, apps in local.workload_tree : {
      for app_name, config in apps : "${namespace}-${app_name}" => {
        namespace     = namespace
        app_name      = app_name
        project_roles = try(tolist(config.project_roles), [])
        bucket_roles  = try(config.bucket_roles, {})
        create_sa_key = try(config.create_sa_key, false)
      }
    }
  ]...)
}

module "workload_gsa" {
  for_each = local.workloads

  source        = "./_modules/gcp-workload-gsa"
  project_id    = module.project.project_id
  namespace     = each.value.namespace
  app_name      = each.value.app_name
  project_roles = each.value.project_roles
  bucket_roles  = each.value.bucket_roles
  create_sa_key = each.value.create_sa_key
}
