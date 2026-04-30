# Setup

## 1. Prerequisites

- A running K3S cluster (for example from `terraform/gcp/mazino2d-as-se1-dev`)
- HCP Terraform workspace `k8s` in organisation `mazino2d-everything-as-code`
- HCP Terraform workspace `infisical` already applied at least once

The `k8s` stack reads Infisical machine identity outputs from remote state and writes the Kubernetes secret in namespace `infra`.

## 2. Terraform Cloud Workspace Variables

Go to workspace `k8s` -> **Variables** -> add:

| Category  | Key          | Value                                                             | Sensitive |
|-----------|--------------|-------------------------------------------------------------------|-----------|
| terraform | `kubeconfig` | base64-encoded kubeconfig for the target cluster                  | ✅        |

Generate the value using:

```bash
ssh user@mazino2d-k3s.duckdns.org "sudo cat /etc/rancher/k3s/k3s.yaml" \
  | sed 's/127.0.0.1/mazino2d-k3s.duckdns.org/g' \
  | base64
```

Notes:

- Store this value in HCP Terraform workspace variables.
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