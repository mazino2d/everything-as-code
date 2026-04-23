module "compartment" {
  source      = "./_modules/oci-compartment"
  name        = "mazino2d-as-se2-dev"
  description = "mazino2d-as-se2-dev compartment"
  parent_id   = var.tenancy_ocid
}
