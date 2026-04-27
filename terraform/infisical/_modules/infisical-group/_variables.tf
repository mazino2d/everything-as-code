variable "name" {
  type        = string
  description = "Display name of the group."
}

variable "slug" {
  type        = string
  description = "URL-safe unique identifier for the group."
}

variable "role" {
  type        = string
  description = "Org-level role for the group: no-access, member, or admin."
  default     = "member"
}
