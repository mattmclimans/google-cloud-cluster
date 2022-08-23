terraform {}

provider "google" {
  project = var.project_id
  region  = var.region
}

locals {
  random_string = random_string.main.result
  prefix = var.prefix != null && var.prefix != "" ? "${var.prefix}-" : "${random_string.main.result}-"
}

data "google_client_config" "main" {}

resource "random_string" "main" {
  length      = 5
  min_lower   = 5
  special     = false
}

module "vpc" {
  source       = "terraform-google-modules/network/google"
  version      = "~> 4.0"
  project_id   = data.google_client_config.main.project
  network_name = "default" # "${local.prefix}vpc"
  routing_mode = "GLOBAL"

  subnets = [
    {
      subnet_name   = "${local.prefix}${var.region}-subnet"
      subnet_ip     = var.subnet_cidr
      subnet_region = var.region
    }
  ]

  firewall_rules = [
    {
      name      = "${local.prefix}vpc-ingress"
      direction = "INGRESS"
      priority  = "100"
      ranges    = ["0.0.0.0/0"]
      allow = [
        {
          protocol = "all"
          ports    = []
        }
      ]
    }
  ]
}

# -------------------------------------------------------------------------------
# Create cluster
resource "google_container_cluster" "cluster" {
  name               = "${local.prefix}cluster"
  location           = var.region
  min_master_version = var.k8s_version

  remove_default_node_pool = true
  initial_node_count       = 1

  network    = module.vpc.network_id
  subnetwork = module.vpc.subnets_self_links[0]

  network_policy {
    # Enabling NetworkPolicy for clusters with DatapathProvider=ADVANCED_DATAPATH is not allowed (yields error)
    enabled = var.k8s_enable_dpv2 ? false : true
    # CALICO provider overrides datapath_provider setting, leaving Dataplane v2 disabled
    provider = var.k8s_enable_dpv2 ? "PROVIDER_UNSPECIFIED" : "CALICO"
  }
  # This is where Dataplane V2 is enabled.
  datapath_provider = var.k8s_enable_dpv2 ? "ADVANCED_DATAPATH" : "DATAPATH_PROVIDER_UNSPECIFIED"

  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "/16"
    services_ipv4_cidr_block = "/22"
  }

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  addons_config {
    network_policy_config {
      disabled = false
    }
  }

  depends_on = []
}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  name     = "${local.prefix}nodepool"
  location = var.region
  cluster  = google_container_cluster.cluster.name

  node_count = 1

  node_config {
    preemptible  = true
    machine_type = "n2-standard-8"

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}
