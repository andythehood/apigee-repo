locals {
  # FOR EVALUATION, allocate a /28 for management and runtime.
  # For PAID ORGS, allocate a /22 for runtime and a /28 for management.
  # Assumes that service_networking_peering_cidr is a /20 CIDR block.

  #EVAL
  # /28 for runtime
  apigee_runtime_cidr_range = cidrsubnet(var.service_networking_peering_cidr, 8, 0) # 10.21.0.0/28
  apigee_mgmt_cidr_range    = cidrsubnet(var.service_networking_peering_cidr, 8, 1) # 10.21.0.16/28
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
resource "google_apigee_environment" "dev_env" {
  name   = "dev"
  org_id = google_apigee_organization.apigee_org.id
}

resource "google_apigee_envgroup" "dev_group" {
  name   = "dev-group"
  org_id = google_apigee_organization.apigee_org.id
  hostnames = [
    "dev-34.111.216.9.nip.io",
  ]
}

resource "google_apigee_environment" "prod_env" {
  name   = "prod"
  org_id = google_apigee_organization.apigee_org.id
}

resource "google_apigee_envgroup" "prod_group" {
  name   = "prod-group"
  org_id = google_apigee_organization.apigee_org.id
  hostnames = [
    "prod-34.111.216.9.nip.io",
  ]
}


# Eval Orgs only support a maximum of two environments and environment groups

# Attach environments to environment groups
resource "google_apigee_envgroup_attachment" "attach_dev" {
  envgroup_id = google_apigee_envgroup.dev_group.id
  environment = google_apigee_environment.dev_env.name
}

resource "google_apigee_envgroup_attachment" "attach_prod" {
  envgroup_id = google_apigee_envgroup.prod_group.id
  environment = google_apigee_environment.prod_env.name
}

# Attach environments to instance
# This doesn't work for Evaluation

resource "google_apigee_instance_attachment" "attach_dev" {
  instance_id = google_apigee_instance.apigee_instance.id
  environment = google_apigee_environment.dev_env.name
}

resource "google_apigee_instance_attachment" "attach_prod" {
  instance_id = google_apigee_instance.apigee_instance.id
  environment = google_apigee_environment.prod_env.name

  depends_on = [google_apigee_instance_attachment.attach_dev]
}

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

resource "google_apigee_target_server" "default" {
  for_each = {
    for ts in var.target_servers : ts.name => ts
  }

  name        = each.value.name
  description = each.value.description
  host        = each.value.host
  port        = each.value.port

  s_sl_info {
    enabled = each.value.s_sl_info.enabled
  }

  env_id = "organizations/${local.apigee_org_id}/environments/${var.environment}"
}

