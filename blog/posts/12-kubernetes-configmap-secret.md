---
date: 2025-04-26
title: ConfigMaps and Secrets — Configuration Without Code Changes
---

Hard-coding configuration into container images is fragile. It means rebuilding and redeploying the image every time an environment variable changes. ConfigMaps and Secrets decouple configuration from images — and they're one of the patterns that makes the same container image work across dev, staging, and production.

---

## ConfigMap

A ConfigMap stores non-sensitive configuration data as key-value pairs or as file content.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  LOG_LEVEL: "info"
  MAX_CONNECTIONS: "100"
  config.yaml: |
    server:
      port: 8080
      timeout: 30s
```

### Using a ConfigMap as Environment Variables

```yaml
spec:
  containers:
  - name: app
    envFrom:
    - configMapRef:
        name: app-config    # inject all keys as env vars
```

Or selectively:

```yaml
    env:
    - name: LOG_LEVEL
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: LOG_LEVEL
```

### Mounting a ConfigMap as a File

```yaml
    volumeMounts:
    - name: config
      mountPath: /etc/app
  volumes:
  - name: config
    configMap:
      name: app-config
```

This creates `/etc/app/config.yaml` with the content from the ConfigMap. When the ConfigMap is updated, the mounted file is updated automatically (with a short delay). Environment variable injection does not update automatically — the Pod must restart.

---

## Secret

A Secret stores sensitive data — passwords, tokens, TLS certificates, API keys.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-creds
type: Opaque
stringData:
  username: admin
  password: s3cr3t
```

!!! warning "Secrets are not encrypted by default"
    Kubernetes stores Secrets as base64-encoded values in etcd. Base64 is encoding, not encryption — anyone with access to etcd or the Kubernetes API can read them.

    For real security, enable **etcd encryption at rest** (supported in all major distributions) and restrict access to Secrets using RBAC. Better still, use an external secret store.

### Secret Types

| Type | Use case |
|---|---|
| `Opaque` | Generic key-value data |
| `kubernetes.io/tls` | TLS certificate and key |
| `kubernetes.io/dockerconfigjson` | Docker registry credentials |
| `kubernetes.io/service-account-token` | Service account tokens (auto-managed) |
| `kubernetes.io/basic-auth` | Username and password |

### Using Secrets

Secrets are used the same way as ConfigMaps — as environment variables or mounted files.

```yaml
envFrom:
- secretRef:
    name: db-creds
```

For TLS certificates:

```yaml
volumes:
- name: tls
  secret:
    secretName: my-tls-cert
```

---

## Secret Management Best Practices

**Never commit secrets to git.** Not even base64-encoded. Tools like `git-secrets`, `gitleaks`, and GitHub Secret Scanning help catch accidental commits.

**Use RBAC to restrict access.** Give workloads only the secrets they need, and grant Secret read access only to the teams and service accounts that require it.

**Consider an external secret store** for production:

| Tool | Approach |
|---|---|
| HashiCorp Vault | Secrets fetched from Vault at runtime; short-lived tokens |
| AWS Secrets Manager / GCP Secret Manager | Sync secrets into K8s using External Secrets Operator |
| Sealed Secrets (Bitnami) | Encrypt secrets with a cluster-specific key; commit the encrypted form to git |
| External Secrets Operator | Unified interface for any external secret store |

For GitOps workflows, **Sealed Secrets** or **External Secrets Operator** are the most common choices. They let you store the secret reference (not the value) in git and have it materialise as a real Kubernetes Secret in the cluster.

---

## ConfigMap vs Secret Quick Reference

| | ConfigMap | Secret |
|---|---|---|
| Data type | Non-sensitive config | Sensitive data |
| Storage | Plain text in etcd | Base64-encoded in etcd |
| Default encryption | No | No (needs etcd encryption) |
| Update on mount | Yes (eventually) | Yes (eventually) |
| Update via env | Requires pod restart | Requires pod restart |
