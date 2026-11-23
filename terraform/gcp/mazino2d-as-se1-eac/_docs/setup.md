# mazino2d-as-se1-eac setup

Holds what every everything-as-code stack needs before it can run, on the
`mazino2d` billing account:

- the Terraform state bucket `gs://mazino2d-as-se1-eac-tfstate`
  (`state/<stack path>` and `secrets/<stack path>.tfvars.json`, see `tfstate.tf`)
- the Workload Identity pool `github` with provider `everything-as-code`
  (`github_actions.tf`)
- the `terraform` service account, which runs the stacks outside GCP and this one

Its own state is `state/gcp/mazino2d-as-se1-eac` in that same bucket. A lien blocks
deleting the project.

## Rebuild from scratch

The bucket, pool and service account have to exist before any stack can init or
sign in, so create them by hand, then add `import` blocks for them (and for the
service account's `roles/owner` and WIF bindings) to `_import.tf`; the first apply
adopts them, after which the blocks can go.

```bash
P=mazino2d-as-se1-eac
gcloud projects create $P
gcloud billing projects link $P --billing-account=0138D2-6EFA6E-34332E
gcloud services enable storage.googleapis.com iam.googleapis.com \
  iamcredentials.googleapis.com sts.googleapis.com cloudresourcemanager.googleapis.com \
  serviceusage.googleapis.com cloudbilling.googleapis.com billingbudgets.googleapis.com \
  logging.googleapis.com --project $P
gcloud storage buckets create gs://$P-tfstate --project $P --location asia-southeast1 \
  --uniform-bucket-level-access --public-access-prevention
gcloud storage buckets update gs://$P-tfstate --versioning
gcloud iam service-accounts create terraform --project $P
gcloud projects add-iam-policy-binding $P \
  --member serviceAccount:terraform@$P.iam.gserviceaccount.com --role roles/owner
gcloud iam workload-identity-pools create github --project $P --location global
gcloud iam workload-identity-pools providers create-oidc everything-as-code \
  --project $P --location global --workload-identity-pool github \
  --issuer-uri https://token.actions.githubusercontent.com \
  --attribute-mapping "google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.ref=assertion.ref" \
  --attribute-condition "assertion.repository == 'mazino2d/everything-as-code'"
```

On every billing account, grant `roles/billing.admin` to
`terraform@mazino2d-as-se1-eac.iam.gserviceaccount.com`. Nothing else can grant it; with
it, `billing_iam.tf` grants each project's terraform service account the billing roles it
needs (this stack's included) and adopts this binding.

If the project number changes, update it in every `terraform/gcp/*/terraform_wif.tf`
and in `gcp-workload-identity-provider` in `.github/workflows/terraform.yml`.

Then apply locally once, since CI can only sign in after the bindings exist:

```bash
gcloud auth application-default login
make apply STACK=terraform/gcp/mazino2d-as-se1-eac
```
