#!/bin/bash
EXTERNAL_IP=$(curl -sf -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/externalIp)

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable servicelb --disable metrics-server --write-kubeconfig-mode 644 --tls-san ${EXTERNAL_IP}" sh -
