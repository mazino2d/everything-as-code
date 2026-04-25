variable "gcp_credentials" {
  type      = string
  sensitive = true
  default   = null
}

variable "ssh_public_key" {
  type    = string
  default = null
}
