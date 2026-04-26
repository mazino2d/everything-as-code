---
date: 2025-04-26
title: Persistent Volumes and Claims — Requesting Storage from the Cluster
---

PersistentVolumes abstract the underlying storage technology from the workloads that consume it. A Pod asks for storage with a claim; the cluster fulfils it from whatever storage is available.

---

## The Abstraction Layers

Three objects work together:

```text
StorageClass  →  describes HOW to provision storage
PersistentVolume (PV)  →  a piece of provisioned storage
PersistentVolumeClaim (PVC)  →  a request for storage by a workload
```

The workload only knows about the PVC. It doesn't know whether the underlying storage is an AWS EBS volume, a GCP Persistent Disk, an NFS share, or a local SSD.

---

## Static vs Dynamic Provisioning

### Static Provisioning

An administrator manually creates PVs. A PVC then binds to a matching PV.

```yaml
# Admin creates a PV
apiVersion: v1
kind: PersistentVolume
metadata:
  name: my-pv
spec:
  capacity:
    storage: 10Gi
  accessModes: [ReadWriteOnce]
  hostPath:
    path: /data/my-pv
```

```yaml
# Developer creates a PVC
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes: [ReadWriteOnce]
  resources:
    requests:
      storage: 5Gi
```

Kubernetes binds the PVC to a PV that satisfies the request. If no PV matches, the PVC stays in `Pending`.

### Dynamic Provisioning

A StorageClass tells Kubernetes how to provision PVs on demand. When a PVC references a StorageClass, Kubernetes automatically creates a PV.

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: kubernetes.io/gce-pd     # GCP Persistent Disk
parameters:
  type: pd-ssd
  replication-type: regional-pd
```

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: db-storage
spec:
  storageClassName: fast-ssd
  accessModes: [ReadWriteOnce]
  resources:
    requests:
      storage: 20Gi
```

When this PVC is created, Kubernetes provisions a 20Gi GCP SSD automatically. Dynamic provisioning is the standard in cloud environments.

---

## Access Modes

Access modes describe how a volume can be mounted:

| Mode | Short | Meaning |
|---|---|---|
| `ReadWriteOnce` | RWO | Mounted read-write by one node |
| `ReadOnlyMany` | ROX | Mounted read-only by many nodes |
| `ReadWriteMany` | RWX | Mounted read-write by many nodes |
| `ReadWriteOncePod` | RWOP | Mounted read-write by a single Pod (added in 1.22) |

Most block storage (AWS EBS, GCP PD, Azure Disk) only supports `ReadWriteOnce`. For `ReadWriteMany`, you need a network filesystem like NFS, CephFS, or AWS EFS.

StatefulSets typically use `ReadWriteOnce` — each Pod gets its own PVC.

---

## Reclaim Policy

What happens to a PV when the PVC that bound it is deleted?

| Policy | Behaviour |
|---|---|
| `Retain` | PV stays; must be manually reclaimed. Data is preserved. |
| `Delete` | PV and underlying storage are deleted automatically. |
| `Recycle` | (Deprecated) Wipes the data and makes the PV available again. |

Use `Retain` for anything you can't afford to lose accidentally. Use `Delete` for ephemeral or dev environments where cleanup is desirable.

---

## Using a PVC in a Pod

```yaml
spec:
  containers:
  - name: db
    image: postgres:16
    volumeMounts:
    - name: data
      mountPath: /var/lib/postgresql/data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: db-storage
```

The Pod's volume points to the PVC by name. If the Pod is deleted and recreated, it reattaches to the same PVC — and the data is intact.

---

## PVC Lifecycle

```text
PVC created → Pending (no matching PV or StorageClass provisioning in progress)
            → Bound   (PV assigned, volume attached to node)
            → Released (PVC deleted, PV not yet reclaimed)
            → Available (PV reclaimed, ready for new PVC)
```

A `Bound` PVC cannot be deleted while a Pod is using it. Kubernetes will mark it for deletion but wait until the Pod releases it.

---

## Expanding PVCs

Most StorageClasses support volume expansion. Increase the PVC's `storage` request; the StorageClass controller resizes the underlying volume.

```bash
kubectl patch pvc db-storage -p '{"spec":{"resources":{"requests":{"storage":"50Gi"}}}}'
```

Some drivers require the Pod to restart for the filesystem to recognise the new size. Check your StorageClass documentation.

!!! note "VolumeBindingMode: WaitForFirstConsumer"
    Setting `volumeBindingMode: WaitForFirstConsumer` on a StorageClass delays PV provisioning until a Pod actually tries to use the PVC. This ensures the volume is provisioned in the same availability zone as the Pod — important for cloud environments where a disk in zone A cannot be attached to a node in zone B.
