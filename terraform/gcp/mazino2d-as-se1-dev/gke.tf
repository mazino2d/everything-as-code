resource "google_container_cluster" "this" {
  name     = "mazino2d-as-se1-dev"
  location = "asia-southeast1-b"
  project  = module.project.project_id

  remove_default_node_pool = true
  initial_node_count       = 1

  deletion_protection = false

  addons_config {
    http_load_balancing {
      disabled = true
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
  }

  logging_service    = "none"
  monitoring_service = "none"

  depends_on = [module.project]
}

resource "google_service_account" "k8s_tf" {
  account_id   = "tf-k8s"
  display_name = "Terraform k8s stack"
  project      = module.project.project_id
}

resource "google_project_iam_member" "k8s_tf_container_developer" {
  project = module.project.project_id
  role    = "roles/container.developer"
  member  = "serviceAccount:${google_service_account.k8s_tf.email}"
}

resource "google_service_account_key" "k8s_tf" {
  service_account_id = google_service_account.k8s_tf.name
}

resource "google_container_node_pool" "spot" {
  name           = "spot-pool"
  location       = "asia-southeast1-b"
  cluster        = google_container_cluster.this.name
  project        = module.project.project_id
  node_locations = ["asia-southeast1-a", "asia-southeast1-b", "asia-southeast1-c"]

  autoscaling {
    total_min_node_count = 0
    total_max_node_count = 1
    location_policy      = "ANY"
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type = "t2d-standard-2"
    spot         = true
    disk_size_gb = 20
    disk_type    = "pd-standard"

    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/trace.append",
    ]
  }
}
