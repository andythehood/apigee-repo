

resource "google_apigee_target_server" "target_server" {

  count = local.is_env_workspace ? length(var.target_servers) : 0

  name        = var.target_servers[count.index].name
  host        = var.target_servers[count.index].host
  description = var.target_servers[count.index].description
  port        = var.target_servers[count.index].port
  protocol    = "HTTP"
  s_sl_info {
    enabled = var.target_servers[count.index].s_sl_info.enabled
  }
  env_id = "organizations/${local.apigee_org_id}/environments/${var.environment}"
}

resource "google_apigee_environment_keyvaluemaps" "kvm" {

  count = local.is_env_workspace ? length(var.kvms) : 0

  name   = var.kvms[count.index].name
  env_id = "organizations/${local.apigee_org_id}/environments/${var.environment}"
}



