terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 7.0.0"
    }
  }
  required_version = ">= 1.12.0"
  backend "gcs" {
    bucket = "aviato-andy-terraform-states"
    prefix = "apigee-repo"
  }
}

provider "google" {
  project = var.apigee_project_id
}