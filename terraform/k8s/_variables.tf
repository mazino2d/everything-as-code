variable "kubeconfig" {
  type        = string
  sensitive   = true
  description = "Base64-encoded kubeconfig for the K8S cluster (same value as KUBECONFIG GitHub secret)."
}
