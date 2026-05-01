output "kube_config_dev" {
  description = "K3s cluster configuration for kubeconfig generation"
  value       = module.vm-dev.kube_config
  sensitive   = true
}
