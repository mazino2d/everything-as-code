# Setup

## 1. Prerequisites

- A running K3S cluster (for example from `terraform/gcp/mazino2d-as-se1-dev`)
- The `infisical` stack already applied at least once

The `k8s` stack reads Infisical machine identity outputs from remote state and writes the Kubernetes secret in namespace `infisical-operator`.

## 2. Terraform Variables

No `kubeconfig` variable is required.

The `k8s` stack reads Kubernetes access credentials directly from the remote state of `terraform/gcp/mazino2d-as-se1-dev` (`state/gcp/mazino2d-as-se1-dev` in `gs://mazino2d-as-se1-eac-tfstate`).

Notes:

- Ensure stack `terraform/gcp/mazino2d-as-se1-dev` has been applied successfully before running `k8s`.
- Argo CD performs workload reconciliation; GitHub Actions is not the normal Kubernetes deployment path.

## 3. State and Authentication

State lives in `gs://mazino2d-as-se1-eac-tfstate` (prefix `state/k8s/mazino2d-as-se1-dev`). CI signs in through Workload Identity Federation as `terraform@mazino2d-as-se1-dev.iam.gserviceaccount.com`; locally run `gcloud auth application-default login` first.

## 4. Bootstrap Notes (Infisical + Argo CD)

This stack must bootstrap both Infisical and Argo CD foundations via Terraform before GitOps can fully take over.

Why:

- Infisical bootstrap: the secret `infisical-machine-identity` must exist in namespace `infisical-operator` first, otherwise workloads that depend on Infisical-synced secrets cannot start correctly.
- Argo CD bootstrap: Argo CD itself (Helm release, repo credentials, and `Application` CRs) must exist first to start syncing cluster manifests from this repository.

This is a classic chicken-and-egg problem in GitOps, so initial installation belongs in Terraform for deterministic first-run provisioning.

## 5. Apply

```bash
make init STACK=terraform/k8s/mazino2d-as-se1-dev
make plan STACK=terraform/k8s/mazino2d-as-se1-dev
make apply STACK=terraform/k8s/mazino2d-as-se1-dev
```

After the first apply:

- Argo CD is installed and starts reconciling `infra`, `monitoring`, and `apps`
- The Infisical machine identity secret exists in `infra` for workloads/operators that consume it