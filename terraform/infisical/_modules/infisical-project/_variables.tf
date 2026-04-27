variable "name" {
  type        = string
  description = "Display name of the project."
}

variable "slug" {
  type        = string
  description = "URL-safe unique identifier for the project."
}

variable "identities" {
  type = list(object({
    id   = string
    role = string
  }))
  description = "Machine identities to assign to this project."
  default     = []
}

variable "groups" {
  type = list(object({
    id   = string
    role = string
  }))
  description = "Groups to assign to this project."
  default     = []
}
