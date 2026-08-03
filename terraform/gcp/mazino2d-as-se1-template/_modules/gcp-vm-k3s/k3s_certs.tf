# Generate persistent K3s certificates
# These persist across VM recreation and keep kubeconfig stable.

resource "tls_private_key" "k3s_server_ca" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_self_signed_cert" "k3s_server_ca" {
  private_key_pem       = tls_private_key.k3s_server_ca.private_key_pem
  is_ca_certificate     = true
  validity_period_hours = 87600 # 10 years

  allowed_uses = [
    "cert_signing",
    "crl_signing",
    "digital_signature",
    "key_encipherment",
  ]

  subject {
    common_name  = "k3s-server-ca"
    organization = "k3s"
  }
}

resource "tls_private_key" "k3s_client_ca" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_self_signed_cert" "k3s_client_ca" {
  private_key_pem       = tls_private_key.k3s_client_ca.private_key_pem
  is_ca_certificate     = true
  validity_period_hours = 87600 # 10 years

  allowed_uses = [
    "cert_signing",
    "crl_signing",
    "digital_signature",
    "key_encipherment",
  ]

  subject {
    common_name  = "k3s-client-ca"
    organization = "k3s"
  }
}

resource "tls_private_key" "k3s_server" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_cert_request" "k3s_server" {
  private_key_pem = tls_private_key.k3s_server.private_key_pem

  subject {
    common_name  = "mazino2d-k3s.duckdns.org"
    organization = "k3s"
  }
}

resource "tls_locally_signed_cert" "k3s_server" {
  cert_request_pem      = tls_cert_request.k3s_server.cert_request_pem
  ca_private_key_pem    = tls_private_key.k3s_server_ca.private_key_pem
  ca_cert_pem           = tls_self_signed_cert.k3s_server_ca.cert_pem
  validity_period_hours = 87600 # 10 years

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "tls_private_key" "k3s_client" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_cert_request" "k3s_client" {
  private_key_pem = tls_private_key.k3s_client.private_key_pem

  subject {
    common_name  = "k3s-admin"
    organization = "system:masters"
  }
}

resource "tls_locally_signed_cert" "k3s_client" {
  cert_request_pem      = tls_cert_request.k3s_client.cert_request_pem
  ca_private_key_pem    = tls_private_key.k3s_client_ca.private_key_pem
  ca_cert_pem           = tls_self_signed_cert.k3s_client_ca.cert_pem
  validity_period_hours = 87600 # 10 years

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "client_auth",
  ]
}

locals {
  k3s_certs = {
    server_ca_cert = base64encode(tls_self_signed_cert.k3s_server_ca.cert_pem)
    server_ca_key  = base64encode(tls_private_key.k3s_server_ca.private_key_pem)
    client_ca_cert = base64encode(tls_self_signed_cert.k3s_client_ca.cert_pem)
    client_ca_key  = base64encode(tls_private_key.k3s_client_ca.private_key_pem)
    server_key     = base64encode(tls_private_key.k3s_server.private_key_pem)
    server_cert    = base64encode(tls_locally_signed_cert.k3s_server.cert_pem)
    client_key     = base64encode(tls_private_key.k3s_client.private_key_pem)
    client_cert    = base64encode(tls_locally_signed_cert.k3s_client.cert_pem)
  }
}
