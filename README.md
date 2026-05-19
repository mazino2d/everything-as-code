# Everything as Code

If it exists, it is declared. If it is declared, it is in Git. If it is in Git, it is reconciled automatically.

---

## What's in here

A full GitOps monorepo — GCP infrastructure, Kubernetes workloads, GitHub settings, Database schemas, Grafana dashboards, Secret structure, DNS... All of it in code. None of it applied manually.

Merge a PR. The rest happens.

---

## GitOps end-to-end

```text
PR → validate → merge to main → Terraform apply + Argo CD sync
```

Argo CD watches the `main` branch continuously. Every workload, every config, every infra component has a declared desired state in this repo. Drift is corrected automatically. Resources deleted from Git are deleted from the cluster.

Terraform covers everything outside the cluster — GCP project, GKE, IAM, GitHub repository settings, Infisical secret structure, Grafana dashboards. Six workspaces, all state remote in Terraform Cloud. Drift shows up in plan output before anything is applied.

---

## Stack

| | |
| --- | --- |
| **Kubernetes (GKE)** | Spot nodes, scale-to-zero, ADVANCED_DATAPATH |
| **Terraform** | IaC — six stacks, remote state in Terraform Cloud |
| **Argo CD + Argo Rollouts** | GitOps engine + blue/green and canary delivery |
| **Grafana Cloud + Alloy + OTel** | Metrics, logs, traces |
| **Atlas Operator** | Declarative database schema migrations |
| **Infisical** | Secret management with in-cluster operator injection |
| **Istio** | mTLS, traffic management |
