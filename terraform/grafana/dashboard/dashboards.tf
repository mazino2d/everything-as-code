data "grafana_data_source" "prometheus" {
  name = "grafanacloud-mazino2d-prom"
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

# Dashboards that use ${DS_PROMETHEUS} / ${DS_PROM} static inputs

resource "grafana_dashboard" "cadvisor" {
  folder = grafana_folder.infrastructure.uid
  config_json = replace(
    file("${path.module}/_dashboards/cadvisor.json"),
    "$${DS_PROMETHEUS}",
    data.grafana_data_source.prometheus.uid
  )
  overwrite = true
}

resource "grafana_dashboard" "postgresql" {
  folder = grafana_folder.infrastructure.uid
  config_json = replace(
    file("${path.module}/_dashboards/postgresql.json"),
    "$${DS_PROMETHEUS}",
    data.grafana_data_source.prometheus.uid
  )
  overwrite = true
}

resource "grafana_dashboard" "redis" {
  folder = grafana_folder.infrastructure.uid
  config_json = replace(
    file("${path.module}/_dashboards/redis.json"),
    "$${DS_PROM}",
    data.grafana_data_source.prometheus.uid
  )
  overwrite = true
}
