module "vm_micro" {
  source         = "./_modules/oci-vm"
  name           = "vm-micro"
  compartment_id = module.compartment.compartment_id
  shape          = "VM.Standard.E2.1.Micro"
  ssh_public_key = var.ssh_public_key
}
