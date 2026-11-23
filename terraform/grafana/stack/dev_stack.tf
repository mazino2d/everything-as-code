module "grafana_cloud_dev" {
  source = "./_modules/grafana-cloud-stack"

  stack_slug        = "mazino2d"
  stack_region_slug = "prod-ap-southeast-1"
}
