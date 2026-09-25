---
name: github-pr
description: Take local changes in the everything-as-code repo all the way to a GitHub pull request — branch, commit, push, and a well-structured PR description tailored to GitOps (Terraform stacks, Kubernetes/Argo CD, blog). Skips any step the user has already done (existing branch, commits, push, or open PR). Use this skill whenever the user wants to open, create, raise, write, draft or update a PR / pull request / merge request, says "tạo PR", "viết PR", "mở PR", "push lên", "commit và tạo PR", "ship this", or asks for a PR title or description — even if they only mention committing or pushing changes that will obviously end in a PR.
---

# GitHub PR

Turn the current working state into a reviewable pull request. In a GitOps repo, merging a PR *is* the deployment — Terraform Cloud applies on push to `main` and Argo CD reconciles Kubernetes manifests — so the PR description is the change record. It should let a reviewer answer: what changes, why, what gets applied where on merge, how risky it is, and how to undo it.

Write all branch names, commit messages and PR text in British English (repo convention). Talk to the user in whatever language they use.

## Step 1 — Work out where the user already is

Run these together and decide which steps to skip:

```bash
git status --short
git branch --show-current
git log --oneline origin/main..HEAD
git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null   # upstream, if any
gh pr view --json number,title,url,state 2>/dev/null                  # PR for this branch, if any
```

| State | Action |
|-------|--------|
| On `main` with changes | Create a branch (Step 2) |
| On a feature branch | Keep it |
| Uncommitted changes | Commit (Step 3) — ask first if it's unclear which files belong in this PR |
| Nothing uncommitted, commits ahead of `origin/main` | Skip commit |
| Branch has upstream and is not ahead of it | Skip push |
| PR already open for the branch | Don't create a new one — offer to update its title/body with `gh pr edit` |
| No changes and no commits ahead | Tell the user there is nothing to PR and stop |

Briefly tell the user which steps you are skipping and why, so they can correct you.

## Step 2 — Branch

Short kebab-case describing the change, no type prefix, matching existing history (`create-vm`, `fix-fqdn`, `update-network-policy`, `optimize-resource`). Two to four words.

```bash
git switch -c <branch-name>
```

## Step 3 — Commit

- Stage only files that belong to this change. Never `git add -A` blindly — look at `git status` first, and leave unrelated edits (and anything that looks like local scratch) unstaged. If unsure, ask.
- Before committing, scan the staged diff for secrets: private keys, tokens, `*.tfvars` with credentials, kubeconfigs, Infisical client secrets. If you find one, stop and tell the user — secrets in this repo belong in Infisical or Terraform Cloud variables, not in git.
- Message format is Conventional Commits, lower-case type, imperative mood, no trailing full stop:
  `<type>: <summary>` — optionally `<type>(<scope>): <summary>`
  - Types: `feat`, `fix`, `refactor`, `docs`, `chore`, `ci`, `perf`, `test`. History also uses `config` for pure value changes; `chore` is the standard equivalent, either is fine.
  - Scope, when useful, is the stack or component: `terraform/gcp`, `k8s`, `argocd`, `grafana`, `blog`.
  - Summary ≤ 72 characters.
- Add a body only when the *why* isn't obvious from the summary.
- Follow the session's attribution instructions for commit trailers.

Use a heredoc so formatting survives:

```bash
git commit -F - <<'EOF'
feat: add free-tier e2-micro vm with duckdns sync

<optional body>

<attribution trailer>
EOF
```

## Step 4 — Validate what changed

Map changed paths to stacks and run the cheap, read-only checks for each. These mirror the PR gate jobs (`check-terraform`, `check-k8s`, `check-blog`), so running them locally catches failures before CI.

| Changed path | Checks | Deploys on merge via |
|--------------|--------|----------------------|
| `terraform/<stack>/**` | `make fmt` (check only — don't commit reformatting of unrelated files), `make validate STACK=<stack>`, `make plan STACK=<stack>` | `tf-apply.yml` → Terraform Cloud workspace (see CLAUDE.md table) |
| `kubernetes/charts/<chart>/**` | `helm lint kubernetes/charts/<chart>` + build every cluster dir that uses it | Argo CD (every app using the chart) |
| `kubernetes/clusters/<cluster>/<group>/**` | `kustomize build --enable-helm kubernetes/clusters/<cluster>/<group>` | Argo CD |
| `blog/**`, `mkdocs.yml` | `mkdocs build --strict` | `blog-deploy.yml` → GitHub Pages |
| `.github/workflows/**` | Read the workflow carefully; no local runner | GitHub Actions itself |

For `make plan`, capture the `Plan: X to add, Y to change, Z to destroy` line and any resource marked `must be replaced` or `destroy`. Those go in the PR's risk section — replacements and destroys are the thing reviewers most need to see in a Terraform PR.

If a check can't run locally (no Terraform Cloud token, no helm repo access, tool missing), say so in the Validation section and note that CI will run it. Don't invent results.

## Step 5 — Write the PR

**Title:** same Conventional Commits format as the commit. If there are several commits, summarise the whole change.

**Body:** use the template below. Omit any section that would be empty or say "N/A" — padding hides the parts that matter. Be concrete: resource addresses, file paths, workspace names, Argo apps.

```markdown
## Summary
<1–3 sentences: what changes and, above all, why. Link the issue/incident/doc if one exists.>

## Changes
<Group by stack when more than one is touched. Bullets, each naming the resource/file and what happens to it.>

### Terraform — `terraform/gcp/mazino2d-as-se1-dev`
- Add `module.vm-free` (e2-micro, us-central1-a) with firewall rules for 22 and 80
### Kubernetes — `infra/`
- …

## Impact on merge
<What actually gets applied, where, and by what. Call out anything with blast radius.>
- **Terraform Cloud** `gcp-mazino2d-as-se1-dev`: 3 to add, 0 to change, 0 to destroy
- **Argo CD**: `infra` app will sync `cert-manager` (no restart expected)
- ⚠️ Replaces / destroys / downtime / cost changes / manual steps required before or after merge

## Validation
- [x] `make plan STACK=…` — Plan: 3 to add, 0 to change, 0 to destroy
- [x] `kustomize build --enable-helm …` — renders cleanly
- [ ] `make plan` for `terraform/infisical` — not run locally (no TFC token); CI will run it

## Rollback
<How to undo: revert the PR, and anything a revert won't undo (state moves, deleted data, DNS, one-off manual steps).>

## Notes
<Reviewer hints, follow-ups, known limitations. Optional.>
```

Then end the body with the session's PR attribution line, if one was given.

Guidance on the sections:
- **Summary** earns its place with the *why*. The diff already shows the what.
- **Impact on merge** is the section that makes a GitOps PR reviewable. If nothing deploys (docs-only, CLAUDE.md), say "No deployment — documentation only" in one line and skip Rollback.
- **Rollback** matters most for Terraform: a revert doesn't bring back destroyed disks, recreated IPs, or `import`/`moved` blocks. Say so when relevant.
- Keep it scannable. A one-file config tweak might need only Summary, Impact and Validation.

## Step 6 — Confirm, push, create

Pushing and opening a PR are visible to others, so show the user the branch name, commit message(s), PR title and body, and ask for a go-ahead before running anything outward-facing. Once confirmed:

```bash
git push -u origin <branch-name>
gh pr create --base main --title "<title>" --body-file - <<'EOF'
<body>
EOF
```

For an existing PR, use `gh pr edit <number> --title … --body-file -` instead.

Finish by giving the user the PR URL. Optionally run `gh pr checks <number>` and mention which gate jobs (`check-terraform`, `check-k8s`, `check-blog`) were triggered.

## Don'ts

- Don't push to `main` directly or force-push unless the user explicitly asks.
- Don't bundle unrelated reformatting or fixes into the PR — mention them to the user instead.
- Don't amend or rewrite commits the user already made unless they ask.
