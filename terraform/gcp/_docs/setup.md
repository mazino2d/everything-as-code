# Setup

## 1. Accounts

- GCP: [console.cloud.google.com](https://console.cloud.google.com)
- HCP Terraform: [app.terraform.io](https://app.terraform.io) (org `mazino2d-everything-as-code` already exists)

---

## 2. Create GCP Project + Service Account (one-time, manual)

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

## 3. Import Project into Terraform State

```bash
cd terraform/gcp/<project-id>
terraform init
terraform import module.project.google_project.this <project-id>
```

Then trigger an apply on TF Cloud — APIs and project settings will be tracked from that point on.

---

## 4. Terraform Cloud Workspace

Create a new workspace at [app.terraform.io](https://app.terraform.io):

1. **Version Control** → select repo `everything-as-code`
2. Name: `gcp-<project-id>`
3. Working Directory: `terraform/gcp/<project-id>`
4. **Variables** → add:

| Type        | Key               | Value                                    | Sensitive |
|-------------|-------------------|------------------------------------------|-----------|
| Terraform | `gcp_credentials` | contents of `/tmp/terraform-sa-key.json` | ✅        |

1. **Settings → General**:
   - Execution Mode: **Remote**
   - Auto-apply API, UI, & VCS runs: **On**

---

## 5. K3S Kubeconfig

After k3s is installed on the VM, export the kubeconfig and set it as a GitHub secret:

```bash
ssh user@<vm-external-ip> "sudo cat /etc/rancher/k3s/k3s.yaml" \
  | sed 's/127.0.0.1/<vm-external-ip>/g' \
  | base64 \
  | gh secret set K3S_KUBECONFIG --repo <owner>/<repo>
```

Also set the VM IP as a GitHub variable (used to replace placeholders in manifests):

```bash
gh variable set VM_IP --body "<vm-external-ip>" --repo <owner>/<repo>
```

---

## 6. GitHub Actions

Add the new project to the matrix in both workflow files:

- `.github/workflows/tf-plan.yml`
- `.github/workflows/tf-apply.yml`

```yaml
matrix:
  stack:
    - terraform/github
    - terraform/gcp/<project-id>   # add this line
```
