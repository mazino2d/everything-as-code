---
date: 2025-04-26
title: Jobs and CronJobs — One-time and Scheduled Tasks
---

Deployments and StatefulSets manage long-running services. Jobs are for work that runs to completion — database migrations, batch processing, report generation, one-off data transformations.

---

## Jobs

A Job creates one or more Pods, runs them until they complete successfully, and then stops. Unlike a Deployment, it does not restart completed Pods to maintain a replica count.

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: db-migrate
spec:
  template:
    spec:
      restartPolicy: Never    # required for Jobs (or OnFailure)
      containers:
      - name: migrate
        image: myapp:1.5
        command: ["python", "manage.py", "migrate"]
```

`restartPolicy: Never` means if the container fails, Kubernetes creates a new Pod (up to `backoffLimit` times). `restartPolicy: OnFailure` restarts the container within the same Pod instead.

### Parallel Jobs

Run multiple Pods simultaneously for work that can be parallelised:

```yaml
spec:
  completions: 10     # total successful completions needed
  parallelism: 3      # run 3 Pods at a time
```

### Handling Failures

```yaml
spec:
  backoffLimit: 4    # retry up to 4 times before marking the Job as failed
```

Each retry creates a new Pod. All failed Pods remain (in `Error` state) until the Job is deleted — useful for debugging, but requires cleanup.

### Automatic Cleanup

```yaml
spec:
  ttlSecondsAfterFinished: 3600    # delete the Job 1 hour after completion
```

Without TTL, completed Jobs and their Pods accumulate indefinitely. Always set TTL for automated pipelines.

---

## CronJobs

A CronJob creates a Job on a recurring schedule, using standard cron syntax.

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: nightly-report
spec:
  schedule: "0 2 * * *"    # every day at 2:00 AM UTC
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: OnFailure
          containers:
          - name: report
            image: reports:latest
            command: ["python", "generate_report.py"]
```

Cron syntax: `minute hour day-of-month month day-of-week`. Use [crontab.guru](https://crontab.guru) to validate expressions.

### Concurrency Policy

What should happen if the previous run hasn't finished when the next one is scheduled?

| Policy | Behaviour |
|---|---|
| `Allow` (default) | New Job starts regardless; multiple can run simultaneously |
| `Forbid` | Skip the new run if the previous is still running |
| `Replace` | Cancel the running Job and start a new one |

For most report jobs and data pipelines, `Forbid` is the right choice: if the previous run is still processing, starting a new one on top of it usually causes problems.

### History Retention

```yaml
spec:
  successfulJobsHistoryLimit: 3    # keep last 3 successful Jobs
  failedJobsHistoryLimit: 1        # keep last 1 failed Job
```

---

## Job vs CronJob vs Deployment

| | Job | CronJob | Deployment |
|---|---|---|---|
| Runs until | Completion | Completion (each run) | Stopped manually |
| Triggered by | Manual / pipeline | Schedule | Desired state |
| Retries | Yes (backoffLimit) | Yes (per run) | Continuous |
| Use case | Migration, batch | Nightly jobs, cleanup | Web server, API |

---

## Common Patterns

**Database migration on deploy**: run the migration as an init container or a Job that completes before the new Deployment Pods start. Kubernetes init containers are simpler for tight coupling; a separate Job with `spec.initContainers` dependency works for more complex orchestration.

**Scheduled cleanup**: CronJob that deletes stale data, rotates logs, or clears cache. Pair with `concurrencyPolicy: Forbid` to avoid overlapping runs.

**Smoke test after deployment**: a Job that runs integration tests against the newly deployed service, with `ttlSecondsAfterFinished` set so it cleans up automatically.

!!! warning "CronJobs don't guarantee execution"
    CronJobs can miss runs if the cluster is down or the control plane is overloaded. For critical scheduled work, use an external scheduler (Airflow, Temporal, a cloud scheduler) that can trigger the Job and monitor its completion.
