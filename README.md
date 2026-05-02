# Everything as Code

A production-shaped personal platform built entirely on GitOps principles — every infrastructure resource, Kubernetes workload, secret, and policy is declared in code and reconciled automatically.

## Tech Stack

| Layer | Technology | Role |
|---|---|---|
| Source of Truth | **GitHub** | All config, manifests, and IaC live here |
| CI/CD | **GitHub Actions** | Validate on PR, apply/deploy on merge to main |
| IaC | **Terraform + Terraform Cloud** | Cloud resources, secrets platform, Grafana, GitHub itself |
| Runtime | **K3S** on GCP spot VM | Lightweight Kubernetes, cost-optimised for continuous experimentation |
| GitOps Engine | **Argo CD** | Pull-based in-cluster reconciliation from Git |
| Service Mesh | **Istio** | mTLS, traffic management, and observability between workloads |
| Secrets | **Infisical + Infisical Operator** | Centralised secret storage with native Kubernetes sync |
| TLS | **cert-manager** | Automated certificate issuance and renewal |
| Schema Management | **Atlas Operator** | Declarative database migrations via Kubernetes CRDs |
| Observability | **Grafana Cloud** | Metrics, logs, and traces for workloads and infrastructure |
| Backup | **Velero** | Cluster backup and disaster recovery |
| Packaging | **Helm + Kustomize** | Chart templating composed with environment overlays |
| DNS | **DuckDNS** | Stable endpoint over ephemeral GCP spot VM public IPs |

## Architecture

```text
GitHub (source of truth)
  │
  ├── GitHub Actions
  │     ├── PR: terraform plan, kustomize build, helm lint, blog check
  │     └── main: terraform apply, blog deploy → GitHub Pages
  │
  ├── Terraform Cloud workspaces
  │     ├── github      → repositories, branch protection, deploy keys
  │     ├── gcp-*       → VM, VPC, firewall, workload identity
  │     ├── infisical   → secret projects, machine identities, folder tree
  │     ├── grafana     → Grafana Cloud stack and data source config
  │     └── k8s         → Kubernetes provider-managed resources
  │
  └── Argo CD (in-cluster)
        └── K3S — asia-southeast1-b (GCP spot VM)
              ├── infra/       cert-manager · Istio · Infisical Operator · Atlas Operator · Velero
              ├── monitoring/  Grafana Agent and exporters
              ├── apps/        hotrod · httpbin · postgresql · redis
              └── platform/    adminer
```

## Design Principles

**Cost-aware production parity** — A single `e2-small` spot VM runs a full K3S cluster. Preemption is handled by an automated startup script that reinstalls K3S and updates DuckDNS on every boot.

**Everything declared, nothing manual** — GitHub repository settings, GCP networking, Infisical secret trees, and Grafana dashboards are all Terraform-managed. Drift is visible in plan output.

**Pull-based delivery** — Argo CD continuously reconciles the cluster against Git. There are no push-to-cluster pipelines; changes reach the runtime by merging to `main`.

**Secret hygiene at the platform level** — Infisical is the single system of record for secrets. The Infisical Operator syncs them into Kubernetes without any secret values passing through CI pipelines.

**Auditable change path** — Every production change goes through a pull request with automated validation gates (`check-terraform`, `check-k8s`, `check-blog`) before reaching main-branch reconciliation.

## Repository Layout

```text
.github/workflows/      CI validation and deployment automation
terraform/              IaC stacks — github, gcp, infisical, grafana, k8s
kubernetes/             Cluster manifests — charts, apps, infra, monitoring, platform
blog/                   Architecture notes and learning journal
mkdocs.yml              Blog site definition
CLAUDE.md               Agent-facing repository instructions
```
