# simsplit-as-se1-dev setup

Dev Firebase backend for [SimSplit](https://github.com/mazino2d/sim-split): its own
Auth, Firestore and Hosting, so internal-test builds never touch production data.

- Android: internal-test builds are a separate Play app, `com.mazino2d.simsplit.dev`
  (**SimSplit Dev**), which installs next to the production app.
- Web: the dev build is served at `https://simsplit-as-se1-dev.web.app` (the default Hosting site; `simsplit-dev` is taken by another project).

The stack mirrors [simsplit-as-se1-prd](../../simsplit-as-se1-prd/_docs/setup.md)
without Apple sign-in and the Play publisher service account. Its telemetry endpoint
(`telemetry.tf`) writes to `dataplatform-as-se1-dev`, not prd, and has no error alert.
Like prd, the target cost is zero: a budget emails at 50 % and 100 %, and a kill switch
unlinks billing once actual cost reaches the budget.

Some steps have no Terraform or API support and are done by hand, once.

## 1. Project, Terraform service account and workspace

Follow [terraform/gcp/_docs/setup.md](../../_docs/setup.md) with
`<project-id>` = `simsplit-as-se1-dev`. The workspace is
`gcp-simsplit-as-se1-dev`. In the workspace's **Settings → General → Remote state
sharing**, share with workspace `github` (see section 6).

The providers bill API quota to this project (`user_project_override`), so the first
apply fails with `SERVICE_DISABLED` unless these APIs are already enabled:

```bash
gcloud services enable cloudbilling.googleapis.com serviceusage.googleapis.com \
  --project=simsplit-as-se1-dev
```

Then grant the Terraform service account two roles on the billing account. It needs them
to create the budget and to link billing again after the kill switch has fired:

```bash
for role in roles/billing.user roles/billing.costsManager; do
  gcloud billing accounts add-iam-policy-binding 0138D2-6EFA6E-34332E \
    --member="serviceAccount:terraform@simsplit-as-se1-dev.iam.gserviceaccount.com" \
    --role="$role"
done
```

## 2. Google sign-in

The same steps as prd's section 2, in this project.

### 2.1 OAuth consent screen

In the [Cloud console](https://console.cloud.google.com), select `simsplit-as-se1-dev` and
open **Google Auth Platform**.

1. **Get started**:
   - App name: `SimSplit Dev`
   - User support email and contact information: `mazino2d@gmail.com`
   - Audience: **External**
2. **Branding**:
   - App home page: `https://mazino2d.github.io/sim-split/`
   - Privacy policy: `https://mazino2d.github.io/sim-split/privacy-policy.html`
   - Authorised domains: `mazino2d.github.io` and `simsplit-as-se1-dev.firebaseapp.com`

   Don't upload a logo: it makes the app need Google verification.
3. **Data access → Add or remove scopes**: `openid`, `.../auth/userinfo.email` and
   `.../auth/userinfo.profile`.
4. **Audience → Publish app**. In Testing mode sessions expire after seven days.

### 2.2 Web OAuth client

In **Google Auth Platform → Clients → Create client**:

- Application type: **Web application**
- Name: `SimSplit Dev Firebase Auth`
- Authorised JavaScript origins: `https://simsplit-as-se1-dev.firebaseapp.com`
- Authorised redirect URIs: `https://simsplit-as-se1-dev.firebaseapp.com/__/auth/handler`

Download the JSON straight after creating it: the console shows the client secret only
once. Keep the file outside git.

### 2.3 Workspace variables

Add these as **Terraform variables** in the workspace:

| Key | Value | Sensitive |
|---|---|---|
| `google_oauth_client_id` | `….apps.googleusercontent.com` | no |
| `google_oauth_client_secret` | `GOCSPX-…` | ✅ |

Changing a variable does not trigger an apply; re-run apply on this stack, or let the
PR in section 4 apply it.

## 3. Manual steps (Play Console)

The dev app is a separate Play app, and nothing about it can be created through an API.
Tick these off in order:

- [ ] **Create the app**: Play Console → **Create app**. App name `SimSplit Dev`,
      default language English, **App**, **Free**. The package name is fixed by the
      first upload, so the first bundle must be built as `com.mazino2d.simsplit.dev`.
- [ ] **Minimum app content for internal testing**: under **Policy and programmes → App
      content**, fill in at least privacy policy
      (`https://mazino2d.github.io/sim-split/privacy-policy.html`), app access (sign-in
      with Google; give review credentials or say all features need a Google account),
      ads (no ads), content rating, target audience, data safety and government apps.
      Internal testing does not go through review, but Play Console blocks rollouts
      until these are done.
- [ ] **Internal testers**: **Test and release → Testing → Internal testing → Testers**,
      create an email list with the testers and save. Copy the opt-in link for them.
- [ ] **First AAB upload by hand**: build a signed release bundle of the dev flavour and
      upload it to a new **Internal testing** release. The Play Developer API cannot
      upload to an app that has no bundle yet, and this first upload enrols the app in
      Play App Signing (accept the Google-generated app signing key).
- [ ] **Grant the publisher**: **Users and permissions → Invite new users** (or edit the
      existing user) `gha-play-publisher@simsplit-as-se1-prd.iam.gserviceaccount.com`,
      and give it **App permissions → SimSplit Dev** with release to testing tracks. The
      service account and its Workload Identity binding live in
      `simsplit-as-se1-prd` (its `github_actions.tf`); this stack creates none.
- [ ] **Link Play Integrity**: **SimSplit Dev → Test and release → App integrity → Play
      Integrity API → Link a Cloud project** → `simsplit-as-se1-dev`. App Check's Play
      Integrity provider (`app_check.tf`) needs this link.
- [ ] **Copy the signing certificate fingerprints**: **SimSplit Dev → Test and release →
      App integrity → Play app signing**: SHA-1 and SHA-256 of the **app signing key**
      and of the **upload key**. Put them in the variables (section 4).

## 4. Android sign-in

### 4.1 Pull request

Fill in the defaults of `android_sha1_hashes` and `android_sha256_hashes` in
`_variables.tf`, one entry per certificate, in the order app signing key, upload key.
Terraform wants them in lower case without colons:

```bash
echo "AB:CD:EF:..." | tr -d ':' | tr 'A-F' 'a-f'
```

Fingerprints are not secret. The plan should show one change to
`google_firebase_android_app.sim_split` (and the Google provider, if section 2.3 is
done). Merging applies it.

### 4.2 Android OAuth clients

As in prd's section 2.6: without an Android OAuth client per signing certificate, Google
sign-in fails with `DEVELOPER_ERROR` (code 10), and there is no API to create them. In
**Google Auth Platform → Clients → Create client**, choose **Android** and create:

| Name | Package name | SHA-1 certificate fingerprint |
|---|---|---|
| `SimSplit Dev Android (Play signing)` | `com.mazino2d.simsplit.dev` | app signing key SHA-1, upper case with colons |
| `SimSplit Dev Android (upload key)` | `com.mazino2d.simsplit.dev` | upload key SHA-1, upper case with colons |

### 4.3 `google-services.json`

Download it after the Android clients exist: **Project settings → Your apps → SimSplit
Dev → google-services.json**, and commit it at the dev flavour's path in sim-split. Its
`oauth_client` list must hold two entries with `client_type: 1` and one with
`client_type: 3` (the Web client from 2.2).

## 5. App Check

`app_check.tf` registers the Android app with Play Integrity and the web app with a
score-based reCAPTCHA key for `simsplit-as-se1-dev.web.app`,
`simsplit-as-se1-dev.firebaseapp.com` and `localhost` (24 h token TTL).

1. **Debug token (optional):** generate a UUID (`uuidgen`), set it as the sensitive
   workspace variable `app_check_debug_token`, and pass the same value to debug builds:
   `flutter run --dart-define=APP_CHECK_DEBUG_TOKEN=<uuid>`. Keep it private.
2. **Enforcement** is on from the start (`app_check_enforced`, default `true`). Play
   Integrity verdicts need the link from section 3, so Android requests are rejected
   until then. Set `app_check_enforced = false` to fall back to metrics only.

## 6. GitHub Actions

The github stack reads this workspace's outputs from remote state (section 1) and sets
these variables on sim-split's `dev` environment (prd's environment has the same names):

| Variable | From |
|---|---|
| `FIREBASE_PROJECT` | `firebase.project_id` |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | `firebase_deployer.workload_identity_provider` |
| `GCP_FIREBASE_DEPLOYER` | `firebase_deployer.service_account` (`gha-firebase-deployer`) |
| `RECAPTCHA_ENTERPRISE_SITE_KEY` | `app_check.recaptcha_site_key` |

Until this stack has applied, the github stack leaves them out; re-run apply on
`terraform/github` after the first apply here. As in prd, the Workload Identity provider
only accepts workflows on `main` and `vX.Y.Z` tags.

## 7. Kill switch

- **Check after the first apply:** publish a test message to the `billing-alerts`
  topic with `costAmount` below `budgetAmount`. The function log should say
  "No action".
- **When it fires:** billing is unlinked and Firestore, Auth and Hosting stop serving
  for dev. Production is not affected. To recover:
  1. Find what caused the cost, using Billing reports and Firestore usage.
  2. Fix it.
  3. Re-run apply on this stack (`terraform.yml`, stack
     `terraform/gcp/simsplit-as-se1-dev`). `module.project` links billing again.

  Any apply of this stack links billing again, so don't apply unrelated changes until
  the cause is fixed.
- **Lag:** budget notifications can arrive hours after the spend, so the cap limits a
  runaway cost but does not guarantee zero.
