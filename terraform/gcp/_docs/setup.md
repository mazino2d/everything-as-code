# Setup

## 1. Accounts

Create accounts if you don't have them already:

- GCP: [console.cloud.google.com](https://console.cloud.google.com)

---

## 2. Create GCP Project + Service Account (one-time, manual)

Create billing account if you don't have one already: [console.cloud.google.com/billing](https://console.cloud.google.com/billing)

```bash
# Create project
gcloud projects create <project-id> --name="<project-name>"
gcloud billing projects link <project-id> --billing-account=<billing-account-id>
gcloud services enable iam.googleapis.com --project=<project-id>
gcloud services enable cloudresourcemanager.googleapis.com --project=<project-id>

# Create Terraform service account in the project
gcloud iam service-accounts create terraform \
  --display-name="Terraform" \
  --project=<project-id>

# Grant owner
gcloud projects add-iam-policy-binding <project-id> \
  --member="serviceAccount:terraform@<project-id>.iam.gserviceaccount.com" \
  --role="roles/owner"
```

No service account key is created: CI signs in as this service account through Workload Identity Federation (section 3).

---

## 3. State bucket access and Workload Identity Federation

State lives in `gs://mazino2d-as-se1-eac-tfstate` under the prefix `state/gcp/<project-id>`, in the project `mazino2d-as-se1-eac` (bucket defined in `terraform/gcp/mazino2d-as-se1-eac/tfstate.tf`). A new project needs four things:

1. Add `<project-id>` to the project list in `local.terraform_service_accounts` in `terraform/gcp/mazino2d-as-se1-eac/tfstate.tf`, so `terraform@<project-id>.iam.gserviceaccount.com` gets `roles/storage.objectAdmin` on the bucket.
2. Add a `terraform_wif.tf` to the new stack like `terraform/gcp/simsplit-as-se1-dev/terraform_wif.tf`. It grants `roles/iam.workloadIdentityUser` on the `terraform` service account to the repo's principalSet in the `github` pool (provider `everything-as-code`, project `mazino2d-as-se1-eac`, number `725985974531`).
3. Add an entry `"terraform/gcp/<project-id>": "terraform@<project-id>.iam.gserviceaccount.com"` to `gcp-service-accounts` in `.github/workflows/terraform.yml`, so CI impersonates that project's service account for the stack.
4. Add `terraform/gcp/<project-id>` to the `stack` choices of the manual run (`workflow_dispatch`) in the same file. Plan and apply on push and pull request find stacks on their own (every directory under `terraform/` holding `*.tf`, `_modules` excluded), so only the manual run needs the entry.

### Variables

Secret and input variables are one JSON file in the same bucket, `secrets/gcp/<project-id>.tfvars.json`:

```bash
make secrets-edit STACK=terraform/gcp/<project-id>
```

CI and `make plan/apply` copy it to `terraform/gcp/<project-id>/ci.auto.tfvars.json` (git-ignored). There is no `gcp_credentials` variable. Stack-specific variables (for example `duckdns_token` for `mazino2d-as-se1-dev`) go in the same file.

Locally, run `gcloud auth application-default login` before `make plan STACK=...`.

---

## 4. Adopt the Project into Terraform State

The project was created by hand in step 1, so add an `import` block to the stack's `_import.tf` (as in `terraform/gcp/simsplit-as-se1-dev/_import.tf`):

```hcl
import {
  to = module.project.google_project.this
  id = local.project_id
}
```

The first CI apply after merging adopts it; APIs and project settings are tracked from then on.
