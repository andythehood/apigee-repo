terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0.0"
    }
  }
  required_version = ">= 1.3.0"
  backend "gcs" {
    bucket = "aviato-andy-terraform-states"
    prefix = "apigee-products"
  }
}

provider "google" {
  project = var.apigee_project_id
}