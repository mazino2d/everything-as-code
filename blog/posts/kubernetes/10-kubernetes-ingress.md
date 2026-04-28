---
date: 2025-04-26
title: Ingress — Routing External Traffic by Domain and Path
---

A LoadBalancer Service gives you one load balancer per service. In a cluster with 20 services, that's 20 load balancers — and 20 cloud bills. Ingress solves this with a single entry point that routes traffic to many services based on host and path rules.

---

## The Problem Ingress Solves

```text
Without Ingress:
  internet → LB-1 → api service
  internet → LB-2 → web service
  internet → LB-3 → auth service   (3 load balancers, 3 IPs)

With Ingress:
  internet → 1 LB → Ingress controller → api service
                                       → web service
                                       → auth service   (1 LB, 1 IP)
```

Ingress operates at Layer 7 (HTTP/HTTPS). It can route based on:
- **Host**: `api.example.com` → api service, `www.example.com` → web service
- **Path**: `example.com/api` → api service, `example.com/` → web service

---

## Ingress vs IngressController

The **Ingress resource** is a Kubernetes object that declares routing rules. It does nothing by itself.

The **Ingress controller** is a running Pod that watches Ingress resources and implements the rules — typically by configuring an nginx, Traefik, or Envoy reverse proxy.

You must install an Ingress controller. Common choices:

| Controller | Good for |
|---|---|
| ingress-nginx | General purpose, widely used |
| Traefik | Auto-discovers services, good for homelab |
| AWS Load Balancer Controller | AWS ALB, native integration |
| GKE Ingress / GCE | GCP, uses Google Cloud LB |

---

## A Basic Ingress Resource

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
spec:
  ingressClassName: nginx    # which controller handles this
  rules:
  - host: api.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: api
            port:
              number: 80
  - host: www.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web
            port:
              number: 80
```

Traffic arriving at `api.example.com` is routed to the `api` Service; traffic arriving at `www.example.com` is routed to the `web` Service.

---

## Path Types

| PathType | Behaviour |
|---|---|
| `Exact` | Matches `/foo` only, not `/foo/` or `/foobar` |
| `Prefix` | Matches `/foo`, `/foo/bar`, `/foo/bar/baz` |
| `ImplementationSpecific` | Behaviour depends on the Ingress controller |

---

## TLS Termination

Ingress handles TLS termination. The certificate is stored as a Kubernetes Secret:

```yaml
spec:
  tls:
  - hosts:
    - api.example.com
    secretName: api-tls-cert    # Secret containing tls.crt and tls.key
  rules:
  - host: api.example.com
    ...
```

For automatic certificate provisioning and renewal, install **cert-manager**. It watches Ingress resources with the right annotations and issues Let's Encrypt certificates automatically.

```yaml
metadata:
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
```

---

## Default Backend

Traffic that doesn't match any rule is sent to the default backend — usually a 404 page:

```yaml
spec:
  defaultBackend:
    service:
      name: default-404
      port:
        number: 80
```

---

## IngressClass

If you have multiple Ingress controllers in the cluster (e.g., nginx for internal, ALB for external), use `ingressClassName` to specify which controller handles each Ingress resource.

```yaml
spec:
  ingressClassName: nginx
```

---

## Gateway API (the future)

The Kubernetes community is replacing Ingress with the **Gateway API** — a more expressive, role-oriented API that supports L4 and L7 routing, traffic splitting, and header manipulation. Ingress remains supported but new features are being added to Gateway API, not Ingress.

For new clusters, consider using Gateway API if your chosen Ingress controller supports it (nginx, Traefik, and Envoy all do).
