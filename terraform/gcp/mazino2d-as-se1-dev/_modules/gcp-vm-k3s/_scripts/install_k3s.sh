#!/bin/bash
set -eo pipefail

METADATA_URL="http://metadata.google.internal/computeMetadata/v1/instance"

# Get external IP for TLS SANs
EXTERNAL_IP=$(curl -sf -H "Metadata-Flavor: Google" \
  "${METADATA_URL}/network-interfaces/0/?recursive=true" \
  | grep -oP '"externalIp":"\K[^"]+' | head -1)

TLS_SAN_ARGS=""
[ -n "$EXTERNAL_IP" ] && TLS_SAN_ARGS="${TLS_SAN_ARGS} --tls-san ${EXTERNAL_IP}"

DUCKDNS_DOMAIN=$(curl -sf -H "Metadata-Flavor: Google" "${METADATA_URL}/attributes/duckdns-domain" || echo "")

if [ -n "$DUCKDNS_DOMAIN" ]; then
  TLS_SAN_ARGS="${TLS_SAN_ARGS} --tls-san ${DUCKDNS_DOMAIN}.duckdns.org"
fi

# Setup persistent K3s certificates if provided via metadata
K3S_SERVER_CERT_B64=$(curl -sf -H "Metadata-Flavor: Google" "${METADATA_URL}/attributes/k3s-server-cert-b64" || echo "")
K3S_SERVER_KEY_B64=$(curl -sf -H "Metadata-Flavor: Google" "${METADATA_URL}/attributes/k3s-server-key-b64" || echo "")
K3S_CA_CERT_B64=$(curl -sf -H "Metadata-Flavor: Google" "${METADATA_URL}/attributes/k3s-ca-cert-b64" || echo "")
K3S_CA_KEY_B64=$(curl -sf -H "Metadata-Flavor: Google" "${METADATA_URL}/attributes/k3s-ca-key-b64" || echo "")
K3S_CLIENT_CA_CERT_B64=$(curl -sf -H "Metadata-Flavor: Google" "${METADATA_URL}/attributes/k3s-client-ca-cert-b64" || echo "")
K3S_CLIENT_CA_KEY_B64=$(curl -sf -H "Metadata-Flavor: Google" "${METADATA_URL}/attributes/k3s-client-ca-key-b64" || echo "")

if [ -n "$K3S_SERVER_CERT_B64" ] && [ -n "$K3S_SERVER_KEY_B64" ] && [ -n "$K3S_CA_CERT_B64" ] && [ -n "$K3S_CA_KEY_B64" ] && [ -n "$K3S_CLIENT_CA_CERT_B64" ] && [ -n "$K3S_CLIENT_CA_KEY_B64" ]; then
  if [ -f /var/lib/rancher/k3s/server/db/state.db ]; then
    echo "K3s datastore already exists; skipping certificate seeding to avoid CA drift"
  else
    echo "Setting up persistent K3s certificates..."

    # Create K3s directories
    mkdir -p /var/lib/rancher/k3s/server/tls

    # Decode and place certificates during first cluster bootstrap only.
    echo "$K3S_CA_CERT_B64" | base64 -d > /var/lib/rancher/k3s/server/tls/server-ca.crt
    echo "$K3S_CA_KEY_B64" | base64 -d > /var/lib/rancher/k3s/server/tls/server-ca.key
    echo "$K3S_CLIENT_CA_CERT_B64" | base64 -d > /var/lib/rancher/k3s/server/tls/client-ca.crt
    echo "$K3S_CLIENT_CA_KEY_B64" | base64 -d > /var/lib/rancher/k3s/server/tls/client-ca.key
    echo "$K3S_SERVER_CERT_B64" | base64 -d > /var/lib/rancher/k3s/server/tls/server.crt
    echo "$K3S_SERVER_KEY_B64" | base64 -d > /var/lib/rancher/k3s/server/tls/server.key

    # Set proper permissions
    chmod 600 /var/lib/rancher/k3s/server/tls/*.key
    chmod 644 /var/lib/rancher/k3s/server/tls/*.crt

    echo "Persistent certificates installed"
  fi
else
  echo "No persistent certificates provided - K3s will generate new ones"
fi

# Install K3s
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable metrics-server --write-kubeconfig-mode 644 ${TLS_SAN_ARGS}" sh -
