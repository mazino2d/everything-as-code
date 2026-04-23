terraform {
  required_version = "~> 1.14"

  required_providers {
    oci = {
      source  = "hashicorp/oci"
      version = "~> 5.0"
    }
  }

  cloud {
    organization = "mazino2d-everything-as-code"

    workspaces {
      name = "oci-mazino2d-as-se2-dev"
    }
  }
}

provider "oci" {
  tenancy_ocid = var.tenancy_ocid
  user_ocid    = var.user_ocid
  fingerprint  = var.fingerprint
  private_key  = var.private_key
  region       = var.region
}
