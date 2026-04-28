---
date: 2025-04-26
title: State — Terraform's Source of Truth
---

State is the most important concept in Terraform — and the most common source of confusion and mistakes. Understanding what state is, what it contains, and what happens when it diverges from reality is essential for operating Terraform safely.

---

## What State Stores

The state file (`terraform.tfstate`) is a JSON document that maps your configuration to real-world resources.

For every managed resource, state stores:
- The resource type and name (e.g., `aws_instance.web`)
- The ID Terraform uses to refer to it in the cloud (e.g., `i-0abc123def456`)
- All attributes of the resource as last seen by Terraform
- Metadata for tracking dependencies

```json
{
  "resources": [
    {
      "type": "aws_instance",
      "name": "web",
      "instances": [
        {
          "attributes": {
            "id": "i-0abc123def456",
            "instance_type": "t3.micro",
            "public_ip": "54.12.34.56",
            ...
          }
        }
      ]
    }
  ]
}
```

State is not a snapshot of the cloud. It is Terraform's **last known state** — what Terraform believed to be true after the last apply.

---

## Why State Is Necessary

Two resources can have identical configurations but be completely different infrastructure objects. State is the only way Terraform knows which real resource corresponds to which configuration block.

Without state, Terraform would have to scan all resources in your cloud account on every plan, match them heuristically to your configuration, and hope for the best. Instead, state gives Terraform exact IDs, making plans fast, deterministic, and safe.

---

## The State File Is Sensitive

The state file often contains sensitive values — database passwords, private keys, API tokens — in plaintext. The state file for a non-trivial infrastructure can be considered a security credential.

Implications:
- **Never commit state to git.** Add `*.tfstate` and `*.tfstate.backup` to `.gitignore`.
- **Restrict access** to state storage (S3 bucket policies, Terraform Cloud access controls).
- **Enable encryption at rest** on your state backend.

Local state (`terraform.tfstate` in the working directory) is fine for learning but unacceptable for any shared or production use. Use a remote backend.

---

## State Drift

**Drift** is the difference between what state says and what actually exists in the cloud.

Causes of drift:
- A resource was modified directly in the cloud console
- A resource was deleted manually
- An external process updated a resource's attribute
- A previous apply partially succeeded and left state inconsistent

Terraform detects drift during the refresh step (run before every plan). When drift is detected, the plan will show changes needed to bring the real world back into alignment with your configuration.

```bash
terraform plan -refresh-only    # see what drift exists without applying
terraform apply -refresh-only   # update state to match real world (no resource changes)
```

`refresh-only` is your friend for understanding drift before deciding how to respond to it.

---

## State and Collaboration

Two engineers running `terraform apply` simultaneously on the same state file will corrupt it. Engineer A reads state, Engineer B reads state, both compute a plan, both apply — the second apply overwrites the first's state changes.

**State locking** prevents this. Remote backends (S3+DynamoDB, Terraform Cloud, GCS) implement locking: a lock is acquired before any operation that modifies state, and released when the operation completes. The second `terraform apply` waits (or fails if the lock has been held too long).

This is why remote backends are a prerequisite for team use.

---

## The State Backend

The backend determines where state is stored and how locking is handled.

```hcl
terraform {
  backend "s3" {
    bucket         = "my-tf-state"
    key            = "production/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

Common backend options:

| Backend | Lock mechanism | Notes |
|---------|---------------|-------|
| S3 + DynamoDB | DynamoDB conditional writes | AWS-native, widely used |
| GCS | Object locking | GCP-native |
| Terraform Cloud | Built-in | Managed service, includes UI and policy |
| Azure Blob | Lease | Azure-native |

The backend configuration is not versioned the same way as the rest of the configuration — changing it requires `terraform init -migrate-state`.

---

## State Is Not a Deployment Record

A common misconception: the state file tells you what is deployed and when. It does not. State tells you what Terraform last created/managed and the current attributes of those resources. It has no history, no timestamps for individual resources, and no record of who made changes.

For deployment history, use your CI/CD pipeline logs, git history, and cloud provider audit logs (CloudTrail, GCP Audit Logs). State is a mechanism, not a ledger.
