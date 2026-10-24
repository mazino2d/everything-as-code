# Setup

## 1. Cloudflare account

- Sign up at [dash.cloudflare.com/sign-up](https://dash.cloudflare.com/sign-up) (Free plan).
- Open **Workers & Pages** once and pick a `workers.dev` subdomain; Workers on `workers.dev` need it.
- Copy the **Account ID** from the Workers & Pages overview sidebar.

---

## 2. Bootstrap token

Terraform uses this token to mint the per-repo deploy tokens in `workers.tf`, the Realtime SFU apps in `realtime.tf`, and the data-platform dashboard's Pages project and Access application in `dashboard.tf`.

[dash.cloudflare.com/profile/api-tokens](https://dash.cloudflare.com/profile/api-tokens) → **Create Token** → **Custom token**:

| Permission                         | Access |
|------------------------------------|--------|
| Account → Account API Tokens       | Edit   |
| Account → Account Settings         | Read   |
| Account → Calls (Media)            | Edit   |
| Account → Cloudflare Pages         | Edit   |
| Account → Access: Apps and Policies | Edit  |

Account Resources: include your account only.

---

## 3. Terraform Cloud workspace

Create workspace `cloudflare` (CLI-driven) in org `mazino2d-everything-as-code`:

- **Settings → General**: Execution Mode **Remote**, Auto-apply **On**.
- **Settings → General → Remote state sharing**: share with workspace `github`.
- **Variables**:

| Category  | Key                     | Value           | Sensitive |
|-----------|-------------------------|-----------------|-----------|
| Terraform | `cloudflare_api_token`  | bootstrap token | ✅        |
| Terraform | `cloudflare_account_id` | account ID      | ❌        |

The `github` workspace reads `workers_deployer_tokens` from this workspace's state, so it must exist before a `terraform/github` plan that references it.

---

## 4. Zero Trust (for the data-platform dashboard)

`dashboard.tf` puts the dashboard behind Cloudflare Access, which needs a Zero Trust
organization. Once, in [one.dash.cloudflare.com](https://one.dash.cloudflare.com): pick a team
name and the **Free** plan (up to 50 users). Sign-in uses the built-in **One-time PIN**
login method (Settings → Authentication), so no identity provider is needed.

Existing bootstrap tokens need the two extra permissions above (Pages Edit, Access: Apps and
Policies Edit) before `dashboard.tf` can apply.

