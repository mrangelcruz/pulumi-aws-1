output "cluster_name" {
  value = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  value = google_container_cluster.primary.endpoint
}

output "client_certificate" {
  value = google_container_cluster.primary.master_auth.0.client_certificate
}
