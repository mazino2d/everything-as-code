module "grafana_cloud_dev" {
  source = "./_modules/grafana-cloud-stack"

  create_stack      = false
  stack_slug        = "mazino2d"
  stack_name        = "mazino2d"
  stack_region_slug = "prod-ap-southeast-1"
}
