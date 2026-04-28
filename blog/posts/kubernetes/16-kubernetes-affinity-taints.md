---
date: 2025-04-26
title: Node Affinity, Taints and Tolerations — Controlling Pod Placement
---

By default, the Kubernetes scheduler places Pods on any node with sufficient capacity. Three mechanisms let you override this: node affinity, taints, and tolerations. They answer different questions: "where should this Pod go?" and "which Pods are allowed on this node?"

---

## nodeSelector — The Simplest Approach

`nodeSelector` is the bluntest tool: the Pod runs only on nodes with all the specified labels.

```yaml
spec:
  nodeSelector:
    kubernetes.io/arch: amd64
    node-type: gpu
```

This works for simple cases. For more expressiveness, use node affinity.

---

## Node Affinity

Node affinity is a more powerful version of `nodeSelector` with two modes:

**RequiredDuringSchedulingIgnoredDuringExecution (hard)**: the Pod cannot be scheduled on a node that doesn't satisfy this rule. If no node matches, the Pod stays `Pending`.

**PreferredDuringSchedulingIgnoredDuringExecution (soft)**: the scheduler prefers nodes that satisfy this rule, but will use others if necessary.

```yaml
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: topology.kubernetes.io/zone
            operator: In
            values: [us-east-1a, us-east-1b]
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 80
        preference:
          matchExpressions:
          - key: node-type
            operator: In
            values: [compute-optimised]
```

The `weight` (1–100) determines preference priority when multiple preferred rules apply.

---

## Pod Affinity and Anti-Affinity

Node affinity targets node characteristics. Pod affinity/anti-affinity targets the presence of other Pods.

**Co-locate** a cache Pod on the same node as the application Pod (reduces latency):

```yaml
affinity:
  podAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        labelSelector:
          matchLabels:
            app: web
        topologyKey: kubernetes.io/hostname
```

**Spread** replicas across nodes for high availability (anti-affinity):

```yaml
affinity:
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
    - labelSelector:
        matchLabels:
          app: web
      topologyKey: kubernetes.io/hostname
```

This ensures no two `app=web` Pods land on the same node. `topologyKey` can also be `topology.kubernetes.io/zone` to spread across availability zones.

---

## Taints and Tolerations

Taints and tolerations work in the opposite direction: instead of Pods choosing nodes, nodes repel Pods.

**A taint** marks a node: "don't schedule Pods here unless they explicitly opt in."

```bash
kubectl taint nodes gpu-node-1 accelerator=nvidia:NoSchedule
```

Taint effects:
- `NoSchedule`: new Pods without the toleration won't be scheduled here
- `PreferNoSchedule`: scheduler avoids this node but may use it if necessary
- `NoExecute`: existing Pods without the toleration are evicted; new ones won't be scheduled

**A toleration** is the Pod's opt-in:

```yaml
spec:
  tolerations:
  - key: accelerator
    operator: Equal
    value: nvidia
    effect: NoSchedule
```

A toleration doesn't guarantee the Pod goes to the tainted node — it just allows it to. Combine with node affinity if you want the Pod to go there, not just be allowed there.

---

## Common Use Cases

**Dedicated nodes**: taint a group of nodes for a specific team or workload. Only Pods with the matching toleration can use them.

```bash
kubectl taint nodes node-1 team=data-engineering:NoSchedule
```

**Spot/preemptible instances**: cloud providers often taint spot nodes. Add a toleration to workloads that tolerate interruption; leave it off workloads that need guaranteed availability.

**GPU nodes**: taint GPU nodes so only GPU workloads are scheduled there. Without the taint, CPU-only Pods would fill GPU nodes, wasting expensive hardware.

**Control plane isolation**: Kubernetes taints control plane nodes by default (`node-role.kubernetes.io/control-plane:NoSchedule`). Only system components with the matching toleration run there.

---

## TopologySpreadConstraints

A cleaner alternative to pod anti-affinity for spreading Pods across failure domains:

```yaml
spec:
  topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: kubernetes.io/hostname
    whenUnsatisfiable: DoNotSchedule
    labelSelector:
      matchLabels:
        app: web
```

This ensures the difference in replica count between any two nodes is at most 1 — a balanced spread. `whenUnsatisfiable: ScheduleAnyway` makes it a soft constraint.

Use `TopologySpreadConstraints` for availability; use taints/tolerations for isolation.
