output "ip" {
  value = google_compute_address.this.address
}

output "ssh_command" {
  value = "ssh user@${google_compute_address.this.address}"
}
