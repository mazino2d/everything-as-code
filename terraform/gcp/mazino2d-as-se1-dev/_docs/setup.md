# mazino2d-as-se1-dev setup

Dev project for the platform: the GKE Autopilot cluster `mazino2d-as-se1-dev`
(`asia-southeast1`), the always-free `vm-free` VM (`us-central1-a`), the Velero backup
bucket, the Terraform state bucket and keyless GitHub Actions identities. Its state is
`state/gcp/mazino2d-as-se1-dev`.

Some steps have no Terraform or API support and are done by hand, once. Use them to
rebuild the project from scratch.

## 1. Project, Terraform service account and state bucket

Follow [terraform/gcp/_docs/setup.md](../../_docs/setup.md) with
`<project-id>` = `mazino2d-as-se1-dev`. This project also holds the state bucket
`gs://mazino2d-as-se1-dev-tfstate` and the Workload Identity pool `github` (defined in
`tfstate.tf`), which every stack's CI uses. The stack's variables live in
`secrets/gcp/mazino2d-as-se1-dev.tfvars.json` (`make secrets-edit STACK=terraform/gcp/mazino2d-as-se1-dev`):

| Key | Value | Sensitive |
|---|---|---|
| `duckdns_token` | token from [duckdns.org](https://www.duckdns.org) | ✅ |

The bucket holds this stack's own state, so on a rebuild it has to exist before the
first `terraform init`. Create it by hand; the first apply adopts it (`import` blocks
in `tfstate.tf`) together with the pool, which already exists in `github_actions.tf`:

```bash
gcloud storage buckets create gs://mazino2d-as-se1-dev-tfstate \
  --project mazino2d-as-se1-dev --location asia-southeast1 \
  --uniform-bucket-level-access --public-access-prevention
gcloud storage buckets update gs://mazino2d-as-se1-dev-tfstate --versioning
gcloud storage buckets add-iam-policy-binding gs://mazino2d-as-se1-dev-tfstate \
  --member user:<you> --role roles/storage.objectAdmin
```

Then run the first apply locally (`gcloud auth application-default login`,
`make apply STACK=terraform/gcp/mazino2d-as-se1-dev`), since CI can only sign in once
the pool and bindings exist.

`module.vm-free` reads `duckdns_token` at plan time and passes it to the VM in its
metadata. Without it, the VM boots but can't update its DuckDNS record.

Other stacks read this stack's outputs from its state in the bucket; no sharing step is
needed:

| Consumer | Reads |
|---|---|
| `terraform/k8s/mazino2d-as-se1-dev` | `gke_cluster_endpoint`, `gke_cluster_ca_cert`, `k8s_tf_sa_key_json` |
| `terraform/infisical` | `workload_gsa` (the Velero SA key, synced to Infisical) |

## 2. vm-free

The VM registers its ephemeral IP as `mazino2d-free.duckdns.org` on boot.

1. In [duckdns.org](https://www.duckdns.org), create the subdomain `mazino2d-free` under
   the account that owns `duckdns_token`.
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
