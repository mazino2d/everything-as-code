#!/bin/bash
set -euo pipefail

# Generic startup helper for GCP VMs:
# - Reads external IP from instance metadata
# - Updates DuckDNS record when duckdns-token and duckdns-domain are present
#
# Expected instance metadata keys:
# - duckdns-token
# - duckdns-domain (without .duckdns.org suffix)

METADATA_URL="http://metadata.google.internal/computeMetadata/v1/instance"

EXTERNAL_IP=$(curl -sf -H "Metadata-Flavor: Google" \
  "${METADATA_URL}/network-interfaces/0/?recursive=true" \
  | grep -oP '"externalIp":"\K[^"]+' | head -1 || true)

if [ -z "${EXTERNAL_IP}" ]; then
  echo "No external IP detected; skipping DuckDNS update"
  exit 0
fi

DUCKDNS_TOKEN=$(curl -sf -H "Metadata-Flavor: Google" "${METADATA_URL}/attributes/duckdns-token" || true)
DUCKDNS_DOMAIN=$(curl -sf -H "Metadata-Flavor: Google" "${METADATA_URL}/attributes/duckdns-domain" || true)

if [ -z "${DUCKDNS_TOKEN}" ] || [ -z "${DUCKDNS_DOMAIN}" ]; then
  echo "DuckDNS metadata not configured; skipping update"
  exit 0
fi

result=$(curl -sf "https://www.duckdns.org/update?domains=${DUCKDNS_DOMAIN}&token=${DUCKDNS_TOKEN}&ip=${EXTERNAL_IP}&verbose=true")
if echo "${result}" | grep -q '^OK'; then
  echo "DuckDNS updated: ${DUCKDNS_DOMAIN}.duckdns.org -> ${EXTERNAL_IP}"
else
  echo "DuckDNS update failed: ${result}"
  exit 1
fi
