output "api_server_address" {
  description = "The IP endpoint of the GKE cluster master.  Use this value in the Kubernetes Panorama plugin for the API Server Address"
  value       = google_container_cluster.cluster.endpoint
}

output "cluster_name" {
  value = google_container_cluster.cluster.name
}

output "run_this_to_authenticate_to_cluster" {
  value = "gcloud container clusters get-credentials ${google_container_cluster.cluster.name} --region ${var.region} --project ${data.google_client_config.main.project}"
}
