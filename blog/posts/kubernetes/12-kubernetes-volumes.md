---
date: 2025-04-26
title: Volumes — Ephemeral vs Persistent Storage
---

Container filesystems are temporary. When a container restarts, its filesystem is reset to the image state. Volumes provide storage that outlasts container restarts — and in some cases, outlasts the Pod itself.

---

## Why Containers Need Volumes

A container's writable layer is destroyed when the container exits. Two scenarios make this a problem:

1. **Data that must survive a crash**: a container writing to disk (logs, uploads, database files) loses that data if the container restarts without a volume.
2. **Sharing data between containers**: two containers in the same Pod cannot directly share files — they need a volume as a common mount point.

---

## Volume Lifetime

A critical distinction in Kubernetes: **pod-scoped volumes** exist as long as the Pod exists. **Cluster-scoped volumes** (PersistentVolumes) exist independently of any Pod.

Most volume types in Kubernetes are pod-scoped. This means they survive container restarts within the same Pod, but are destroyed when the Pod is deleted.

---

## Common Volume Types

### emptyDir

Created when the Pod starts, deleted when the Pod is deleted. Both containers in a multi-container Pod can mount the same `emptyDir` to share files.

```yaml
spec:
  volumes:
  - name: shared-data
    emptyDir: {}
  containers:
  - name: writer
    volumeMounts:
    - name: shared-data
      mountPath: /data
  - name: reader
    volumeMounts:
    - name: shared-data
      mountPath: /input
```

**Use cases**:
- Scratch space for temporary computation
- Passing files between an init container and the main container
- Caching data that can be regenerated if lost

By default, `emptyDir` uses the node's disk. Setting `emptyDir.medium: Memory` makes it a RAM-backed tmpfs — faster, but counts against the Pod's memory limit.

### hostPath

Mounts a file or directory from the node's filesystem into the Pod.

```yaml
volumes:
- name: node-logs
  hostPath:
    path: /var/log
    type: Directory
```

!!! warning "hostPath is dangerous"
    A Pod with a `hostPath` mount has access to the node's filesystem. A misconfigured or compromised container can read `/etc/passwd`, write to system directories, or escape the container. Avoid `hostPath` in production except for DaemonSets that explicitly need host-level access (e.g., log collectors, node monitoring agents).

### configMap and secret

Mount a ConfigMap or Secret as files in the container's filesystem. Covered in depth in the [ConfigMaps and Secrets](11-kubernetes-configmap-secret.md) post.

### PersistentVolumeClaim (PVC)

Mount a persistent volume — network-attached storage that outlives the Pod. This is the standard for anything that needs to survive Pod deletion. Covered in depth in the [next post](13-kubernetes-pv-pvc.md).

---

## Init Containers and Volumes

A common pattern: an init container prepares data in an `emptyDir` volume, and the main container consumes it.

```yaml
initContainers:
- name: fetch-config
  image: curlimages/curl
  command: ["curl", "-o", "/init/config.json", "http://config-service/config"]
  volumeMounts:
  - name: init-data
    mountPath: /init

containers:
- name: app
  volumeMounts:
  - name: init-data
    mountPath: /config
    readOnly: true

volumes:
- name: init-data
  emptyDir: {}
```

The init container runs to completion before the main container starts, guaranteeing the config file is present.

---

## Volume Summary

| Type | Lifetime | Use case |
|---|---|---|
| `emptyDir` | Pod lifetime | Scratch space, inter-container sharing |
| `hostPath` | Node lifetime | DaemonSet agents (use carefully) |
| `configMap` | Until ConfigMap is deleted | Config files |
| `secret` | Until Secret is deleted | Certificates, passwords as files |
| `persistentVolumeClaim` | Independent of Pod | Databases, uploads, anything persistent |
| `emptyDir (Memory)` | Pod lifetime | High-speed temporary storage |

For anything that needs to survive Pod deletion — databases, user uploads, application state — use a PersistentVolumeClaim. Ephemeral volumes are for transient data only.
