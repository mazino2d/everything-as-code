variable "name" {
  type        = string
  description = "Display name of the machine identity."
}

variable "org_role" {
  type        = string
  description = "Org-level role: no-access, member, or admin."
  default     = "no-access"
}

variable "access_token_ttl" {
  type        = number
  description = "Access token TTL in seconds."
  default     = 2592000
}

variable "access_token_max_ttl" {
  type        = number
  description = "Access token max TTL in seconds."
  default     = 2592000
}
