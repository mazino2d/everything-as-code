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
- `terraform/grafana/stack`
- `terraform/grafana/dashboard`
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
- Kubernetes workloads reconcile via Argo CD (GitOps in-cluster)
- Blog build and deploy to GitHub Pages (`blog-deploy.yml`)

### Terraform Structure

Stacks and Terraform Cloud workspaces (org: `mazino2d-everything-as-code`):

| Stack | Workspace | Primary scope |
|-------|-----------|---------------|
| `terraform/github` | `github` | GitHub repos/settings/branch protection |
| `terraform/gcp/mazino2d-as-se1-dev` | `gcp-mazino2d-as-se1-dev` | GCP VM/networking for K3S |
| `terraform/infisical` | `infisical` | Infisical projects, identities, folders |
| `terraform/grafana/stack` | `grafana-stack` | Grafana Cloud stack, access policies, service accounts |
| `terraform/grafana/dashboard` | `grafana-dashboard` | Grafana dashboards and folders (reads SA token from `grafana-stack` remote state) |
| `terraform/k8s` | `k8s` | Kubernetes provider-managed resources |

Reusable modules live under each stack's `_modules/`. The GCP stack includes `_scripts/install_k3s.sh`, the startup script that installs K3S and updates DuckDNS to the VM external IP.

### Kubernetes Structure

```
kubernetes/
├── _docs/                   # cluster documentation
│   ├── setup.md            # kubeconfig setup for local access
│   └── backup-velero.md    # Velero backup procedures
├── charts/                 # reusable Helm charts
│   ├── eac-app/            # generic application chart template
│   ├── eac-postgresql/     # PostgreSQL deployment chart
│   └── eac-redis/          # Redis deployment chart
└── clusters/
    └── mazino2d-as-se1-dev/
        ├── apps/           # application workloads
        │   ├── hotrod/     # Jaeger demo application
        │   ├── httpbin/    # HTTP request/response debugging
        │   ├── postgresql/ # PostgreSQL database
        │   └── redis/      # Redis cache
        ├── infra/          # cluster infrastructure components
        │   ├── atlas-operator/      # DB schema automation
        │   ├── cert-manager/        # TLS certificate management
        │   ├── infisical-operator/  # secrets operator
        │   ├── istio/               # service mesh
        │   ├── kustomization.yaml
        │   └── velero/              # cluster backup solution
        ├── monitoring/     # observability stack
        │   └── [observability components]
        └── platform/       # platform utilities
            ├── adminer/    # database admin UI
            └── [other tools]
```

Local reusable charts are defined in `kubernetes/charts/`. Cluster components use local charts via Kustomize `helmCharts`, and also consume external Helm charts directly from upstream repositories.

### Infrastructure Notes

**Compute:**
- Main K3S cluster runs on a GCP spot VM (`e2-small` in `asia-southeast1-b`). Preemption is expected; recovery is automated.
- VM startup includes `_scripts/install_k3s.sh`, which installs K3S and updates DuckDNS with the current external IP.

**Networking:**
- DuckDNS domain: `mazino2d-k3s.duckdns.org` (stable DNS for ephemeral public IP)
- K3S API TLS SANs include both the domain and the active external IP
- Firewall rules expose: 22 (SSH), 6443 (K3S API), 80/443 (HTTP/S), 30379 (Redis NodePort)

**Secrets & State:**
- Infisical manages secret storage and distribution across infrastructure
- Kubeconfig stored as base64 in Terraform Cloud workspace `k8s` variable
- PostgreSQL and Redis are deployed in-cluster for demo/testing

### PR Status Checks

Validation workflows expose these gate jobs:
- `check-terraform`
- `check-k8s`
- `check-blog`

### Required GitHub Secrets

| Secret | Used by |
|--------|---------|
| `TF_API_TOKEN` | Terraform CLI auth in `tf-plan.yml` and `tf-apply.yml` |

Notes:
- `GITHUB_TOKEN` is provided automatically by GitHub Actions.
- Kubernetes deployment is not driven by GitHub Actions in normal operation; Argo CD performs reconciliation in-cluster.
- Other sensitive values (for example `gcp_credentials`, `infisical_client_secret`, `grafana_cloud_access_policy_token`) are Terraform input variables managed per stack/workspace, not repository-level GitHub secrets.

## Coding Style

- Write all code, comments, variable names, and documentation in British English.
