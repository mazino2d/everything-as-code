variable "gcp_credentials" {
  type      = string
  sensitive = true
  default   = null
}

variable "budget_amount" {
  description = "Monthly budget in the billing account's currency. Billing is unlinked once actual cost reaches it."
  type        = string
  default     = "1"
}
