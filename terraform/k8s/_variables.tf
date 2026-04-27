variable "k3s_kubeconfig" {
  type        = string
  sensitive   = true
  description = "Base64-encoded kubeconfig for the K3S cluster (same value as K3S_KUBECONFIG GitHub secret)."
}
