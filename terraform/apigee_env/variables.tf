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

variable "environment" {
  type        = string
  description = "Environment name for environment-scoped resources"
  default     = null
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

variable "kvms" {
  type = list(object({
    name = string
  }))
  description = "List of key value map definitions."
}