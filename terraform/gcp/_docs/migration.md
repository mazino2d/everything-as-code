# Migration — Existing GCP Projects

If a GCP project already exists, use import blocks instead of letting Terraform recreate it.

## Prerequisites

### Switch to Local execution (temporary)

Remote execution on a fresh workspace causes `409 Conflict` on the first state write. Switch to Local mode for the migration, then switch back to Remote after.

Go to workspace `gcp-<project-id>` → **Settings → General** → Execution Mode: **Local**

### Create `terraform.tfvars`

Create `terraform/gcp/<project-id>/terraform.tfvars` (gitignored — never commit this file):

```hcl
gcp_credentials = "<contents of sa-key.json>"
```

---

## Step 1 — Declare resources in `main.tf`

Ensure `module "project"` in `main.tf` matches the actual project configuration.

## Step 2 — Write import blocks

Create `imports.tf` in `terraform/gcp/<project-id>/`:

```hcl
import {
  to = module.project.google_project.this
  id = "<project-id>"
}

import {
  to = module.project.google_project_service.this["compute.googleapis.com"]
  id = "<project-id>/compute.googleapis.com"
}

import {
  to = module.project.google_project_service.this["iam.googleapis.com"]
  id = "<project-id>/iam.googleapis.com"
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

Delete the file after a successful apply. Import blocks are one-time use — keeping them causes errors on subsequent applies.

## Step 6 — Switch back to Remote

Go to workspace → **Settings → General** → Execution Mode: **Remote**, Auto-apply: **On**

---

## Notes

- `google_project_service` import ID format: `<project-id>/<service-name>`
- If a service is not yet enabled, omit its import block — Terraform will enable it on apply
