# Private access with Telepresence

The cluster has no external ingress. [Telepresence](https://telepresence.io) connects a laptop to the cluster network, so Services resolve and respond as they would from inside a Pod (`http://<service>.<namespace>:<port>`).

The server side (`traffic-manager`) runs in the `ambassador` namespace (`infra/telepresence`), deployed by Argo CD from the `telepresence-oss` chart.

## Prerequisites

- `kubectl` access to the cluster (see [setup.md](setup.md))
- Telepresence client matching the server version (`2.32.x`):

```bash
brew install telepresenceio/telepresence/telepresence-oss
telepresence version
```

## Connect

```bash
telepresence connect
telepresence status

curl http://httpbin.apps/get
open http://dagster-webserver.apps
open http://argocd-server.argocd
```

Disconnect with `telepresence quit`.

## Reachable Services

| Service | URL |
|---------|-----|
| httpbin | `http://httpbin.apps` |
| hotrod | `http://hotrod.apps:8080` |
| Dagster | `http://dagster-webserver.apps` |
| Adminer | `http://adminer.platform:8080` |
| Argo CD | `http://argocd-server.argocd` |

Workloads built on the `eac-app` chart deny ingress by default, so traffic from the `traffic-manager` must be allowed explicitly. To expose another `eac-app` workload, add it to `nacl.ingress` in its values:

```yaml
nacl:
  ingress:
    - ambassador/traffic-manager:<containerPort>
```

Workloads without a NetworkPolicy (for example, Argo CD and Dagster) are reachable without changes.

## Operations

- The agent injector's webhook certificate is issued by cert-manager (`Issuer/telepresence`, `Certificate/mutator-webhook-tls`), which keeps Argo CD free of diffs from Helm-generated certificates.
- Helm hooks are skipped (`skipHooks: true`); Argo CD manages the lifecycle.
- After `k8s-power` sleep, `traffic-manager` is scaled to zero with everything else; run wake before connecting.
- Intercepts (`telepresence intercept`) are not tested; the injected traffic-agent may need capabilities that GKE Autopilot does not allow.
