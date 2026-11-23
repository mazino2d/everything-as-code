---
name: k8s-debug
description: Find the root cause of a broken workload on the mazino2d-as-se1-dev GKE Autopilot cluster — Pods crashing, Pending, not ready, an Argo CD app OutOfSync, Degraded or stuck syncing, an operator (Infisical, Atlas, cert-manager, Velero) not reconciling — by reading cluster state top-down (power state, Argo CD, Pods, events, logs) and ending with a fix proposed as a change to this repo. Read-only on the cluster unless the user approves a specific command. Use when the user says "app lỗi", "pod crash", "check log", "debug k8s", "CrashLoopBackOff", "Pending", "OOMKilled", "argocd stuck", "sync failed", "OutOfSync", "cluster không lên", names a broken app or namespace, or invokes /k8s-debug. Not for designing or adding workloads (infra) or a security review (security-review).
argument-hint: "[app or namespace] [symptom]"
---

# Debug a workload on mazino2d-as-se1-dev

The cluster is GKE Autopilot in `asia-southeast1`, all Pods on Spot capacity,
reconciled by Argo CD from `main`. Four things about it explain most "broken"
reports before any application bug does:

1. **It sleeps.** `k8s-power.yml` scales every non-system workload to zero at
   00:00 ICT and evicts DaemonSets; waking is manual. Zero replicas everywhere
   is not a bug.
2. **Spot.** Pods get preempted and rescheduled; a fresh restart or a short
   Pending is often just that.
3. **Autopilot.** There are no node pools to scale. Pending means the Pod's
   requests, a ComputeClass, or a policy GKE Warden rejects — read the events.
4. **GitOps.** Argo CD self-heals and prunes. A manual `kubectl apply` or `edit`
   is reverted; the fix is a commit.

## Hard rules

- Read-only by default: `get`, `describe`, `logs`, `top`, `events`. Never read
  a Secret's data (`get secret -o yaml`, `describe secret` is fine).
- Anything that changes the cluster — restart, delete a Pod, patch an Argo CD
  Application, suspend sync, `kubectl apply`, wake the cluster — needs the
  user's explicit yes for that exact command. Prefer the fix as a PR (`infra`
  for the change, `pr-open` for the PR).
- If you are the in-cluster `claude-agent`, you have read-only RBAC: propose,
  don't attempt.

## Step 0 — Connect

```bash
export CLOUDSDK_CORE_ACCOUNT=mazino2d@gmail.com
gcloud container clusters get-credentials mazino2d-as-se1-dev \
  --region asia-southeast1 --project mazino2d-as-se1-dev
kubectl config current-context
```

If the user gave the app, namespace and symptom, go on. Otherwise ask for them
in one message. Layers and their Argo CD app / main namespace:
`platform`, `infra`, `monitoring`, `apps` (namespace `apps`: dagster, outline,
hotrod, httpbin, postgresql, redis). Find an app's path with
`ls kubernetes/clusters/mazino2d-as-se1-dev/*/`.

## Step 1 — Is the cluster awake?

```bash
kubectl get deploy,sts,rollouts -A -o json | jq -r '.items[]
  | select(.metadata.annotations["eac.mazino2d.dev/replicas-before-sleep"] != null)
  | "\(.metadata.namespace)/\(.metadata.name)"' | head
gh run list -R mazino2d/everything-as-code -w k8s-power.yml -L 3   # GH_TOKEN for mazino2d
```

Workloads carrying the annotation at zero replicas mean the cluster is asleep.
Waking is `gh workflow run k8s-power.yml -f action=wake` — ask first, then stop
here unless the problem persists after waking (Argo CD wakes last; give it a few
minutes).

## Step 2 — Argo CD

```bash
kubectl -n argocd get applications
kubectl -n argocd get application <layer> -o json | jq '{sync: .status.sync.status,
  health: .status.health.status, phase: .status.operationState.phase,
  message: .status.operationState.message,
  unhealthy: [.status.resources[] | select(.health.status != null and .health.status != "Healthy")
              | {kind, namespace, name, health: .health.status, msg: .health.message}]}'
```

| Signal | Meaning |
|---|---|
| `OutOfSync` that persists | render error or a resource Argo CD can't apply — read `status.conditions` and `operationState.message`; reproduce with `kustomize build --enable-helm kubernetes/clusters/mazino2d-as-se1-dev/<layer>` |
| `phase: Running` for > 5 min | stuck hook: a `helm.sh/hook` on a non-Job resource, or a CR whose CRD/operator isn't up yet |
| `Degraded` / `Missing` resource | go to Step 3 with that resource |
| Healthy and Synced but app broken | the problem is in the app or its config, not GitOps — Step 3 |

Controller logs: `kubectl -n argocd logs sts/argocd-application-controller --tail=100`.
Argo CD itself, its Applications and repo credentials come from Terraform
(`terraform/k8s/mazino2d-as-se1-dev/argocd.tf`), not from `kubernetes/`.

## Step 3 — Pods, events, logs

```bash
kubectl -n <ns> get pods -o wide | grep -i <app>
kubectl -n <ns> describe pod <pod>              # Events, State, Last State, probes, requests
kubectl -n <ns> get events --sort-by=.lastTimestamp | tail -30
kubectl -n <ns> logs <pod> [-c <container>] --tail=100
kubectl -n <ns> logs <pod> [-c <container>] --previous --tail=100
```

| Symptom | Likely cause here | Where to fix |
|---|---|---|
| `CrashLoopBackOff`, exit 1 | missing env or secret, bad config, DB not reachable | app values in the layer; Infisical secret path |
| exit 137 / `OOMKilled` | memory limit too low | `resources` in the app's values |
| `Pending`, `FailedScheduling` / Warden denial | requests outside Autopilot ranges, a nodeSelector Autopilot rejects, or Spot capacity short in the zone | values; `terraform/k8s/mazino2d-as-se1-dev/compute_class.tf` |
| DaemonSet Pods missing, nodeSelector `topology.kubernetes.io/zone: sleeping` | left asleep by `power.sh` | wake the cluster |
| Recent restart, node gone | Spot preemption | nothing, unless it loops |
| `ImagePullBackOff` | wrong tag, or a private `ghcr.io/mazino2d/*` image | image tag; `docker.yml` run on main |
| `CreateContainerConfigError` | referenced Secret/ConfigMap missing — often an `InfisicalSecret` not synced | Step 4 |
| Not ready, no errors | probe path/port or slow start | probes in values |
| Egress timeouts | network policy (`nacl` in `eac-app`) doesn't allow the destination | the app's `nacl` list |

## Step 4 — Dependencies (only if Step 3 points there)

```bash
kubectl -n <ns> get infisicalsecret,secret,configmap,pvc
kubectl -n <ns> describe infisicalsecret <name>        # sync status and error
kubectl -n infisical-operator get deploy            # then: logs deploy/<name> --tail=50
kubectl -n <ns> get atlasschema,atlasmigration          # DB schema (atlas-operator)
kubectl get networkpolicy,fqdnnetworkpolicy -n <ns>
```

Names of operator namespaces and deployments can differ: `kubectl get deploy -A | grep -i <operator>`.

## Step 5 — Diagnosis

```
## Diagnosis
**Root cause:** <one sentence>
**Evidence:** <status / event / log line, each with the command that showed it>
**Fix:** <the file in this repo and the change, or the one approved command>
**Not checked:** <what you couldn't see>
```

Point at the exact file under `kubernetes/clusters/mazino2d-as-se1-dev/…`,
`kubernetes/charts/…` or `terraform/k8s/…`. Charts pulled by Kustomize
`helmCharts` are git-ignored and downloaded at render time; read the version
and values in `kustomization.yaml`, not a local chart copy.

## Emergency: test a fix live (only on request)

If the user asks to try a change before committing: suspend that Application's
auto-sync, apply the rendered layer, verify, then restore sync and commit the
same change. Each command needs a yes, and the final state must match `main`.
