# dataplatform-as-se1-prd setup

BigQuery warehouse for [data-platform](https://github.com/mazino2d/data-platform), the
data pipeline for mazino2d projects (dlt, dbt and Evidence, orchestrated by GitHub
Actions). The target cost is zero: usage stays inside the BigQuery free tier, a budget
emails at 50 % and 100 %, and a kill switch unlinks billing once actual cost reaches the
budget.

Some steps have no Terraform or API support and are done by hand, once.

## 1. Project, Terraform service account and workspace

Follow [terraform/gcp/_docs/setup.md](../../_docs/setup.md) with
`<project-id>` = `dataplatform-as-se1-prd`. The workspace is
`gcp-dataplatform-as-se1-prd`; it only needs the `gcp_credentials` variable. In the
workspace's **Settings → General → Remote state sharing**, share with workspace `github`.

The providers bill API quota to this project (`user_project_override`), so the first
apply fails with `SERVICE_DISABLED` unless these APIs are already enabled:

```bash
gcloud services enable cloudbilling.googleapis.com serviceusage.googleapis.com \
  --project=dataplatform-as-se1-prd
```

Then grant the Terraform service account two roles on the billing account. It needs them
to create the budget and to link billing again after the kill switch has fired:

```bash
for role in roles/billing.user roles/billing.costsManager; do
  gcloud billing accounts add-iam-policy-binding 0138D2-6EFA6E-34332E \
    --member="serviceAccount:terraform@dataplatform-as-se1-prd.iam.gserviceaccount.com" \
    --role="$role"
done
```

## 2. GitHub Actions

The `data_platform_ci` output holds the project ID, Workload Identity provider and
service account for data-platform's `google-github-actions/auth` step. The github stack
reads it from remote state and sets them as the repo variables `GCP_PROJECT_ID`,
`GCP_WORKLOAD_IDENTITY_PROVIDER` and `GCP_SERVICE_ACCOUNT`, so re-run apply on
`terraform/github` after the first apply of this stack.

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
