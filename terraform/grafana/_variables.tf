variable "grafana_cloud_access_policy_token" {
  type      = string
  sensitive = true
  default   = null
}

variable "infisical_client_id" {
  type      = string
  sensitive = true
  default   = null
}

variable "infisical_client_secret" {
  type      = string
  sensitive = true
  default   = null
}

variable "infisical_project_id" {
  type        = string
  description = "ID of the everything-as-code Infisical project (from Infisical UI → Project Settings)."
}
