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
  name         = "3fc350dc-e011-41c4-b823-e6842bf99cf9"
  display_name = "Android key (auto created by Firebase)"

  restrictions {
    android_key_restrictions {
      dynamic "allowed_applications" {
        for_each = var.android_sha1_hashes
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

resource "google_apikeys_key" "browser" {
  project      = module.project.project_id
  name         = "ee83280a-109a-45f0-ad49-42cc112c6f07"
  display_name = "Browser key (auto created by Firebase)"

  restrictions {
    browser_key_restrictions {
      # The dev web app, its auth handler, and local web builds (dev only).
      allowed_referrers = [
        "https://${local.hosting_site_id}.web.app/*",
        "https://${local.project_id}.firebaseapp.com/*",
        "http://localhost/*",
        "http://localhost:*/*",
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
