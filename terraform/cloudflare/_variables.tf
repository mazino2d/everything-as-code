variable "cloudflare_api_token" {
  description = "Cloudflare API token with Cloudflare Tunnel, Zero Trust and Access: Apps and Policies edit permissions."
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID."
  type        = string
}

variable "warp_allowed_emails" {
  description = "Email addresses allowed to enrol devices in the WARP client (one-time PIN login)."
  type        = list(string)
}
