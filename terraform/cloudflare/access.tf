resource "cloudflare_zero_trust_access_policy" "warp_enrolment" {
  account_id = var.cloudflare_account_id
  name       = "WARP enrolment"
  decision   = "allow"

  include = [for email in var.warp_allowed_emails : { email = { email = email } }]
}

# Device enrolment permissions: only the listed emails can log in to the WARP client.
resource "cloudflare_zero_trust_access_application" "warp" {
  account_id       = var.cloudflare_account_id
  type             = "warp"
  name             = "Warp Login App"
  session_duration = "720h"

  policies = [
    {
      id         = cloudflare_zero_trust_access_policy.warp_enrolment.id
      precedence = 1
    },
  ]
}
