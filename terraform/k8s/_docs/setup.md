# Setup

## 1. Prerequisites

- A running K3S cluster (for example from `terraform/gcp/mazino2d-as-se1-dev`)
- HCP Terraform workspace `k8s` in organisation `mazino2d-everything-as-code`
- HCP Terraform workspace `infisical` already applied at least once

The `k8s` stack reads Infisical machine identity outputs from remote state and writes the Kubernetes secret in namespace `infra`.

## 2. Terraform Cloud Workspace Variables

No `kubeconfig` variable is required.

The `k8s` stack reads Kubernetes access credentials directly from remote state output `kube_config_dev` in workspace `gcp-mazino2d-as-se1-dev`.

Notes:

- Ensure workspace `gcp-mazino2d-as-se1-dev` has been applied successfully before running `k8s`.
- Argo CD performs workload reconciliation; GitHub Actions is not the normal Kubernetes deployment path.

## 3. Terraform Cloud Workspace Settings

Go to workspace `k8s` -> **Settings -> General**:

- Execution Mode: **Remote**
- Auto-apply API, UI, & VCS runs: **On**

## 4. Bootstrap Notes (Infisical + Argo CD)

This stack must bootstrap both Infisical and Argo CD foundations via Terraform before GitOps can fully take over.

Why:

- Infisical bootstrap: the secret `infisical-machine-identity` must exist in namespace `infra` first, otherwise workloads that depend on Infisical-synced secrets cannot start correctly.
- Argo CD bootstrap: Argo CD itself (Helm release, repo credentials, and `Application` CRs) must exist first to start syncing cluster manifests from this repository.

This is a classic chicken-and-egg problem in GitOps, so initial installation belongs in Terraform for deterministic first-run provisioning.

## 5. Apply

```bash
make init STACK=terraform/k8s
make plan STACK=terraform/k8s
make apply STACK=terraform/k8s
```

After the first apply:

- Argo CD is installed and starts reconciling `infra`, `monitoring`, and `apps`
- The Infisical machine identity secret exists in `infra` for workloads/operators that consume it