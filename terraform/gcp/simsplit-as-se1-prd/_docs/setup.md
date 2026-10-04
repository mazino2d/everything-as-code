# simsplit-as-se1-prd setup

Firebase backend for [SimSplit](https://github.com/mazino2d/sim-split) co-worked groups
(spec R-3). The project runs on the Blaze plan, but the target cost is zero: usage stays
inside the free quotas, a budget emails at 50 % and 100 %, and a kill switch unlinks
billing once actual cost reaches the budget.

Some steps have no Terraform or API support and are done by hand, once.

## 1. Project, Terraform service account and workspace

Follow [terraform/gcp/_docs/setup.md](../../_docs/setup.md) with
`<project-id>` = `simsplit-as-se1-prd`. The workspace is
`gcp-simsplit-as-se1-prd`.

Then grant the Terraform service account two roles on the billing account. It needs them
to create the budget and to link billing again after the kill switch has fired:

```bash
for role in roles/billing.user roles/billing.costsManager; do
  gcloud billing accounts add-iam-policy-binding 0138D2-6EFA6E-34332E \
    --member="serviceAccount:terraform@simsplit-as-se1-prd.iam.gserviceaccount.com" \
    --role="$role"
done
```

## 2. Google sign-in

1. In **APIs & Services → OAuth consent screen**, set up an **External** app named
   SimSplit, with your support email and the scopes `email`, `profile` and `openid`.
   Publish it.
2. In **APIs & Services → Credentials**, create an OAuth client ID of type **Web
   application** named `SimSplit Firebase Auth`. Use the redirect URI
   `https://simsplit-as-se1-prd.firebaseapp.com/__/auth/handler`.
3. Add these workspace variables:

   | Key | Value | Sensitive |
   |---|---|---|
   | `google_oauth_client_id` | the client ID | no |
   | `google_oauth_client_secret` | the client secret | ✅ |

4. Add the Android signing certificate fingerprints to `local.android_sha1_hashes` and
   `local.android_sha256_hashes` in `firebase.tf`. You need both the upload key and the
   Play App Signing key (Play Console → Test and release → App integrity). Without them,
   Google sign-in fails on Android.

## 3. Apple sign-in (when the Apple Developer account is active)

1. In the Apple Developer portal:
   - Enable **Sign in with Apple** on the App ID `com.mazino2d.simsplit`.
   - Create a **Services ID** with the return URL
     `https://simsplit-as-se1-prd.firebaseapp.com/__/auth/handler`. Android uses the
     web flow.
   - Create a **Sign in with Apple key**. Keep the `.p8` file outside git.
2. Generate the client secret, a JWT signed with the key, valid for at most six months.
   Set a reminder to rotate it.
3. Add these workspace variables:

   | Key | Value | Sensitive |
   |---|---|---|
   | `apple_team_id` | the Team ID | no |
   | `apple_services_id` | the Services ID | no |
   | `apple_client_secret` | the JWT | ✅ |

## 4. Google Play publisher

The Android release workflow in sim-split uploads App Bundles as
`gha-play-publisher@simsplit-as-se1-prd.iam.gserviceaccount.com`. After the first
apply:

1. In **Play Console → Users and permissions**, invite that email with the release
   permissions for SimSplit.
2. In sim-split, set the workflow's `google-github-actions/auth` inputs from the
   `play_publisher` output of this stack.

## 5. Kill switch

- **Check after the first apply:** publish a test message to the `billing-alerts`
  topic with `costAmount` below `budgetAmount`. The function log should say
  "No action".
- **When it fires:** billing is unlinked and Firestore, Auth and Hosting stop serving.
  To recover:
  1. Find what caused the cost, using Billing reports and Firestore usage.
  2. Fix it.
  3. Re-run apply on this stack (`tf-apply.yml`, stack
     `terraform/gcp/simsplit-as-se1-prd`). `module.project` links billing again.

  Any apply of this stack links billing again, so don't apply unrelated changes until
  the cause is fixed.
- **Lag:** budget notifications can arrive hours after the spend, so the cap limits a
  runaway cost but does not guarantee zero.
