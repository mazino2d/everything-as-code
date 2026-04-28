---
date: 2025-04-26
title: Remote State and Backends — Team-safe Terraform
---

Local state works for solo experimentation. The moment two people run `terraform apply`, or you need consistent state between CI/CD and local machines, you need a remote backend. Remote backends are also the mechanism by which independent Terraform configurations can share data.

---

## Why Remote State

Three problems with local state that remote backends solve:

**Concurrent modification**: two applies on the same local state file will corrupt it. Remote backends implement distributed locking.

**Accessibility**: local state lives on your machine. Your CI/CD pipeline, your teammates, and your disaster recovery process can't reach it. Remote backends store state in a shared, accessible location.

**Security**: a local state file containing database passwords is an unencrypted file sitting on someone's laptop. Remote backends support encryption at rest and access controls.

---

## Terraform Cloud as a Backend

Terraform Cloud is the simplest remote backend for most teams — it handles storage, locking, and encryption without managing separate infrastructure.

```hcl
terraform {
  cloud {
    organization = "my-org"
    workspaces {
      name = "production"
    }
  }
}
```

Beyond state storage, Terraform Cloud adds:
- **VCS-driven runs**: connects to a git repo and plans/applies automatically on push
- **Policy as code**: enforce rules before apply (e.g., "no instances larger than t3.medium in dev")
- **Audit logging**: who ran what, when, and what changed
- **Team access controls**: who can plan vs. apply vs. manage variables

The free tier supports unlimited state storage and single-user workspaces. For teams, the paid tier adds RBAC and policy enforcement.

---

## S3 + DynamoDB (AWS)

The standard self-managed backend for AWS users:

```hcl
terraform {
  backend "s3" {
    bucket         = "my-tfstate-bucket"
    key            = "services/api/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
    kms_key_id     = "arn:aws:kms:..."    # optional CMK for encryption
  }
}
```

The S3 bucket stores the state file; the DynamoDB table implements locking. Best practice for the bucket:
- Versioning enabled (natural state history and rollback)
- Public access blocked
- Server-side encryption with KMS
- Bucket policy limiting access to specific IAM roles

---

## Sharing State Between Configurations

Large infrastructures are split into multiple Terraform configurations (stacks): one for networking, one for databases, one for applications. These configurations need to reference each other's outputs.

The `terraform_remote_state` data source reads outputs from another configuration's state:

```hcl
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "my-tfstate-bucket"
    key    = "core/network/terraform.tfstate"
    region = "us-east-1"
  }
}

resource "aws_instance" "app" {
  subnet_id = data.terraform_remote_state.network.outputs.private_subnet_id
  ...
}
```

The `app` configuration doesn't manage the VPC or subnets — it just reads the output from the configuration that does. This is the standard pattern for sharing values across Terraform boundaries.

!!! note "Tight coupling via remote state"
    `terraform_remote_state` creates a read dependency between configurations. If the network configuration changes its output names or structure, the app configuration breaks. Design outputs as a stable interface — version them if needed, and avoid leaking internal implementation details.

---

## Workspaces and State Isolation

Each Terraform workspace has its own state file. Workspaces let you manage multiple environments (dev, staging, production) from the same configuration directory:

```bash
terraform workspace new staging
terraform workspace select production
terraform workspace list
```

When using workspaces, the `terraform.workspace` value can be used to vary configuration:

```hcl
locals {
  instance_type = terraform.workspace == "production" ? "t3.medium" : "t3.micro"
}
```

However, workspaces have limitations — they share the same provider configuration and variable definitions, just with different state. For environments with significantly different configurations, separate directories are often cleaner (covered in the [next chapter](10-terraform-workspaces-directories.md)).

---

## Backend Migration

Moving state from one backend to another is safe:

```bash
# Change the backend configuration in main.tf
# then:
terraform init -migrate-state
```

Terraform prompts you to confirm, copies the state to the new backend, and removes it from the old location. The migration is atomic — if it fails, the original state is preserved.

This is how you graduate from local state to a remote backend: change the backend block, run `init -migrate-state`, done.
