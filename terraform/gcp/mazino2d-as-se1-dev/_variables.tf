variable "budget_amount" {
  description = "Monthly budget alert in the billing account's currency."
  type        = string
  default     = "200000" # VND, about 10 USD
}

variable "duckdns_token" {
  description = "DuckDNS token for the VM's dynamic DNS record"
  type        = string
  sensitive   = true
  default     = null
}
