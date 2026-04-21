variable "github_token" {
  type      = string
  sensitive = true
  default   = null
}

variable "github_owner" {
  type    = string
  default = null
}
