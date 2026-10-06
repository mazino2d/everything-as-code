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

The providers bill API quota to this project (`user_project_override`), so the first
apply fails with `SERVICE_DISABLED` unless these APIs are already enabled:

```bash
gcloud services enable cloudbilling.googleapis.com serviceusage.googleapis.com \
  --project=simsplit-as-se1-prd
```

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

### 2.1 OAuth consent screen

In the [Cloud console](https://console.cloud.google.com), select `simsplit-as-se1-prd` and
open **Google Auth Platform** (the old **APIs & Services → OAuth consent screen** page
redirects there).

1. **Get started**:
   - App name: `SimSplit`
   - User support email and contact information: `mazino2d@gmail.com`
   - Audience: **External**
2. **Branding**:
   - App home page: `https://mazino2d.github.io/sim-split/`
   - Privacy policy: `https://mazino2d.github.io/sim-split/privacy-policy.html`
   - Authorised domains: `mazino2d.github.io` and `simsplit-as-se1-prd.firebaseapp.com`

   Don't upload a logo. A logo makes the app need Google verification, which takes days.
3. **Data access → Add or remove scopes**: `openid`, `.../auth/userinfo.email` and
   `.../auth/userinfo.profile`. None of them is sensitive, so no verification is needed.
4. **Audience → Publish app**. In Testing mode only up to 100 listed test users can sign
   in, and their sessions expire after seven days.

### 2.2 Web OAuth client

Firebase Auth uses this client, and the Android app sends its ID as `serverClientId`.

In **Google Auth Platform → Clients → Create client**:

- Application type: **Web application**
- Name: `SimSplit Firebase Auth`
- Authorised JavaScript origins: `https://simsplit-as-se1-prd.firebaseapp.com`
- Authorised redirect URIs: `https://simsplit-as-se1-prd.firebaseapp.com/__/auth/handler`

Download the JSON straight after creating it: the console shows the client secret only
once. Keep the file outside git.

### 2.3 Workspace variables

Add these as **Terraform variables** in the workspace:

| Key | Value | Sensitive |
|---|---|---|
| `google_oauth_client_id` | `….apps.googleusercontent.com` | no |
| `google_oauth_client_secret` | `GOCSPX-…` | ✅ |

Changing a variable does not trigger an apply. The PR in 2.5 applies it together with
the fingerprints.

### 2.4 Android signing certificate fingerprints

Google sign-in on Android works only with a registered signing certificate. Get the
SHA-1 and SHA-256 of each:

| Certificate | Signs | Where |
|---|---|---|
| App signing key | Builds installed from Play | Play Console → SimSplit → **Protected with Play** → Play app signing → App signing key (copy buttons on the right) |
| Upload key | AAB artifacts from CI | Same page → Upload key |

Android builds come from CI only, so the debug key is not registered and Google sign-in
fails in a local `flutter run`. To test it locally, add that machine's debug key
fingerprints (`keytool -list -v -keystore ~/.android/debug.keystore -alias
androiddebugkey -storepass android`). Gradle generates this key per machine, so a new
laptop needs new fingerprints unless you copy the file across.

Terraform wants the hashes in lower case without colons:

```bash
echo "AB:CD:EF:..." | tr -d ':' | tr 'A-F' 'a-f'
```

### 2.5 Pull request

Fill in `local.android_sha1_hashes` and `local.android_sha256_hashes` in `firebase.tf`,
one entry per certificate, in the order Play App Signing, upload key.
Fingerprints are not secret.

The plan should show one change to `google_firebase_android_app.sim_split` and one add
for `google_identity_platform_default_supported_idp_config.google[0]`. Merging applies
both. The apply also links billing again, which is expected (see section 5).

### 2.6 Android OAuth clients

Google sign-in on Android also needs an Android OAuth client per signing certificate.
Without one, sign-in fails with `DEVELOPER_ERROR` (code 10). Firebase creates these only
when fingerprints are added in the Firebase console, not through the API that Terraform
uses, and there is no public API to create them, so they are made by hand.

In **Google Auth Platform → Clients → Create client**, choose **Android** and create one
client per row:

| Name | Package name | SHA-1 certificate fingerprint |
|---|---|---|
| `SimSplit Android (Play signing)` | `com.mazino2d.simsplit` | `05:D7:3D:DB:AF:E5:B6:BE:EB:2C:11:E0:F2:97:14:E6:DD:90:1E:B3` |
| `SimSplit Android (upload key)` | `com.mazino2d.simsplit` | `D4:BA:31:1C:4D:85:F5:F0:84:B0:68:39:74:2D:E9:39:0E:23:7F:A5` |

These are the SHA-1 values from `local.android_sha1_hashes` in `firebase.tf`, upper case
with colons. Android clients have no secret, so nothing goes into the workspace. If a
certificate changes, update `firebase.tf` and the matching client together.

### 2.7 Checks after apply

- Firebase console → **Authentication → Sign-in method**: Google is **Enabled**.
- **Project settings → Your apps → SimSplit Android**: all four fingerprints are listed.
- **Google Auth Platform → Clients**: the Web client from 2.2 and both Android clients
  from 2.6 are listed.

### 2.8 `google-services.json`

Download it after the Android clients exist: **Project settings → Your apps → SimSplit
Android → google-services.json**. Put it at `android/app/google-services.json` in
sim-split. It is not secret, since the API key is restricted to the package and
certificates, so it is committed there.

Its `oauth_client` list must hold two entries with `client_type: 1` (Android, one per
SHA-1) and one with `client_type: 3` (the Web client, which the app uses as
`serverClientId`). A file downloaded before 2.6 lacks the Android entries, so download it
again whenever a certificate or client changes.

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

## 6. Play Integrity API

Play Console uses this project for SimSplit's integrity verdicts. Linking has no API, so
it is done by hand: **Play Console → SimSplit → Protected with Play → Play Integrity API
→ Manage → Project configuration → Add project** → `simsplit-as-se1-prd`.

Linking enables `playintegrity.googleapis.com`, which `module.project` also declares.
Play Console needs at least one linked project at all times, so keep the API enabled and
link another project first if this one is ever replaced.

## 7. App Check

`app_check.tf` registers the Android app with Play Integrity and the web app with a
score-based reCAPTCHA key (24 h token TTL, so web stays inside reCAPTCHA's 10,000 free
assessments a month). The github stack copies the site key into sim-split's
`RECAPTCHA_ENTERPRISE_SITE_KEY` repo variable, which the web release build reads.

1. **Remote state:** the `github` workspace reads this workspace's outputs. In Terraform
   Cloud, open this workspace → **Settings → General → Remote state sharing** and allow
   `github`. Until the site key exists, the github stack skips the variable; re-run its
   apply once this stack has applied.
2. **Debug token (optional):** generate a UUID (`uuidgen`), set it as the sensitive
   workspace variable `app_check_debug_token`, and pass the same value to debug builds:
   `flutter run --dart-define=APP_CHECK_DEBUG_TOKEN=<uuid>`. Keep it private: anyone with
   it can pass App Check.
3. **Enforcement** is on (`app_check_enforced`, default `true`): Auth and Firestore
   reject requests without a valid token, including debug builds without the
   registered token. If real users are rejected (low reCAPTCHA scores show up in
   **Firebase console → App Check → APIs**), set the workspace variable
   `app_check_enforced = false` to go back to metrics only while investigating.
