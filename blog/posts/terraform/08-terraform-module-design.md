---
date: 2025-04-26
title: Module Design — What Makes a Good Terraform Module
---

Writing a module that works is easy. Writing one that is maintainable, composable, and safe to use across a team is harder. Good module design is mostly about choosing the right level of abstraction and designing a stable, minimal interface.

---

## The Purpose of a Module

A module should encapsulate a **pattern**, not just a resource. If you're writing a module for a single `aws_s3_bucket`, ask whether the module adds anything beyond what the resource itself provides. The answer might be yes (you enforce encryption, versioning, and access logging as defaults) — or it might be that a module adds complexity without benefit.

A useful heuristic: a module should create at least 2–3 related resources. One-resource modules are usually wrapping a resource to enforce defaults, which is a valid use case — but it's different from encapsulating a multi-resource pattern.

---

## The Interface Is the Contract

A module's variables (inputs) and outputs are its contract with callers. Changes to this interface are breaking changes for anything that uses the module.

Design principles for the interface:

**Minimal inputs**: expose only what callers genuinely need to vary. Hide implementation decisions inside the module. If every caller would pass the same value, make it a local or a default.

**Typed inputs with validation**: use specific types and validation rules to catch errors at plan time rather than apply time.

```hcl
variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Must be dev, staging, or production."
  }
}
```

**Expressive outputs**: expose what callers actually need. Resource IDs are almost always needed. ARNs, DNS names, and connection strings often are. Internal implementation details (e.g., the name of a security group that callers shouldn't reference directly) should not be exposed.

---

## Sensible Defaults

Modules should be usable with minimal configuration. Production-safe settings should be the default; less-safe settings should require explicit opt-in.

```hcl
variable "enable_versioning" {
  type    = bool
  default = true    # safe default: versioning on
}

variable "enable_deletion_protection" {
  type    = bool
  default = true    # safe default: accidental deletion blocked
}

variable "force_destroy" {
  type    = bool
  default = false   # destructive: must opt in explicitly
}
```

The inverse — making `force_destroy = true` the default — would mean a caller who doesn't read the documentation could inadvertently destroy their data.

---

## Avoid Over-generalisation

A module that accepts 40 variables to support every possible combination of features is not a module — it's a configuration language embedded inside a configuration language.

Signs of over-generalisation:
- Most variables have complicated conditional logic in the resources
- Callers need to understand the module's internals to use it correctly
- Adding a new feature requires touching every caller

When a module becomes too complex, split it. A networking module might become a VPC module and a subnets module. Each is simpler, and callers compose them.

---

## Resource Naming Conventions

Resources inside a module should use predictable, consistent naming. The `name_prefix` or `name` variable pattern gives callers control while ensuring uniqueness:

```hcl
variable "name" {
  type        = string
  description = "Base name for all resources in this module"
}

resource "aws_security_group" "this" {
  name = "${var.name}-sg"
  ...
}

resource "aws_iam_role" "this" {
  name = "${var.name}-role"
  ...
}
```

This makes resources in the cloud traceable back to the Terraform call: `prod-api-sg`, `prod-api-role`.

---

## Module Documentation

Every module should have a `README.md` that describes:
- What the module creates
- All input variables with their types, defaults, and descriptions
- All outputs
- A minimal usage example

Tools like `terraform-docs` generate this automatically from variable and output definitions:

```bash
terraform-docs markdown . > README.md
```

Treat module documentation as part of the module interface. Without it, callers must read the source to understand how to use the module.

---

## Testing Modules

Modules can be tested with tools like **Terratest** (Go-based) or **terraform test** (native, added in Terraform 1.6).

```hcl title="tests/basic.tftest.hcl"
run "creates_vpc" {
  command = plan

  assert {
    condition     = aws_vpc.this.cidr_block == "10.0.0.0/16"
    error_message = "VPC CIDR block is incorrect"
  }
}
```

Tests verify that the module produces the expected plan and, when run against a real environment, creates resources with the expected attributes. For shared, widely-used modules, testing is not optional.
