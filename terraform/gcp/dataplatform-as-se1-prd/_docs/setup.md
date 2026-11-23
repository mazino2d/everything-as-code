# dataplatform-as-se1-prd setup

BigQuery warehouse for [data-platform](https://github.com/mazino2d/data-platform), the
data pipeline for mazino2d projects (dlt, dbt and Evidence, orchestrated by GitHub
Actions). The target cost is zero: usage stays inside the BigQuery free tier, a budget
emails at 50 % and 100 %, and a kill switch unlinks billing once actual cost reaches the
budget.

Some steps have no Terraform or API support and are done by hand, once.

## 1. Project, Terraform service account and state

Follow [terraform/gcp/_docs/setup.md](../../_docs/setup.md) with
`<project-id>` = `dataplatform-as-se1-prd`. The stack needs no
variables. The github stack reads its state from the bucket, so there is no sharing step.

The providers bill API quota to this project (`user_project_override`), so the first
apply fails with `SERVICE_DISABLED` unless these APIs are already enabled:

```bash
gcloud services enable cloudbilling.googleapis.com serviceusage.googleapis.com \
  --project=dataplatform-as-se1-prd
```

The Terraform service account's billing roles (`roles/billing.user` to link billing
again after the kill switch has fired, `roles/billing.costsManager` for the budget) are
granted by `terraform/gcp/mazino2d-as-se1-eac/billing_iam.tf`: add the project there and
apply that stack before this one's first apply.

## 2. GitHub Actions

The `data_platform_ci` output holds the project ID, Workload Identity provider and
service account for data-platform's `google-github-actions/auth` step. The github stack
reads it from remote state and sets them as `GCP_PROJECT_ID`,
`GCP_WORKLOAD_IDENTITY_PROVIDER` and `GCP_SERVICE_ACCOUNT` in data-platform's `prd`
environment, so re-run apply on `terraform/github` after the first apply of this stack.

## 3. Kill switch

- **Check after the first apply:** publish a test message to the `billing-alerts`
  topic with `costAmount` below `budgetAmount`. The function log should say
  "No action".
- **When it fires:** billing is unlinked and billed BigQuery usage stops. To recover:
  1. Find what caused the cost, using Billing reports and BigQuery job history.
  2. Fix it.
  3. Re-run apply on this stack (`terraform.yml`, stack
     `terraform/gcp/dataplatform-as-se1-prd`). `module.project` links billing again.

  Any apply of this stack links billing again, so don't apply unrelated changes until
  the cause is fixed.
- **Lag:** budget notifications can arrive hours after the spend, so the cap limits a
  runaway cost but does not guarantee zero.

## 4. sim-split raw data (R-4)

`simsplit.tf` creates the `simsplit_raw` dataset (time travel at its 48-hour minimum),
the `error_reports` and `usage_events` tables the telemetry endpoint writes, and a
storage alert at 8 GiB. The endpoint's write grant waits for the
`terraform/gcp/simsplit-as-se1-prd` stack to apply `telemetry.tf` (its setup § 8);
re-run apply on this stack after that. Confirm the notification channel's email once.
