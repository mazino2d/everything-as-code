---
date: 2025-04-26
title: Setting Up a Local Kubernetes Lab
---

You don't need a cloud account to learn Kubernetes. Three tools give you a real cluster on your laptop. This post covers the options, what to install, and the handful of kubectl commands you'll use constantly.

---

## Choosing a Local Distribution

### Minikube

The original local Kubernetes. Runs a single-node cluster inside a VM (or Docker container). Best for beginners because it handles everything — cluster creation, addons, tunneling — with simple commands.

```bash
minikube start
minikube stop
minikube dashboard  # opens a web UI
minikube tunnel     # exposes LoadBalancer services on localhost
```

**Good for**: first-time learners, testing addons, quick demos.
**Drawback**: VM overhead; not representative of multi-node clusters.

### Kind (Kubernetes in Docker)

Runs Kubernetes nodes as Docker containers. Fast to start, easy to create multi-node clusters, and popular in CI pipelines.

```bash
kind create cluster
kind create cluster --config kind-config.yaml  # multi-node
kind delete cluster
```

**Good for**: multi-node testing, CI/CD integration, fast iteration.
**Drawback**: requires Docker; network behaviour differs slightly from production.

### K3s

A production-grade, lightweight Kubernetes distribution. Runs as a single binary. Popular for edge, IoT, and homelab. Most representative of a real cluster.

```bash
curl -sfL https://get.k3s.io | sh -
kubectl get nodes  # works immediately; K3s installs its own kubeconfig
```

**Good for**: production-like behaviour, ARM devices (Raspberry Pi), learning the full stack.
**Drawback**: Linux only (runs in a VM on Mac/Windows).

---

## Installing kubectl

`kubectl` is the command-line client for the Kubernetes API. Install it independently from your cluster:

```bash
# macOS
brew install kubectl

# Linux
curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl && sudo mv kubectl /usr/local/bin/

# Verify
kubectl version --client
```

kubectl reads cluster connection details from `~/.kube/config` (the kubeconfig file). Most local distributions write this file automatically on cluster creation.

---

## Managing Multiple Clusters

The kubeconfig file can hold credentials for multiple clusters. Each entry is called a **context**.

```bash
kubectl config get-contexts          # list available contexts
kubectl config use-context minikube  # switch to minikube cluster
kubectl config current-context       # show active context
```

Tools like `kubectx` and `kubens` make switching faster:

```bash
kubectx minikube   # switch cluster
kubens kube-system # switch default namespace
```

---

## Essential kubectl Commands

These ten commands cover 80% of day-to-day work:

```bash
# Inspect resources
kubectl get pods                          # list pods in current namespace
kubectl get pods -n kube-system           # list pods in a specific namespace
kubectl get all                           # all resources in namespace
kubectl describe pod <name>               # detailed info + events
kubectl logs <pod-name>                   # stdout/stderr of a pod
kubectl logs <pod-name> -f                # follow logs in real time
kubectl logs <pod-name> -c <container>    # specific container in multi-container pod

# Act on resources
kubectl apply -f manifest.yaml            # create or update from file
kubectl delete -f manifest.yaml           # delete resources from file
kubectl exec -it <pod-name> -- sh         # shell into a running pod

# Inspect the cluster
kubectl get nodes                         # node status
kubectl top nodes                         # CPU/memory usage (requires metrics-server)
kubectl top pods                          # pod resource usage
```

---

## Verifying Your Lab

After starting your cluster, run these to confirm everything is healthy:

```bash
kubectl get nodes
# NAME       STATUS   ROLES           AGE   VERSION
# minikube   Ready    control-plane   2m    v1.30.0

kubectl get pods -n kube-system
# All pods should be Running or Completed

kubectl cluster-info
# Kubernetes control plane is running at https://127.0.0.1:...
```

Once nodes are `Ready` and system pods are `Running`, the lab is ready. The next posts build on this environment with actual workloads.

!!! tip "Recommended starting point"
    Start with Minikube if this is your first time. Move to K3s (on a cheap VM or Raspberry Pi) once you're comfortable — it forces you to deal with real networking and storage behaviour that Minikube abstracts away.
