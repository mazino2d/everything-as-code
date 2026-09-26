output "tunnel_id" {
  description = "ID of the mazino2d-as-se1-dev Cloudflare Tunnel."
  value       = cloudflare_zero_trust_tunnel_cloudflared.mazino2d_as_se1_dev.id
}

output "tunnel_token" {
  description = "Token for cloudflared to run the mazino2d-as-se1-dev tunnel (synced to Infisical)."
  value       = data.cloudflare_zero_trust_tunnel_cloudflared_token.mazino2d_as_se1_dev.token
  sensitive   = true
}
