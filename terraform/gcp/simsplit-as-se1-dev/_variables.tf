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

# Signing certificate fingerprints of the Play app com.mazino2d.simsplit.dev,
# for Google sign-in on Android: Play Console → SimSplit Dev → App integrity →
# Play app signing (app signing key, then upload key). The upload key is prd's
# (same keystore); the app signing key is added with a PR once the app exists in
# Play Console (_docs/setup.md § 4).
variable "android_sha1_hashes" {
  description = "SHA-1 fingerprints, lower case without colons."
  type        = list(string)
  default = [
    "d4ba311c4d85f5f084b06839742de9390e237fa5", # upload key
  ]
}

variable "android_sha256_hashes" {
  description = "SHA-256 fingerprints, lower case without colons."
  type        = list(string)
  default = [
    "8ab3bf0adce70fdd609fb0d527eed930b6f829b2f69af45cdcd179b885a89399", # upload key
  ]
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
