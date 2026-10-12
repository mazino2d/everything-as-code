variable "cloudflare_api_token" {
  type        = string
  sensitive   = true
  default     = null
  description = "Bootstrap token with Account API Tokens Edit (created manually, see _docs/setup.md)"
}

variable "cloudflare_account_id" {
  type = string
}
