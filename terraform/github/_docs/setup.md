# Setup

## 1. Accounts

- GitHub: [github.com/signup](https://github.com/signup)

---

## 2. GitHub Token + Terraform Variables

**Create a GitHub Classic Token:** [github.com/settings/tokens/new](https://github.com/settings/tokens/new)

Required scopes:

- `repo`
- `delete_repo`
- `read:org`

**Add to the stack's variables file:**

State lives in `gs://mazino2d-as-se1-eac-tfstate` (prefix `state/github`). The stack's variables are one JSON file in the same bucket, `secrets/github.tfvars.json`:

```bash
make secrets-edit STACK=terraform/github
```

| Key            | Value           | Sensitive |
|----------------|-----------------|-----------|
| `github_token` | token           | ✅        |
| `github_owner` | GitHub username | ❌        |

CI and `make plan/apply` copy the file to `terraform/github/ci.auto.tfvars.json` (git-ignored). CI signs in through Workload Identity Federation as `terraform@mazino2d-as-se1-dev.iam.gserviceaccount.com`, so no GitHub Actions secret is needed; locally run `gcloud auth application-default login` first.

---

## 3. eac-deployer GitHub App

Lets other repos' CI open image-bump PRs against `everything-as-code`. GitHub has no API to create Apps, so this is a one-off manual step; Terraform then distributes the credentials (`deploy_apps.tf`).

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

**Add to the stack's variables file** (`make secrets-edit STACK=terraform/github`):

| Key                            | Value                  | Sensitive |
|--------------------------------|------------------------|-----------|
| `eac_deployer_app_id`          | App ID                 | ❌        |
| `eac_deployer_app_private_key` | contents of the `.pem` | ✅        |

Delete the local `.pem` once saved.

**Allow a repo to deploy:** set `deploy_app = local.eac_deploy_app` on its module in `active_repos.tf`. The repo then receives `vars.EAC_DEPLOYER_APP_ID` and `secrets.EAC_DEPLOYER_PRIVATE_KEY`, and mints a token in its workflow:

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
