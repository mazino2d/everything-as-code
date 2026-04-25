locals {
  region = join("-", slice(split("-", var.zone), 0, 2))
}

resource "terraform_data" "duckdns" {
  count            = var.duckdns_domain != null ? 1 : 0
  triggers_replace = [google_compute_address.this[0].address]

  provisioner "local-exec" {
    command = <<-EOT
      result=$(curl -sf "https://www.duckdns.org/update?domains=${var.duckdns_domain}&token=$DUCKDNS_TOKEN&ip=${google_compute_address.this[0].address}&verbose=true")
      echo "$result"
      echo "$result" | grep -q '^OK'
    EOT
  }
}


resource "google_compute_address" "this" {
  count   = var.enable_static_ip ? 1 : 0
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

    dynamic "access_config" {
      for_each = var.enable_static_ip ? [1] : []
      content {
        nat_ip = google_compute_address.this[0].address
      }
    }
  }

  metadata = {
    ssh-keys               = var.ssh_public_key != null ? "user:${var.ssh_public_key}" : null
    block-project-ssh-keys = "true"
    startup-script         = var.startup_script
  }

  scheduling {
    preemptible                 = var.spot
    automatic_restart           = var.spot ? false : true
    on_host_maintenance         = var.spot ? "TERMINATE" : "MIGRATE"
    provisioning_model          = var.spot ? "SPOT" : "STANDARD"
    instance_termination_action = var.spot ? "STOP" : null
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "google_compute_firewall" "deny_egress_internet" {
  count     = var.enable_internet ? 0 : 1
  name      = "${var.name}-deny-egress-internet"
  network   = "default"
  project   = var.project_id
  direction = "EGRESS"
  priority  = 1000

  deny {
    protocol = "all"
  }

  destination_ranges = ["0.0.0.0/0"]
  target_tags        = ["${var.name}-ssh"]
}
