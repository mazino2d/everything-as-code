# Web OAuth client created by hand (see _docs/setup.md); Google sign-in stays
# disabled until both are set in the stack's secrets tfvars
# (make secrets-edit STACK=terraform/gcp/simsplit-as-se1-dev).
variable "google_oauth_client_id" {
  type    = string
  default = null
}

variable "google_oauth_client_secret" {
  type      = string
  sensitive = true
  default   = null
}

variable "budget_amount" {
  description = "Monthly budget in the billing account's currency. Billing is unlinked once actual cost reaches it."
  type        = string
  default     = "1"
}

variable "app_check_debug_token" {
  description = "UUID that debug builds of sim-split pass as APP_CHECK_DEBUG_TOKEN (see _docs/setup.md)."
  type        = string
  sensitive   = true
  default     = null
}

variable "app_check_enforced" {
  description = "Reject Auth and Firestore requests without a valid App Check token."
  type        = bool
  default     = true
}
