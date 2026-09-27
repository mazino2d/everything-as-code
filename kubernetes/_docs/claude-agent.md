# Claude agent (Remote Control)

`platform/claude-agent` runs a [Claude Code Remote Control](https://code.claude.com/docs/en/remote-control) server inside the cluster. You send it tasks from [claude.ai/code](https://claude.ai/code) or the Claude mobile app. It investigates with `kubectl` and `terraform plan`, then opens pull requests against this repository.

It can read, plan and propose changes, but it can't apply them. Every change still goes through a pull request, CI, and then Argo CD or `tf-apply`. That limit comes from the credentials the pod holds, not from prompts:

| Tool | Credential | Scope |
|------|------------|-------|
| `kubectl` | ServiceAccount `platform/claude-agent` | ClusterRole `claude-agent-read`: `get/list/watch` plus `pods/log`, **no Secrets** |
| `terraform` | `TF_API_TOKEN` | TFC team token with **Plan** permission on the workspaces |
| `gh` / `git` | `GH_TOKEN` | Fine-grained PAT for `mazino2d/everything-as-code` only; branch protection still gates `main` |

`/etc/claude-code/managed-settings.json` in the image adds an allow/deny list on top, for example denying `terraform apply`, `kubectl delete` and `gh pr merge`.

## Components

- **Image**: `docker/claude-agent/`, built by `.github/workflows/docker-build.yml` into `ghcr.io/mazino2d/claude-agent`. It contains Claude Code, `gh`, `kubectl`, `helm`, `kustomize`, `terraform` and `make`.
- **Workload**: `kubernetes/clusters/mazino2d-as-se1-dev/platform/claude-agent/`, an `eac-app` StatefulSet.
  - It runs as uid 1000.
  - A 5Gi PVC is mounted at `/home/agent`. It holds the Claude login, the repo checkout and the Terraform plugin cache.
- **Secrets**: the Infisical folder `/platform/claude-agent`, synced to Secret `claude-agent-env`. Its values are set by hand.
- **Network**: `nacl.egress: ["*"]` allows all outbound traffic, including Anthropic, GitHub, Terraform, Helm repositories and the kube-apiserver. Ingress stays denied.

## First-time setup

1. **Create the credentials** and add them to Infisical under `everything-as-code` / `dev` / `/platform/claude-agent`:
   - `GH_TOKEN`: a fine-grained PAT.
     - Repository access: `mazino2d/everything-as-code` only.
     - Permissions: Contents RW, Pull requests RW, Actions R, Metadata R.
   - `TF_API_TOKEN`: in TFC, create a team (e.g. `claude-agent`) with **Plan** access on every workspace, then generate a team token.

2. **Sign in to Claude.** Remote Control needs a full claude.ai login. A `claude setup-token` / `CLAUDE_CODE_OAUTH_TOKEN` token can only make model requests, and an API key is not accepted. Until you sign in, the container waits and logs a reminder.

   ```bash
   kubectl -n platform exec -it claude-agent-0 -- claude auth login
   ```

   Open the printed URL, approve, and paste the code back. The credentials are saved on the PVC, so they survive restarts and the nightly sleep.

3. **Check it's running.** Within a minute the entrypoint starts `claude remote-control`:

   ```bash
   kubectl -n platform logs claude-agent-0 -f
   ```

   Session **eac-agent** then appears in the claude.ai/code session list and in the Claude app.

## Usage

Open the `eac-agent` session and describe the task, for example:

> httpbin is restarting, find out why and open a PR with a fix.

Each new session starts in `/home/agent/workspace/everything-as-code`. File edits are auto-accepted (`acceptEdits`). Shell commands outside the allow list come to your phone as permission prompts.

## Operations

- **Rotate `GH_TOKEN` / `TF_API_TOKEN`**: update them in Infisical. The operator resyncs within 60s. Then run `kubectl -n platform delete pod claude-agent-0`, because the environment is read only at start-up.
- **Re-login** (after a sign-out or an expired session): repeat step 2.
- **Nightly sleep**: `k8s-power.yml` scales the StatefulSet to zero at 00:00 ICT. After wake, the server restores the previous sessions if the gap was less than about 4 hours. Otherwise it starts a new one.
- **Upgrade tools**: bump the `ARG`s in `docker/claude-agent/Dockerfile`, merge, then set `image.tag` in `values.yaml` to the new `sha-<short>` tag.
