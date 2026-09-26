# Private Access via Cloudflare WARP

This document describes how to reach in-cluster Services from a laptop or phone without `kubectl port-forward`, using Cloudflare Tunnel and the WARP client. No domain or load balancer is involved.

---

## 1. How it works

```text
device (WARP) ──► Cloudflare edge ──► cloudflared (ns cloudflared) ──► Service ClusterIP
```

- `terraform/cloudflare` creates the tunnel, routes the GKE Service CIDR (`34.118.224.0/20`) through it, and resolves `cluster.local` via kube-dns (`34.118.224.10`) with WARP local domain fallback.
- `kubernetes/clusters/mazino2d-as-se1-dev/infra/cloudflared` runs two connectors using `TUNNEL_TOKEN` synced from Infisical (`/cloudflared/cloudflared`).
- Only Services allowed in the cloudflared `nacl.egress` (and in the backend's `nacl.ingress`) are reachable. Everything else in the Service CIDR is blocked by NetworkPolicy.

---

## 2. Enrol a device

1. Install the client:
   - macOS: `brew install --cask cloudflare-warp`
   - iOS / Android: *Cloudflare One Agent*
2. *Preferences → Account → Login to Cloudflare Zero Trust*, enter the team name, then log in with an email listed in `warp_allowed_emails` (workspace `cloudflare`) using the one-time PIN.
3. Connect in **WARP** mode (traffic and DNS). *DNS only* mode does not route private networks.
4. Check: `dig +short httpbin.apps.svc.cluster.local` returns a `34.118.x.x` address.

The WARP client can only be logged in to one Zero Trust organisation at a time.

---

## 3. Exposed Services

| Service | URL |
|---------|-----|
| Argo CD | http://argocd-server.argocd.svc.cluster.local |
| httpbin | http://httpbin.apps.svc.cluster.local |
| HotROD | http://hotrod.apps.svc.cluster.local:8080 |
| Outline | http://outline.apps.svc.cluster.local:3000 |
| Adminer | http://adminer.platform.svc.cluster.local:8080 |

---

## 4. Exposing another Service

1. Add `<namespace>/<app>:<containerPort>` to `nacl.egress` in `infra/cloudflared/values.yaml`.
2. Add `cloudflared/cloudflared:<containerPort>` to `nacl.ingress` of the target app.
3. For workloads without the `app` label (upstream charts), add an extra NetworkPolicy like `infra/cloudflared/networkpolicy-argocd.yaml`.

---

## 5. Operations

- Grant access to another person: add their email to `warp_allowed_emails` in the `cloudflare` workspace and apply.
- Disable access: disconnect WARP, or set `deployment.replicaCount: 0` in `infra/cloudflared/values.yaml` (Argo CD self-heals manual scaling).
- Rotate the tunnel token: replace the tunnel in the `cloudflare` workspace, apply `infisical`, then `kubectl -n cloudflared rollout restart deploy/cloudflared`.
- Troubleshoot: `kubectl -n cloudflared logs deploy/cloudflared` should show `Registered tunnel connection ... protocol=quic`. If it shows `http2`, UDP egress to the edge is blocked and DNS over WARP will fail.
