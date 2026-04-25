#!/bin/bash
EXTERNAL_IP=$(curl -sf -H "Metadata-Flavor: Google" \
  "http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/?recursive=true" \
  | grep -oP '"externalIp":"\K[^"]+' | head -1)

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable metrics-server --write-kubeconfig-mode 644 --tls-san ${EXTERNAL_IP} --tls-san mazino2d-k3s.duckdns.org" sh -
