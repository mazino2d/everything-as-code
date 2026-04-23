module "compartment" {
  source    = "./_modules/oci-compartment"
  name      = "mazino2d-as-se2-dev"
  parent_id = var.tenancy_ocid
}
