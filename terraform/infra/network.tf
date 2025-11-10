# VPC network resource
resource "google_compute_network" "apigee_vpc" {
  name                    = "apigee-vpc"
  auto_create_subnetworks = false
  project                 = data.google_project.apigee.project_id
  depends_on              = [google_project_service.compute, google_project_service.apigee]
}

# Subnet resource
resource "google_compute_subnetwork" "apigee_vpc_apigee_subnet" {
  name          = "apigee-vpc-subnet"
  ip_cidr_range = "10.10.0.0/24"
  region        = var.region
  network       = google_compute_network.apigee_vpc.id
  project       = data.google_project.apigee.project_id
}

# Reserve IP range for service networking
locals {
  service_networking_peering_cidr_address = cidrhost(var.service_networking_peering_cidr, 0)
  service_networking_peering_cidr_length  = tonumber(split("/", var.service_networking_peering_cidr)[1])
}

resource "google_compute_global_address" "apigee_service_networking_peering_range" {
  name          = "apigee-service-networking-peering-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  address       = local.service_networking_peering_cidr_address
  prefix_length = local.service_networking_peering_cidr_length
  network       = google_compute_network.apigee_vpc.id
  project       = data.google_project.apigee.project_id

  depends_on = [google_compute_network.apigee_vpc]
}

# service networking peering connection
resource "google_service_networking_connection" "apigee_private_connection" {
  network                 = google_compute_network.apigee_vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.apigee_service_networking_peering_range.name]

  depends_on = [
    google_project_service.servicenetworking
  ]
}