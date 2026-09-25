resource "google_container_cluster" "this" {
  name     = "mazino2d-as-se1-dev"
  location = "asia-southeast1"
  project  = module.project.project_id

  enable_autopilot    = true
  deletion_protection = false

  enable_fqdn_network_policy = true

  # The project has no default Compute Engine service account, so nodes use a dedicated one.
  cluster_autoscaling {
    auto_provisioning_defaults {
      service_account = google_service_account.gke_node.email
      oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]
    }
  }

  gateway_api_config {
    channel = "CHANNEL_STANDARD"
  }

  ip_allocation_policy {}

  release_channel {
    channel = "REGULAR"
  }

  # Autopilot cannot disable Cloud Logging/Monitoring; keep system components only.
  logging_config {
    enable_components = ["SYSTEM_COMPONENTS"]
  }

  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS"]
  }

  depends_on = [
    module.project,
    google_project_iam_member.gke_node_default,
  ]
}

resource "google_service_account" "gke_node" {
  account_id   = "gke-node"
  display_name = "GKE node service account"
  project      = module.project.project_id
}

resource "google_project_iam_member" "gke_node_default" {
  project = module.project.project_id
  role    = "roles/container.defaultNodeServiceAccount"
  member  = "serviceAccount:${google_service_account.gke_node.email}"
}

resource "google_service_account" "k8s_tf" {
  account_id   = "tf-k8s"
  display_name = "Terraform k8s stack"
  project      = module.project.project_id
}

resource "google_project_iam_member" "k8s_tf_container_developer" {
  project = module.project.project_id
  role    = "roles/container.admin"
  member  = "serviceAccount:${google_service_account.k8s_tf.email}"
}

resource "google_service_account_key" "k8s_tf" {
  service_account_id = google_service_account.k8s_tf.name
}
