# mazino2d-as-se1-dev setup

Dev project for the platform: the GKE Autopilot cluster `mazino2d-as-se1-dev`
(`asia-southeast1`), the always-free `vm-free` VM (`us-central1-a`), the Velero backup
bucket and keyless GitHub Actions identities. The workspace is `gcp-mazino2d-as-se1-dev`.

Some steps have no Terraform or API support and are done by hand, once. Use them to
rebuild the project from scratch.

## 1. Project, Terraform service account and workspace

Follow [terraform/gcp/_docs/setup.md](../../_docs/setup.md) with
`<project-id>` = `mazino2d-as-se1-dev`. The workspace is `gcp-mazino2d-as-se1-dev`, with
these variables:

| Type | Key | Value | Sensitive |
|---|---|---|---|
| Terraform | `gcp_credentials` | contents of the `terraform` SA key | ✅ |
| Environment | `DUCKDNS_TOKEN` | token from [duckdns.org](https://www.duckdns.org) | ✅ |

`module.vm-free` reads `DUCKDNS_TOKEN` at plan time and passes it to the VM in its
metadata. Without it, the VM boots but can't update its DuckDNS record.

In **Settings → Remote state sharing**, share this workspace with the workspaces that
read its outputs:

| Consumer | Reads |
|---|---|
| `k8s-mazino2d-as-se1-dev` | `gke_cluster_endpoint`, `gke_cluster_ca_cert`, `k8s_tf_sa_key_json` |
| `infisical` | `workload_gsa` (the Velero SA key, synced to Infisical) |

## 2. vm-free

The VM registers its ephemeral IP as `mazino2d-free.duckdns.org` on boot.

1. In [duckdns.org](https://www.duckdns.org), create the subdomain `mazino2d-free` under
   the account that owns `DUCKDNS_TOKEN`.
2. To SSH in, use the key whose public half is `ssh_public_key` in `vms.tf`:

   ```bash
   ssh user@mazino2d-free.duckdns.org
   ```

## 3. After the first apply

Apply the downstream stacks, in this order:

1. `terraform/k8s/mazino2d-as-se1-dev`: installs Argo CD and the Infisical operator on
   the new cluster. Argo CD then reconciles `kubernetes/clusters/mazino2d-as-se1-dev`.
2. `terraform/infisical`: syncs the Velero SA key from `workload_gsa` into Infisical.

Then set up local cluster access with [kubernetes/_docs/setup.md](../../../../kubernetes/_docs/setup.md).

## 4. GitHub Actions

`.github/workflows/k8s-power.yml` authenticates with values hard-coded from this stack.
After you rebuild the project, update them from the outputs:

| Workflow input | Output |
|---|---|
| `workload_identity_provider` | `github_actions_wif_provider` (contains the project number) |
| `service_account` | `gha_k8s_power_sa_email` |

The provider only trusts workflows on `main` of `mazino2d/everything-as-code`
(`github_actions.tf`).
