module "vm" {
  source         = "./_modules/oci-vm"
  name           = "vm"
  compartment_id = module.compartment.compartment_id
  ocpus          = 4
  memory_in_gbs  = 24
  ssh_public_key = var.ssh_public_key
  startup_script = file("${path.module}/_scripts/install_k3s.sh")
}
