variable "grafana_cloud_access_policy_token" {
  description = "Grafana Cloud access policy token for managing cloud-level resources (stacks, access policies, service accounts)."
  type        = string
  sensitive   = true
  default     = null
}
