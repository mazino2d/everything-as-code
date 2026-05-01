# Setup

## 1. Create Grafana Cloud PAT

1. Log in at grafana.com
2. My Account → Security → Access Policies
3. Create access policy with scopes: `stacks:read stacks:write accesspolicies:read accesspolicies:write accesspolicies:delete`
4. Copy the token immediately — shown only once

## 2. Create TF Cloud Workspace

Create workspace `grafana` in org `mazino2d-everything-as-code`:

- Working directory: `terraform/grafana`
- Execution mode: Remote, auto-apply on

Add variables:

| Key | Sensitive |
|-----|-----------|
| `grafana_cloud_access_policy_token` | ✅ |

## 3. Apply Grafana Stack

```bash
make init STACK=terraform/grafana
make plan STACK=terraform/grafana
make apply STACK=terraform/grafana
```

This stack now manages Grafana Cloud resources and outputs only. It does not write secrets to Infisical directly.

## 4. Configure Secret Sync In Infisical Stack

Grafana credentials are pushed to Infisical by the infisical stack via `secret_tree.yaml` and Terraform remote state.

1. In Terraform Cloud, allow workspace `infisical` to read remote state from workspace `grafana`.
2. In `terraform/infisical/secret_tree.yaml`, define secrets using `remote_state` and optional `format`:

```yaml
tree:
  monitoring:
    grafana-alloy:
      secrets:
        - key: PROMETHEUS_URL
          remote_state:
            workspace: grafana
            output: dev_prometheus_remote_endpoint
            format: "%s/push"
```

3. Apply the infisical stack after grafana:

```bash
make init STACK=terraform/infisical
make plan STACK=terraform/infisical
make apply STACK=terraform/infisical
```

## 5. Bootstrap K8s Operator Secret (Optional)

After the infisical stack is applied (which creates the `k8s-operator` identity) and the `infra/` K8s directory is deployed (which creates the `infisical-operator` namespace), create the one-time bootstrap secret:

```bash
kubectl create secret generic infisical-operator-credentials \
  --namespace infisical-operator \
  --from-literal=clientId="$(terraform -chdir=terraform/infisical output -raw k8s_operator_client_id)" \
  --from-literal=clientSecret="$(terraform -chdir=terraform/infisical output -raw k8s_operator_client_secret)"
```

This secret is never committed to git. It allows the Infisical Kubernetes Operator to authenticate and sync secrets into the cluster.
