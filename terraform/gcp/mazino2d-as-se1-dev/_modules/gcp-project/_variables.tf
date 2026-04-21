variable "name" {
  type = string
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
