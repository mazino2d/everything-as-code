---
date: 2025-04-26
title: Resource Requests and Limits — Fair Sharing in the Cluster
---

Without resource management, one poorly-behaved Pod can exhaust CPU or memory on a node, causing other Pods to fail or be evicted. Requests and limits give Kubernetes the information it needs to schedule workloads fairly and enforce boundaries at runtime.

---

## Requests vs Limits

These are two distinct concepts that serve different purposes:

**Request**: the minimum amount of CPU or memory the container needs. Kubernetes uses requests for scheduling — it only places a Pod on a node that has at least this much capacity available. The container is *guaranteed* this resource.

**Limit**: the maximum amount of CPU or memory the container can use. Enforced at runtime by the kernel. A container that tries to use more than its limit is throttled (CPU) or killed (memory).

```yaml
resources:
  requests:
    cpu: "250m"      # 250 millicores = 0.25 CPU
    memory: "256Mi"
  limits:
    cpu: "500m"
    memory: "512Mi"
```

In this example: Kubernetes schedules this container on a node with at least 250m CPU and 256Mi memory free. At runtime, the container can burst up to 500m CPU and 512Mi memory, but no further.

---

## CPU Units

CPU is measured in millicores. `1000m` = 1 CPU core = 1 vCPU.

- `250m` = 0.25 core (one quarter of a CPU)
- `100m` = 0.1 core
- `2` = 2 cores

CPU is a **compressible** resource. If a container tries to use more than its limit, the kernel throttles it — the container slows down but doesn't crash.

---

## Memory Units

Memory is measured in bytes with SI or binary suffixes:
- `Mi` = mebibytes (1 MiB = 1,048,576 bytes)
- `Gi` = gibibytes
- `M` = megabytes (1 MB = 1,000,000 bytes)

Memory is an **incompressible** resource. If a container exceeds its memory limit, it is killed with OOMKilled (Out Of Memory). Kubernetes restarts it, but if it keeps OOMKilling, it enters a crash loop.

!!! warning "Symptom of too-low memory limits"
    If you see `OOMKilled` in `kubectl describe pod`, the container is exceeding its memory limit. Increase the limit or investigate the memory leak.

---

## Quality of Service Classes

Kubernetes assigns each Pod a QoS class based on its resource configuration. This determines eviction priority when the node runs out of memory.

**Guaranteed**: every container in the Pod has equal requests and limits for both CPU and memory. These Pods are evicted last.

```yaml
resources:
  requests: { cpu: "500m", memory: "512Mi" }
  limits:   { cpu: "500m", memory: "512Mi" }
```

**Burstable**: at least one container has requests or limits defined, but requests != limits. These Pods are evicted after BestEffort.

**BestEffort**: no container has any requests or limits defined. These Pods are evicted first when the node is under memory pressure.

For production workloads, aim for **Guaranteed** QoS — or at minimum Burstable with realistic requests.

---

## Namespace-level Controls

### LimitRange

Sets default and maximum resource values for Pods in a namespace. Pods created without explicit resources inherit the defaults.

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: default-limits
spec:
  limits:
  - type: Container
    default:
      cpu: "200m"
      memory: "256Mi"
    defaultRequest:
      cpu: "100m"
      memory: "128Mi"
    max:
      cpu: "2"
      memory: "4Gi"
```

### ResourceQuota

Caps the total resource consumption for an entire namespace.

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: team-quota
spec:
  hard:
    requests.cpu: "4"
    requests.memory: "8Gi"
    limits.cpu: "8"
    limits.memory: "16Gi"
    pods: "20"
```

---

## Practical Guidance

Start with no limits in development to understand actual consumption, then set limits based on observed usage with a reasonable buffer (1.5–2×).

Profile with `kubectl top pods` and application-level metrics before committing to production resource values. Overly tight limits cause OOMKills and throttling; overly loose limits waste cluster capacity.

```bash
kubectl top pods -n my-namespace             # current CPU/memory usage
kubectl top pods --sort-by=memory            # sort by memory usage
kubectl describe node <node-name>            # see resource allocation per node
```
