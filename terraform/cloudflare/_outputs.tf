output "account_id" {
  value = var.cloudflare_account_id
}

output "workers_deployer_tokens" {
  value       = { for name, token in cloudflare_account_token.workers_deployer : name => token.value }
  sensitive   = true
  description = "Workers deploy token per app repo, keyed by repo name (read by terraform/github)."
}

output "realtime_apps" {
  value = {
    for name, app in cloudflare_calls_sfu_app.app : name => { id = app.uid, token = app.secret }
  }
  sensitive   = true
  description = "Realtime SFU app id and token per app repo, keyed by repo name (read by terraform/github)."
}
