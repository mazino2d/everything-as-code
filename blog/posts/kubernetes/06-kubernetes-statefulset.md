---
date: 2025-04-26
title: StatefulSets — Managing Stateful Applications
---

Deployments treat Pods as identical and interchangeable. StatefulSets are for workloads where each Pod needs a stable identity, ordered lifecycle, and its own persistent storage.

---

## The Problem with Stateful Apps in Kubernetes

A MySQL replica set is not like a web server. Pod 0 is the primary; Pod 1 and Pod 2 are replicas that replicate from Pod 0. They are not interchangeable. If Pod 0 is killed and replaced, the new Pod must rejoin the cluster as the primary with the same name — not as a fresh instance.

Deployments can't provide this. They create Pods with random names, in arbitrary order, all sharing the same identity.

---

## What StatefulSet Provides

**Stable, unique Pod names**: pods are named `<statefulset>-0`, `<statefulset>-1`, etc. The names are deterministic and persistent across rescheduling.

**Stable network identity**: each Pod gets a DNS entry based on its name. `mysql-0.mysql.default.svc.cluster.local` always resolves to the same Pod, regardless of which node it's on.

**Ordered deployment and scaling**: Pods are created in order (0, 1, 2) and terminated in reverse order (2, 1, 0). Pod N is not started until Pod N-1 is Running and Ready.

**Per-Pod persistent storage**: each Pod gets its own PersistentVolumeClaim. The PVC survives Pod deletion — if Pod 1 is deleted and recreated, it gets the same PVC with its data intact.

---

## A Minimal StatefulSet

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
spec:
  serviceName: mysql          # required: must reference a headless service
  replicas: 3
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        volumeMounts:
        - name: data
          mountPath: /var/lib/mysql
  volumeClaimTemplates:       # one PVC per Pod
  - metadata:
      name: data
    spec:
      accessModes: [ReadWriteOnce]
      resources:
        requests:
          storage: 10Gi
```

The `volumeClaimTemplates` field is the key difference from a Deployment. Each Pod gets its own PVC (`data-mysql-0`, `data-mysql-1`, `data-mysql-2`).

---

## Headless Service

StatefulSets require a **headless service** (ClusterIP: None) to provide stable DNS for each Pod.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mysql
spec:
  clusterIP: None    # headless: no virtual IP
  selector:
    app: mysql
  ports:
  - port: 3306
```

With a headless service, DNS resolves directly to Pod IPs instead of a virtual IP. Each Pod is reachable individually:

```text
mysql-0.mysql.default.svc.cluster.local  →  Pod 0 IP
mysql-1.mysql.default.svc.cluster.local  →  Pod 1 IP
mysql-2.mysql.default.svc.cluster.local  →  Pod 2 IP
```

This is how the primary node in a replica set is addressable: `mysql-0.mysql`.

---

## Update Strategy

StatefulSets support two update strategies:

- **RollingUpdate** (default): updates Pods in reverse order, one at a time, waiting for each to be Ready before proceeding. The primary (Pod 0) is updated last.
- **OnDelete**: Pods are only updated when manually deleted. Useful when you need fine-grained control over the update sequence.

---

## Common Use Cases

| Application | Why StatefulSet |
|---|---|
| MySQL, PostgreSQL | Stable identity for replication roles |
| MongoDB, Cassandra | Cluster membership by stable hostname |
| Redis Sentinel | Primary/replica roles with stable addresses |
| Kafka, ZooKeeper | Broker IDs tied to Pod names |
| Elasticsearch | Node roles, shard allocation by hostname |

---

## StatefulSet vs Deployment Summary

| | Deployment | StatefulSet |
|---|---|---|
| Pod names | Random | Predictable (`pod-0`, `pod-1`) |
| Pod DNS | Shared service | Per-pod stable hostname |
| Storage | Shared or none | One PVC per Pod |
| Startup order | Parallel | Sequential |
| Use case | Stateless (API, web) | Stateful (DB, queue) |

!!! tip "Operators for complex stateful apps"
    For production databases, consider using a Kubernetes Operator (e.g., Percona Operator for MySQL, Strimzi for Kafka) instead of writing your own StatefulSet. Operators encode the operational knowledge of the application — including failover, backups, and scaling — as code.
