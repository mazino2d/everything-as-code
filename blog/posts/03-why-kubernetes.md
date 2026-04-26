---
date: 2025-04-26
title: Why Kubernetes? Scale, Self-healing, Zero Downtime
---

Containers solve the packaging problem. Kubernetes solves what happens when you have many containers, many machines, and users who expect the service to never go down.

---

## The Problem at Scale

Imagine you have a web application packaged as a container. Running it on one machine is easy: `docker run`. But production requirements quickly outgrow a single `docker run`:

- **Traffic spikes**: you need 10 containers at peak, 2 at night
- **Hardware failures**: the machine running your container crashes
- **Deployments**: you want to ship new code without taking the service down
- **Multiple services**: 20 microservices that need to talk to each other
- **Secrets and config**: database passwords that should not be baked into images

Without an orchestrator, you solve each of these manually — with scripts, cron jobs, and runbooks. That works until it doesn't.

---

## What Kubernetes Provides

Kubernetes is a container orchestration platform. You declare what you want; Kubernetes figures out how to achieve and maintain it.

### Automated Scheduling

You don't tell Kubernetes which machine to run your container on. You declare how much CPU and memory the container needs, and Kubernetes finds a machine with available capacity and schedules the container there.

```text
You say:  "I need 3 replicas of this container, each needing 256MB RAM"
K8s does: finds nodes with capacity, schedules pods, tracks placement
```

### Self-healing

If a container crashes, Kubernetes restarts it. If a node goes down, Kubernetes reschedules its containers onto healthy nodes. If a container fails its health check, Kubernetes stops routing traffic to it until it recovers.

!!! note "Self-healing vs magic"
    Self-healing handles process crashes and node failures. It does not fix application bugs. If your app crashes because of a bug, Kubernetes will restart it — creating a crash loop, not a fix.

### Horizontal Scaling

Scale up or down by changing a number:

```bash
kubectl scale deployment myapp --replicas=10
```

Or automatically with a Horizontal Pod Autoscaler that scales based on CPU utilisation, request rate, or custom metrics.

### Zero-downtime Deployments

When you push a new container image, Kubernetes performs a **rolling update**: it brings up new pods and takes down old ones gradually. At no point are all pods replaced simultaneously, so traffic continues to be served throughout.

If the new version fails its health check, Kubernetes stops the rollout automatically. You can roll back with a single command.

### Service Discovery and Load Balancing

Every set of pods gets a stable DNS name and virtual IP address. Other services in the cluster use that name to connect; they don't need to know which pods are actually running or on which machines.

### Configuration and Secret Management

Kubernetes stores configuration separately from container images. You can update a password or a config flag without rebuilding and redeploying the container.

---

## The Kubernetes Architecture

```text
┌─────────────────────────────────────────────────────┐
│                  Control Plane                       │
│  API Server  │  etcd  │  Scheduler  │  Controller   │
└─────────────────────────────────────────────────────┘
          │               │               │
┌─────────┴───┐   ┌───────┴───┐   ┌─────────────┐
│   Node 1    │   │   Node 2  │   │   Node 3    │
│  [Pod][Pod] │   │  [Pod]    │   │  [Pod][Pod] │
│  kubelet    │   │  kubelet  │   │  kubelet    │
└─────────────┘   └───────────┘   └─────────────┘
```

- **Control Plane**: the brain. Stores desired state (etcd), schedules pods (Scheduler), and reconciles actual state toward desired state (Controllers).
- **Nodes**: the workers. Run containers (via kubelet and a container runtime like containerd).
- **API Server**: the single entry point for all operations. `kubectl` talks to the API Server.

You interact with the control plane, not the nodes directly.

---

## When You Don't Need Kubernetes

Kubernetes has real operational overhead. It is not the right choice for every situation.

You probably don't need Kubernetes if:
- You have a single app with low, predictable traffic
- Your team is small and has no one to operate the cluster
- A managed platform (Heroku, Railway, Render) meets your needs at lower cost

Kubernetes earns its complexity when:
- You have multiple services with different scaling needs
- High availability is a hard requirement
- You need fine-grained control over resource allocation and deployment strategy
