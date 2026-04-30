# Kubernetes Setup

This document describes how to prepare cluster access for local administration.

Use the section that matches your cluster type.

---

## 1. Self-managed Kubernetes (k3s)

If you self-deploy Kubernetes with `k3s`, export kubeconfig as base64 and store it in Terraform Cloud workspace `k8s` variable `kubeconfig`.

For environments with ephemeral public IP (for example, spot VM), prefer a stable DNS name (such as DuckDNS) in kubeconfig.

```bash
ssh user@mazino2d-k3s.duckdns.org "sudo cat /etc/rancher/k3s/k3s.yaml" \
  | sed 's/127.0.0.1/mazino2d-k3s.duckdns.org/g' \
  | base64
```

Then go to Terraform Cloud workspace `k8s` -> Variables and set:

- Category: `terraform`
- Key: `kubeconfig`
- Value: output from the command above
- Sensitive: enabled

For local kubectl usage on laptop (optional):

```bash
ssh user@mazino2d-k3s.duckdns.org "sudo cat /etc/rancher/k3s/k3s.yaml" \
  | sed 's/127.0.0.1/mazino2d-k3s.duckdns.org/g' \
  > "$HOME/.kube/mazino2d-k3s.yaml"

chmod 600 "$HOME/.kube/mazino2d-k3s.yaml"
```

Rename k3s default context to avoid conflicts:

```bash
kubectl config rename-context default k3s-mazino2d --kubeconfig="$HOME/.kube/mazino2d-k3s.yaml"
```

Merge into default kubeconfig:

```bash
KUBECONFIG="$HOME/.kube/config:$HOME/.kube/mazino2d-k3s.yaml" kubectl config view --flatten > /tmp/merged.yaml
mv /tmp/merged.yaml "$HOME/.kube/config"
chmod 600 "$HOME/.kube/config"
kubectl config use-context k3s-mazino2d
kubectl get nodes
```

If your SSH key is not used by default, specify it explicitly:

```bash
ssh -i <path-to-private-key> <ssh-user>@mazino2d-k3s.duckdns.org "sudo cat /etc/rancher/k3s/k3s.yaml" \
  | sed 's/127.0.0.1/mazino2d-k3s.duckdns.org/g' \
  > "$HOME/.kube/mazino2d-k3s.yaml"
```

Notes:

- Deployments are reconciled by Argo CD from this repository.
- This repository does not rely on GitHub Actions to deploy Kubernetes manifests during normal operation.

---

## 2. Access Argo CD and check admin password

After merging kubeconfig into default context, use these commands from your laptop.

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
