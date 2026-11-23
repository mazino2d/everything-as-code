variable "name" {
  description = "Display name; defaults to project_id."
  type        = string
  default     = null
}

variable "project_id" {
  type = string
}

variable "billing_account_id" {
  type      = string
  sensitive = true
  default   = null
}

variable "services" {
  type    = list(string)
  default = []
}
