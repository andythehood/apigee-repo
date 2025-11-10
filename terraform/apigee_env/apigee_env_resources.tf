
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

resource "google_apigee_target_server" "target_server" {

  count = local.is_env_workspace ? length(var.target_servers) : 0

  name        = var.target_servers[count.index].name
  host        = var.target_servers[count.index].host
  description = var.target_servers[count.index].description
  port        = var.target_servers[count.index].port
  env_id      = "organizations/${local.apigee_org_id}/environments/${var.environment}"

  protocol = "HTTP"
}



# for_each = {
#   for ts in var.target_servers : ts.name => ts
# }

# name        = each.value.name
# description = each.value.description
# host        = each.value.host
# port        = each.value.port

# s_sl_info {
#   enabled = each.value.s_sl_info.enabled
# }

# env_id = "organizations/${local.apigee_org_id}/environments/${var.environment}"
# }

