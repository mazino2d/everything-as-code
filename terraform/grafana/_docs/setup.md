# Setup

## 1. Create Grafana Cloud PAT

1. Log in at grafana.com
2. My Account → Security → Access Policies
3. Create access policy with scopes: `stacks:read stacks:write accesspolicies:read accesspolicies:write accesspolicies:delete`
4. Copy the token immediately — shown only once

## 2. Get Infisical credentials

Reuse the `github-actions` machine identity credentials from the infisical stack, or create a dedicated identity. The client needs `write` access to the `everything-as-code` project.

Get `infisical_project_id` from Infisical UI → Project → Settings → Project ID.

## 3. Create TF Cloud Workspace

Create workspace `grafana` in org `mazino2d-everything-as-code`:

- Working directory: `terraform/grafana`
- Execution mode: Remote, auto-apply on

Add variables:

| Key | Sensitive |
|-----|-----------|
| `grafana_cloud_access_policy_token` | ✅ |
| `infisical_client_id` | ✅ |
| `infisical_client_secret` | ✅ |
| `infisical_project_id` | ❌ |

## 4. Apply

```bash
make init STACK=terraform/grafana
make plan STACK=terraform/grafana
make apply STACK=terraform/grafana
```

After apply, Grafana Cloud credentials are automatically stored in Infisical under `/grafana-alloy` (env: `dev`).

## 5. Bootstrap K8s Operator Secret

After the infisical stack is applied (which creates the `k8s-operator` identity) and the `infra/` K8s directory is deployed (which creates the `infisical-operator` namespace), create the one-time bootstrap secret:

```bash
kubectl create secret generic infisical-operator-credentials \
  --namespace infisical-operator \
  --from-literal=clientId="$(terraform -chdir=terraform/infisical output -raw k8s_operator_client_id)" \
  --from-literal=clientSecret="$(terraform -chdir=terraform/infisical output -raw k8s_operator_client_secret)"
```

This secret is never committed to git — it allows the Infisical Kubernetes Operator to authenticate and sync secrets into the cluster.
