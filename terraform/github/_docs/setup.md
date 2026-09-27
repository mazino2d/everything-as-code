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
| Environment | `GITHUB_OWNER` | GitHub username | ❌        |

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

---

## 5. eac-deployer GitHub App

Lets other repos' CI open image-bump PRs against `everything-as-code`. GitHub has no API to create Apps, so this is a one-off manual step; Terraform then distributes the credentials (`deployer_app.tf`).

**Create the App:** [github.com/settings/apps/new](https://github.com/settings/apps/new)

| Field | Value |
|-------|-------|
| GitHub App name | `eac-deployer-mazino2d` (must be globally unique) |
| Homepage URL | `https://github.com/mazino2d/everything-as-code` |
| Webhook → Active | ❌ untick |
| Repository permissions → Contents | Read and write |
| Repository permissions → Pull requests | Read and write |
| Where can this GitHub App be installed? | Only on this account |

After creating it:

1. Note the **App ID** on the App's General page.
2. **Private keys → Generate a private key** — a `.pem` file downloads.
3. **Install App** → your account → **Only select repositories** → `everything-as-code`.

**Add to Terraform Cloud workspace variables:**

Go to workspace `github` → **Variables** → Add variable:

| Category  | Key                            | Value                  | Sensitive |
|-----------|--------------------------------|------------------------|-----------|
| Terraform | `eac_deployer_app_id`          | App ID                 | ❌        |
| Terraform | `eac_deployer_app_private_key` | contents of the `.pem` | ✅        |

Delete the local `.pem` once saved.

**Allow a repo to deploy:** set `auto_deploy = true` and `deployer_app = local.eac_deployer_app` on its module in `active_repos.tf`. The repo then receives `vars.EAC_DEPLOYER_APP_ID` and `secrets.EAC_DEPLOYER_PRIVATE_KEY`, and mints a token in its workflow:

```yaml
- uses: actions/create-github-app-token@v2
  id: app-token
  with:
    app-id: ${{ vars.EAC_DEPLOYER_APP_ID }}
    private-key: ${{ secrets.EAC_DEPLOYER_PRIVATE_KEY }}
    owner: mazino2d
    repositories: everything-as-code
```

Use `${{ steps.app-token.outputs.token }}` for checkout/push/`gh pr create`. Unlike `GITHUB_TOKEN`, PRs opened with an App token trigger the required checks, so auto-merge works.
