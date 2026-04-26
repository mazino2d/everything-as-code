---
date: 2025-04-26
title: Pods — The Smallest Deployable Unit
---

Every workload in Kubernetes runs inside a Pod. Understanding what a Pod is — and what it is not — is the foundation for understanding everything else.

---

## What Is a Pod?

A Pod is a group of one or more containers that share:

- **Network namespace**: they share the same IP address and port space. Container A on port 8080 and container B on port 9090 are both reachable at the same Pod IP.
- **Storage volumes**: any volumes defined on the Pod can be mounted by any container in the Pod.
- **Lifecycle**: containers in the same Pod are started and stopped together.

The most common case is a single container per Pod. Multi-container Pods are used for specific patterns (described below).

---

## Multi-container Pod Patterns

When should you put two containers in the same Pod? Only when they are so tightly coupled that they must run on the same machine and share resources.

**Sidecar**: a helper container that augments the main container. Example: a log shipper that reads the app's log files and forwards them to a centralised logging service.

**Ambassador**: a proxy container that handles external communication. Example: an Envoy sidecar that handles TLS termination and retries, so the main app talks to plain HTTP.

**Adapter**: a container that normalises output from the main container. Example: transforming proprietary metrics into a format Prometheus can scrape.

For most applications, one container per Pod is the right choice. Multi-container Pods add complexity.

---

## Why You Never Run Naked Pods

A "naked" Pod is one created directly with `kubectl run` or a plain Pod manifest — without a controller (Deployment, StatefulSet, etc.) managing it.

The problem: if the node running the Pod fails, the Pod is gone. Kubernetes will not reschedule it. There is no desired count to maintain, no restart logic at the pod level — only at the container level within the Pod.

In practice, you almost never create Pods directly. You create a Deployment (or StatefulSet, DaemonSet), and Kubernetes creates and manages the Pods for you.

!!! warning "The one exception"
    Static Pods — defined as files on a node, managed by kubelet directly — are used for control plane components (etcd, API server, scheduler). You'll see them in `kube-system`. Don't create your own static Pods; use a Deployment instead.

---

## Pod Lifecycle

A Pod moves through these phases:

| Phase | Meaning |
|-------|---------|
| `Pending` | Scheduled but containers not yet started (pulling images, awaiting resources) |
| `Running` | At least one container is running |
| `Succeeded` | All containers exited with code 0 (terminal state for Jobs) |
| `Failed` | All containers exited, at least one with non-zero code |
| `Unknown` | Node communication lost |

Within `Running`, individual containers have their own states: `Waiting`, `Running`, `Terminated`.

---

## Health Checks

Kubernetes knows whether a Pod is healthy through probes:

**Liveness probe**: is the container alive? If it fails, Kubernetes restarts the container.

**Readiness probe**: is the container ready to accept traffic? If it fails, the Pod is removed from the Service's endpoints (traffic stops routing to it) but it is not restarted.

**Startup probe**: has the container finished initialising? Used for slow-starting apps to prevent liveness probes from killing a container before it's ready.

```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 5

readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  periodSeconds: 5
```

Always define both liveness and readiness probes for production workloads. Without them, Kubernetes routes traffic to a Pod the moment it starts — even if it hasn't finished initialising.

---

## Useful Commands

```bash
kubectl get pods                           # list pods
kubectl get pod <name> -o yaml             # full YAML definition
kubectl describe pod <name>                # events + status details
kubectl logs <name>                        # container logs
kubectl logs <name> --previous             # logs from the previous (crashed) container
kubectl exec -it <name> -- sh              # shell into the container
kubectl delete pod <name>                  # delete (controller will recreate it)
```

`kubectl describe` is your first stop when a Pod isn't behaving as expected. The `Events` section at the bottom shows what Kubernetes has done and any errors encountered.
