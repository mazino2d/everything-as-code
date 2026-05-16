---
date: 2026-05-16
title: Rollout Strategies — How to Ship Without Breaking Things
---

Deploying a new version of an application is a controlled replacement of running processes. The question is not whether to replace them, but *how* — how quickly, how safely, and how reversibly.

Rollout strategy is the answer to that question.

---

## The Problem with Hard Cutover

The naive approach is to stop the old version and start the new one. This is simple to reason about but produces a window of unavailability between the two states. For most production systems, that window is unacceptable.

The strategies below all attempt to close that window — each with different trade-offs between safety, speed, resource cost, and operational complexity.

---

## RollingUpdate — The Default

Replace old pods gradually, a few at a time, while the service continues to handle traffic.

```
Before:  [v1] [v1] [v1] [v1]
Step 1:  [v1] [v1] [v1] [v2]   ← one replaced
Step 2:  [v1] [v1] [v2] [v2]
Step 3:  [v2] [v2] [v2] [v2]   ← done
```

Two parameters control the pace:

- **maxSurge** — how many extra pods may exist above the desired count during the rollout. A surge of 1 means the cluster temporarily runs `n+1` pods.
- **maxUnavailable** — how many pods may be absent below the desired count. Setting this to 0 guarantees full capacity is maintained throughout.

The combination `maxSurge: 1, maxUnavailable: 0` is the safest default: the new pod starts and passes health checks before the old one is removed.

!!! warning "Both versions run simultaneously"
    During a rolling update, old and new pods serve traffic at the same time. The application must be backwards compatible — database schema changes, API contracts, and message formats must remain valid across both versions.

---

## Recreate — Accept the Downtime

Stop all old pods, then start all new pods.

```
Before:  [v1] [v1] [v1] [v1]
Gap:     [ ] [ ] [ ] [ ]       ← unavailable
After:   [v2] [v2] [v2] [v2]
```

This is the right strategy when backwards compatibility is impossible — a breaking schema migration, a protocol change, or a stateful initialisation that cannot run alongside the old version.

The downtime is deliberate and bounded. It is operationally honest: the system acknowledges it cannot guarantee continuity and makes the transition window visible.

---

## Blue/Green — Instant Switch

Run two complete environments in parallel. The active one (blue) serves all traffic. The new one (green) is deployed and validated while idle. Traffic switches in a single atomic operation.

```
Blue (active):  [v1] [v1] [v1] [v1]  ← all traffic here
Green (idle):   [v2] [v2] [v2] [v2]  ← fully deployed, no traffic

  ↓  switch

Blue (idle):    [v1] [v1] [v1] [v1]  ← kept for rollback
Green (active): [v2] [v2] [v2] [v2]  ← all traffic here
```

The key property is **instant rollback**: if the new version behaves unexpectedly, traffic reverts to blue in one operation. No re-deployment is needed.

The cost is resource duplication. Running two full environments doubles the infrastructure footprint for the duration of the validation window. This is acceptable when the cost of a bad deployment is high enough to justify it.

!!! tip "Blue/green requires two complete healthy environments before switching"
    The switch is only safe if green is fully ready. The validation period — observing metrics, running smoke tests, checking error rates — happens *before* the switch, not during it.

---

## Canary — Gradual Traffic Shift

Route a small percentage of traffic to the new version first. Observe. Expand if healthy. Roll back if not.

```
Step 1:  90% → [v1]  10% → [v2]   ← small exposure
Step 2:  50% → [v1]  50% → [v2]   ← if metrics look good
Step 3:   0% → [v1] 100% → [v2]   ← fully promoted
```

Canary is the most operationally complex strategy but the most information-rich. It exposes the new version to real production load and real user behaviour before full rollout. Issues surface in a controlled blast radius.

The critical question canary answers that no pre-production environment can: *does this version behave correctly under real traffic?*

Traffic shifting can be implemented in two ways:

- **Replica-based**: the percentage of canary pods approximates the traffic split. Imprecise — a 25% canary with 4 replicas means 1 pod receives all "canary" traffic, but distribution is not guaranteed.
- **Traffic-weighted**: a service mesh (Istio) or gateway routes requests by weight independent of replica count. Precise — 10% of requests go to the canary regardless of how many pods are running.

---

## Choosing a Strategy

| Strategy | Downtime | Rollback speed | Resource cost | Complexity |
|---|---|---|---|---|
| RollingUpdate | None | Re-deploy | Minimal | Low |
| Recreate | Yes | Re-deploy | Minimal | None |
| Blue/Green | None | Instant | 2× during switch | Medium |
| Canary | None | Immediate | Modest | High |

The strategies are not ranked — each fits a different risk profile:

- **RollingUpdate** is the right default for most stateless services with backwards-compatible changes.
- **Recreate** is correct when version coexistence is impossible, and downtime is preferable to data corruption.
- **Blue/Green** is appropriate when validation must happen before any user sees the change, and rollback speed is critical.
- **Canary** is appropriate when the cost of a bad deployment is high but downtime is unacceptable, and the team has the observability to make meaningful decisions during the rollout.

!!! note "Canary without observability is just a slow rollout"
    The value of canary is the ability to *decide* based on signal — error rates, latency, business metrics. Without dashboards and alerts tuned to the new version, canary collapses into a delayed RollingUpdate with extra operational burden.
