# ----------------------------------------------------------------------------
#  variables - main.tf
variable "project_id" {
  description = "The GCP project ID"
  default     = null
}

variable "region" {
  description = "The GCP region"
  default     = "us-east1"
}

variable "prefix" {
  description = "Prefix to add before resource names"
  default     = null
}

# ----------------------------------------------------------------------------
# variables - cluster.tf
variable "k8s_version" {
  description = "The version of Kubernetes"
  default     = "1.23.17-gke.7000" // Pull version: gcloud container get-server-config --zone=us-east1-a --format=json
}

variable "k8s_enable_dpv2" {
  description = "Boolean operator to enable or disable Dataplane V2. True is enabled."
  default     = false
}

variable "subnet_cidr" {
  description = "Subnet CIDR range"
  default     = "10.0.0.0/16"
}
