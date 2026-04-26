---
date: 2025-04-26
title: Workspaces vs Directories — Structuring Multi-environment Terraform
---

Every non-trivial infrastructure has multiple environments: at least dev and production, often staging, preview, or per-team sandboxes. There are two main approaches to structuring Terraform for multiple environments: workspaces and separate directories. They represent different tradeoffs, and choosing the wrong one creates significant friction.

---

## The Problem

You have infrastructure that needs to exist in three environments: dev, staging, and production. The resources are mostly the same — a VPC, a Kubernetes cluster, some databases — but with different sizes, redundancy settings, and access controls.

How do you manage three versions of the same configuration?

---

## Approach 1: Workspaces

Terraform workspaces give each environment its own state file while sharing the same configuration directory.

```bash
terraform workspace new dev
terraform workspace new staging
terraform workspace new production
terraform workspace select production
terraform apply
```

The `terraform.workspace` value varies the configuration:

```hcl
locals {
  config = {
    dev = {
      instance_type = "t3.micro"
      replica_count = 1
    }
    production = {
      instance_type = "t3.large"
      replica_count = 3
    }
  }
}

resource "aws_db_instance" "main" {
  instance_class    = local.config[terraform.workspace].instance_type
  multi_az          = terraform.workspace == "production"
  ...
}
```

**When workspaces work well**:
- Environments are truly identical except for a few parameters
- The same engineer manages all environments
- You want a single, concise configuration to review

**When workspaces break down**:
- Environments have genuinely different resource structures (production has a CDN, dev doesn't)
- Different teams own different environments
- You want to gate production deploys independently from dev deploys
- The conditional logic proliferates: `var.environment == "production" ? ... : ...` everywhere

---

## Approach 2: Separate Directories

Each environment is a separate Terraform root module with its own state and its own CI/CD pipeline.

```text
terraform/
├── _modules/
│   ├── vpc/
│   └── cluster/
├── dev/
│   ├── main.tf         # calls modules with dev settings
│   └── backend.tf
├── staging/
│   ├── main.tf
│   └── backend.tf
└── production/
    ├── main.tf
    └── backend.tf
```

Each environment directory calls shared modules with environment-specific inputs:

```hcl title="production/main.tf"
module "cluster" {
  source = "../_modules/cluster"

  node_count    = 5
  instance_type = "t3.large"
  multi_az      = true
}
```

```hcl title="dev/main.tf"
module "cluster" {
  source = "../_modules/cluster"

  node_count    = 1
  instance_type = "t3.micro"
  multi_az      = false
}
```

**When separate directories work well**:
- Environments differ meaningfully in structure, not just size
- You want independent state and pipelines per environment
- You need different approval gates (production requires explicit approval, dev auto-applies)
- Multiple teams manage different environments

**Drawback**: when the module interface changes, all environment directories must be updated. The "copy-paste drift" problem — where environments diverge because updates weren't applied consistently — requires discipline.

---

## The Module Layer Is Key

Both approaches work better when the shared logic lives in modules. The directory or workspace is just the "wiring" that calls modules with the right inputs.

Without modules, separate directories lead to duplicated resources that diverge over time. With modules, each directory is thin and expresses only the environment-specific differences.

---

## Recommended Structure

For most teams, **separate directories backed by shared modules** is the cleaner long-term choice:

| Concern | Workspace | Separate Directory |
|---------|-----------|-------------------|
| State isolation | ✓ | ✓ |
| Pipeline isolation | Difficult | Natural |
| Approval gates per env | Difficult | Natural |
| Environment structural differences | Messy | Clean |
| Consistent apply across envs | Easy | Requires discipline |
| Learning curve | Lower | Higher |

Use workspaces for **temporary, short-lived environments** (per-PR preview environments, short-lived test environments) where the overhead of a directory isn't worth it.

Use separate directories for **persistent, long-lived environments** where isolation, independent lifecycle, and differing configurations matter.

---

## Terragrunt: A Third Option

[Terragrunt](https://terragrunt.gruntwork.io) is a thin wrapper around Terraform that adds native support for multi-environment, multi-module configurations — DRY backend configuration, dependency management between stacks, and hooks. It's popular in large-scale Terraform codebases where neither workspaces nor plain directories fully solve the duplication problem.

It adds a tool dependency and a learning curve, but for teams managing dozens of environments across multiple stacks, it can significantly reduce boilerplate.
