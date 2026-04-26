---
date: 2025-04-26
title: HCL Fundamentals — Resources, Variables, Outputs, and Locals
---

HCL (HashiCorp Configuration Language) is Terraform's configuration language. It is not a programming language — there are no loops in the traditional sense, no classes, no functions you define. It is a declarative configuration language with just enough expressiveness to make infrastructure configs DRY and composable.

This post covers the four building blocks you'll use in every Terraform configuration.

---

## Resources

A resource is a declaration that a piece of infrastructure should exist with certain properties.

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.micro"

  tags = {
    Name        = "web-server"
    Environment = "production"
  }
}
```

The resource address (`aws_instance.web`) is how you refer to this resource elsewhere in the configuration. Attributes of the resource are accessed with dot notation: `aws_instance.web.id`, `aws_instance.web.public_ip`.

---

## Variables

Variables are the inputs to a Terraform configuration. They decouple values that change between environments from the structure of the configuration.

```hcl
variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3.micro"
}

variable "allowed_cidrs" {
  type    = list(string)
  default = ["10.0.0.0/8"]
}
```

Variable values are supplied at apply time via:
- `-var="instance_type=t3.large"` (command line)
- A `terraform.tfvars` file (auto-loaded)
- Environment variables (`TF_VAR_instance_type`)
- Terraform Cloud workspace variables

```hcl title="terraform.tfvars"
instance_type = "t3.large"
allowed_cidrs = ["10.0.0.0/8", "172.16.0.0/12"]
```

!!! tip "Type constraints are documentation"
    Always declare a type for your variables. `type = string` vs `type = list(string)` vs `type = object({ ... })` catches configuration errors early and documents the expected shape of the input.

---

## Outputs

Outputs expose values from a Terraform configuration — either for display after `terraform apply` or for use by other configurations (via remote state).

```hcl
output "instance_ip" {
  value       = aws_instance.web.public_ip
  description = "Public IP of the web server"
}

output "db_password" {
  value     = random_password.db.result
  sensitive = true    # masked in terminal output, but stored in state
}
```

Outputs are the interface of a module or a root configuration. Well-designed outputs make it easy to connect configurations together without duplicating resource references.

---

## Locals

Locals are intermediate values computed within the configuration. They reduce duplication and name complex expressions.

```hcl
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  name_prefix = "${var.project_name}-${var.environment}"
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-web"
  })
}
```

Locals are evaluated once and reused. Unlike variables, they are not inputs — they cannot be set from outside the configuration.

---

## Data Sources

Data sources read existing infrastructure that Terraform does not manage. They are the "read-only" counterpart to resources.

```hcl
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]    # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-22.04-amd64-server-*"]
  }
}

resource "aws_instance" "web" {
  ami = data.aws_ami.ubuntu.id    # reference the looked-up AMI ID
  ...
}
```

Data sources are evaluated during the plan phase. They let you reference IDs and attributes of resources created outside your configuration — VPCs created manually, AMIs published by a vendor, DNS zones managed elsewhere.

---

## The Dependency Graph

Terraform automatically determines the order of operations by analysing **references** between resources.

```hcl
resource "aws_vpc" "main" { ... }

resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id    # reference creates an implicit dependency
  ...
}
```

Because `aws_subnet.public` references `aws_vpc.main.id`, Terraform knows the VPC must be created first. This is an **implicit dependency** — no explicit declaration needed.

For cases where there is a dependency that isn't expressed through attribute references, use `depends_on`:

```hcl
resource "aws_instance" "web" {
  ...
  depends_on = [aws_iam_role_policy.web_policy]
}
```

Use `depends_on` sparingly. When it's needed, it's a sign that the dependency is operational (e.g., a policy must exist before a service starts) rather than structural. Document why.

---

## Count and for_each

Two meta-arguments for creating multiple instances of a resource:

```hcl
# count: simple numeric repetition
resource "aws_instance" "web" {
  count = 3
  ami   = data.aws_ami.ubuntu.id
  tags  = { Name = "web-${count.index}" }
}

# for_each: create one resource per map entry
resource "aws_iam_user" "team" {
  for_each = toset(["alice", "bob", "carol"])
  name     = each.value
}
```

Prefer `for_each` over `count` when resources have distinct identities. With `count`, Terraform identifies resources by index — remove the middle element and Terraform wants to destroy and recreate everything after it. With `for_each`, resources are identified by key, so removals are targeted.
