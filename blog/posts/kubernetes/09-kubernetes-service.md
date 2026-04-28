---
date: 2025-04-26
title: Services — How Pods Talk to Each Other
---

Pods are ephemeral. They get new IP addresses when they restart, and they come and go as deployments scale and roll out. Services provide a stable network endpoint that other workloads can rely on, regardless of which Pods are actually running.

---

## The Problem

A Deployment creates Pods with random names and IPs: `10.0.0.5`, `10.0.0.12`, `10.0.0.23`. When Pod `10.0.0.5` crashes and is replaced, the new Pod gets a different IP. Any other service that hardcoded `10.0.0.5` is now broken.

Services solve this by providing a stable virtual IP (ClusterIP) and DNS name that maps to the current set of healthy Pods.

---

## How Services Work

A Service selects Pods using label selectors and maintains an Endpoints object listing the IPs of matching Pods.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web
spec:
  selector:
    app: web          # selects all pods with label app=web
  ports:
  - port: 80          # port the Service listens on
    targetPort: 8080  # port on the Pod
```

When a client connects to the Service's ClusterIP on port 80, kube-proxy (running on each node) forwards the traffic to one of the matching Pods on port 8080. The selection is random by default (roughly round-robin via iptables or IPVS).

---

## Service Types

### ClusterIP (default)

A virtual IP accessible only within the cluster. Use this for internal service-to-service communication.

```
client pod  →  web.default.svc.cluster.local:80  →  Pod A or B or C
```

The DNS name is automatically available to all Pods in the cluster.

### NodePort

Exposes the Service on a static port on every node's IP (default range: 30000–32767).

```
external client  →  <any-node-ip>:30080  →  Service  →  Pod
```

Useful for development and simple setups. Not recommended for production: it exposes a port on every node, and load balancing is only as good as how traffic reaches the nodes.

### LoadBalancer

Provisions an external cloud load balancer (AWS ALB/NLB, GCP Load Balancer, Azure Load Balancer). The LB forwards traffic to the NodePort on healthy nodes.

```
internet  →  cloud LB  →  NodePort  →  Service  →  Pod
```

Simple to set up but expensive: one load balancer per Service. For many HTTP services, use Ingress instead (one load balancer routes to many services).

### ExternalName

Maps a Service to an external DNS name. Useful for integrating external databases or services using Kubernetes DNS.

```yaml
spec:
  type: ExternalName
  externalName: db.example.com
```

---

## Headless Services

Setting `clusterIP: None` creates a headless Service. Instead of a virtual IP, DNS resolves directly to the IPs of the Pods.

```yaml
spec:
  clusterIP: None
  selector:
    app: mysql
```

DNS query for `mysql.default.svc.cluster.local` returns all Pod IPs. Used by StatefulSets to give each Pod a stable DNS address (`mysql-0.mysql`, `mysql-1.mysql`).

---

## Service DNS

Every Service gets a DNS name in the cluster:

```
<service-name>.<namespace>.svc.cluster.local
```

Pods in the same namespace can use the short form:

```bash
# From a pod in the "default" namespace:
curl http://web            # works (same namespace)
curl http://web.default    # works
curl http://web.default.svc.cluster.local  # works (fully qualified)

# Accessing a service in another namespace:
curl http://api.backend    # from default, accessing "api" in "backend" namespace
```

---

## Summary

| Type | Accessible from | Use case |
|---|---|---|
| ClusterIP | Inside cluster | Service-to-service communication |
| NodePort | Outside cluster (via node IP) | Dev/test, simple external access |
| LoadBalancer | Outside cluster (via cloud LB) | Production external access |
| ExternalName | Inside cluster | Alias to external DNS |
| Headless | Inside cluster (direct Pod DNS) | StatefulSets, client-side LB |

For exposing many HTTP services to the internet, combine a single LoadBalancer or NodePort with an Ingress controller — the subject of the next post.
