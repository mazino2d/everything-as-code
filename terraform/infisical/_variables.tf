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

variable "remote_state_organization" {
  type        = string
  description = "Terraform Cloud organization used to resolve remote state secrets."
  default     = "mazino2d-everything-as-code"
}
