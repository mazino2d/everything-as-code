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

variable "remote_state_bucket" {
  type        = string
  description = "GCS bucket holding every stack's state under state/<stack path>."
  default     = "mazino2d-as-se1-eac-tfstate"
}
