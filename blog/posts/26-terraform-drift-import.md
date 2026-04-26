---
date: 2025-04-26
title: Drift and Import — When Reality Diverges from State
---

Terraform assumes it has sole control over the resources it manages. In practice, infrastructure is touched by humans, automation, and incidents. Understanding how to detect and reconcile drift — and how to bring existing infrastructure under Terraform management — are essential operational skills.

---

## Drift Defined

**Drift** is any difference between what Terraform's state says and what actually exists in the real world.

Three flavours:

**Configuration drift**: a resource exists in state but has been modified outside Terraform. The EC2 instance's instance type was changed in the console; the S3 bucket's versioning was enabled manually.

**Missing resource**: a resource in state was deleted outside Terraform. Terraform's next plan will try to recreate it.

**Out-of-band resource**: infrastructure was created outside Terraform entirely and is not tracked in state. Terraform is unaware it exists.

---

## Detecting Drift

```bash
terraform plan -refresh-only
```

This runs a refresh (queries the real state of every tracked resource) and shows the differences between what state contains and what the cloud reports — without proposing any changes to bring resources back to the desired configuration.

```
~ update in-place
  resource "aws_instance" "web" {
    ~ instance_type = "t3.micro" -> "t3.large"    # changed in console
  }
```

Use `refresh-only` to audit for drift regularly, or whenever you suspect someone has made changes outside Terraform.

---

## Responding to Drift

You have three choices when you discover drift:

**Revert it**: run `terraform apply` normally. Terraform will restore the configuration-declared state. The manual change is overwritten.

**Accept it**: update your Terraform configuration to match the current real state, then apply. The drift becomes the new desired state.

**Ignore it**: apply `refresh-only` to update state without reverting the resource. The next plan will show no drift — but the configuration still differs from the real resource. Risky for resources where correctness matters.

There is no universally correct answer. The decision depends on whether the out-of-band change was intentional and whether it should be permanent.

---

## Import: Adopting Existing Infrastructure

When infrastructure was created before Terraform (manually, by a script, or by another tool), you can bring it under Terraform management using import.

**The old way** (still supported):

```bash
terraform import aws_instance.web i-0abc123def456
```

This tells Terraform: "the resource `aws_instance.web` in my configuration corresponds to instance `i-0abc123def456` in AWS." Terraform adds the resource to state — but does not generate the configuration. You must write the `.tf` code yourself to match the imported resource's attributes.

**The new way** (Terraform 1.5+): the `import` block generates both the state and the configuration.

```hcl
import {
  to = aws_instance.web
  id = "i-0abc123def456"
}
```

```bash
terraform plan -generate-config-out=generated.tf
```

Terraform generates HCL that matches the real resource's current state. Review and clean up the generated code, then apply. This dramatically reduces the manual effort of bringing existing infrastructure under management.

---

## Removing Resources from State

Sometimes you need to stop managing a resource without destroying it — for example, a resource that will be managed by a different configuration, or one you want to preserve but let Terraform forget about.

```bash
terraform state rm aws_instance.web
```

This removes the resource from state. The real resource is untouched. The next `terraform plan` will not show it, as if it never existed from Terraform's perspective.

Use this with caution: removing a resource from state without updating the configuration means the next plan will try to create a new one.

---

## The `moved` Block

When you refactor Terraform code — renaming a resource, moving it into a module, or restructuring configuration — the resource address changes. Without instruction, Terraform would destroy the old resource and create a new one.

The `moved` block tells Terraform that a resource at one address should now be considered the same resource at another address:

```hcl
moved {
  from = aws_instance.web
  to   = module.compute.aws_instance.web
}
```

After applying the `moved` block, Terraform updates state without touching the real resource. It's a zero-downtime refactoring primitive. Once the move is complete, the block can be removed (the state has been updated).

---

## State Surgery as a Last Resort

For situations not covered by the above — splitting state files, mass-renaming resources, recovering from corruption — Terraform has `terraform state mv`, `terraform state pull`, and `terraform state push`. These allow direct manipulation of the state file.

Treat these commands as surgery. Make a backup first, work on a copy, and apply minimal targeted changes. State corruption from botched manual edits is recoverable only if you have a backup.

```bash
# always backup before state manipulation
terraform state pull > backup.tfstate
```
