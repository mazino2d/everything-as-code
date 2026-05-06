variable "create_stack" {
  type    = bool
  default = true
}

variable "stack_slug" {
  type = string
}

variable "stack_name" {
  type = string
}

variable "stack_region_slug" {
  type    = string
  default = "prod-ap-southeast-1"
}
