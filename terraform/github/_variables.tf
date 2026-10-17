variable "github_token" {
  type      = string
  sensitive = true
  default   = null
}

variable "github_owner" {
  type    = string
  default = null
}

variable "eac_deployer_app_id" {
  type        = string
  description = "App ID of the eac-deployer GitHub App (created manually, see _docs/setup.md)"
}

variable "eac_deployer_app_private_key" {
  type        = string
  sensitive   = true
  description = "PEM private key of the eac-deployer GitHub App"
}

variable "a3spy_telegram_bot_token" {
  type        = string
  sensitive   = true
  default     = null
  description = "a3spy bot token from @BotFather (set by hand on the github workspace)"
}

variable "a3spy_owner_telegram_id" {
  type        = string
  sensitive   = true
  default     = null
  description = "Telegram user id allowed to send a3spy announcements with /announce (set by hand on the github workspace)"
}
