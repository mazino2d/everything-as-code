# dataplatform-as-se1-dev setup

Dev BigQuery warehouse for [data-platform](https://github.com/mazino2d/data-platform).
CI on pull requests and the pipeline on `main` run here, so nothing before a release
tag touches [dataplatform-as-se1-prd](../../dataplatform-as-se1-prd/_docs/setup.md).
The data comes from:

- the telemetry endpoint in `simsplit-as-se1-dev`, which receives sim-split's dev builds;
- data-platform's dlt load of the `simsplit-as-se1-dev` Firestore;
- data-platform's fake source (`dlt/sources/simsplit_fake.py`), which adds synthetic
  rows prefixed `fake-` so dashboards have something to draw.

The stack mirrors prd, with one difference: partitions in `simsplit_raw` expire after two
years, so there is no storage alert. Like prd, the target cost is zero. A budget emails
at 50 % and 100 %, and a kill switch unlinks billing once actual cost reaches the budget.

Some steps have no Terraform or API support and are done by hand, once.

## 1. Project, Terraform service account and workspace

Follow [terraform/gcp/_docs/setup.md](../../_docs/setup.md) with
`<project-id>` = `dataplatform-as-se1-dev`. The workspace is
`gcp-dataplatform-as-se1-dev`, and it only needs the `gcp_credentials` variable. In the
workspace's **Settings → General → Remote state sharing**, share with workspace `github`.

Before the first apply, run the one-time gcloud steps in prd's section 1 against
`dataplatform-as-se1-dev`:

- enable `cloudbilling.googleapis.com` and `serviceusage.googleapis.com`;
- grant `roles/billing.user` and `roles/billing.costsManager` on the billing account to
  `terraform@dataplatform-as-se1-dev.iam.gserviceaccount.com`.

## 2. GitHub Actions

The `data_platform_ci` output holds the values for data-platform's
`google-github-actions/auth` step. The github stack sets them in data-platform's `dev`
environment, so re-run apply on `terraform/github` after the first apply of this stack.

## 3. Kill switch

The kill switch works the same way as in prd's section 3. To recover after it fires,
re-run apply on `terraform/gcp/dataplatform-as-se1-dev`.

## 4. sim-split dev data

`simsplit.tf` creates `simsplit_raw` with the same tables as prd. When you change a
table's schema, change both stacks in the same PR and apply dev first.

The dev endpoint's write grant waits for two things:

- the `gcp-simsplit-as-se1-dev` workspace has applied `telemetry.tf`;
- that workspace shares its state with this one.

Re-run apply on this stack after both are done.
