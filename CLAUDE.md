# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working in this repository.

## What This Repo Is

A GitOps monorepo managing personal infrastructure and platform assets:
- Terraform for cloud/services provisioning and external platform config
- Kubernetes (GKE) workloads on GCP
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
- `terraform/gcp/simsplit-as-se1-prd`
- `terraform/infisical`
- `terraform/grafana/stack`
- `terraform/grafana/dashboard`
- `terraform/k8s/mazino2d-as-se1-dev`

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
- Docker images: `.github/workflows/docker-build.yml` (build only)
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
| `terraform/gcp/mazino2d-as-se1-dev` | `gcp-mazino2d-as-se1-dev` | GCP networking and GKE cluster provisioning |
| `terraform/gcp/simsplit-as-se1-prd` | `gcp-simsplit-as-se1-prd` | Firebase backend for sim-split (Auth, Firestore, Hosting), budget and billing kill switch |
| `terraform/infisical` | `infisical` | Infisical projects, identities, folders |
| `terraform/grafana/stack` | `grafana-stack` | Grafana Cloud stack, access policies, service accounts |
| `terraform/grafana/dashboard` | `grafana-dashboard` | Grafana dashboards and folders (reads SA token from `grafana-stack` remote state) |
| `terraform/k8s/mazino2d-as-se1-dev` | `k8s-mazino2d-as-se1-dev` | GKE cluster resources (ArgoCD, Infisical operator) |

Reusable modules live under each stack's `_modules/`.

### Kubernetes Structure

```
kubernetes/
├── _docs/                   # cluster documentation
│   ├── setup.md            # kubeconfig setup for local access
│   ├── access-telepresence.md # private access via Telepresence
│   ├── backup-velero.md    # Velero backup procedures
│   └── claude-agent.md     # Claude Code Remote Control agent
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
        │   ├── argocd/              # Argo CD GitOps engine
        │   ├── atlas-operator/      # DB schema automation
        │   ├── cert-manager/        # certificates (OpenTelemetry operator webhook)
        │   ├── infisical-operator/  # secrets operator
│   ├── telepresence/        # Telepresence traffic-manager (private access)
        │   ├── kustomization.yaml
        │   └── velero/              # cluster backup solution
        ├── monitoring/     # observability stack
        │   └── [observability components]
        └── platform/       # platform utilities
            ├── adminer/    # database admin UI
            ├── claude-agent/ # Claude Code Remote Control agent (read-only kubectl, terraform plan, PRs)
            └── [other tools]
```

Local reusable charts are defined in `kubernetes/charts/`. Cluster components use local charts via Kustomize `helmCharts`, and also consume external Helm charts directly from upstream repositories.

### Container Images

Each `docker/<name>/Dockerfile` is built by `.github/workflows/docker-build.yml` into `ghcr.io/mazino2d/<name>` (build-only on PRs; `sha-<short>` and `latest` pushed from `main`). Adding an image needs no workflow change; see `docker/README.md`.

### Infrastructure Notes

**Compute:**
- GKE Autopilot cluster `mazino2d-as-se1-dev` (regional, `asia-southeast1`); all Pods run on Spot capacity via the cluster-wide `default` ComputeClass (`terraform/k8s/mazino2d-as-se1-dev/compute_class.tf`), with no on-demand fallback.
- Dataplane V2 (Autopilot default) with FQDN network policy and Gateway API (`CHANNEL_STANDARD`) enabled.

**Cost / power:**
- `.github/workflows/k8s-power.yml` (`workflow_dispatch` sleep/wake, nightly auto-sleep at 00:00 ICT) runs `kubernetes/_scripts/power.sh`: sleep records replica counts in an annotation and scales all non-system workloads to zero and evicts DaemonSet Pods via a non-matching nodeSelector (Argo CD application controller first); wake restores them (controller last). Auth is keyless via Workload Identity Federation (`terraform/gcp/mazino2d-as-se1-dev/github_actions.tf`).

**Networking:**
- No external ingress (no load balancer). Services are reachable privately with Telepresence (`telepresence connect`, then `http://<service>.<namespace>`; `infra/telepresence`, see `kubernetes/_docs/access-telepresence.md`); otherwise use `kubectl port-forward`, e.g. `kubectl -n argocd port-forward svc/argocd-server 8080:80`.

**Claude agent:**
- `platform/claude-agent` runs `claude remote-control`, steered from claude.ai/code or the Claude app. It has read-only cluster RBAC (no Secrets), a plan-only TFC token and a repo-scoped GitHub PAT, so it can only propose changes via PRs. The claude.ai login is a one-off `kubectl exec ... claude auth login`, persisted on its PVC (`kubernetes/_docs/claude-agent.md`).

**Secrets & State:**
- Infisical manages secret storage and distribution across infrastructure
- GKE cluster credentials (endpoint, CA cert, SA key) are passed between Terraform workspaces via remote state — no manual kubeconfig management
- PostgreSQL and Redis are deployed in-cluster for demo/testing

### PR Status Checks

Validation workflows expose these gate jobs:
- `check-terraform`
- `check-k8s`
- `check-blog`
- `check-docker`

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
- Do not reformat or auto-fix code that is unrelated to the current task. If an issue is spotted, mention it and wait for instruction.
