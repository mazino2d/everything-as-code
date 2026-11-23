---
name: project-onboard
description: Onboard a new product (or a new environment of one) onto everything-as-code end to end — the GCP project pair `<product>-as-se1-{dev,prd}` with its terraform service account, state access, workload identity, budget and billing kill switch; the product's GitHub repo, environments (dev/prd), tag rulesets and the variables and secrets its CI needs; keyless GCP access or a Cloudflare deploy token for that repo — split into the manual steps the user runs and a sequence of PRs that each plan cleanly. Use when the user says "onboard <product>", "dự án mới", "tạo project GCP mới", "thêm môi trường dev/prd cho X", "repo mới cần deploy lên GCP / Cloudflare", "set up infra cho app mới", or invokes /project-onboard. Not for adding a single resource to an existing project (infra), a security review (security-review) or writing the PR text (pr-open).
argument-hint: "<product> [dev|prd|both] [gcp|cloudflare|github-only]"
---

# Onboard a product

Every product so far (sim-split, data-platform, a3spy) went through the same
steps across several stacks, in a fixed order, because each step reads the
outputs of the one before. This skill is that checklist. Code follows the
existing stacks exactly; `infra`'s principles and hard rules apply.

The repo lives under the `mazino2d` GitHub account: prefix `gh` with
`GH_TOKEN=$(gh auth token --user mazino2d)`; gcloud with
`CLOUDSDK_CORE_ACCOUNT=mazino2d@gmail.com`.

## Step 1 — Scope (ask once, in one message)

- Product name and repo (`mazino2d/<repo>`, existing or new, public or private).
- Environments: `dev` and `prd` (default), or one of them.
- What the repo deploys to: GCP (which services: Firebase, BigQuery, Cloud Run,
  …), Cloudflare Workers/Pages, or nothing (GitHub settings only).
- Billing account: a product gets its own billing account (the `mazino2d`
  account is at its 5-project quota, see #267). Get its ID from the user.
- Monthly budget per project (`budget_amount`).

Project IDs are `<product>-as-se1-<env>` (no hyphens inside `<product>`:
`simsplit`, `dataplatform`), region `asia-southeast1`.

## Step 2 — Manual steps (the user runs them; they cannot be code)

Print these for the user with the IDs filled in; do not run them.

1. Create the billing account if new; link it to a payment profile.
2. Per project, `terraform/gcp/_docs/setup.md` § 2: create the project, link
   billing, enable `iam` and `cloudresourcemanager`, create SA `terraform`,
   grant it `roles/owner`. No key.
3. For a new billing account only: grant `terraform@mazino2d-as-se1-eac`
   `roles/billing.admin` on it (the one binding Terraform cannot grant itself).

Wait until the user confirms they are done.

## Step 3 — PR 1: state and billing access (`terraform/gcp/mazino2d-as-se1-eac`)

Add the new project IDs to `local.terraform_service_accounts` in
`terraform/gcp/mazino2d-as-se1-eac/tfstate.tf`, and to
`local.billing_account_projects` (plus the account in `local.billing_accounts`
if new) in `billing_iam.tf`. Expected plan: only
`google_storage_bucket_iam_member.tfstate[...]` and
`google_billing_account_iam_member.terraform[...]` to add. This stack is
high blast radius — the PR touches nothing else. It must be merged and applied
before PR 2 can plan.

## Step 4 — PR 2: the GCP stacks (`terraform/gcp/<project>`)

Copy the shape of the closest existing pair (`dataplatform-as-se1-{dev,prd}`
for a warehouse/CI product, `simsplit-as-se1-{dev,prd}` for Firebase/Cloud Run)
and strip what the new product doesn't use:

| File | Content |
|---|---|
| `_providers.tf` | `required_version = "~> 1.14"`, pinned providers, `backend "gcs"` with `prefix = "state/gcp/<project>"`, locals `project_id`, `region`, `billing_account_id`, `google` provider with `user_project_override` |
| `_variables.tf` | `budget_amount` and any product input; secrets `sensitive = true`, no default |
| `_outputs.tf` | only what another stack reads (`terraform/github` for repo variables) |
| `_import.tf` | `import` for `module.project.google_project.this` (and anything else made by hand); delete the blocks once applied |
| `project.tf` | `module "project"` from `./_modules/gcp-project` with the services list, each group commented with why |
| `budget.tf`, `kill_switch.tf`, `_functions/billing_kill_switch/` | copied unchanged; budget on `local.billing_account_id` |
| `terraform_wif.tf` | `roles/iam.workloadIdentityUser` on `terraform@<project>` for `mazino2d/everything-as-code` in the eac `github` pool (its `import` goes in `_import.tf` if the binding was made by hand) |
| `github_actions.tf` | only if the product repo deploys to GCP: its own `github` pool, a provider whose `attribute_condition` pins `assertion.repository == 'mazino2d/<repo>'` (and the ref or environment for prd), a deployer SA with the narrowest roles |
| `_docs/setup.md` | what is manual for this project and how to relink billing after the kill switch |

Also in the same PR:
- `.github/workflows/terraform.yml`: the `gcp-service-accounts` entry and the
  `workflow_dispatch` stack option, per project.
- `CLAUDE.md`: the valid `STACK` list and the stack table.

Run `terraform fmt`, `validate` and `make plan STACK=terraform/gcp/<project>`
for each. Expected plan: the project imported, APIs, budget, kill switch and WIF
added, nothing destroyed. After merge, `make secrets-edit` the stack's
variables if it has any secret input, before or right after the first apply.

## Step 5 — PR 3: credentials for the product repo

Only what the repo needs, each in the stack that owns it:

- **Cloudflare**: add the repo to `local.workers_deployers` in
  `terraform/cloudflare/workers.tf` (merge and apply first; `terraform/github`
  reads the token from its remote state).
- **GitHub** (`terraform/github`):
  - repo module in `active_repos.tf` (description, topics, visibility,
    `branch_protection` with the repo's real gate check names, `security`
    block, `deploy_app = local.eac_deploy_app` if it opens image-bump PRs);
    an existing repo needs an `import` block.
  - `remote_states.tf`: a `terraform_remote_state` per new GCP stack, read with
    `try(…, null)` so the plan works before that stack has outputs.
  - `actions.tf`: environments `dev`/`prd` with deployment policies (`main` for
    dev; `main` plus `v*` tags for prd, as sim-split and data-platform), a `v*`
    tag ruleset if releases are tags, and environment variables from the
    remote states (WIF provider, deployer SA, project ID). Secrets only when no
    keyless option exists.

`terraform/github` is high blast radius: confirm the plan touches only the new
repo's resources.

## Step 6 — Hand over

For each PR use `pr-open` with its expected plan. Order and dependencies:

```
manual steps → PR 1 (eac) → PR 2 (gcp stacks) → [cloudflare] → PR 3 (github)
```

Each PR merges and applies before the next plans against it. End with what the
product repo itself still needs (its workflows reading `vars.*`, the
`google-github-actions/auth` step with the provider and SA), and offer
`security-review pr <n>` for PR 2 and PR 3, since both create identities.
