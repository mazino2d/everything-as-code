# Kubernetes Backup with Velero

This document explains how backup and restore are handled in this repository using Velero.

---

## 1. Current setup in this repository

Velero is deployed from:

- kubernetes/clusters/mazino2d-as-se1-dev/infra/velero

Current design:

- Backup storage: GCS bucket mazino2d-as-se1-dev-velero-backups-usc1
- Credentials source: Infisical Secret path /workload-gsa-keys/gcp-mazino2d-as-se1-dev/infra-velero
- Kubernetes secret consumed by Velero: velero-gcp-credentials in namespace infra
- Credentials key used by Velero: gcp_service_account_json
- Automatic schedules:
  - Daily at 02:00, TTL 7 days
  - Weekly at 03:00 on Sunday, TTL 30 days

Notes:

- Bucket lifecycle in Terraform is set to delete objects older than 30 days.
- Effective retention is therefore bounded by both Velero TTL and bucket lifecycle policy.

---

## 2. Prerequisites for operations

- kubectl context points to the target cluster
- velero CLI installed locally
- Permission to read namespace infra and Velero resources

Quick checks:

    kubectl get pods -n infra -l app.kubernetes.io/name=velero
    kubectl get backupstoragelocation -n infra
    kubectl get schedules -n infra

---

## 3. Trigger an on-demand backup

Create a manual backup for all namespaces:

    velero backup create manual-all-$(date +%Y%m%d%H%M) \
      --include-namespaces '*' \
      --snapshot-volumes

Create a manual backup for one namespace:

    velero backup create manual-apps-$(date +%Y%m%d%H%M) \
      --include-namespaces apps \
      --snapshot-volumes

Watch backup progress:

    velero backup get
    velero backup describe <backup-name> --details
    velero backup logs <backup-name>

---

## 4. Validate scheduled backups

List schedules:

    velero schedule get

Describe schedules in cluster:

    kubectl get schedules -n infra
    kubectl describe schedule velero-velero-daily -n infra
    kubectl describe schedule velero-velero-weekly -n infra

List recent backups and status:

    velero backup get

Recommended health checks:

- New backups are created at expected cron times
- Status is Completed
- Errors and warnings are empty or understood

---

## 5. Restore workflow

Important:

- Always restore into a non-production namespace first where possible.
- Validate workloads and data before production restore.

Create restore from a backup:

    velero restore create --from-backup <backup-name>

Watch restore status:

    velero restore get
    velero restore describe <restore-name> --details
    velero restore logs <restore-name>

Restore one namespace only:

    velero restore create restore-apps-test \
      --from-backup <backup-name> \
      --include-namespaces apps

---

## 6. Credential and secret flow

Credential chain in this repository:

1. GCP stack creates workload GSA key for infra/velero workload.
2. Infisical Terraform syncs that key into project everything-as-code.
3. Infisical operator syncs to Kubernetes secret velero-gcp-credentials.
4. Velero reads GOOGLE_APPLICATION_CREDENTIALS from /credentials/gcp_service_account_json.

Key files:

- terraform/gcp/mazino2d-as-se1-dev/workload_gsa.yaml
- terraform/infisical/workload_gsa_keys.tf
- kubernetes/clusters/mazino2d-as-se1-dev/infra/velero/infisical-secret.yaml
- kubernetes/clusters/mazino2d-as-se1-dev/infra/velero/values.yaml

---

## 7. Troubleshooting

If backups are not created:

- Check Velero pod logs:

      kubectl logs deploy/velero -n infra

- Check schedule objects:

      kubectl get schedules -n infra

- Check backup storage location availability:

      kubectl get backupstoragelocation -n infra -o wide

If backups fail with auth or access errors:

- Ensure secret velero-gcp-credentials exists in namespace infra
- Ensure key gcp_service_account_json exists in that secret
- Ensure GSA has Storage permissions on bucket mazino2d-as-se1-dev-velero-backups-usc1

If restore fails:

- Inspect restore logs and events
- Confirm CRDs and operators required by restored workloads are already present

---

## 8. Operational recommendations

- Run a restore drill at least once per month.
- Keep one documented restore test evidence entry each month.
- Review retention policy against compliance needs.
- Monitor bucket storage growth and backup success trend.
