host_project_id   = "aviato-andy-sandbox-host"
apigee_project_id = "aviato-andy-apigee-shared-01"

region = "australia-southeast1"
# target_server_port     = 443
# target_server_protocol = "https"

# # maybe used by multiple modules
# analytics_region = "australia-southeast1"

service_networking_peering_cidr = "10.21.0.0/20"

environments = [

  {
    name        = "dev"
    description = "Development Environment"
    hostnames   = ["dev-34.111.216.9.nip.io"]
  },
  {
    name        = "prod"
    description = "Production Environment"
    hostnames   = ["prod-34.111.216.9.nip.io"]
  }
]

dataset_name =  "apigee_analytics"
