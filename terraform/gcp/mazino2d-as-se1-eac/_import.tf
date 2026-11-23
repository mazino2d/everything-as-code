# Adopts the billing account bindings made by hand (billing_iam.tf). Delete
# these blocks once applied.
import {
  for_each = {
    for key, item in local.billing_account_members : key => item
    if item.project != "mazino2d-as-se1-dev"
  }
  to = google_billing_account_iam_member.terraform[each.key]
  id = "${local.billing_accounts[each.value.account]} ${each.value.role} serviceAccount:terraform@${each.value.project}.iam.gserviceaccount.com"
}

import {
  for_each = local.billing_accounts
  to       = google_billing_account_iam_member.eac_admin[each.key]
  id       = "${each.value} roles/billing.admin serviceAccount:terraform@mazino2d-as-se1-eac.iam.gserviceaccount.com"
}
