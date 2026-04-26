---
date: 2025-04-26
title: Managing Secrets in Terraform — The Sensitive Data Problem
---

Terraform needs credentials to provision infrastructure. The infrastructure it creates often generates new credentials. And both kinds of secrets are, at some point, written to the state file. This post covers the problem space and the practical approaches for handling secrets in Terraform without compromising security.

---

## The Fundamental Tension

Terraform is designed for version-controlled, collaborative, reviewable code. Secrets are the opposite: they should not be in version control, should not be visible in logs, and should be accessible only to authorised principals.

These properties are in tension. Resolving the tension requires separating *what Terraform does* from *how secrets flow into it*.

---

## Provider Credentials

Terraform needs credentials to call cloud APIs. The rule here is simple: **never put credentials in `.tf` files**.

The right approaches, in order of preference:

**Environment variables**: most providers read credentials from standard env vars.
```bash
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
terraform apply
```

**Instance/workload identity**: when Terraform runs in CI/CD, use the platform's native identity. AWS CodeBuild has an IAM role; GitHub Actions has OIDC federation; GCP Cloud Build has a service account. No static credentials needed.

**Short-lived tokens**: generate a token at the start of the pipeline run, set it as an env var, and let it expire after the run. This limits the window for credential abuse.

```yaml title="GitHub Actions with AWS OIDC"
- uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::123456789:role/terraform-ci
    aws-region: us-east-1
# No static credentials — GitHub provides a JWT that AWS exchanges for a role session
```

**Never**: static credentials in `provider {}` blocks, in `.tfvars` files committed to git, or in environment variables that are logged by CI.

---

## Input Variables for Secrets

When a Terraform configuration needs a secret as input (a database password, an API key), use a variable marked `sensitive`:

```hcl
variable "db_password" {
  type      = string
  sensitive = true    # masked in plan/apply output
}
```

Supplying the value:
- Terraform Cloud workspace variables (marked as sensitive — not stored in logs or UI)
- Environment variable: `TF_VAR_db_password=...`
- A secrets manager read at pipeline start time, injected as an env var

**Never** supply sensitive variables via a committed `.tfvars` file.

---

## Secrets in State

This is where things get complicated. When Terraform creates a resource that generates a credential — an IAM access key, a database password, a random secret — that value ends up in state.

```hcl
resource "aws_iam_access_key" "ci" {
  user = aws_iam_user.ci.name
}

output "ci_secret_key" {
  value     = aws_iam_access_key.ci.secret
  sensitive = true
}
```

The `sensitive = true` on the output masks the value in CLI output. But it is still stored in plaintext in the state file.

Mitigations:
- **Encrypt state at rest**: all major remote backends support this. Enable it.
- **Restrict state access**: use IAM policies, Terraform Cloud access controls, or GCS bucket IAM to limit who can read state.
- **Avoid storing secrets in state when possible**: use data sources to look up secrets from a secrets manager rather than creating them with Terraform.

---

## Prefer Lookup Over Creation

When possible, store secrets in a secrets manager and have Terraform look them up rather than generate them:

```hcl
# Less ideal: Terraform creates the secret, stores it in state
resource "random_password" "db" {
  length = 32
}

# Better: secret exists in the secrets manager; Terraform reads it
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "production/database/password"
}
```

In the second pattern, the secret is never stored in Terraform state. It exists only in Secrets Manager, with its own access controls, rotation, and audit log.

---

## The External Secrets Pattern

For Kubernetes workloads, the External Secrets Operator (ESO) syncs secrets from an external secrets manager (Vault, AWS Secrets Manager, GCP Secret Manager) into Kubernetes Secrets. Terraform provisions the IAM roles and policies that grant ESO access; the actual secret values never pass through Terraform.

This pattern cleanly separates concerns:
- Terraform manages infrastructure and access policies
- The secrets manager manages secret values
- ESO bridges the two at runtime

---

## Summary: The Safe Path

1. Use workload identity or environment variables for provider credentials — never static credentials in code
2. Mark all secret variables as `sensitive = true`
3. Encrypt state at rest and restrict access to state storage
4. Prefer looking up secrets from a secrets manager over generating them in Terraform
5. Audit state file access as you would audit a credential store

The state file is a credential. Treat it accordingly.
