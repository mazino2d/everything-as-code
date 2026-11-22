# Setup

## 1. Accounts

- Infisical: [app.infisical.com](https://app.infisical.com)

---

## 2. Infisical Machine Identity

Create a machine identity for Terraform to authenticate against Infisical:

1. Go to **Infisical org → Access Control → Machine Identities → + Create Organization Machine Identity**
2. Fill in:
   - **Name**: `terraform`
   - **Organization Role**: `Admin`
3. Open the created identity → **Authentication → Add Auth Method → Universal Auth** → leave defaults → Save
4. Click **+ Add Client Secret**:
   - **Description**: `terraform`
   - **TTL**: `0` (no expiry)
   - **Max Number of Uses**: `0` (unlimited)
5. Copy **Client ID** (shown at top of identity page) and **Client Secret** (shown once only — save it immediately)

---

## 3. Terraform variables

State lives in `gs://mazino2d-as-se1-eac-tfstate` (prefix `state/infisical`). Put the identity in the stack's variables file, `secrets/infisical.tfvars.json` in the same bucket:

```bash
make secrets-edit STACK=terraform/infisical
```

```json
{
  "infisical_client_id": "<Client ID>",
  "infisical_client_secret": "<Client Secret>"
}
```

CI and `make plan/apply` copy it to `terraform/infisical/ci.auto.tfvars.json` (git-ignored). CI signs in through Workload Identity Federation as `terraform@mazino2d-as-se1-dev.iam.gserviceaccount.com`; locally run `gcloud auth application-default login` first.
