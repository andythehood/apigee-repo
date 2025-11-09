
variable "host_project_id" {
  description = "The ID of the Host project"
  type        = string
}

variable "apigee_project_id" {
  description = "The ID of the Apigee project"
  type        = string
}

locals {
  description   = "The ID of the Apigee Org, same as the GCP project id"
  apigee_org_id = var.apigee_project_id
}

variable "region" {
  description = "Region for resources"
  type        = string
}

variable "service_networking_peering_cidr" {
  type = string
}

variable "environment" {
  description = "The SDLC environment name"
  type        = string
}

variable "target_servers" {
  type = list(object({
    name        = string
    description = string
    host        = string
    port        = number
    s_sl_info = object({
      enabled = bool
    })

  }))
  description = "List of target server definitions."
}