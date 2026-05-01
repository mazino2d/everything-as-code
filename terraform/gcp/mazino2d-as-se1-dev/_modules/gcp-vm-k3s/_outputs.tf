output "ip" {
  value = module.vm.ip
}

output "kube_config" {
  description = "K3s cluster configuration for kubeconfig generation"
  value = {
    cluster_endpoint   = "https://mazino2d-k3s.duckdns.org:6443"
    cluster_name       = "k3s-mazino2d"
    ca_cert_b64        = local.k3s_certs.ca_cert
    client_cert_b64    = local.k3s_certs.client_cert
    client_key_b64     = local.k3s_certs.client_key
  }
  sensitive = true
}