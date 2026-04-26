# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A GitOps monorepo managing all personal infrastructure as code:
- **Terraform** — manages GCP compute and GitHub repos/settings
- **Kubernetes (K3S)** — app workloads and monitoring on a single GCP spot VM
- **GitHub Actions** — CI/CD for both IaC and Kubernetes deployments

## Common Commands

### Terraform (via Makefile)

```bash
make init STACK=terraform/github              # Initialize backend
make plan STACK=terraform/github              # Preview changes
make apply STACK=terraform/github             # Apply changes
make fmt                                      # Format all Terraform files recursively
make validate STACK=terraform/github          # Validate configs
```

Valid `STACK` values:
- `terraform/github` (default)
- `terraform/gcp/mazino2d-as-se1-dev`

### Kubernetes (manual validation)

```bash
helm lint kubernetes/charts/<chart-name>
kustomize build --enable-helm kubernetes/clusters/mazino2d-as-se1-dev/apps
kustomize build --enable-helm kubernetes/clusters/mazino2d-as-se1-dev/monitoring
```

## Architecture

### GitOps Flow

PRs trigger validation only (no mutations). Merges to `main` auto-apply:
- Terraform changes via GitHub Actions → Terraform Cloud workspaces
- Kubernetes changes via Kustomize + `kubectl apply` against the K3S cluster

### Terraform Structure

Two independent stacks, each with its own Terraform Cloud workspace (`mazino2d-everything-as-code` org):

| Stack | Workspace | Manages |
|-------|-----------|---------|
| `terraform/github` | `github` | GitHub repos, branch protection, Pages settings |
| `terraform/gcp/mazino2d-as-se1-dev` | `gcp-mazino2d-as-se1-dev` | GCP project, VM, firewall rules |

Reusable modules live in each stack's `_modules/` directory. The GCP stack also has `_scripts/install_k3s.sh` — the VM startup script that installs K3S and updates DuckDNS with the ephemeral external IP.

### Kubernetes Structure

```
kubernetes/
├── charts/                    # Reusable Helm chart definitions
│   ├── eac-app/               # Generic Deployment/StatefulSet template
│   ├── eac-redis/             # Redis StatefulSet with optional replication
│   └── eac-node-exporter/     # Prometheus node exporter DaemonSet
└── clusters/
    └── mazino2d-as-se1-dev/
        ├── apps/              # apps namespace (whoami, Redis)
        └── monitoring/        # monitoring namespace (node exporter)
```

Helm charts are defined in `kubernetes/charts/` and consumed via Kustomize in `kubernetes/clusters/`. To add a new workload, either reference an existing chart in a cluster kustomization or create a new chart under `kubernetes/charts/`.

### Infrastructure Notes

- The GCP VM is a **spot e2-small** in `asia-southeast1-b` — it can be preempted at any time. K3S is re-installed on each boot via startup script.
- **DuckDNS** (`mazino2d-k3s.duckdns.org`) is updated at startup to point to the current ephemeral external IP, keeping the kubeconfig valid across reboots. TLS SANs include both the domain and live IP.
- Firewall rules open ports 22 (SSH), 6443 (K3S API), 80/443 (HTTP/S), and 30379 (Redis NodePort).

### CI/CD Checks Required for Merge

Branch protection (managed by Terraform) requires these checks to pass:
- `check-terraform` — from `tf-plan.yml`
- `check-k8s` — from `k8s-validate.yml`

### Required Secrets

| Secret | Used by |
|--------|---------|
| `TF_API_TOKEN` | Terraform Cloud authentication |
| `K3S_KUBECONFIG` | Base64-encoded kubeconfig for kubectl deploy |
| `DUCKDNS_TOKEN` | VM startup script for DNS updates |
| `GCP_CREDENTIALS` | GCP provider auth in Terraform |
