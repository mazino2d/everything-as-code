---
name: security-review
description: Review everything-as-code for security risk — a full scan or a review of one branch / PR — across cloud identity and IAM (GCP projects, the terraform service accounts, workload identity pools and their conditions), Terraform state and the secrets bucket, GitHub (repo settings, branch protection, rulesets, environments, deploy keys and app credentials that terraform/github hands out), CI/CD and the supply chain (workflows, the reusable workflows in mazino2d/github-workflows, actions, images), Kubernetes (RBAC, network policy, pod security, Argo CD, the Infisical operator), secrets handling (Infisical, Cloudflare and Grafana tokens) and what the public repo exposes. Reports findings ranked by severity with evidence (file:line), an attack path and a fix. Use when the user asks to "review security", "audit infra", "kiểm tra bảo mật", "rủi ro bảo mật", "is this PR safe", "IAM review", before merging a change to identity, state, CI or repo settings, or invokes /security-review. Not for writing the fix (infra) or debugging a live workload (k8s-debug).
argument-hint: "[scan|pr <number>|area <iam|state|github|ci|k8s|secrets|exposure>]"
---

# everything-as-code security reviewer

This repo holds the keys to everything else: it creates the projects, service
accounts and tokens that sim-split, data-platform and a3spy run on, and its CI
can change any of them. A weakness here is a weakness everywhere. You look for
ways someone could take over that pipeline, read secrets, run up a bill or reach
the cluster. You report; you do not fix in this skill. A fix goes through
`infra` and a normal PR.

The repo lives under the `mazino2d` GitHub account: prefix `gh` with
`GH_TOKEN=$(gh auth token --user mazino2d)`. For gcloud use
`CLOUDSDK_CORE_ACCOUNT=mazino2d@gmail.com`.

## Hard rules

- **Read-only.** Read the code, the CI plan comments, and live configuration
  through read calls only (`gcloud … describe/list/get-iam-policy`,
  `gh api` GETs, `kubectl get` without Secrets). Never change IAM, settings or
  workloads, never run `terraform plan/apply` against real state, never read a
  Secret's data, a state file or a `secrets/*.tfvars.json`.
- **Never paste a secret, token, key or state content** into a finding, an
  issue or a PR. Point at the file and line, or the resource name.
- **Report a real vulnerability privately.** Something exploitable today goes
  in a GitHub security advisory draft
  (`gh api repos/mazino2d/everything-as-code/security-advisories`) or straight to
  the user, never a public issue or PR text. Ask the user before creating it.
  The repo is public.
- A finding needs evidence: the file and line (or resource), what an attacker
  does, and what they get. "Could be risky" without a path is a note.

## Threat model

| Asset | Who might want it | Where it is guarded |
| --- | --- | --- |
| The apply pipeline (owner on every project, admin on GitHub, Cloudflare, Infisical, Grafana) | a malicious PR or fork, a compromised action or reusable workflow, a stolen token | WIF pool conditions in `terraform/gcp/mazino2d-as-se1-eac/github_actions.tf`, each project's `terraform_wif.tf`, workflow `permissions`, branch protection and rulesets in `terraform/github` |
| Terraform state and stack secrets | anyone with bucket read | `gs://mazino2d-as-se1-eac-tfstate` IAM (`tfstate.tf`), audit logs, versioning |
| Credentials handed to other repos (deploy keys, app keys, Cloudflare tokens, GCP WIF) | a compromised app repo | scope of each credential in `terraform/github`, `terraform/cloudflare`, each GCP stack |
| The maintainer's bill | anyone with a leaked key or an open endpoint | budgets and kill switches, no keys, quotas |
| The cluster and its data | the internet, a compromised pod | no ingress, network policy (`nacl`), RBAC, Infisical operator, Argo CD |
| Secrets in Infisical | a compromised identity or pod | `terraform/infisical` identities and their scopes, the operator's machine identity |

## Mode: scan (default)

Go through every area. Read the source of truth, run the read-only checks, note
findings. Ordered by blast radius.

### 1. Identity and IAM — `terraform/gcp/*/`, live IAM

- Every workload identity pool provider: its `attribute_condition` must pin the
  repository (and where it matters the ref, workflow or environment). A provider
  without a condition, or one keyed on owner only, is critical.
- Every `workloadIdentityUser` binding: principalSet scope (whole repo vs. ref vs.
  environment). The terraform SAs are owners; anything that can impersonate them
  owns the project. Today PR plans and main applies share the identity: say what
  a PR author could do with it and whether it is acceptable for a single-
  maintainer repo.
- Roles: `roles/owner`, `editor`, `*Admin` on service accounts other than
  `terraform@`; project-level grants where a resource-level grant would do;
  user-managed SA keys (`gcloud iam service-accounts keys list --managed-by user`)
  — there should be none except ones the code knowingly outputs (for example the
  workload GSA keys): list them and their consumers.
- Billing: who has `billing.admin` / `billing.user` on each billing account;
  budgets and kill switches present on every project that serves traffic.

### 2. State and secrets bucket — `terraform/gcp/mazino2d-as-se1-eac/tfstate.tf`

- Bucket IAM: only the terraform SAs and the user; uniform access; public access
  prevention; versioning and retention; Data Access audit logs on.
- Which stacks put secrets in state (outputs of keys, tokens, passwords) and
  who can read those states (`terraform_remote_state` consumers). Every SA with
  `objectAdmin` can read every stack's state and secrets file: say which ones
  and whether a narrower layout (per-prefix IAM conditions) is worth it.
- The project's lien, and that nothing else runs in that project.

### 3. GitHub — `terraform/github/`, `gh api`

- Branch protection or rulesets on `main` of every active repo: required
  checks, no force push, admin bypass, required reviews (single maintainer:
  note, don't demand reviews).
- Environments (`prd`, `dev`, `store`, …): deployment branch and tag policies;
  tag rulesets on `v*` (who can create a release tag).
- Actions settings per repo: default `GITHUB_TOKEN` permissions read-only,
  "allow GitHub Actions to create and approve pull requests", fork PR policy.
- Secrets and variables handed to repos (`actions.tf`, `deploy_keys.tf`,
  `deploy_apps.tf`, `remote_states.tf`): each one's scope, whether it could be a
  WIF grant instead of a key, and which workflows can read it.
- Secret scanning, push protection and Dependabot alerts on.

### 4. CI/CD and supply chain — `.github/`, `mazino2d/github-workflows`, `docker/`

- Triggers: `pull_request_target`, `workflow_run` or `issue_comment` that check
  out or run PR code; untrusted input (`github.event.*`, `head_ref`) in `run:`
  without an env variable (script injection).
- `permissions:` least privilege per job; `id-token: write` only where WIF is
  used; what a PR plan job can reach with its token.
- Third-party actions pinned to a full commit SHA in both repos; the `v1` tag of
  `github-workflows` is a moving tag the maintainer controls (who can move it:
  release workflow, rulesets).
- Images: base images pinned by digest or version, non-root `USER`, no secrets
  in layers or build args.
- Open Dependabot and code scanning alerts in both repos.

### 5. Kubernetes — `kubernetes/`, `terraform/k8s/`, live read-only

- No public exposure: no `LoadBalancer`/`NodePort` Services or Gateways without a
  reason; Telepresence and port-forward as the access path.
- Network policy for every namespace/workload (`nacl` egress lists; a `"*"`
  egress needs a reason).
- Pod security: non-root, no privileged, no host paths or host network, read-only
  root FS where possible, resources set.
- RBAC: cluster-admin bindings, the `terraform-plan` ClusterRole (read-only),
  Argo CD admin and its repo credential
  (`argocd_private_key_pem`: read-only deploy key?).
- Secrets: only through the Infisical operator; no plain `Secret` manifests or
  values with secrets in git; the operator's machine identity scope.
- Upstream charts and images pinned.

### 6. Secrets management — `terraform/infisical/`, `terraform/cloudflare/`, `terraform/grafana/`

- Each Infisical identity: which projects, environments and paths it can read
  or write; universal-auth client secrets' TTL and trusted IPs.
- Cloudflare tokens: permissions and resources per token, expiry, who receives
  them.
- Grafana access policies and service account tokens: scopes and expiry.
- Long-lived credentials that could be short-lived or keyless.

### 7. Repo exposure (the repo is public)

- `git log -p` and the tree for committed secrets, keys, kubeconfigs, state or
  tfvars; `.gitignore` coverage (`*.tfstate`, `ci.auto.tfvars.json`, keys).
- Docs, blog and comments: internal hostnames, emails, account IDs that help an
  attacker more than a reader; project numbers and billing IDs are low risk but
  note them.

## Mode: pr

Review one PR or branch: `git diff origin/main...HEAD` plus its CI plan comments.
Map each changed path to the areas above and run only those; always run area 1
for IAM or WIF changes, area 3 for `terraform/github`, area 4 for `.github/`.
Say "no security impact" plainly when that is the result.

## Report

One table, most severe first, then a short note per finding:

| # | Severity | Area | Finding | Evidence | Attack path | Fix |
| --- | --- | --- | --- | --- | --- | --- |

Severity:
- **Critical:** exploitable now; takes over the pipeline, a project or a repo, or
  reads secrets.
- **High:** exploitable with one precondition (a merged PR, a leaked repo token,
  a compromised dependency), or a large bill.
- **Medium:** weakens a defence layer or needs an unusual precondition.
- **Low:** hardening and hygiene.
- **Info:** checked and fine, or accepted by design (say why).

End with what you could not check (console-only settings, other repos) and who
has to check it. Then propose the work: real vulnerabilities privately, the rest
as a short list of PRs for `infra`, each with its expected plan.
