# Setup

## 1. Accounts

- Infisical: [app.infisical.com](https://app.infisical.com)
- HCP Terraform: [app.terraform.io/public/signup/account](https://app.terraform.io/public/signup/account)

After creating an HCP Terraform account, create an organization at [app.terraform.io/app/organizations/new](https://app.terraform.io/app/organizations/new)

---

## 2. Infisical Machine Identity

Create a machine identity for Terraform to authenticate against Infisical:

1. Go to **Infisical org → Access Control → Machine Identities → + Create Organization Machine Identity**
2. Fill in:
   - **Name**: `terraform`
   - **Organization Role**: `Admin`
3. Open the created identity → **Authentication → Add Auth Method → Universal Auth** → leave defaults → Save
4. Click **+ Add Client Secret**:
   - **Description**: `terraform-cloud`
   - **TTL**: `0` (no expiry)
   - **Max Number of Uses**: `0` (unlimited)
5. Copy **Client ID** (shown at top of identity page) and **Client Secret** (shown once only — save it immediately)

---

## 3. Infisical Organization ID

1. Go to **Infisical org → Organization Settings**
2. Copy the **Organization ID** (UUID shown on the settings page)

---

## 4. Terraform Cloud Workspace Variables

Go to workspace `infisical` → **Variables** → add the following:

| Category  | Key                       | Value           | Sensitive |
|-----------|---------------------------|-----------------|-----------|
| terraform | `infisical_client_id`     | Client ID       | ❌        |
| terraform | `infisical_client_secret` | Client Secret   | ✅        |
| terraform | `infisical_org_id`        | Organization ID | ❌        |

---

## 5. Terraform Cloud Workspace Settings

Go to workspace `infisical` → **Settings → General**:

- Execution Mode: **Remote**
- Auto-apply API, UI, & VCS runs: **On**
