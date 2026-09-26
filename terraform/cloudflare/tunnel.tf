# Remotely managed tunnel used purely for private network routing (no public hostnames).
# cloudflared runs in-cluster with the token from Infisical.
resource "cloudflare_zero_trust_tunnel_cloudflared" "mazino2d_as_se1_dev" {
  account_id = var.cloudflare_account_id
  name       = "mazino2d-as-se1-dev"
  config_src = "cloudflare"
}

data "cloudflare_zero_trust_tunnel_cloudflared_token" "mazino2d_as_se1_dev" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.mazino2d_as_se1_dev.id
}

# Routes the GKE Service CIDR through the tunnel so WARP clients can reach ClusterIPs.
# Which Services are actually reachable is controlled by cloudflared's NetworkPolicy egress.
resource "cloudflare_zero_trust_tunnel_cloudflared_route" "gke_services" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.mazino2d_as_se1_dev.id
  network    = data.terraform_remote_state.gcp.outputs.gke_services_ipv4_cidr
  comment    = "GKE mazino2d-as-se1-dev Service CIDR"
}
