#!/bin/bash
set -euo pipefail

# Generic startup wrapper for GCP VMs.
# 1) Updates DuckDNS when metadata is configured.
# 2) Executes a custom startup script from metadata key: user-startup-script-b64.
#
# Expected instance metadata keys:
# - duckdns-token
# - duckdns-domain (without .duckdns.org suffix)
# - user-startup-script-b64 (optional, base64 encoded script content)

METADATA_URL="http://metadata.google.internal/computeMetadata/v1/instance"
METADATA_HEADER="Metadata-Flavor: Google"

get_metadata_attr() {
  local key="$1"
  curl -sf -H "$METADATA_HEADER" "${METADATA_URL}/attributes/${key}" || true
}

update_duckdns() {
  local external_ip
  local duckdns_token
  local duckdns_domain
  local result

  external_ip=$(curl -sf -H "$METADATA_HEADER" \
    "${METADATA_URL}/network-interfaces/0/?recursive=true" \
    | grep -oP '"externalIp":"\K[^"]+' | head -1 || true)

  if [ -z "$external_ip" ]; then
    echo "No external IP detected; skipping DuckDNS update"
    return 0
  fi

  duckdns_token=$(get_metadata_attr "duckdns-token")
  duckdns_domain=$(get_metadata_attr "duckdns-domain")

  if [ -z "$duckdns_token" ] || [ -z "$duckdns_domain" ]; then
    echo "DuckDNS metadata not configured; skipping update"
    return 0
  fi

  result=$(curl -sf "https://www.duckdns.org/update?domains=${duckdns_domain}&token=${duckdns_token}&ip=${external_ip}&verbose=true")

  if echo "$result" | grep -q '^OK'; then
    echo "DuckDNS updated: ${duckdns_domain}.duckdns.org -> ${external_ip}"
    return 0
  fi

  echo "DuckDNS update failed: ${result}"
  return 1
}

run_user_startup_script() {
  local startup_script_b64
  local script_file

  startup_script_b64=$(get_metadata_attr "user-startup-script-b64")

  if [ -z "$startup_script_b64" ]; then
    echo "No user-startup-script-b64 metadata found; nothing else to run"
    return 0
  fi

  script_file="$(mktemp /tmp/user-startup.XXXXXX.sh)"
  echo "$startup_script_b64" | base64 -d > "$script_file"
  chmod +x "$script_file"

  echo "Executing user startup script from metadata"
  bash "$script_file"
}

update_duckdns
run_user_startup_script
