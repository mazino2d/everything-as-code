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
  ssh_public_key   = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDFN11kywcyrDb/iiguUkDGFAgGTqvzVmsIG7Fv4+HYHLuPZGKsCrTv9L7BD5BLeZ6wlZDvWwkHEGW7+RzMC235y8gvkZIEfx1Wz3rOMhqmw4lc1miCVTX8pXL5ypyTjSWaMvcRaOczV8ewg+sgvHazEuy/i/t42NmVrZx3je9qI09FsHetF42zCbIf+2FpxG8OZfGUi6GfuKDi4pztO+wHfKpcoDZOzVKG3ZHHimXu342Zgbb2sFxx69qpxt+ntcGdFiEiE6U4nhCetL7xX7PEiyOs8Yr0XS41DTSsvR3Ejx1BWPfe/k42Bu2G2yqM2G3iPtqo4X1glDQpAQlIdRzZ ddkhoa@ddkhoa"
  tags             = ["free"]
  duckdns_domain   = "mazino2d-free"
  startup_script   = file("${path.module}/_scripts/fortune_server.sh")
}
