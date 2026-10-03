variable "gcp_credentials" {
  type      = string
  sensitive = true
  default   = null
}

# Web OAuth client created by hand (see _docs/setup.md); Google sign-in stays
# disabled until both are set as TFC variables.
variable "google_oauth_client_id" {
  type    = string
  default = null
}

variable "google_oauth_client_secret" {
  type      = string
  sensitive = true
  default   = null
}

# Apple sign-in needs an active Apple Developer account; it stays disabled
# until the services ID and client secret are set (see _docs/setup.md).
variable "apple_team_id" {
  type    = string
  default = null
}

variable "apple_services_id" {
  type    = string
  default = null
}

variable "apple_client_secret" {
  description = "Signed JWT from the Sign in with Apple key; expires after at most six months."
  type        = string
  sensitive   = true
  default     = null
}

variable "budget_amount" {
  description = "Monthly budget in the billing account's currency. Billing is unlinked once actual cost reaches it."
  type        = string
  default     = "1"
}
