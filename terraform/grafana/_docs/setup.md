# Setup

## 1. Create Grafana Cloud PAT

1. Log in at grafana.com
2. My Account → Security → Access Policies
3. Create access policy with scopes: `stacks:read stacks:write accesspolicies:read accesspolicies:write accesspolicies:delete stack-service-accounts:write`
4. Copy the token immediately — shown only once

## 2. Add the Terraform variable

State lives in `gs://mazino2d-as-se1-eac-tfstate` (prefix `state/grafana/stack`). Put the token in the stack's variables file, `secrets/grafana/stack.tfvars.json` in the same bucket:

```bash
make secrets-edit STACK=terraform/grafana/stack
```

```json
{
  "grafana_cloud_access_policy_token": "<token>"
}
```

CI and `make plan/apply` copy it to `terraform/grafana/stack/ci.auto.tfvars.json` (git-ignored).

## 3. Apply Grafana Stack

Merge to `main`: CI applies `terraform/grafana/stack` (preview locally with `make plan STACK=terraform/grafana/stack`).

The stack manages Grafana Cloud resources and exposes their credentials as outputs; it does not write to Infisical (see §4).

## 4. Configure Secret Sync In Infisical Stack

Grafana credentials are pushed to Infisical by the infisical stack via `secret_tree.yaml` and Terraform remote state.

1. No sharing step is needed: stacks read each other's state from the bucket, and the infisical stack's service account has access to it.
2. In `terraform/infisical/secret_tree.yaml`, define secrets using `remote_state` (the `stack` path under `terraform/`) and optional `format`:

```yaml
tree:
  monitoring:
    grafana-alloy:
      secrets:
        - key: PROMETHEUS_URL
          remote_state:
            stack: grafana/stack
            output: dev_prometheus_remote_endpoint
            format: "%s/push"
```

3. Merge to `main`: CI applies `terraform/infisical`. It reads `terraform/grafana/stack`'s state, so that stack must have applied first.
