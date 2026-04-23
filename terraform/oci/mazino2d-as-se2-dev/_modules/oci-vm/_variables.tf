variable "name" {
  type = string
}

variable "compartment_id" {
  type = string
}

variable "ocpus" {
  type    = number
  default = 4
}

variable "memory_in_gbs" {
  type    = number
  default = 24
}

variable "boot_volume_size_gb" {
  type    = number
  default = 50
}

variable "ssh_public_key" {
  type    = string
  default = null
}

variable "startup_script" {
  type    = string
  default = null
}
