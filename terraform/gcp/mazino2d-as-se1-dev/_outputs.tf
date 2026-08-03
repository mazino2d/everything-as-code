output "vm_free_ip" {
  description = "Ephemeral public IP of the free-tier VM."
  value       = module.vm-free.ip
}
