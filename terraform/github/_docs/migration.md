# Migration — Existing GitHub Repositories

If your GitHub account already has repositories, you need to import them into Terraform state instead of letting Terraform recreate them.

## Prerequisites

### Set the Terraform variables

Store `github_token` and `github_owner` in the stack's variables file in the state bucket (`make secrets-edit STACK=terraform/github`, see [setup.md](setup.md)). `make plan/apply` copies it to `terraform/github/ci.auto.tfvars.json` (git-ignored — never commit this file) so `terraform plan/apply` can authenticate with GitHub when running locally. The token requires scopes: `repo`, `delete_repo`, `read:org`. Locally, also run `gcloud auth application-default login` for the GCS state backend.

---

## Step 1 — Declare resources in `repos.tf`

Add all existing repos to `repos.tf` matching their actual configuration.

## Step 2 — Write import blocks

Create `imports.tf` in `terraform/github/` with all resources to import.

```hcl
import {
  to = module.<module_name>.github_repository.this
  id = "<repo-name>"
}

import {
  to = module.<module_name>.github_branch_default.this[0]
  id = "<repo-name>"
}

import {
  to = module.<module_name>.github_branch_protection.this[0]
  id = "<repo-name>:main"
}
```

> `github_branch_protection` uses `repo-name:branch` format, not the node ID.

## Step 3 — Verify with plan

```sh
terraform init
terraform plan -no-color -lock=false
```

The output should show `N to import, 0 to add, 0 to destroy` (in-place updates are normal due to metadata drift).

## Step 4 — Apply

```sh
terraform apply -auto-approve -lock=false
```

Repeat until `Apply complete!` and `No changes`.

## Step 5 — Remove `imports.tf`

Once the apply succeeds, delete `imports.tf` and commit. Import blocks are one-time use — keeping them will cause errors on subsequent applies.

---

## Notes

- Individual `terraform import` CLI commands each write state separately, causing serial mismatches. Use HCL import blocks instead so all imports happen in a single apply transaction.
- For many repos, add `-parallelism=1` to avoid GitHub API rate limits during import.
