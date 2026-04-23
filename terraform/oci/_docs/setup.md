# Setup

## 1. Accounts

- OCI: [cloud.oracle.com](https://cloud.oracle.com) (tenancy `mazino2d` already exists)
- HCP Terraform: [app.terraform.io](https://app.terraform.io) (org `mazino2d-everything-as-code` already exists)

---

## 2. Create OCI API Key (one-time, manual)

1. OCI Console → avatar (top-right) → **My profile**
2. Scroll to **API keys** → **Add API key**
3. Select **Generate API key pair** → **Download private key** → save as `oci_api_key.pem`
4. Click **Add** — a **Configuration file preview** popup appears, copy the values:

```
user=ocid1.user.oc1..aaaaa...        ← user_ocid
fingerprint=aa:bb:cc:dd:...          ← fingerprint
tenancy=ocid1.tenancy.oc1..aaaaa...  ← tenancy_ocid
region=ap-singapore-1
```

---

## 3. Terraform Cloud Workspace

Create a new workspace at [app.terraform.io](https://app.terraform.io):

1. **New Workspace** → **API-driven workflow**
2. Name: `oci-<project-id>` (e.g. `oci-mazino2d-as-se2-dev`)
3. **Variables** → add:

| Type      | Key            | Value                              | Sensitive |
|-----------|----------------|------------------------------------|-----------|
| Terraform | `tenancy_ocid` | `ocid1.tenancy.oc1..aaaaa...`      | ✅        |
| Terraform | `user_ocid`    | `ocid1.user.oc1..aaaaa...`         | ✅        |
| Terraform | `fingerprint`  | `aa:bb:cc:dd:...`                  | ✅        |
| Terraform | `private_key`  | contents of `oci_api_key.pem`      | ✅        |
| Terraform | `region`       | `ap-singapore-1`                   | ❌        |
| Terraform | `ssh_public_key` | contents of `~/.ssh/id_rsa.pub`  | ❌        |

> For `private_key`: paste the full PEM content including `-----BEGIN ... KEY-----` headers. Mark as **Sensitive**, **not HCL**.

4. **Settings → General**:
   - Execution Mode: **Remote**
   - Auto-apply API, UI, & VCS runs: **On**

---

## 4. GitHub Actions

Add the new project to the matrix in both workflow files:

- `.github/workflows/tf-plan.yml`
- `.github/workflows/tf-apply.yml`

```yaml
matrix:
  stack:
    - terraform/github
    - terraform/gcp/mazino2d-as-se1-dev
    - terraform/oci/<project-id>   # add this line
```

---

## 5. SSH into the VM

After `terraform apply`, the output `ssh_command` shows the connection string:

```bash
ssh ubuntu@<OCI_IP>   # Ubuntu image — user is "ubuntu", not "debian"
```

Verify K3s is running:

```bash
kubectl get nodes
cat /etc/rancher/k3s/k3s.yaml   # kubeconfig
```
