environment = "prod"

target_servers = [
  {
    name        = "gateway-service"
    description = "Gateway Service"
    host        = "httpbin.org"
    port        = 443
    protocol    = "http"
    s_sl_info = {
      enabled = true
    }
  },
  {
    name        = "authentication-service"
    description = "Authentication Service"
    host        = "httpbin.org"
    port        = 443
    protocol    = "http"
    s_sl_info = {
      enabled = true
    }
  },
  {
    name        = "logging-service"
    description = "Logging Service"
    host        = "httpbin.org"
    port        = 443
    protocol    = "http"
    s_sl_info = {
      enabled = true
    }
  }
]

kvms = [
  {
    name = "kvm-credentials"
  }
]
