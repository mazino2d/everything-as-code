# Migration — Existing OCI Resources

If a compartment already exists, use import blocks instead of letting Terraform recreate it.

## Prerequisites

### Switch to Local execution (temporary)

Remote execution on a fresh workspace causes state conflicts on first write. Switch to Local mode for the migration, then switch back to Remote after.

Go to workspace `oci-<project-id>` → **Settings → General** → Execution Mode: **Local**

### Create `terraform.tfvars`

Create `terraform/oci/<project-id>/terraform.tfvars` (gitignored — never commit this file):

```hcl
tenancy_ocid   = "ocid1.tenancy.oc1..aaaaa..."
user_ocid      = "ocid1.user.oc1..aaaaa..."
fingerprint    = "aa:bb:cc:dd:..."
private_key    = <<-EOT
  -----BEGIN RSA PRIVATE KEY-----
  ...
  -----END RSA PRIVATE KEY-----
EOT
```

---

## Step 1 — Find the existing compartment OCID

OCI Console → **Identity & Security** → **Compartments** → click the compartment → copy **OCID**.

## Step 2 — Write import blocks

Create `imports.tf` in `terraform/oci/<project-id>/`:

```hcl
import {
  to = module.compartment.oci_identity_compartment.this
  id = "<compartment-ocid>"
}
```

## Step 3 — Verify with plan

```bash
terraform init
terraform plan -no-color -lock=false
```

Output should show `N to import, 0 to add, 0 to destroy`.

## Step 4 — Apply

```bash
terraform apply -auto-approve -lock=false
```

## Step 5 — Remove `imports.tf`

Delete the file after a successful apply. Import blocks are one-time use.

## Step 6 — Switch back to Remote

Go to workspace → **Settings → General** → Execution Mode: **Remote**, Auto-apply: **On**

---

## Notes

- Compartment OCID format: `ocid1.compartment.oc1..aaaaa...`
- VCN, subnet, instance created fresh by Terraform — no import needed unless they pre-exist
- Reserved public IP: if a reserved IP already exists and is attached to the VNIC, import it with `oci_core_public_ip.this` using its OCID
