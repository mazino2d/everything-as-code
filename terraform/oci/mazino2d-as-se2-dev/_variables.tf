variable "tenancy_ocid" {
  type      = string
  sensitive = true
}

variable "user_ocid" {
  type      = string
  sensitive = true
}

variable "fingerprint" {
  type      = string
  sensitive = true
}

variable "private_key" {
  type      = string
  sensitive = true
}

variable "region" {
  type    = string
  default = "ap-singapore-1"
}

variable "ssh_public_key" {
  type    = string
  default = null
}
