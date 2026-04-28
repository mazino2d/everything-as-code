---
date: 2025-04-26
title: Deployments — Managing Stateless Applications
---

A Deployment is the standard way to run stateless applications in Kubernetes. It manages a set of identical, interchangeable Pods and handles rolling updates and rollbacks automatically.

---

## What a Deployment Does

A Deployment declares: "I want N replicas of this container image running at all times." Kubernetes creates a ReplicaSet, which in turn creates and maintains the Pods.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: web
        image: nginx:1.25
        ports:
        - containerPort: 80
```

This declares: "run 3 Pods with the `app: web` label, each running `nginx:1.25`."

The `selector.matchLabels` connects the Deployment to its Pods. The Deployment manages any Pod with matching labels — it doesn't care how the Pod was created.

---

## The Deployment → ReplicaSet → Pod Hierarchy

```text
Deployment (desired state: 3 replicas of v1.25)
  └── ReplicaSet (ensures 3 pods exist)
        ├── Pod 1
        ├── Pod 2
        └── Pod 3
```

You interact with the Deployment. The ReplicaSet is an implementation detail you rarely touch directly. The split exists to support rolling updates: during an update, you'll have two ReplicaSets — old and new — simultaneously.

---

## Rolling Updates

When you update the container image, Kubernetes performs a rolling update by default:

1. Creates a new ReplicaSet for the new image version
2. Scales up the new ReplicaSet one Pod at a time
3. Scales down the old ReplicaSet one Pod at a time
4. Completes when all Pods are on the new version

```bash
kubectl set image deployment/web web=nginx:1.26
# or: edit the YAML and kubectl apply

kubectl rollout status deployment/web
# Waiting for deployment "web" rollout to finish: 1 of 3 updated...
# deployment "web" successfully rolled out
```

Two parameters control how aggressive the rollout is:

- `maxSurge`: how many extra Pods can be created above the desired count during the update (default: 25%)
- `maxUnavailable`: how many Pods can be unavailable during the update (default: 25%)

Setting `maxUnavailable: 0` means capacity never drops below the desired count — useful for services that can't tolerate reduced capacity.

---

## Rollback

If a new version has problems, roll back to the previous version:

```bash
kubectl rollout undo deployment/web
# or to a specific revision:
kubectl rollout undo deployment/web --to-revision=2

kubectl rollout history deployment/web
# REVISION  CHANGE-CAUSE
# 1         <none>
# 2         nginx:1.26
```

Rollback works because Kubernetes keeps a history of ReplicaSets. The previous ReplicaSet is still present (with 0 replicas); rolling back scales it back up.

---

## Stateless vs Stateful

Deployments work well for **stateless** applications: web servers, APIs, background workers — anything where:

- Every Pod is identical (no unique identity)
- Pods can be killed and replaced in any order
- No persistent local state

If your application needs stable network identity, ordered startup, or per-Pod persistent storage, use a StatefulSet instead.

---

## Useful Commands

```bash
kubectl get deployments
kubectl describe deployment web
kubectl scale deployment web --replicas=5
kubectl rollout status deployment/web
kubectl rollout history deployment/web
kubectl rollout undo deployment/web
kubectl rollout pause deployment/web     # pause mid-rollout
kubectl rollout resume deployment/web   # resume
```

`kubectl scale` is useful for quick manual adjustments. For production, use a Horizontal Pod Autoscaler so scaling happens automatically based on metrics.
