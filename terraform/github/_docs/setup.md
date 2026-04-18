# Setup

## 1. Accounts

- GitHub: [github.com/signup](https://github.com/signup)
- HCP Terraform: [app.terraform.io/public/signup/account](https://app.terraform.io/public/signup/account)

After creating an HCP Terraform account, create an organization at [app.terraform.io/app/organizations/new](https://app.terraform.io/app/organizations/new)

---

## 2. GitHub Token + Terraform Cloud Variable

**Create a GitHub Classic Token:** [github.com/settings/tokens/new](https://github.com/settings/tokens/new)

Required scopes:
- `repo`
- `delete_repo`
- `read:org`

**Add to Terraform Cloud workspace variables:**

Go to workspace `github` → **Variables** → Add variable:

| Category    | Key            | Value           | Sensitive |
|-------------|----------------|-----------------|-----------|
| Environment | `GITHUB_TOKEN` | token           | ✅        |
| Terraform   | `github_owner` | GitHub username | ❌        |

---

## 3. Terraform Token + GitHub Actions Secret

**Create a Terraform User Token:** [app.terraform.io/app/settings/tokens/new](https://app.terraform.io/app/settings/tokens/new)

Select **User API token** (not team or org token).

**Add to GitHub repository secret:**

Go to repo → **Settings → Secrets and variables → Secrets** → New repository secret:

| Name            | Value |
|-----------------|-------|
| `TF_API_TOKEN`  | token |

---

## 4. Terraform Cloud Workspace Settings

Go to workspace `github` → **Settings → General**:
- Execution Mode: **Remote**
- Auto-apply API, UI, & VCS runs: **On**
