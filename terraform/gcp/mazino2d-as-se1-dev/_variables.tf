variable "gcp_credentials" {
  type      = string
  sensitive = true
  default   = null
}

variable "alert_notification_channel_ids" {
  type        = list(string)
  description = "Cloud Monitoring notification channel resource IDs used by alert policies."
  default     = []
}
