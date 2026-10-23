"""Unlink billing from the project once actual cost reaches the budget.

Triggered by budget notifications on the billing-alerts Pub/Sub topic
(budget.tf). Billing is linked again by re-running apply on this stack.
"""

import base64
import json
import os

import functions_framework
from google.cloud import billing_v1

PROJECT_NAME = f"projects/{os.environ['PROJECT_ID']}"


@functions_framework.cloud_event
def stop_billing(cloud_event):
    payload = json.loads(base64.b64decode(cloud_event.data["message"]["data"]))
    cost = payload["costAmount"]
    budget = payload["budgetAmount"]
    if cost < budget:
        print(f"No action: cost {cost} is below budget {budget}")
        return

    client = billing_v1.CloudBillingClient()
    info = client.get_project_billing_info(name=PROJECT_NAME)
    if not info.billing_enabled:
        print("No action: billing is already disabled")
        return

    client.update_project_billing_info(
        name=PROJECT_NAME,
        project_billing_info=billing_v1.ProjectBillingInfo(billing_account_name=""),
    )
    print(f"Billing disabled: cost {cost} reached budget {budget}")
