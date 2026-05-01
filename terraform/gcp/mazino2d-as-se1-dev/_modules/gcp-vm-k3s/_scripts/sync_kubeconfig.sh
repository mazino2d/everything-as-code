#!/bin/bash
set -euo pipefail

# Script to sync K3s kubeconfig from remote VM after recreation
# Extracts certificates from VM and injects into template
# Usage: ./sync_kubeconfig.sh <vm-ip> [ssh-user] [ssh-key-path]
# Example: ./sync_kubeconfig.sh 35.240.123.45 root ~/.ssh/id_ed25519

VM_IP="${1:?VM IP required}"
SSH_USER="${2:-root}"
SSH_KEY="${3:-$HOME/.ssh/id_ed25519}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_FILE="${SCRIPT_DIR}/kubeconfig.template.yaml"
KUBECONFIG_LOCAL="$HOME/.kube/config"
KUBECONFIG_REMOTE="/etc/rancher/k3s/k3s.yaml"
KUBECONFIG_BACKUP="${KUBECONFIG_LOCAL}.backup.$(date +%s)"
DUCKDNS_DOMAIN="mazino2d-k3s.duckdns.org"
SERVER_ENDPOINT="https://${DUCKDNS_DOMAIN}:6443"

if [ ! -f "$TEMPLATE_FILE" ]; then
  echo "❌ Template file not found: $TEMPLATE_FILE"
  exit 1
fi

echo "🔄 Syncing kubeconfig from ${VM_IP}..."

# Backup current kubeconfig
if [ -f "$KUBECONFIG_LOCAL" ]; then
  cp "$KUBECONFIG_LOCAL" "$KUBECONFIG_BACKUP"
  echo "✓ Backed up current kubeconfig to $KUBECONFIG_BACKUP"
else
  mkdir -p "$HOME/.kube"
fi

# Pull full kubeconfig from VM
echo "  Pulling kubeconfig from ${VM_IP}..."
REMOTE_CONFIG=$(ssh -i "$SSH_KEY" -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 \
  "${SSH_USER}@${VM_IP}" "sudo cat ${KUBECONFIG_REMOTE}")

# Extract certificates and keys
CA_CERT=$(echo "$REMOTE_CONFIG" | grep -A 1 "certificate-authority-data:" | tail -1 | xargs)
CLIENT_CERT=$(echo "$REMOTE_CONFIG" | grep -A 1 "client-certificate-data:" | tail -1 | xargs)
CLIENT_KEY=$(echo "$REMOTE_CONFIG" | grep -A 1 "client-key-data:" | tail -1 | xargs)

if [ -z "$CA_CERT" ] || [ -z "$CLIENT_CERT" ] || [ -z "$CLIENT_KEY" ]; then
  echo "❌ Failed to extract certificates from VM kubeconfig"
  exit 1
fi

echo "  Extracting certificates..."
# Replace placeholders in template
cat "$TEMPLATE_FILE" \
  | sed "s|{{CA_CERT}}|${CA_CERT}|g" \
  | sed "s|{{CLIENT_CERT}}|${CLIENT_CERT}|g" \
  | sed "s|{{CLIENT_KEY}}|${CLIENT_KEY}|g" \
  > "$KUBECONFIG_LOCAL"
chmod 600 "$KUBECONFIG_LOCAL"

echo "✓ Kubeconfig updated: $KUBECONFIG_LOCAL"
echo "✓ Server endpoint: ${SERVER_ENDPOINT}"

# Wait for cluster to be ready (retry up to 30 times, 2 seconds each = 60 seconds)
echo "  Waiting for cluster to be ready..."
for i in {1..30}; do
  if kubectl cluster-info &> /dev/null; then
    echo "✓ Successfully synced kubeconfig from ${VM_IP}"
    echo "✓ Cluster is accessible!"
    exit 0
  fi
  echo "  Attempt $i/30: Waiting for cluster..."
  sleep 2
done

echo "⚠ Kubeconfig synced but cluster not ready yet (K3s still initializing)"
echo "  Try again in a moment: kubectl cluster-info"
exit 1
