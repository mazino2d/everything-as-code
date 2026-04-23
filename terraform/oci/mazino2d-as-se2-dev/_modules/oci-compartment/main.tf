resource "oci_identity_compartment" "this" {
  compartment_id = var.parent_id
  name           = var.name
  description    = var.description

  lifecycle {
    prevent_destroy = false
  }
}
