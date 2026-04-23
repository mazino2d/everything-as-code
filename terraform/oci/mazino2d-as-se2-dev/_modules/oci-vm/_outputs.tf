output "ip" {
  value = oci_core_public_ip.this.ip_address
}

output "ssh_command" {
  value = "ssh ubuntu@${oci_core_public_ip.this.ip_address}"
}
