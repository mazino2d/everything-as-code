output "ip" {
  value = (
    var.external_ip_type == "static"
    ? google_compute_address.this[0].address
    : try(google_compute_instance.this.network_interface[0].access_config[0].nat_ip, null)
  )
}

output "ssh_command" {
  value = (
    var.external_ip_type == "static"
    ? "ssh user@${google_compute_address.this[0].address}"
    : try("ssh user@${google_compute_instance.this.network_interface[0].access_config[0].nat_ip}", null)
  )
}
