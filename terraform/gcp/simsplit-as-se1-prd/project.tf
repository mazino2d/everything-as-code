module "project" {
  source             = "./_modules/gcp-project"
  name               = "simsplit-as-se1-prd"
  project_id         = local.project_id
  billing_account_id = local.billing_account_id
  services = [
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
    # Workload Identity Federation for sim-split's GitHub Actions (github_actions.tf)
    "sts.googleapis.com",
    "iamcredentials.googleapis.com",
    # Google Play Developer API: sim-split uploads AABs (github_actions.tf)
    "androidpublisher.googleapis.com",
    # Play Integrity API: Play Console links this project for integrity verdicts (_docs/setup.md § 6)
    "playintegrity.googleapis.com",
    # App Check: Play Integrity on Android, reCAPTCHA on web (app_check.tf)
    "firebaseappcheck.googleapis.com",
    "recaptchaenterprise.googleapis.com",
    # Firebase: Auth (Identity Platform), Firestore, rules and Hosting (firebase.tf, auth.tf)
    "firebase.googleapis.com",
    "identitytoolkit.googleapis.com",
    "firestore.googleapis.com",
    "firebaserules.googleapis.com",
    "firebasehosting.googleapis.com",
    "apikeys.googleapis.com",
    # Budget alerts and the billing kill switch (budget.tf, kill_switch.tf)
    "cloudbilling.googleapis.com",
    "billingbudgets.googleapis.com",
    "pubsub.googleapis.com",
    "cloudfunctions.googleapis.com",
    "run.googleapis.com",
    "cloudbuild.googleapis.com",
    "artifactregistry.googleapis.com",
    "eventarc.googleapis.com",
    "storage.googleapis.com",
    "logging.googleapis.com",
  ]
}
