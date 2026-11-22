variable "duckdns_token" {
  description = "DuckDNS token for the VM's dynamic DNS record"
  type        = string
  sensitive   = true
  default     = null
}
