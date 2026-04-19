locals {
  region = join("-", slice(split("-", var.zone), 0, 2))
}

resource "google_compute_address" "this" {
  name    = "${var.name}-ip"
  region  = local.region
  project = var.project_id
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.name}-allow-ssh"
  network = "default"
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["${var.name}-ssh"]
}

resource "google_compute_firewall" "extra_ports" {
  count   = length(var.extra_ports) > 0 ? 1 : 0
  name    = "${var.name}-allow-extra"
  network = "default"
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = var.extra_ports
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["${var.name}-ssh"]
}

resource "google_compute_instance" "this" {
  name         = var.name
  machine_type = var.machine_type
  zone         = var.zone
  project      = var.project_id
  tags         = concat(["${var.name}-ssh"], var.tags)

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = var.disk_size_gb
      type  = "pd-standard"
    }
  }

  network_interface {
    network = "default"

    access_config {
      nat_ip = google_compute_address.this.address
    }
  }

  metadata = {
    ssh-keys               = var.ssh_public_key != null ? "user:${var.ssh_public_key}" : null
    block-project-ssh-keys = "true"
    startup-script         = var.startup_script
  }

  lifecycle {
    prevent_destroy = false
  }
}
