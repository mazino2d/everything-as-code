output "ip" {
  value = var.enable_static_ip ? google_compute_address.this[0].address : null
}

output "ssh_command" {
  value = var.enable_static_ip ? "ssh user@${google_compute_address.this[0].address}" : null
}
