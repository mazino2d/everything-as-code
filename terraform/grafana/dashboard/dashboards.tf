locals {
  create_prom_dashboards = var.grafana_prometheus_datasource_uid != null
  prom_uid               = var.grafana_prometheus_datasource_uid != null ? var.grafana_prometheus_datasource_uid : ""
}

resource "grafana_folder" "infrastructure" {
  title = "Infrastructure"
}

# Dashboards that use Grafana template variables — no UID substitution needed

resource "grafana_dashboard" "node_exporter" {
  folder      = grafana_folder.infrastructure.uid
  config_json = file("${path.module}/_dashboards/node_exporter.json")
  overwrite   = true
}

resource "grafana_dashboard" "cert_manager" {
  folder      = grafana_folder.infrastructure.uid
  config_json = file("${path.module}/_dashboards/cert_manager.json")
  overwrite   = true
}

# Dashboards that use ${DS_PROMETHEUS} / ${DS_PROM} static inputs — requires Prometheus datasource UID

resource "grafana_dashboard" "cadvisor" {
  count  = local.create_prom_dashboards ? 1 : 0
  folder = grafana_folder.infrastructure.uid
  config_json = replace(
    file("${path.module}/_dashboards/cadvisor.json"),
    "$${DS_PROMETHEUS}",
    local.prom_uid
  )
  overwrite = true
}

resource "grafana_dashboard" "postgresql" {
  count  = local.create_prom_dashboards ? 1 : 0
  folder = grafana_folder.infrastructure.uid
  config_json = replace(
    file("${path.module}/_dashboards/postgresql.json"),
    "$${DS_PROMETHEUS}",
    local.prom_uid
  )
  overwrite = true
}

resource "grafana_dashboard" "redis" {
  count  = local.create_prom_dashboards ? 1 : 0
  folder = grafana_folder.infrastructure.uid
  config_json = replace(
    file("${path.module}/_dashboards/redis.json"),
    "$${DS_PROM}",
    local.prom_uid
  )
  overwrite = true
}
