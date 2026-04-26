---
date: 2025-04-26
title: The Provider Model — One Tool, Every API
---

Terraform itself does not know anything about AWS, GCP, GitHub, Datadog, or Kubernetes. It is a generic engine for resource lifecycle management. **Providers** are the plugins that translate Terraform's resource model into real API calls.

This is the architecture that lets a single tool manage cloud infrastructure, DNS records, GitHub repositories, database users, and Slack channels with the same workflow.

---

## What a Provider Is

A provider is a binary plugin that:

1. Declares the **resources** it manages (e.g., `aws_instance`, `github_repository`)
2. Implements **CRUD operations** for each resource (create, read, update, delete)
3. Handles **authentication** with the underlying API

When you run `terraform init`, Terraform downloads the required providers from the Terraform Registry and stores them in `.terraform/`. They are versioned, cryptographically verified, and pinned in `.terraform.lock.hcl`.

---

## Declaring Providers

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

provider "github" {
  owner = "my-org"
  token = var.github_token
}
```

The `terraform` block pins provider versions. The `provider` block configures them. You can have multiple configurations of the same provider (e.g., two AWS providers for different regions) using provider aliases.

---

## The Resource Abstraction

Every resource follows the same interface regardless of provider:

```hcl
resource "<provider>_<type>" "<local_name>" {
  # configuration attributes
}
```

The provider handles everything below this interface: which API endpoint to call, how to parse the response, what to do on update vs. replace. From Terraform's perspective, an `aws_instance` and a `github_repository` are both just "resources" — they have attributes, they can be created and destroyed, and their state is tracked.

This uniformity means the Terraform workflow (init → plan → apply) works identically across all providers.

---

## The Terraform Registry

The [Terraform Registry](https://registry.terraform.io) is the central hub for providers and modules. The breadth of available providers is one of Terraform's most significant advantages:

- **Cloud**: AWS, GCP, Azure, DigitalOcean, Oracle
- **SaaS APIs**: GitHub, GitLab, Datadog, PagerDuty, Cloudflare, Fastly
- **Databases**: PostgreSQL, MySQL, MongoDB Atlas, Snowflake
- **Security**: HashiCorp Vault, AWS IAM, OPA
- **Kubernetes**: manages Kubernetes resources directly from Terraform
- **Internal**: any team can write a custom provider for internal APIs

This means the principle of *Everything as Code* can extend to your entire operational stack — not just cloud VMs, but DNS records, monitoring alerts, GitHub settings, and user access controls.

---

## Provider vs. Resource vs. Data Source

Three distinct concepts within a provider:

**Resource**: manages the lifecycle of an infrastructure object.
```hcl
resource "aws_s3_bucket" "assets" { ... }  # creates and manages a bucket
```

**Data source**: reads existing infrastructure without managing it. Useful for referencing resources created outside Terraform, or resources managed by a different Terraform configuration.
```hcl
data "aws_vpc" "main" {
  default = true    # look up the default VPC, don't create it
}
```

**Output**: exposes values from a configuration for use by other configurations or for display.
```hcl
output "vpc_id" {
  value = data.aws_vpc.main.id
}
```

---

## Provider Versioning

Provider versions follow semantic versioning. The `~> 5.0` constraint means "5.x but not 6.0" — accept patch and minor updates, but not breaking major version changes.

The `.terraform.lock.hcl` file records the exact version and checksum used. Commit this file. It ensures that everyone on the team (and CI/CD) uses exactly the same provider version, preventing subtle behaviour differences between environments.

```hcl title=".terraform.lock.hcl"
provider "registry.terraform.io/hashicorp/aws" {
  version     = "5.31.0"
  constraints = "~> 5.0"
  hashes = [
    "h1:...",
  ]
}
```

---

## Providers Are Not Magic

Providers are limited to what the underlying API supports. If the API is eventually consistent, Terraform may see a resource as created before it's actually ready. If the API doesn't support updates to a field, Terraform must destroy and recreate the resource.

Understanding your provider's limitations — what's immutable, what triggers a replace, what the API rate limits are — is as important as understanding Terraform itself.
