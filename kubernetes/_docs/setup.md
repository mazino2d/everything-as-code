# Kubernetes Setup

This document describes how to prepare cluster access and publish kubeconfig for CI/CD.

Use the section that matches your cluster type.

---

## 1. Self-managed Kubernetes (k3s)

If you self-deploy Kubernetes with `k3s`, export the kubeconfig from your control plane and store it as a GitHub secret.

For environments with ephemeral public IP (for example, spot VM), prefer a stable DNS name (such as DuckDNS) in kubeconfig.

```bash
ssh user@<duckdns-domain>.duckdns.org "sudo cat /etc/rancher/k3s/k3s.yaml" \
  | sed 's/127.0.0.1/<duckdns-domain>.duckdns.org/g' \
  | base64 \
  | gh secret set KUBECONFIG --repo <owner>/<repo>
```

Notes:

- Use a generic secret name: `KUBECONFIG`.
- Ensure your GitHub Actions workflow reads this secret and writes it back to a kubeconfig file before running `kubectl`.
