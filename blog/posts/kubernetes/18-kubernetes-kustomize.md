---
date: 2025-04-26
title: Kustomize — Environment-specific Configuration Without Duplication
---

Kustomize lets you customise Kubernetes YAML for different environments without templates, without a new language, and without copying files. It works by layering patches on top of a common base — pure YAML in, pure YAML out.

---

## The Problem

You have an application with three environments: dev, staging, and production. They share 90% of their YAML. The differences are: replica count, resource limits, image tag, and a few environment variables.

Options:
1. **Copy-paste**: three separate sets of YAML files. Every shared change must be made three times.
2. **Helm templates**: full Go template syntax for what are mostly minor variations.
3. **Kustomize**: a base of shared YAML, with small overlays for each environment.

---

## Base + Overlays

The core pattern:

```text
kubernetes/
├── base/
│   ├── kustomization.yaml
│   ├── deployment.yaml
│   └── service.yaml
└── overlays/
    ├── dev/
    │   └── kustomization.yaml
    ├── staging/
    │   └── kustomization.yaml
    └── production/
        ├── kustomization.yaml
        └── replica-patch.yaml
```

**Base** contains the shared resources. It is a complete, deployable configuration on its own.

**Overlays** reference the base and apply patches. An overlay does not copy the base files — it transforms them.

---

## Kustomization Files

```yaml title="base/kustomization.yaml"
resources:
- deployment.yaml
- service.yaml
```

```yaml title="overlays/production/kustomization.yaml"
resources:
- ../../base

namePrefix: prod-          # prepend "prod-" to all resource names
namespace: production       # set namespace on all resources

images:
- name: myapp
  newTag: "1.5.2"          # override image tag

patches:
- path: replica-patch.yaml
```

```yaml title="overlays/production/replica-patch.yaml"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app                  # matches the base deployment name (before namePrefix)
spec:
  replicas: 5
```

Build the production configuration:

```bash
kustomize build overlays/production
# or with kubectl:
kubectl apply -k overlays/production
```

The output is plain Kubernetes YAML — no template syntax, no Kustomize-specific runtime required.

---

## Patch Types

### Strategic Merge Patch

The patch file looks like a partial Kubernetes manifest. Kustomize merges it into the base resource. Lists (like `containers`) are merged by name.

```yaml title="Add an environment variable to a container"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
spec:
  template:
    spec:
      containers:
      - name: app
        env:
        - name: ENVIRONMENT
          value: production
```

### JSON Patch (RFC 6902)

More precise control. Use `add`, `replace`, `remove` operations on specific JSON paths.

```yaml
patches:
- target:
    kind: Deployment
    name: app
  patch: |-
    - op: replace
      path: /spec/replicas
      value: 5
    - op: add
      path: /spec/template/spec/containers/0/env/-
      value:
        name: LOG_LEVEL
        value: warn
```

Use strategic merge for most cases. Use JSON patch when you need to remove a field or target a specific list element.

---

## Built-in Transformers

Kustomize has transformers that apply to all resources automatically:

```yaml
# Common transformations
namePrefix: prod-
nameSuffix: -v2
namespace: production
commonLabels:
  environment: production
commonAnnotations:
  team: platform
```

These are applied to every resource in the overlay without writing patch files.

---

## Helm + Kustomize Together

Kustomize can render Helm charts as part of a build:

```yaml title="kustomization.yaml"
helmCharts:
- name: redis
  repo: https://charts.bitnami.com/bitnami
  version: "18.0.0"
  releaseName: cache
  namespace: apps
  valuesFile: redis-values.yaml
```

This is how you can manage both your own apps (via base/overlays) and third-party charts (via Helm) in a single GitOps workflow, applying Kustomize patches on top of Helm output.

---

## When to Use Kustomize vs Helm

Use **Kustomize** when:
- You own the application and manage it across environments
- You want plain YAML in git (GitOps-friendly, no render step)
- Customisations are overlays and patches on a shared base
- You want to patch Helm chart output after rendering

Use **Helm** when:
- You're packaging an application for others to install
- Your chart has complex templating logic or dependencies
- You need versioned releases with rollback history
- You're installing third-party software (Redis, Postgres, etc.)
