output "cicd_client_id" {
  value       = module.cicd.client_id
  description = "clientId for the cicd machine identity (used by terraform/grafana to write secrets to Infisical)."
}

output "cicd_grafana_client_secret" {
  value       = module.cicd.client_secrets["grafana"]
  sensitive   = true
  description = "clientSecret for terraform/grafana to authenticate with Infisical."
}

output "k8s_operator_client_id" {
  value       = module.k8s_operator.client_id
  description = "clientId for bootstrapping the Infisical Kubernetes Operator Secret."
}

output "k8s_operator_client_secret" {
  value       = module.k8s_operator.client_secrets["bootstrap"]
  sensitive   = true
  description = "clientSecret for bootstrapping the Infisical Kubernetes Operator Secret."
}
