variable "budget_amount" {
  description = "Monthly budget in the billing account's currency. Billing is unlinked once actual cost reaches it."
  type        = string
  default     = "20000" # VND, about 1 USD
}
