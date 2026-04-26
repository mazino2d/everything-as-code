---
date: 2025-04-26
title: Helm — The Package Manager for Kubernetes
---

Deploying a non-trivial application to Kubernetes means writing a Deployment, a Service, an Ingress, a ConfigMap, maybe a Secret, an HPA, and PodDisruptionBudget. That's hundreds of lines of YAML — with slight variations for each environment. Helm bundles all of it into a single, versioned, configurable package.

---

## What Helm Solves

Three problems:

**Templating**: instead of duplicating YAML for dev/staging/production with slightly different values, write templates with variables and provide a `values.yaml` per environment.

**Versioning**: a Helm *release* has a version. You can see what version is deployed, upgrade to a new version, or roll back to a previous one — just like `apt upgrade` and `apt install`.

**Dependency management**: an application chart can declare dependencies on other charts (e.g., a web app that depends on a PostgreSQL chart). `helm dependency update` fetches them.

---

## Chart Structure

```text
mychart/
├── Chart.yaml          # metadata: name, version, description
├── values.yaml         # default configuration values
├── charts/             # dependency charts
└── templates/
    ├── deployment.yaml
    ├── service.yaml
    ├── ingress.yaml
    ├── _helpers.tpl    # reusable template fragments
    └── NOTES.txt       # printed after install
```

A chart is a directory (or a `.tgz` archive). `Chart.yaml` is the manifest:

```yaml
apiVersion: v2
name: myapp
version: 1.2.0          # chart version
appVersion: "2.5.1"     # application version the chart deploys
description: My web application
```

---

## Templates and Values

Templates are Go templates with Helm-specific functions. Values from `values.yaml` (or overrides) are injected at render time.

```yaml title="templates/deployment.yaml"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-app
spec:
  replicas: {{ .Values.replicaCount }}
  template:
    spec:
      containers:
      - name: app
        image: {{ .Values.image.repository }}:{{ .Values.image.tag }}
        resources:
          {{- toYaml .Values.resources | nindent 10 }}
```

```yaml title="values.yaml"
replicaCount: 2
image:
  repository: myapp
  tag: "1.0.0"
resources:
  requests:
    cpu: 100m
    memory: 128Mi
```

Override values without touching the chart:

```bash
helm install myapp ./mychart --set replicaCount=5
helm install myapp ./mychart -f production-values.yaml
```

---

## Core Commands

```bash
# Install a chart
helm install <release-name> <chart>
helm install redis bitnami/redis -n cache --create-namespace

# Upgrade (update values or chart version)
helm upgrade myapp ./mychart -f production-values.yaml

# Rollback
helm rollback myapp 2           # roll back to revision 2
helm rollback myapp             # roll back to previous revision

# Inspect
helm list                       # all releases in current namespace
helm list -A                    # all releases across all namespaces
helm history myapp              # release revision history
helm status myapp               # current status and notes

# Dry run (preview rendered manifests)
helm install myapp ./mychart --dry-run --debug

# Uninstall
helm uninstall myapp
```

---

## Finding Charts

[Artifact Hub](https://artifacthub.io) is the central repository for public Helm charts. Add a repository and search:

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm search repo bitnami/redis
helm show values bitnami/redis    # inspect default values
```

Popular chart repositories: Bitnami, Prometheus Community, Cert-Manager, Ingress-Nginx, Argo CD.

---

## Helm vs Kustomize

| | Helm | Kustomize |
|---|---|---|
| Templating | Yes (Go templates) | No (pure YAML overlays) |
| Versioning | Yes (chart versions, release history) | No |
| Dependencies | Yes | No |
| Learning curve | Higher | Lower |
| GitOps-friendliness | Requires Helm controller | Native kubectl/kustomize |
| Best for | Distributing apps to others | Environment overlays in your own repo |

Many teams use both: Helm to install third-party applications (Redis, Postgres, Ingress), Kustomize to manage their own application manifests across environments.
