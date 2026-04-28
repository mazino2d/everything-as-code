---
date: 2025-04-26
title: Lens — A Visual Interface for Your Cluster
---

`kubectl` is powerful but requires memorising commands and mentally parsing YAML. Lens (and similar tools) give you a real-time visual view of your cluster — useful for exploration, debugging, and understanding what's running without typing a command for every question.

---

## What Lens Does

Lens is a desktop application (Mac, Windows, Linux) that connects to your Kubernetes clusters via kubeconfig and presents a graphical interface. Key capabilities:

**Workload overview**: see all Deployments, Pods, StatefulSets, DaemonSets, and their current status at a glance. Running, pending, and failing Pods are colour-coded.

**Real-time logs**: stream logs from any Pod or container without `kubectl logs -f`. Filter by keyword, copy to clipboard, or open in a separate pane.

**Shell access**: open a terminal into any container with one click — equivalent to `kubectl exec -it <pod> -- sh`.

**Resource editing**: edit any resource's YAML directly in the interface and apply changes.

**Multi-cluster**: connect to multiple clusters and switch between them with a sidebar.

**Built-in metrics**: if Prometheus is installed in the cluster, Lens displays CPU and memory graphs for nodes and Pods without additional configuration.

---

## Getting Started

1. Download from [k8slens.dev](https://k8slens.dev)
2. Open Lens → Add Cluster → Paste kubeconfig or let Lens auto-detect from `~/.kube/config`
3. Connect — the cluster appears in the sidebar

Lens reads your existing kubeconfig. Any cluster you've configured with `kubectl` is immediately available.

---

## Common Workflows

**Debugging a failing Pod**: click Workloads → Pods, filter by namespace, click the failing Pod. The detail panel shows the container status, restart count, last exit code, and events — all at once, without multiple `kubectl describe` and `kubectl logs` commands.

**Checking resource consumption**: the Nodes view shows CPU and memory allocation across the cluster. The Pods view can be sorted by resource usage to find the heaviest consumers.

**Exploring an unfamiliar cluster**: browse namespaces, ConfigMaps, Secrets (values hidden by default), Services, and Ingress rules without writing any commands. Good for onboarding to a new environment.

---

## Lens vs kubectl

Lens does not replace kubectl — it complements it.

kubectl is faster for:
- Scripted or automated operations
- Bulk operations (delete many resources, label many pods)
- Complex queries with `-o jsonpath` or `-o custom-columns`
- Operations in CI/CD pipelines

Lens is faster for:
- Getting a high-level view of a running cluster
- Following logs from multiple pods
- Investigating an incident without knowing exact resource names upfront
- Browsing resources you don't use every day

---

## Alternatives

**k9s**: a terminal-based interface — keyboard-driven, fast, works over SSH, no installation beyond a single binary. Preferred by engineers who want the benefits of a visual interface without leaving the terminal.

```bash
brew install k9s
k9s  # connects to current kubectl context
```

**Headlamp**: open-source, browser-based. Similar to Lens but lighter weight and fully open source.

**Kubernetes Dashboard**: the official web UI. More limited than Lens but available in-cluster (no desktop app required). Security warning: do not expose it publicly without authentication.

---

## Lens Licensing Note

Lens changed its licensing model in 2023. The free version (Lens Personal) has usage restrictions for commercial use. For teams or commercial use, review the current licensing terms or use an alternative like k9s or Headlamp, which are fully open source.

!!! tip "Terminal users: try k9s first"
    If you're already comfortable in the terminal, k9s is often the better choice. It has nearly all of Lens's capabilities in a terminal UI, works over SSH, and installs as a single binary with no licensing concerns.
