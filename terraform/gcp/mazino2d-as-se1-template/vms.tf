module "vm-free" {
  source           = "./_modules/gcp-vm"
  name             = "vm-free"
  project_id       = module.project.project_id
  zone             = "us-central1-a"
  machine_type     = "e2-micro"
  disk_size_gb     = 30
  spot             = false
  external_ip_type = "ephemeral"
  extra_ports      = ["80"]
  ssh_public_key   = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHqUrfB0oPmolyXRYtA9kHDWYy5D2GhhaGb9odfQYvAu"
  tags             = ["free"]
  duckdns_domain   = "mazino2d-free"
  startup_script   = file("${path.module}/_scripts/fortune_server.sh")
}
