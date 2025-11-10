locals {
  # FOR EVALUATION, allocate a /28 for management and runtime.
  # For PAID ORGS, allocate a /22 for runtime and a /28 for management.
  # Assumes that service_networking_peering_cidr is a /20 CIDR block.

  #EVAL
  # /28 for runtime
  apigee_runtime_cidr_range = cidrsubnet(var.service_networking_peering_cidr, 8, 0) # 10.21.0.0/28
  apigee_mgmt_cidr_range    = cidrsubnet(var.service_networking_peering_cidr, 8, 1) # 10.21.0.16/28
}


locals {
  # Only create envs in default workspace
  environments = terraform.workspace == "default" ? var.environments : []
}


# Apigee organization
resource "google_apigee_organization" "apigee_org" {

  project_id          = data.google_project.apigee.project_id
  display_name        = "Apigee Organization for ${data.google_project.apigee.project_id}"
  description         = "Apigee Organization created via Terraform for DEV environment"
  analytics_region    = var.region
  disable_vpc_peering = false
  authorized_network  = google_compute_network.apigee_vpc.id
  runtime_type        = "CLOUD"

  # For testing purposes, we can use EVALUATION billing type
  billing_type = "EVALUATION"
  retention    = "MINIMUM"

  # billing_type = "SUBSCRIPTION"
  # retention = "DELETION_RETENTION_UNSPECIFIED"

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [
    google_service_networking_connection.apigee_private_connection,
    google_project_service.apigee
  ]
}

# Apigee instance
resource "google_apigee_instance" "apigee_instance" {

  name     = "eval-instance"
  location = var.region
  org_id   = google_apigee_organization.apigee_org.id

  # Uncomment the following line to specify a the CIDR ranges, otherwise Apigee will auto allocate from the Service Networking peering range
  # ip_range = "10.21.0.0/28,10.21.0.16/28"
  ip_range = "${local.apigee_runtime_cidr_range},${local.apigee_mgmt_cidr_range}"

  consumer_accept_list = [
    "${var.apigee_project_id}",
    "${var.host_project_id}"
  ]
}

# Apigee environments and groups
resource "google_apigee_environment" "env" {


  for_each = {
    for env in var.environments : env.name => env
  }

  name        = each.value.name
  description = each.value.description
  org_id      = google_apigee_organization.apigee_org.id
}

resource "google_apigee_envgroup" "envgroup" {

  for_each = {
    for env in local.environments : env.name => env
  }

  name      = "${each.value.name}-group"
  org_id    = google_apigee_organization.apigee_org.id
  hostnames = each.value.hostnames
}

# resource "google_apigee_environment" "prod_env" {
#   name   = "prod"
#   org_id = google_apigee_organization.apigee_org.id
# }

# resource "google_apigee_envgroup" "prod_group" {
#   name   = "prod-group"
#   org_id = google_apigee_organization.apigee_org.id
#   hostnames = [
#     "prod-34.111.216.9.nip.io",
#   ]
# }


# # Eval Orgs only support a maximum of two environments and environment groups

# Attach environments to environment groups
resource "google_apigee_envgroup_attachment" "envgroup_attachment" {

  for_each = {
    for env in var.environments : env.name => env
  }
  envgroup_id = google_apigee_envgroup.envgroup[each.value.name].id
  environment = google_apigee_environment.env[each.value.name].name
}

# resource "google_apigee_envgroup_attachment" "attach_prod" {
#   envgroup_id = google_apigee_envgroup.prod_group.id
#   environment = google_apigee_environment.prod_env.name
# }

# Attach environments to instance
# This sometimes doesn't work for Evaluation

resource "google_apigee_instance_attachment" "instance_attachment" {

  for_each = {
    for env in var.environments : env.name => env
  }
  instance_id = google_apigee_instance.apigee_instance.id
  environment = google_apigee_environment.env[each.value.name].name
}

# resource "google_apigee_instance_attachment" "attach_prod" {
#   instance_id = google_apigee_instance.apigee_instance.id
#   environment = google_apigee_environment.prod_env.name

#   depends_on = [google_apigee_instance_attachment.attach_dev]
# }

# resource "google_apigee_target_server" "gateway_service" {
#   name        = "gateway-service"
#   description = "Gateway Cloud Run Service"
#   env_id      = google_apigee_environment.dev_env.id
#   host        = "httpbin.org"
#   port        = 443
#   protocol    = "HTTP"
#   s_sl_info {
#     enabled = true
#   }
# }


output "apigee_org" {

  value = google_apigee_organization.apigee_org.id
}

output "apigee_service_attachment" {
  value = google_apigee_instance.apigee_instance.service_attachment
}