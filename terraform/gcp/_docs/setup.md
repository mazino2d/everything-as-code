# Setup

## 1. Accounts

Create accounts if you don't have them already:

- GCP: [console.cloud.google.com](https://console.cloud.google.com)
- HCP Terraform: [app.terraform.io](https://app.terraform.io)

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

# Create key
gcloud iam service-accounts keys create /tmp/terraform-sa-key.json \
  --iam-account=terraform@<project-id>.iam.gserviceaccount.com
```

---

## 3. Terraform Cloud Workspace

### Org-level settings

In the `mazino2d-everything-as-code` org at [app.terraform.io](https://app.terraform.io), go to **Settings → General** and set:

- Execution Mode: **Remote**
- Auto-apply API, UI, & VCS runs: **On**

### Workspace

Create a new workspace:

1. **API-driven workflow**
2. Name: `gcp-<project-id>`
3. **Variables** → add:

  | Type        | Key               | Value                                    | Sensitive |
  |-------------|-------------------|------------------------------------------|-----------|
  | Terraform   | `gcp_credentials` | contents of `/tmp/terraform-sa-key.json` | ✅        |
  | Environment | `DUCKDNS_TOKEN`   | DuckDNS API token                        | ✅        |

---

## 4. Import Project into Terraform State

```bash
cd terraform/gcp/<project-id>
terraform init
terraform import module.project.google_project.this <project-id>
```

Then trigger an apply on TF Cloud — APIs and project settings will be tracked from that point on.

---

## 5. GitHub Actions

Add the new project to the matrix in both workflow files:

- `.github/workflows/tf-plan.yml`
- `.github/workflows/tf-apply.yml`

```yaml
matrix:
  stack:
    - terraform/github
    - terraform/gcp/<project-id>   # add this line
```
