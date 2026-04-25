variable "name" {
  type = string
}

variable "project_id" {
  type = string
}

variable "zone" {
  type    = string
  default = "us-central1-a"
}

variable "machine_type" {
  type    = string
  default = "e2-micro"
}

variable "disk_size_gb" {
  type    = number
  default = 30
}

variable "ssh_public_key" {
  type    = string
  default = null
}

variable "tags" {
  type    = list(string)
  default = []
}

variable "startup_script" {
  type    = string
  default = null
}

variable "extra_ports" {
  type    = list(string)
  default = []
}

variable "spot" {
  type    = bool
  default = false
}

variable "external_ip_type" {
  type    = string
  default = "none"
  validation {
    condition     = contains(["none", "ephemeral", "static"], var.external_ip_type)
    error_message = "Must be none, ephemeral, or static."
  }
}

variable "deny_egress_internet" {
  type    = bool
  default = false
}

variable "duckdns_domain" {
  type    = string
  default = null
}


