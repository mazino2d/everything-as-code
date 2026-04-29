---
date: 2025-04-26
title: ArgoCD — GitOps Continuous Delivery for Kubernetes
---

ArgoCD is a declarative, GitOps continuous delivery tool for Kubernetes. Instead of pushing deployments from CI pipelines, ArgoCD pulls from Git and continuously reconciles the cluster state to match what is in the repository.

---

## The GitOps Model

Traditional CD pipelines push changes to the cluster: a CI job runs `kubectl apply` or `helm upgrade` after a build. The cluster state diverges from Git whenever someone applies a hotfix manually, a job fails mid-way, or config drifts over time.

GitOps inverts this. Git is the single source of truth. ArgoCD runs inside the cluster, watches the repository, and applies any divergence it detects — automatically or on approval. Manual changes to the cluster are overwritten on the next sync.

---

## Core Concepts

**Application**: an ArgoCD resource that maps a Git path to a cluster destination. It declares where the manifests live (repo, branch, path) and where they should be deployed (cluster, namespace).

**Sync**: the act of applying the desired state from Git to the cluster. Can be triggered manually or run automatically.

**Self-heal**: when enabled, ArgoCD detects live drift (someone ran `kubectl edit`, a controller mutated a resource) and reverts it to match Git.

**App of Apps**: a pattern where one ArgoCD Application points to a directory of other Application manifests. Used to bootstrap an entire cluster from a single entry point.

---

## How It Works

```
Git repository
  └── kubernetes/clusters/my-cluster/
        ├── apps/
        ├── infra/
        └── monitoring/
```

ArgoCD polls (or receives a webhook from) the repository. When it detects a diff between the Git revision and the live cluster state, it applies the delta using `kubectl apply` or Helm.

The diff view in the ArgoCD UI shows exactly what will change before a sync — useful for reviewing infrastructure changes the same way you review code.

---

## Installation

ArgoCD is distributed as a Helm chart:

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  --version 9.5.9
```

Access the UI:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Retrieve the initial admin password:

```bash
kubectl get secret argocd-initial-admin-secret -n argocd \
  -o jsonpath="{.data.password}" | base64 -d
```

---

## Defining an Application

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: apps
  namespace: argocd
spec:
  project: default
  source:
    repoURL: git@github.com:your-org/your-repo.git
    targetRevision: main
    path: kubernetes/clusters/my-cluster/apps
  destination:
    server: https://kubernetes.default.svc
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
      - ServerSideApply=true
```

`prune: true` removes resources from the cluster that have been deleted from Git. `selfHeal: true` reverts manual changes.

---

## Sync Strategies

| Strategy | Behaviour |
|----------|-----------|
| Manual | Sync only when triggered by a user |
| Automated | Sync on every Git change, within a few minutes |
| Automated + self-heal | Sync on Git change and revert cluster drift |

Automated sync with self-heal is the strictest GitOps posture — the cluster is always an exact reflection of Git.

---

## ArgoCD vs CI-based Deployment

| | ArgoCD (pull) | CI pipeline (push) |
|---|---|---|
| Cluster credentials | Stored in cluster | Stored in CI secrets |
| Drift detection | Continuous | Only on deploy |
| Rollback | Point to previous Git commit | Re-run old pipeline |
| Audit trail | Git history | CI logs |

The pull model keeps cluster credentials out of CI systems, which reduces the blast radius of a compromised pipeline.

---

## Kustomize and Helm Support

ArgoCD renders both Kustomize overlays and Helm charts natively. Set `kustomize.buildOptions: "--enable-helm"` in the ArgoCD ConfigMap to support Kustomize overlays that reference Helm charts:

```yaml
configs:
  cm:
    kustomize.buildOptions: "--enable-helm"
```

No separate rendering step is needed in CI — ArgoCD handles it at sync time.
