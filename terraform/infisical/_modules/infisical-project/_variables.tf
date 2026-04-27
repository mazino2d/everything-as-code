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
    name = string
    id   = string
    role = string
  }))
  description = "Machine identities to assign to this project. 'name' is used as the static for_each key."
  default     = []
}
