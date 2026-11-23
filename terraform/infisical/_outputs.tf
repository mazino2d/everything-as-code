output "k8s_operator_client_id" {
  value       = module.k8s_operator.client_id
  description = "clientId for bootstrapping the Infisical Kubernetes Operator Secret."
}

output "k8s_operator_client_secret" {
  value       = module.k8s_operator.client_secrets["bootstrap"]
  sensitive   = true
  description = "clientSecret for bootstrapping the Infisical Kubernetes Operator Secret."
}
