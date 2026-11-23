# Web OAuth client created by hand (see _docs/setup.md); Google sign-in stays
# disabled until both are set in the stack's secrets tfvars
# (make secrets-edit STACK=terraform/gcp/simsplit-as-se1-prd).
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
  default     = "20000" # VND, about 1 USD
}

variable "app_check_enforced" {
  description = "Reject Auth and Firestore requests without a valid App Check token."
  type        = bool
  default     = true
}
