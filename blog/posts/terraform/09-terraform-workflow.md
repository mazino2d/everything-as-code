---
date: 2025-04-26
title: The Plan/Apply Workflow — GitOps-friendly Terraform
---

Terraform's plan/apply cycle is naturally suited to a GitOps workflow: propose changes as a pull request, validate the plan as a CI check, review the plan before merging, apply automatically on merge. Done well, this workflow makes infrastructure changes auditable, reviewable, and safe.

---

## The Core Loop

```text
Write HCL  →  terraform plan  →  Review plan  →  terraform apply
```

This loop is the same whether you run it locally or in CI/CD. The key discipline: **never apply without reviewing the plan**. The plan is not a formality — it's the decision about what will change.

---

## The PR-based Workflow

The standard GitOps workflow for Terraform:

1. **Branch**: engineer creates a branch with infrastructure changes
2. **Plan on PR**: CI runs `terraform plan` and posts the output as a PR comment
3. **Review**: another engineer reviews both the code diff and the plan output
4. **Merge**: on merge to main, CI runs `terraform apply` automatically
5. **Output**: apply results (or failures) are recorded in CI logs

```text
PR opened
  └── CI: terraform init && terraform plan
        └── Post plan summary to PR comment
              └── Review: code + plan
                    └── Merge
                          └── CI: terraform init && terraform apply
```

The plan output on the PR is essential. A PR that modifies a single line of HCL might plan to destroy and recreate a database — which is only visible in the plan, not the code diff.

---

## Saved Plans

`terraform plan -out=tfplan` saves the plan to a file. `terraform apply tfplan` applies exactly that plan — no refresh, no recalculation.

This is important for CI/CD:

```bash
# In the plan job:
terraform plan -out=tfplan
# Upload tfplan as an artifact

# In the apply job (after approval):
# Download tfplan artifact
terraform apply tfplan
```

Without a saved plan, `terraform apply` runs a new plan at apply time. If the state changed between the plan and the apply (e.g., another apply ran), the actual changes may differ from what was reviewed. A saved plan guarantees that what was approved is exactly what gets applied.

---

## Manual vs. Automated Apply

**Automated apply** (apply runs automatically on merge): appropriate for low-risk changes and mature teams with good review culture. Fast and consistent.

**Manual apply** (engineer reviews CI plan and applies manually): appropriate for high-risk infrastructure (databases, networking), or when the team is still building confidence in the workflow.

A pragmatic middle ground: automated apply for most resources, manual approval gates for resources tagged as high-risk (using Terraform Cloud's approval workflows or a manual step in the CI pipeline).

---

## Separating Plan and Apply Permissions

One principle of secure Terraform workflows: the CI service account that runs `terraform plan` should have **read-only permissions**, while the one that runs `terraform apply` should have the necessary write permissions.

This limits blast radius: a compromised plan job can read credentials but cannot modify infrastructure. The apply job's credentials are used only in the protected main branch pipeline.

---

## The Multi-stack Problem

Most real-world Terraform deployments involve multiple stacks (directories) that deploy independently. A single monolithic root module that manages all infrastructure becomes a liability: every plan refreshes every resource, every apply risks touching everything, and the blast radius of a mistake is maximised.

Split by lifecycle and ownership:
- **Core network** (VPCs, subnets, DNS zones): changes rarely, high blast radius
- **Platform** (Kubernetes cluster, RDS, load balancers): changes occasionally
- **Applications** (services, queues, caches): changes frequently

Each stack has its own state, its own CI/CD pipeline, and its own review process. Cross-stack dependencies use remote state data sources rather than resource references.

---

## Don't Automate `terraform destroy`

`terraform destroy` deletes everything Terraform manages. Automating it (e.g., "destroy the dev environment at midnight") is tempting for cost saving but requires careful safeguards:

- Destroy pipelines should require explicit manual approval
- Target specific resources with `-target` rather than entire stacks
- Use `lifecycle { prevent_destroy = true }` on critical resources as a guard

```hcl
resource "aws_rds_instance" "db" {
  ...
  lifecycle {
    prevent_destroy = true    # terraform plan will error if this resource would be destroyed
  }
}
```

`prevent_destroy` turns an accidental destroy into a plan-time error that must be explicitly removed before the destroy can proceed.
