# WARP must proxy TCP and UDP through Gateway for private network routing to work
# (UDP is needed for DNS queries to kube-dns).
resource "cloudflare_zero_trust_device_settings" "this" {
  account_id                = var.cloudflare_account_id
  gateway_proxy_enabled     = true
  gateway_udp_proxy_enabled = true
}

locals {
  # Cloudflare's default local domain fallback entries; this resource replaces the whole list,
  # so they are declared explicitly to keep the default behaviour.
  default_fallback_suffixes = [
    "intranet", "internal", "private", "localdomain", "domain", "lan", "home", "host",
    "corp", "local", "localhost", "home.arpa", "invalid", "test",
  ]
}

# Resolves cluster.local through kube-dns (reached via the tunnel route) instead of Gateway DNS.
resource "cloudflare_zero_trust_device_default_profile_local_domain_fallback" "this" {
  account_id = var.cloudflare_account_id

  domains = concat(
    [
      {
        suffix      = "cluster.local"
        description = "GKE mazino2d-as-se1-dev in-cluster DNS"
        dns_server  = [data.terraform_remote_state.gcp.outputs.gke_kube_dns_ip]
      },
    ],
    [for suffix in local.default_fallback_suffixes : { suffix = suffix }],
  )
}
