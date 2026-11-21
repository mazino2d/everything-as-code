# The project is created by hand with gcloud (_docs/setup.md, step 1); the first
# apply adopts it into state.
import {
  to = module.project.google_project.this
  id = local.project_id
}

# The API keys Firebase created with the apps (api_keys.tf).
import {
  to = google_apikeys_key.android
  id = "projects/${local.project_id}/locations/global/keys/fbf6ec61-09cd-441e-83f8-06fa20b23a23"
}

import {
  to = google_apikeys_key.ios
  id = "projects/${local.project_id}/locations/global/keys/75a4d546-52bf-4f6d-81ed-bb42c1557a7f"
}

import {
  to = google_apikeys_key.browser
  id = "projects/${local.project_id}/locations/global/keys/05070398-da8a-4106-91ca-232387c6de8f"
}
