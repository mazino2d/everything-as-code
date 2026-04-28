---
date: 2025-04-26
title: Modules — The Unit of Reuse in Terraform
---

At some point, you'll find yourself writing the same VPC, the same ECS service pattern, or the same S3-with-CloudFront setup for the third time. Modules are how you encapsulate that pattern into a reusable component — called once with different inputs to produce different (but consistently structured) infrastructure.

---

## What a Module Is

Every Terraform configuration is technically a module. The "root module" is the directory where you run `terraform apply`. A "child module" is any directory called with a `module` block.

```hcl
module "network" {
  source = "./modules/vpc"

  cidr_block       = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]
}
```

Terraform downloads (or reads) the module, passes the given inputs, and creates the resources defined inside it. The module's internals are opaque to the caller — you see what it outputs, not what it creates internally.

---

## Module Sources

Modules can be sourced from multiple locations:

```hcl
# Local directory
source = "./modules/vpc"

# Terraform Registry (public module)
source = "terraform-aws-modules/vpc/aws"
version = "5.0.0"

# Private registry
source = "app.terraform.io/my-org/vpc/aws"

# Git repository
source = "git::https://github.com/my-org/terraform-modules.git//vpc?ref=v2.1.0"

# S3 bucket
source = "s3::https://s3.amazonaws.com/my-modules/vpc.zip"
```

Use version pinning for any external module. An unpinned module source means the next `terraform init` might pull a breaking change.

---

## Module Inputs and Outputs

A module's interface consists of its variables (inputs) and outputs.

```hcl title="modules/vpc/variables.tf"
variable "cidr_block" {
  type        = string
  description = "The CIDR block for the VPC"
}

variable "name" {
  type    = string
}
```

```hcl title="modules/vpc/outputs.tf"
output "vpc_id" {
  value = aws_vpc.this.id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}
```

The caller uses module outputs with `module.<name>.<output>`:

```hcl
resource "aws_instance" "web" {
  subnet_id = module.network.private_subnet_ids[0]
}
```

The module's resources — `aws_vpc.this`, `aws_subnet.private`, etc. — are invisible to the caller. Only outputs are exposed. This encapsulation is intentional: the caller doesn't need to know how the VPC is built, only what it produces.

---

## Module Registry: Don't Reinvent

The [Terraform Registry](https://registry.terraform.io/browse/modules) has high-quality, battle-tested modules for common patterns:

- `terraform-aws-modules/vpc/aws` — production-grade VPC with public/private subnets, NAT gateways, routing
- `terraform-aws-modules/eks/aws` — EKS cluster with managed node groups
- `terraform-google-modules/network/google` — GCP VPC with subnets and secondary ranges

These modules encode years of operational knowledge. For standard infrastructure components (VPCs, Kubernetes clusters, databases), using a registry module is usually better than writing your own.

Write custom modules when:
- Your organisation has specific conventions that registry modules don't follow
- You're wrapping a provider resource to enforce defaults (e.g., "all S3 buckets must have versioning and encryption")
- You have a complex multi-resource pattern used repeatedly across your infrastructure

---

## Module Composition

Modules can call other modules, building a tree of dependencies:

```text
root
├── module "network" (./modules/vpc)
│     └── module "subnets" (./modules/subnets)
├── module "cluster" (./modules/eks)
│     └── [uses module.network.vpc_id]
└── module "apps" (./modules/apps)
      └── [uses module.cluster.cluster_endpoint]
```

The composition pattern is the foundation of large-scale Terraform organisation. Each module is independently testable and reusable. Root configurations wire modules together.

---

## Module Versions and Stability

Modules published to a registry should follow semantic versioning:

- **Patch** (1.0.0 → 1.0.1): bug fix, no interface change
- **Minor** (1.0.0 → 1.1.0): new optional variable, backwards compatible
- **Major** (1.0.0 → 2.0.0): breaking change to interface or behaviour

In your module's `README` or `CHANGELOG`, document what each version changes. Callers pin to a minimum version (`>= 1.1.0`) or a range (`~> 1.1`), and can upgrade deliberately rather than accidentally.
