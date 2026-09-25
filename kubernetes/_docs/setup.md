# Kubernetes Setup

This document describes how to prepare cluster access for local administration.

---

## 1. GKE cluster access

The active cluster is a GKE cluster (`mazino2d-as-se1-dev`) (Autopilot, regional) in `asia-southeast1`. Use `gcloud` to configure kubectl access:

```bash
gcloud container clusters get-credentials mazino2d-as-se1-dev \
  --region asia-southeast1 \
  --project mazino2d-as-se1-dev
```

Rename the context to avoid conflicts with other clusters:

```bash
kubectl config rename-context \
  gke_mazino2d-as-se1-dev_asia-southeast1_mazino2d-as-se1-dev \
  gke-mazino2d
kubectl config use-context gke-mazino2d
kubectl get nodes
```

Notes:

- Deployments are reconciled by Argo CD from this repository.
- This repository does not rely on GitHub Actions to deploy Kubernetes manifests during normal operation.
- The `terraform/k8s` workspace accesses the cluster via remote state (endpoint, CA cert, SA key) — no kubeconfig is required for Terraform operations.

---

## 2. Access Argo CD and check admin password

After configuring kubectl, use these commands from your laptop.

Port-forward Argo CD server:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Get the initial admin password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 --decode
echo
```

Login details:

- Username: `admin`
- Password: output from the command above
