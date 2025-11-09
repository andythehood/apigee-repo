# Data source: Reference existing project
data "google_project" "host" {
  project_id = var.host_project_id
}

# Data source: Reference existing project
data "google_project" "apigee" {
  project_id = var.apigee_project_id
}

# Enable Compute Engine API
resource "google_project_service" "compute" {
  project            = data.google_project.apigee.project_id
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

# Enable Apigee API
resource "google_project_service" "apigee" {
  project            = data.google_project.apigee.project_id
  service            = "apigee.googleapis.com"
  disable_on_destroy = false
}

# Enable Cloud KMS API
resource "google_project_service" "cloudkms" {
  project            = data.google_project.apigee.project_id
  service            = "cloudkms.googleapis.com"
  disable_on_destroy = false
}

# Enable Service Networking API
resource "google_project_service" "servicenetworking" {
  project            = data.google_project.apigee.project_id
  service            = "servicenetworking.googleapis.com"
  disable_on_destroy = false
}

# Enable Cloud DNS API
resource "google_project_service" "cloud_dns" {
  project            = data.google_project.apigee.project_id
  service            = "dns.googleapis.com"
  disable_on_destroy = false
}

# Enable Certificate Manager API
resource "google_project_service" "certificatemanager" {
  project            = data.google_project.apigee.project_id
  service            = "certificatemanager.googleapis.com"
  disable_on_destroy = false
}

# Enable Secret Manager API
resource "google_project_service" "secretmanager" {
  project            = data.google_project.apigee.project_id
  service            = "secretmanager.googleapis.com"
  disable_on_destroy = false
}