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
    prefix = "apigee-repo/apigee-env"
  }
}

provider "google" {
  project = var.apigee_project_id
}

locals {
  # Check if we're in an environment workspace (not default)
  is_env_workspace = terraform.workspace != "default"
}