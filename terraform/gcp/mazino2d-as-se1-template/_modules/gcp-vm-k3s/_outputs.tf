output "ip" {
  value = module.vm.ip
}

output "kube_config" {
  description = "K3s cluster configuration for kubeconfig generation"
  value = {
    cluster_endpoint   = var.duckdns_domain != null && trimspace(var.duckdns_domain) != "" ? "https://${trimspace(var.duckdns_domain)}.duckdns.org:6443" : "https://${module.vm.ip}:6443"
    ca_cert_b64        = local.k3s_certs.server_ca_cert
    client_cert_b64    = local.k3s_certs.client_cert
    client_key_b64     = local.k3s_certs.client_key
  }
  sensitive = true
}