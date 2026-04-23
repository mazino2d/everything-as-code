#!/bin/bash
set -e

# OCI Ubuntu blocks inbound traffic at OS level by default (unlike GCP)
# Insert rules before the existing REJECT rule
iptables -I INPUT -p tcp --dport 80 -j ACCEPT
iptables -I INPUT -p tcp --dport 443 -j ACCEPT
iptables -I INPUT -p tcp --dport 6443 -j ACCEPT
iptables-save > /etc/iptables/rules.v4

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable servicelb --disable metrics-server --write-kubeconfig-mode 644" sh -
