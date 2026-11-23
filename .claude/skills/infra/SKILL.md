---
name: infra
description: Design, build and review infrastructure in everything-as-code the GitOps way — Terraform stacks and modules (GCP, GitHub, Cloudflare, Infisical, Grafana, Kubernetes), Kubernetes manifests (Kustomize overlays, local Helm charts, Argo CD), container images and the GitHub Actions callers — keeping every change small, readable and boring. Three modes: `plan` audits an area (or the whole repo) for duplication, drift from repo conventions and needless complexity and returns a prioritised plan; `build` makes one change end to end (code, docs, plan output) ready for a PR; `review` reads a diff for correctness, simplicity and blast radius. Use when the user asks to "add a stack", "write a module", "refactor terraform", "add an app to the cluster", "deploy X on k8s", "simplify the infra", "gitops", "devops", "viết module", "thêm app vào cluster", "dọn infra", "review PR infra", or invokes /infra. Not for onboarding a new product (GCP project pair, repo, credentials: project-onboard), a security audit (security-review), debugging a live workload (k8s-debug) or for writing the PR text (pr-open).
argument-hint: "[plan [area]|build <what>|review <pr>]"
---

# everything-as-code DevOps engineer

Everything here is applied by merging to `main`: Terraform applies every changed
stack from GitHub Actions, Argo CD reconciles `kubernetes/clusters/`. So the code is
the system, and the reader of the code is the operator. Optimise for the person who
opens a file in six months, knows Terraform and Kubernetes, and does not know why
something is the way it is.

The repo lives under the `mazino2d` GitHub account: prefix `gh` with
`GH_TOKEN=$(gh auth token --user mazino2d)`. For gcloud use
`CLOUDSDK_CORE_ACCOUNT=mazino2d@gmail.com` (the machine's default account is a
work account).

## Principles

1. **Simple beats clever.** A flat list of resources a reader can scan beats a
   `for_each` over a computed map of maps. Use `for_each` when there are three or
   more near-identical things, or when the list lives in YAML that people edit.
   No `dynamic` blocks, ternaries in ternaries or string templating where a plain
   attribute does.
2. **One way to do each thing.** Before writing, find how the repo already does
   it (`grep` for the resource type, look at a sibling stack) and copy that shape.
   A second pattern for the same job is a finding, not a style choice.
3. **A module earns its place.** Extract a module when it is used twice or hides
   real complexity behind a small interface. A module that wraps one resource and
   passes every argument through is noise; inline it.
4. **Explain why, not what.** A comment says why a value is what it is, a
   constraint, or a link to the doc that forced it. Never restate the code.
5. **Small blast radius.** One concern per PR. A change that touches many stacks
   says why in the PR; a change to `terraform/gcp/mazino2d-as-se1-eac` (state and
   CI identity) or to `terraform/github` (repo settings) is high risk by default.
6. **Declarative only.** Nothing is created by hand without an `import` block
   that adopts it, and a `_docs/setup.md` step for the parts that cannot be code.
   `null_resource`, `local-exec` and scripts that mutate cloud state are a last
   resort and need a comment saying why.
7. **No drift.** A plan with changes nobody asked for is a bug to fix (or to
   accept explicitly with `lifecycle.ignore_changes` and a comment), not noise
   to live with.

## Repo conventions (check before inventing)

### Terraform

- A stack is a directory under `terraform/` with `*.tf` (CI finds it on its own;
  `_modules` excluded). Files: `_providers.tf` (versions, `backend "gcs"`,
  locals for project/billing, providers), `_variables.tf`, `_outputs.tf`,
  `_import.tf` (adoption of hand-made resources), then one file per concern
  (`budget.tf`, `github_actions.tf`, …). Modules live in the stack's own
  `_modules/<name>/` with `main.tf`, `_variables.tf`, `_outputs.tf` and a
  `_providers.tf` naming every provider's `source` (a module without it gets an
  unconfigured default provider — see `terraform/github/_modules/github-repository`).
- Backend: `bucket = "mazino2d-as-se1-eac-tfstate"`, `prefix = "state/<stack path
  under terraform/>"`. Cross-stack reads use `terraform_remote_state` with
  `backend = "gcs"` and the same prefix rule.
- Secrets: never in git, never in a `default`. A sensitive input is a variable
  with `sensitive = true` and no default (or `null`), and its value goes in
  `gs://mazino2d-as-se1-eac-tfstate/secrets/<stack path>.tfvars.json`
  (`make secrets-edit STACK=…`).
- GCP auth: no keys. A GCP stack runs as `terraform@<project>` through the
  `github` pool in `mazino2d-as-se1-eac`; a new project needs the three steps in
  `terraform/gcp/_docs/setup.md` § 3 (bucket access, `terraform_wif.tf`, the
  `gcp-service-accounts` entry in `.github/workflows/terraform.yml`).
- Versions: `required_version = "~> 1.14"`, providers pinned with `~>` to a minor.
  `terraform fmt -recursive terraform` must leave nothing to change.
- Billing: every GCP project has a budget; projects that can run up a bill also
  have the kill switch (`kill_switch.tf`), except the state project.
- YAML-driven lists (`workload_gsa.yaml`, `secret_tree.yaml`) are for things the
  user edits often; keep their schema small and validate it in the module.

### Kubernetes

- `kubernetes/clusters/mazino2d-as-se1-dev/<layer>/<app>/` with a
  `kustomization.yaml`; layers are `apps`, `infra`, `monitoring`, `platform`.
  Argo CD picks up what the layer's kustomization lists.
- Prefer the local charts (`kubernetes/charts/eac-app`, `eac-cronjob`,
  `eac-postgresql`, `eac-redis`) through Kustomize `helmCharts` over raw
  manifests; extend a chart only when two apps need the same option.
- Upstream charts are pinned to a version. Secrets come from Infisical through
  the operator (`infisical.enabled` in `eac-app`), never as plain `Secret`
  manifests.
- Every workload sets resources, runs as non-root, and has a network policy
  (`nacl` in `eac-app`) that names what it may reach.
- Validate with `helm lint kubernetes/charts/<chart>` and
  `kustomize build --enable-helm kubernetes/clusters/mazino2d-as-se1-dev/<layer>`.

### CI and images

- Workflows in `.github/workflows/` are thin callers of
  `mazino2d/github-workflows` at `@v1`; logic changes go there (and ship as a
  release-please release that moves `v1`). Only `k8s-power.yml` is local.
- Every reusable workflow ends in `gate`; required checks are the gates.
- `docker/<name>/Dockerfile` is built by `docker.yml` without workflow changes.

## Mode: plan (default)

Audit an area (`terraform/<stack>`, `kubernetes/<layer>`, `.github`, `docker`) or
the whole repo, read-only. For each area:

1. Read every file. Run `terraform fmt -check -recursive`, `terraform validate`
   per stack (`init -backend=false`), `helm lint` and `kustomize build` where
   they apply. Never run `plan` or `apply` against real state in this mode.
2. Look for: duplicated modules or blocks across stacks (for example the same
   `gcp-project` module copied into every GCP stack), dead code (variables,
   outputs, locals nobody reads; resources whose purpose is gone), patterns that
   differ for no reason, comments that no longer match the code, docs
   (`CLAUDE.md`, `_docs/`, skills) that describe a past setup, unpinned versions,
   hand-made resources without an import, and anything a newcomer would need
   five minutes to understand.
3. For each item: what it is, where (file:line), why it matters, the simplest
   fix, its risk (what `plan` would show: no change, in-place, replace,
   destroy), and effort (S < 1 h, M < half a day, L more).

Report as one table, highest value per effort first, then a suggested order of
PRs (each one concern, each with an expected plan). End with what you could not
check. Ask which items to do; do not change files in this mode.

## Mode: build

1. Restate the change in one line and the stacks or layers it touches.
2. Find the existing pattern (Principle 2) and follow it.
3. Write the code, the `import` blocks for anything that already exists, the
   docs (`_docs/setup.md` for manual steps, `CLAUDE.md` tables when a stack or
   layer is added) and nothing else.
4. Check: `terraform fmt`, `validate`, and a plan where safe
   (`make plan STACK=…` with ADC as mazino2d; it reads real state, never applies).
   For Kubernetes, `kustomize build` the layer and read the rendered diff.
5. Hand over to `pr-open` with the expected plan per stack. Merging applies;
   say so.

## Mode: review

Read `git diff origin/main...HEAD` (or the PR) and the CI plan comments. Check:
the plan matches the intent (no surprise replace or destroy), the change follows
the conventions above, nothing is more complex than it needs to be, docs moved
with the code, and the rollback is clear. Report blocking issues first, then
simplifications, then nits; say "looks good" plainly when it does.

## Hard rules

- Never `terraform apply`, `state rm`, `state mv`, `import` or `force-unlock`
  outside CI without the user's explicit yes for that exact command and stack;
  never delete a cloud resource, bucket object or Kubernetes object by hand.
  List what would go and wait for approval.
- Never print or paste a secret, a state file or `ci.auto.tfvars.json`.
- Commits and PRs follow the user's approval rules for this repo (merge when CI
  is green for agreed work).
