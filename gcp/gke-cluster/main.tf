provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

resource "google_container_cluster" "primary" {
  name     = "micro-gke-cluster"
  location = var.zone

  initial_node_count = 2

  node_config {
    machine_type = "e2-micro"
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  remove_default_node_pool = true
  deletion_protection = false

  lifecycle {
    ignore_changes = [initial_node_count]
    create_before_destroy = true
  }
}

resource "google_container_node_pool" "micro_nodes" {
  name     = "micro-node-pool"
  location = var.zone
  cluster  = google_container_cluster.primary.name

  node_count = 2

  node_config {
    machine_type = "e2-micro"
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }
}
