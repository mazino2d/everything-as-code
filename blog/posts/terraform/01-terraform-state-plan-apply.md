---
date: 2025-04-26
title: How Terraform Works — State, Plan, Apply
---

Terraform is not a script runner. It does not execute commands in sequence to create infrastructure. It is a **reconciliation engine**: it compares your declared desired state against the actual state of the world, and computes the minimum set of changes needed to make them match.

Understanding this mental model — desire → state → diff → apply — explains nearly every Terraform behaviour that would otherwise seem surprising.

---

## The Three-Phase Model

Every Terraform operation follows the same logic:

```text
1. Read declared configuration  (your .tf files)
2. Read current actual state    (Terraform state file + live API calls)
3. Compute the diff             (what needs to change?)
4. Apply the diff               (create, update, or destroy resources)
```

`terraform plan` executes steps 1–3 and shows you the diff without making any changes.

`terraform apply` executes all four steps (or just step 4 if given a saved plan).

---

## What State Is

The **state file** is Terraform's record of what it created. It maps your configuration (`resource "aws_instance" "web"`) to the real-world resource (instance ID `i-0abc123def`).

State is not a snapshot of the cloud. It's Terraform's local knowledge: "last time I checked, I created this resource with these attributes, and the cloud gave it this ID."

Without state, Terraform would have no way to:
- Know that `resource "aws_instance" "web"` refers to `i-0abc123def` rather than `i-0xyz789`
- Detect that a resource was deleted outside of Terraform
- Plan an update (without knowing the current value, it can't compute the diff)

---

## Plan as a Diff

The plan output uses a familiar diff language:

```
+ create      (resource does not exist in state or cloud)
~ update      (resource exists but attributes differ)
- destroy     (resource in state but removed from config)
-/+ replace   (resource must be destroyed and recreated)
```

The `replace` case is important: some attributes are **immutable** — they cannot be changed in-place. Changing the `availability_zone` of an EC2 instance requires destroying the old one and creating a new one. Terraform shows this explicitly in the plan.

!!! tip "Always read the plan"
    The plan is not a preview for formality — it's the actual decision tree Terraform will execute. Look for unexpected destroys (`-`) and replacements (`-/+`). A misconfigured change that triggers a replace on a database can be catastrophic.

---

## The Refresh Step

Before computing the diff, Terraform optionally **refreshes state**: it queries the actual current state of each resource from the cloud provider's API and updates the state file to match.

```bash
terraform plan -refresh=false    # skip refresh (faster, uses cached state)
terraform apply -refresh-only    # refresh state without making any changes
```

Refresh is how Terraform detects **drift**: resources that were changed outside of Terraform (via the console, CLI, or another tool). After a refresh, the plan will show what changes are needed to bring the real world back to the declared configuration.

---

## Idempotency

A fundamental property of the plan/apply model: **running `terraform apply` twice on the same configuration produces the same result**.

The second apply has nothing to do — the state already matches the configuration. The plan output is empty:

```
No changes. Your infrastructure matches the configuration.
```

This is the core guarantee of declarative infrastructure: applying the same config repeatedly is safe. There are no accidental re-creates, no duplicate resources.

---

## Why This Beats Scripts

Compare to an imperative script:

```bash
# Script: creates a new bucket every time it runs
aws s3api create-bucket --bucket my-bucket --region us-east-1
```

The script doesn't know if the bucket already exists. Run it twice: error, or worse, a second bucket.

Terraform doesn't have this problem. It knows what exists, what you want, and only does what's necessary.

This is the principle of **idempotent, declarative infrastructure**. It's the foundation every other Terraform concept is built on.
