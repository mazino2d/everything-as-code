#!/bin/bash
EXTERNAL_IP=$(curl -sf -H "Metadata-Flavor: Google" \
  "http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/?recursive=true" \
  | grep -oP '"externalIp":"\K[^"]+' | head -1)

TLS_SAN_ARGS=""
[ -n "$EXTERNAL_IP" ] && TLS_SAN_ARGS="${TLS_SAN_ARGS} --tls-san ${EXTERNAL_IP}"

DUCKDNS_TOKEN=$(curl -sf -H "Metadata-Flavor: Google" \
  "http://metadata.google.internal/computeMetadata/v1/instance/attributes/duckdns-token")
DUCKDNS_DOMAIN=$(curl -sf -H "Metadata-Flavor: Google" \
  "http://metadata.google.internal/computeMetadata/v1/instance/attributes/duckdns-domain")

if [ -n "$DUCKDNS_TOKEN" ] && [ -n "$DUCKDNS_DOMAIN" ]; then
  result=$(curl -sf "https://www.duckdns.org/update?domains=${DUCKDNS_DOMAIN}&token=${DUCKDNS_TOKEN}&ip=${EXTERNAL_IP}&verbose=true")
  echo "$result" | grep -q '^OK' && echo "DuckDNS updated: ${EXTERNAL_IP}" || echo "DuckDNS update failed: $result"
  TLS_SAN_ARGS="${TLS_SAN_ARGS} --tls-san ${DUCKDNS_DOMAIN}.duckdns.org"
fi

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable metrics-server --write-kubeconfig-mode 644 ${TLS_SAN_ARGS}" sh -
