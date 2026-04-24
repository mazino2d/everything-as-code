variable "name" {
  type = string
}

variable "compartment_id" {
  type = string
}

variable "shape" {
  type = string
}

variable "ocpus" {
  type    = number
  default = null
}

variable "memory_in_gbs" {
  type    = number
  default = null
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
