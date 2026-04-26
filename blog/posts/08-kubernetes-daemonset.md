---
date: 2025-04-26
title: DaemonSets — Running Agents on Every Node
---

Some workloads don't belong to a specific application — they belong to every node. A DaemonSet ensures exactly one Pod runs on each node in the cluster (or a selected subset of nodes).

---

## The Use Case

Think of node-level agents: tools that need to be present everywhere to observe, instrument, or manage each machine.

Common examples:

- **Monitoring agents**: Prometheus node-exporter collects hardware and OS metrics from each node
- **Log collectors**: Fluentd or Filebeat ship container logs from the node's filesystem to a centralised log store
- **Network plugins**: CNI plugins (Calico, Cilium) run on every node to manage pod networking
- **Storage drivers**: CSI node plugins that expose local storage to pods
- **Security agents**: runtime threat detection tools that monitor syscalls at the node level

The defining characteristic: the number of replicas is not configured. It's always "one per node" — whatever the cluster size is.

---

## A Minimal DaemonSet

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-exporter
spec:
  selector:
    matchLabels:
      app: node-exporter
  template:
    metadata:
      labels:
        app: node-exporter
    spec:
      hostNetwork: true        # access node's network interfaces
      containers:
      - name: node-exporter
        image: prom/node-exporter:v1.8.0
        ports:
        - containerPort: 9100
          hostPort: 9100
```

When a new node joins the cluster, Kubernetes automatically schedules a DaemonSet Pod on it. When a node is removed, its DaemonSet Pod is garbage-collected.

---

## Running on Control Plane Nodes

By default, control plane nodes have a taint that prevents most Pods from being scheduled on them:

```
node-role.kubernetes.io/control-plane:NoSchedule
```

If your DaemonSet should also run on control plane nodes (common for network plugins and monitoring), add a toleration:

```yaml
tolerations:
- key: node-role.kubernetes.io/control-plane
  operator: Exists
  effect: NoSchedule
```

---

## Targeting a Subset of Nodes

Use `nodeSelector` or `nodeAffinity` to restrict the DaemonSet to specific nodes:

```yaml
spec:
  template:
    spec:
      nodeSelector:
        type: gpu-node    # only nodes labelled with type=gpu-node
```

This is useful for workloads that only make sense on certain hardware — a GPU metrics collector that should only run on GPU-equipped nodes, for example.

---

## DaemonSet vs Deployment

| | Deployment | DaemonSet |
|---|---|---|
| Replicas | Fixed count (you decide) | One per node (automatic) |
| Scheduling | Anywhere with capacity | Every node (or subset) |
| Scale with cluster | No (fixed count) | Yes (follows node count) |
| Use case | Application workloads | Node-level agents |

---

## Useful Commands

```bash
kubectl get daemonset
kubectl get daemonset -n kube-system          # system DaemonSets
kubectl describe daemonset node-exporter
kubectl rollout status daemonset node-exporter
kubectl rollout undo daemonset node-exporter
```

DaemonSets support rolling updates with the same `maxUnavailable` mechanism as Deployments. The default strategy is `RollingUpdate`.

!!! note "kube-proxy is a DaemonSet"
    Running `kubectl get daemonset -n kube-system` in any cluster will show `kube-proxy` — the component that manages network rules for Services. It runs on every node because it needs to program iptables/IPVS rules locally on each machine.
