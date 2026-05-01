module "vm" {
  source = "../gcp-vm"

  name                      = var.name
  project_id                = var.project_id
  zone                      = var.zone
  machine_type              = var.machine_type
  disk_size_gb              = var.disk_size_gb
  ssh_public_key            = var.ssh_public_key
  tags                      = var.tags
  startup_script            = file("${path.module}/_scripts/install_k3s.sh")
  extra_ports               = var.extra_ports
  spot                      = var.spot
  external_ip_type          = var.external_ip_type
  deny_egress_internet      = var.deny_egress_internet
  duckdns_domain            = var.duckdns_domain
  allow_stopping_for_update = var.allow_stopping_for_update

  instance_metadata = {
    k3s-ca-cert-b64     = local.k3s_certs.ca_cert
    k3s-ca-key-b64      = local.k3s_certs.ca_key
    k3s-server-cert-b64 = local.k3s_certs.server_cert
    k3s-server-key-b64  = local.k3s_certs.server_key
  }
}