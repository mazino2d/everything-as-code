# The project is created by hand with gcloud (_docs/setup.md, step 1); the first
# apply adopts it into state.
import {
  to = module.project.google_project.this
  id = local.project_id
}

# The API keys Firebase created with the apps (api_keys.tf).
import {
  to = google_apikeys_key.android
  id = "projects/${local.project_id}/locations/global/keys/3fc350dc-e011-41c4-b823-e6842bf99cf9"
}

import {
  to = google_apikeys_key.browser
  id = "projects/${local.project_id}/locations/global/keys/ee83280a-109a-45f0-ad49-42cc112c6f07"
}
