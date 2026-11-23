---
name: pr-open
description: Take local changes in the everything-as-code repo all the way to a GitHub pull request — branch, commit, push, and a PR description written for GitOps (Terraform stacks, Kubernetes/Argo CD, images, blog), where merging is the deployment. Skips any step already done (existing branch, commits, push, or open PR) and updates an open PR instead of creating a second one. Use whenever the user wants to open, create, raise, write, draft or update a PR / pull request, says "tạo PR", "viết PR", "mở PR", "push lên", "commit và tạo PR", "ship this", asks for a PR title or description, or invokes /pr-open — even if they only mention committing or pushing changes that will obviously end in a PR. Not for designing the change itself (infra) or for a security verdict on it (security-review).
---

# Open a PR

Turn the current working state into a reviewable pull request. Merging a PR *is*
the deployment here — `terraform.yml` applies every changed stack on push to
`main` and Argo CD reconciles `kubernetes/clusters/` — so the PR description is
the change record. A reviewer should be able to answer from it: what changes,
why, what gets applied where on merge, how risky it is, and how to undo it.

Branch names, commit messages and PR text are in British English (repo
convention). Talk to the user in whatever language they use.

The repo lives under the `mazino2d` GitHub account: prefix every `gh` command
with `GH_TOKEN=$(gh auth token --user mazino2d)`. For gcloud (needed by
`make plan`) use `CLOUDSDK_CORE_ACCOUNT=mazino2d@gmail.com`; the machine's
default account is a work account.

## Step 1 — Work out where the user already is

Run these together and decide which steps to skip:

```bash
git status --short
git branch --show-current
git fetch -q origin && git log --oneline origin/main..HEAD
git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null   # upstream, if any
gh pr view --json number,title,url,state 2>/dev/null                  # PR for this branch, if any
```

| State | Action |
|-------|--------|
| On `main` with changes | Create a branch (Step 2) |
| On a feature branch whose PR is open | Keep it; the change joins that PR only if it belongs there — otherwise ask |
| On a feature branch whose PR is merged or closed | Branch again from `origin/main` and carry the changes over |
| Uncommitted changes | Commit (Step 3) — ask first if it's unclear which files belong |
| Nothing uncommitted, commits ahead of `origin/main` | Skip commit |
| Branch has upstream and is not ahead of it | Skip push |
| PR already open for the branch | Don't create a new one — update its title/body with `gh pr edit` |
| No changes and no commits ahead | Tell the user there is nothing to PR and stop |

Tell the user in one line which steps you are skipping and why.

## Step 2 — Branch

`<type>/<short-kebab-description>`, matching history (`feat/simsplit-crm-p3`,
`chore/billing-accounts-per-product`, `docs/simsplit-auth-handler-on-hosting`).
The type is the commit type; the description is two to five words, product
first when the change is for one product.

```bash
git switch -c <type>/<description> origin/main
```

## Step 3 — Commit

- Stage only files that belong to this change. Never `git add -A` blindly —
  read `git status` first and leave unrelated edits unstaged. If unsure, ask.
- Before committing, scan the staged diff for secrets: private keys, tokens,
  `ci.auto.tfvars.json` or any `*.tfvars*` with values, kubeconfigs, state
  files. If you find one, stop and tell the user — secrets belong in the
  stack's `secrets/<stack>.tfvars.json` in `gs://mazino2d-as-se1-eac-tfstate`
  (`make secrets-edit STACK=…`) or in Infisical, never in git. The repo is
  public.
- Conventional Commits, lower-case type, imperative mood, no trailing full stop:
  `<type>(<scope>): <summary>`, summary ≤ 72 characters.
  - Types: `feat`, `fix`, `refactor`, `docs`, `chore`, `ci`, `perf`, `test`.
  - Scope is the stack or area, as in history: `terraform/gcp`,
    `terraform/github`, `terraform/cloudflare`, `terraform/k8s`, `terraform`
    (several stacks), `k8s`, `docker`, `blog`, `skills`. Add the product in the
    summary (`sim-split crm send log`), and a release or phase tag in brackets
    when the work has one (`(R-9 P5)`).
- Add a body only when the *why* isn't obvious from the summary.
- Follow the session's attribution instructions for commit trailers, and the
  user's rule to show a change summary and wait for approval before committing.

```bash
git commit -F - <<'EOF'
feat(terraform/gcp): sim-split crm send log (R-9 P5)

<optional body>

<attribution trailer>
EOF
```

## Step 4 — Validate what changed

Map changed paths to checks. These mirror the PR gates (`terraform / gate`,
`k8s / gate`, `blog / gate`, `docker / gate`), so failures show up before CI.

| Changed path | Checks | Deploys on merge via |
|--------------|--------|----------------------|
| `terraform/<stack>/**` | `terraform fmt -check -recursive terraform`, `make validate STACK=<stack>`, `make plan STACK=<stack>` (needs ADC as mazino2d; reads real state, never applies) | `terraform.yml` apply as `terraform@<project>` (CLAUDE.md table) |
| `kubernetes/charts/<chart>/**` | `helm lint kubernetes/charts/<chart>` + `kustomize build --enable-helm` every layer that uses it | Argo CD (every app using the chart) |
| `kubernetes/clusters/<cluster>/<layer>/**` | `kustomize build --enable-helm kubernetes/clusters/<cluster>/<layer>` | Argo CD app `<layer>` |
| `docker/<name>/**` | `docker build docker/<name>` if Docker is available | `docker.yml` pushes `ghcr.io/mazino2d/<name>` |
| `blog/**`, `mkdocs.yml` | `mkdocs build --strict` (CLAUDE.md § Blog) | `blog.yml` → GitHub Pages |
| `.github/workflows/**` | Read the workflow; logic lives in `mazino2d/github-workflows@v1` | GitHub Actions itself |
| `.claude/**`, `CLAUDE.md`, `**/_docs/**` | None | Nothing deploys |

From `make plan`, keep the `Plan: X to add, Y to change, Z to destroy` line and
every resource marked `must be replaced` or `destroy` — they go in Impact on
merge. If a check can't run locally, say so in Validation and note that CI posts
the plan as a sticky comment per stack. Don't invent results.

High blast radius, call it out in the PR: `terraform/gcp/mazino2d-as-se1-eac`
(state bucket and CI identity for every stack), `terraform/github` (settings,
branch protection and credentials of every repo), anything that changes IAM,
WIF or a billing kill switch.

## Step 5 — Write the PR

**Title:** the commit format. With several commits, summarise the whole change.

**Body:** the template below. Omit any section that would be empty — padding
hides what matters. Be concrete: resource addresses, file paths, stacks, Argo apps.

```markdown
## Summary
<1–3 sentences: what changes and, above all, why. Link the issue, release or doc.>

## Changes
### Terraform — `terraform/gcp/simsplit-as-se1-dev`
- Add `google_firestore_index.crm_sends` …
### Kubernetes — `apps`
- …

## Impact on merge
- **`terraform/gcp/simsplit-as-se1-dev`**: 3 to add, 0 to change, 0 to destroy
- **Argo CD `apps`**: syncs `outline` (rolling restart)
- ⚠️ Replaces / destroys / downtime / cost / manual steps before or after merge

## Validation
- [x] `make plan STACK=…` — Plan: 3 to add, 0 to change, 0 to destroy
- [x] `kustomize build --enable-helm …` — renders cleanly
- [ ] `make plan STACK=terraform/cloudflare` — not run locally; see the CI plan comment

## Rollback
<Revert the PR, plus anything a revert won't undo: destroyed data, recreated
IPs or keys, `import`/`moved`/`removed` blocks, state moves, manual steps.>

## Notes
<Reviewer hints, follow-ups, known limitations. Optional.>
```

End the body with the session's PR attribution line, if one was given.

- **Summary** earns its place with the *why*; the diff shows the what.
- **Impact on merge** makes a GitOps PR reviewable. If nothing deploys, say
  "No deployment — documentation only" and skip Rollback.
- A one-file tweak may need only Summary, Impact and Validation.

## Step 6 — Confirm, push, create

Pushing and opening a PR are visible to others: show the branch name, commit
message(s), PR title and body, and wait for a go-ahead. Then:

```bash
git push -u origin <branch>
GH_TOKEN=$(gh auth token --user mazino2d) gh pr create --base main --title "<title>" --body-file - <<'EOF'
<body>
EOF
```

For an open PR, use `gh pr edit <number> --title … --body-file -`.

Give the user the PR URL. GitHub Actions can take a few minutes to start; don't
block waiting for checks — mention which gates were triggered and check back
with `gh pr checks <number>` when asked.

## Don'ts

- Don't push to `main` directly or force-push unless the user explicitly asks.
- Don't merge unless the user said so for this work.
- Don't bundle unrelated reformatting or fixes — mention them instead.
- Don't amend or rewrite commits the user already made unless they ask.
