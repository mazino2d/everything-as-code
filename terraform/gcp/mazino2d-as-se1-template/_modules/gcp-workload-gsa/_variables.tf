variable "project_id" {
  type = string
}

variable "namespace" {
  type = string
}

variable "app_name" {
  type = string
}

variable "project_roles" {
  type    = list(string)
  default = []
}

variable "bucket_roles" {
  type    = map(list(string))
  default = {}
}

variable "create_sa_key" {
  type    = bool
  default = false
}
