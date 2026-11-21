# The API keys Firebase created for the apps, managed here so their
# restrictions can't drift from what the docs say (sim-split R-8 P1). Each key
# works only from its own app and only for the APIs the app calls; App Check
# stays the main gate, this is the layer under it. Imported in _import.tf.

locals {
  # What sim-split calls with an API key: sign-in (Identity Toolkit, Secure
  # Token), sync (Firestore), App Check and the installation ID App Check uses.
  api_key_services = [
    "firebaseappcheck.googleapis.com",
    "firebaseinstallations.googleapis.com",
    "firestore.googleapis.com",
    "identitytoolkit.googleapis.com",
    "securetoken.googleapis.com",
  ]
}

resource "google_apikeys_key" "android" {
  project      = module.project.project_id
  name         = "fbf6ec61-09cd-441e-83f8-06fa20b23a23"
  display_name = "Android key (auto created by Firebase)"

  restrictions {
    android_key_restrictions {
      dynamic "allowed_applications" {
        for_each = local.android_sha1_hashes
        content {
          package_name     = google_firebase_android_app.sim_split.package_name
          sha1_fingerprint = allowed_applications.value
        }
      }
    }

    dynamic "api_targets" {
      for_each = local.api_key_services
      content {
        service = api_targets.value
      }
    }
  }
}

resource "google_apikeys_key" "ios" {
  project      = module.project.project_id
  name         = "75a4d546-52bf-4f6d-81ed-bb42c1557a7f"
  display_name = "iOS key (auto created by Firebase)"

  restrictions {
    ios_key_restrictions {
      allowed_bundle_ids = [google_firebase_apple_app.sim_split.bundle_id]
    }

    dynamic "api_targets" {
      for_each = local.api_key_services
      content {
        service = api_targets.value
      }
    }
  }
}

resource "google_apikeys_key" "browser" {
  project      = module.project.project_id
  name         = "05070398-da8a-4106-91ca-232387c6de8f"
  display_name = "Browser key (auto created by Firebase)"

  restrictions {
    browser_key_restrictions {
      # The web app, the project's default Hosting site and its auth handler.
      allowed_referrers = [
        "https://${google_firebase_hosting_site.default.site_id}.web.app/*",
        "https://${local.project_id}.web.app/*",
        "https://${local.project_id}.firebaseapp.com/*",
      ]
    }

    dynamic "api_targets" {
      for_each = local.api_key_services
      content {
        service = api_targets.value
      }
    }
  }
}
