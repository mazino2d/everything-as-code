# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working in this repository.

## What This Repo Is

A GitOps monorepo managing personal infrastructure and platform assets:
- Terraform for cloud/services provisioning and external platform config
- Kubernetes (K3S) workloads on a GCP spot VM
- GitHub Actions for validation and deployment automation
- MkDocs blog content and publishing

## Common Commands

### Terraform (via Makefile)

```bash
make init STACK=terraform/github
make plan STACK=terraform/github
make apply STACK=terraform/github
make fmt
make validate STACK=terraform/github
```

Valid `STACK` values:
- `terraform/github` (default)
- `terraform/gcp/mazino2d-as-se1-dev`
- `terraform/infisical`
- `terraform/grafana`
- `terraform/k8s`

### Kubernetes (manual validation)

```bash
helm lint kubernetes/charts/<chart-name>
kustomize build --enable-helm kubernetes/clusters/mazino2d-as-se1-dev/apps
kustomize build --enable-helm kubernetes/clusters/mazino2d-as-se1-dev/infra
kustomize build --enable-helm kubernetes/clusters/mazino2d-as-se1-dev/monitoring
```

### Blog (manual validation)

```bash
pip install mkdocs mkdocs-material
mkdocs build --strict
```

## Architecture

### GitOps Flow

PRs run validation-only pipelines (no mutations):
- Terraform: `.github/workflows/tf-plan.yml`
- Kubernetes: `.github/workflows/k8s-validate.yml`
- Blog: `.github/workflows/blog-check.yml`

Pushes to `main` trigger deployment/apply pipelines:
- Terraform apply to Terraform Cloud workspaces (`tf-apply.yml`)
- Kubernetes deploy via Kustomize + `kubectl apply` (`k8s-deploy.yml`)
- Blog build and deploy to GitHub Pages (`blog-deploy.yml`)

### Terraform Structure

Stacks and Terraform Cloud workspaces (org: `mazino2d-everything-as-code`):

| Stack | Workspace | Primary scope |
|-------|-----------|---------------|
| `terraform/github` | `github` | GitHub repos/settings/branch protection |
| `terraform/gcp/mazino2d-as-se1-dev` | `gcp-mazino2d-as-se1-dev` | GCP VM/networking for K3S |
| `terraform/infisical` | `infisical` | Infisical projects, identities, folders |
| `terraform/grafana` | `grafana` | Grafana Cloud stack and related secrets flow |
| `terraform/k8s` | `k8s` | Kubernetes provider-managed resources |

Reusable modules live under each stack's `_modules/`. The GCP stack includes `_scripts/install_k3s.sh`, the startup script that installs K3S and updates DuckDNS to the VM external IP.

### Kubernetes Structure

```
kubernetes/
├── charts/
│   ├── eac-app/
│   └── eac-redis/
└── clusters/
    └── mazino2d-as-se1-dev/
        ├── apps/        # app workloads (e.g., whoami, redis)
        ├── infra/       # cluster infra components (e.g., infisical operator)
        └── monitoring/  # observability components (e.g., node exporter, alloy)
```

Local reusable charts are defined in `kubernetes/charts/`. Some cluster components also consume external Helm charts directly from upstream repos via Kustomize `helmCharts`.

### Infrastructure Notes

- The main VM is a spot `e2-small` in `asia-southeast1-b`, so preemption is expected.
- DuckDNS (`mazino2d-k3s.duckdns.org`) is updated during VM startup; K3S API TLS SANs include both domain and active external IP.
- Firewall rules expose 22 (SSH), 6443 (K3S API), 80/443 (HTTP/S), and 30379 (Redis NodePort).

### PR Status Checks

Validation workflows expose these gate jobs:
- `check-terraform`
- `check-k8s`
- `check-blog`

### Required GitHub Secrets

| Secret | Used by |
|--------|---------|
| `TF_API_TOKEN` | Terraform CLI auth in `tf-plan.yml` and `tf-apply.yml` |
| `KUBECONFIG` | Base64 kubeconfig for `k8s-deploy.yml` |

Notes:
- `GITHUB_TOKEN` is provided automatically by GitHub Actions.
- Other sensitive values (for example `gcp_credentials`, `infisical_client_secret`, `grafana_cloud_access_policy_token`) are Terraform input variables managed per stack/workspace, not repository-level GitHub secrets.

## Coding Style

- Write all code, comments, variable names, and documentation in British English.
