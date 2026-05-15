---
name: kubectl-debug
description: Debug Kubernetes workloads using kubectl, Helm, and ArgoCD. Use this skill when the user describes a problem with a Kubernetes application — such as a pod crashing, not starting, or behaving unexpectedly — and wants to investigate the root cause. Trigger phrases include "app error", "debug k8s", "check app", "check log", "CrashLoopBackOff", "app pending", "app error", "kubectl debug", "argocd stuck", "sync failed", "helm release", or any mention of a broken workload in a namespace.
---

> **Scope:** This skill is for the `mazino2d-as-se1-dev` **dev cluster only**. Do not apply destructive or bypass steps (force-sync, ArgoCD suspend, direct kubectl apply) to production clusters.

# kubectl Debug

Help the user identify the root cause of a broken Kubernetes workload by gathering information progressively — from broad cluster state down to specific container logs.

## Phase 1 — Gather context from the user

If the user has not already provided it, ask for:

1. **Namespace** — which namespace is the workload in? (e.g. `default`, `apps`, `infra`, `monitoring`)
2. **Workload name** — the app, Deployment, StatefulSet, or Pod name that is misbehaving
3. **Symptom** — what does "broken" mean? (crash loop, pending, OOMKilled, 5xx errors, slow response, etc.)

Ask all three in a single message. If the user's opening message already answers them, skip straight to Phase 2.

---

## Phase 2 — Inspect pod state

Run the following commands and reason through the output before moving on.

```bash
# Get pod list and current status
kubectl get pods -n <namespace> -l app=<app-label> -o wide

# If no label is known, list all pods and grep
kubectl get pods -n <namespace> | grep <app-name>
```

Look for:
- **STATUS**: `CrashLoopBackOff`, `OOMKilled`, `Error`, `Pending`, `ImagePullBackOff`, `Terminating`
- **RESTARTS**: high restart count signals repeated crashes
- **AGE / READY**: pods stuck not-ready despite being old usually point to readiness probe failures

---

## Phase 3 — Describe the failing pod

Pick the most relevant pod (preferably one that is not Running/Ready) and describe it:

```bash
kubectl describe pod <pod-name> -n <namespace>
```

Key sections to analyse:
| Section | What to look for |
|---|---|
| **Events** | `FailedScheduling`, `BackOff`, `Pulling`, `Failed`, `OOMKilling` |
| **Conditions** | `Ready: False`, `PodScheduled: False` |
| **Containers → State** | `Waiting (reason: CrashLoopBackOff)`, `Terminated (exit code: 1/137/OOMKilled)` |
| **Limits / Requests** | missing or too-tight resource limits causing OOM |
| **Liveness/Readiness probes** | misconfigured paths or timeouts causing repeated probe failures |

---

## Phase 4 — Read container logs

```bash
# Current logs
kubectl logs <pod-name> -n <namespace> --tail=100

# Previous container (if it already restarted)
kubectl logs <pod-name> -n <namespace> --previous --tail=100

# If the pod has multiple containers
kubectl logs <pod-name> -n <namespace> -c <container-name> --tail=100
```

When reading logs:
- Look for stack traces, panics, connection errors, or `FATAL` / `ERROR` lines near the end
- Note the **last timestamp** to understand when the crash occurred
- If logs are empty (container never started), the problem is in the image pull, init containers, or resource scheduling — go back to `describe` events

---

## Phase 5 — Check related resources (if needed)

Run these only when Phase 2–4 have not pinpointed the cause:

```bash
# Check if a ConfigMap or Secret it depends on exists
kubectl get configmap,secret -n <namespace> | grep <app-name>

# Check PersistentVolumeClaim status (if the app uses storage)
kubectl get pvc -n <namespace>

# Check HorizontalPodAutoscaler (if scaling issues are suspected)
kubectl get hpa -n <namespace>

# Check recent events across the whole namespace
kubectl get events -n <namespace> --sort-by='.lastTimestamp' | tail -30

# Check if the node has pressure (disk/memory)
kubectl describe node <node-name> | grep -A5 "Conditions:"
```

---

## Phase 5b — ArgoCD (if the workload is managed by ArgoCD)

Use when the pod issue may stem from a failed or stuck ArgoCD sync rather than the app itself.

```bash
# List all ArgoCD applications and their sync/health status
kubectl get applications -n argocd

# Describe a specific app — check Conditions, Operation State, and Resource list
kubectl describe application <app-name> -n argocd

# Get full operation state as JSON for detailed hook/resource status
kubectl get application <app-name> -n argocd -o jsonpath='{.status.operationState}' | python3 -m json.tool

# Check recent ArgoCD events
kubectl get events -n argocd --sort-by='.lastTimestamp' | tail -20

# Check ArgoCD app-controller logs (useful for sync errors)
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller --tail=50
```

Key things to look for in ArgoCD:
| Field | What to look for |
|---|---|
| `status.sync.status` | `OutOfSync` means desired state differs from cluster |
| `status.health.status` | `Degraded` or `Missing` means resources are broken/absent |
| `status.operationState.phase` | `Running` for >5 min usually means a stuck hook or job |
| `status.operationState.message` | Describes what ArgoCD is waiting on |
| `status.operationState.syncResult.resources` | Lists each resource and its hook phase — look for `hookPhase: Running` on non-Job resources |

**Common ArgoCD stuck patterns:**
- `waiting for completion of hook ... ClusterRole/...` — a Helm hook annotation (`helm.sh/hook`) on a non-Job resource (ClusterRole, ConfigMap, etc.) that ArgoCD waits on indefinitely. Fix: disable the helm hook in chart values (e.g. `upgradeCRDs: false`) or set `argocd.argoproj.io/hook-delete-policy` correctly.
- Sync stuck after restarting a new cluster — check whether dependent operators (Infisical, cert-manager, etc.) are deployed and their CRDs exist before ArgoCD tries to apply CRs that use them.

To terminate a stuck ArgoCD operation (when it will never self-resolve):
```bash
# Clear the in-flight operation — app-controller will re-evaluate
kubectl patch application <app-name> -n argocd --type merge -p '{"operation": null}'

# If patch alone does not clear it, restart the app-controller
kubectl rollout restart deployment argocd-application-controller -n argocd  # or statefulset
kubectl rollout restart statefulset argocd-application-controller -n argocd
```

---

## Phase 5d — Test a fix manually before pushing to git (dev cluster only)

Use this flow when you want to verify a manifest/values change works on the cluster **without committing to git first**, then hand back control to ArgoCD after confirming.

**Step 1 — Suspend ArgoCD auto-sync for the affected app**
```bash
kubectl patch application <app-name> -n argocd \
  --type merge -p '{"spec": {"syncPolicy": null}}'
```
ArgoCD will stop watching and reverting changes for this app. The app stays in the cluster untouched.

**Step 2 — Terminate any in-flight operation**
```bash
kubectl patch application <app-name> -n argocd \
  --type merge -p '{"operation": null}'
```

**Step 3 — Apply the fix directly**

Option A — Kustomize app (most common in this repo):
```bash
kustomize build --enable-helm kubernetes/clusters/mazino2d-as-se1-dev/<layer>/<app> \
  | kubectl apply -f -
```

Option B — Plain manifest:
```bash
kubectl apply -f <path-to-manifest>
```

Option C — Confirm only (dry-run, no apply):
```bash
kustomize build --enable-helm kubernetes/clusters/mazino2d-as-se1-dev/<layer>/<app> \
  | grep -A5 "helm.sh/hook"   # check no unwanted hooks remain
```

**Step 4 — Verify the fix**
```bash
kubectl get pods -n <namespace>
kubectl get events -n <namespace> --sort-by='.lastTimestamp' | tail -20
```

**Step 5 — Re-enable ArgoCD auto-sync after confirming**
```bash
kubectl patch application <app-name> -n argocd \
  --type merge \
  -p '{"spec": {"syncPolicy": {"automated": {"prune": true, "selfHeal": true}}}}'
```

Then commit and push the fix to git so ArgoCD's desired state matches what is on the cluster.

---

## Phase 5c — Helm (if the workload is deployed as a Helm release)

```bash
# List all Helm releases across namespaces
helm list -A

# Check release status — "failed" or "pending-upgrade" signals a broken deploy
helm status <release-name> -n <namespace>

# Show computed values actually used by the release
helm get values <release-name> -n <namespace>

# Show all rendered manifests for the release
helm get manifest <release-name> -n <namespace>

# Check release history — useful to see if a recent upgrade broke things
helm history <release-name> -n <namespace>

# Roll back to the previous working revision
helm rollback <release-name> -n <namespace>
```

> **Note — gitignored charts:** In this repo, `kubernetes/clusters/*/*/*/charts` and `kubernetes/clusters/*/*/charts` are gitignored. Helm charts are **not committed** — they are downloaded at build/sync time by Kustomize (`helmCharts` in `kustomization.yaml`) or by ArgoCD. Do not assume chart files exist locally in the repo; reference the `kustomization.yaml` for chart source and version.

---

## Phase 6 — Summarise findings

After gathering evidence, present a concise diagnosis:

```
## Diagnosis

**Root cause:** <one sentence>

**Evidence:**
- Pod status: <status>
- Key event: <most relevant event from describe>
- Log signal: <key error line from logs>

**Suggested fix:**
1. <concrete step>
2. <concrete step>
```

Keep the suggested fix actionable — include the exact kubectl command or config change where possible. If the fix requires editing a Helm values file, Kubernetes manifest, or Terraform resource in this repo, point to the specific file path.

---

## Common patterns and their fixes

| Symptom | Likely cause | Fix |
|---|---|---|
| `CrashLoopBackOff` + exit code 1 | App startup error | Check logs for missing env var or bad config |
| `CrashLoopBackOff` + exit code 137 | OOMKilled | Raise `resources.limits.memory` in the Helm values |
| `Pending` — FailedScheduling | No node with sufficient CPU/memory | Check node capacity; scale node pool or lower requests |
| `ImagePullBackOff` | Bad image tag or missing registry credentials | Verify image tag and imagePullSecret |
| Readiness probe failing | Wrong path/port in probe or app not ready | Fix probe config or increase `initialDelaySeconds` |
| `Init:CrashLoopBackOff` | Init container failing | Check init container logs separately |
