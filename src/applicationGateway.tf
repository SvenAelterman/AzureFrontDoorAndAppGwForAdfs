# Module:
# https://registry.terraform.io/modules/Azure/avm-res-network-applicationgateway/azurerm/latest
# Sample: 
# https://registry.terraform.io/modules/Azure/avm-res-network-applicationgateway/azurerm/latest/examples/kv_selfssl_waf_https_app_gateway

module "application_gateway_waf_policy" {
  source           = "Azure/avm-res-network-applicationgatewaywebapplicationfirewallpolicy/azurerm"
  version          = "~> 0.1.0"
  enable_telemetry = var.enable_telemetry

  for_each = var.regions

  name                = replace(replace(local.naming_structure, "{resource_type}", "waf"), "{region}", each.key)
  resource_group_name = module.resource_group[each.key].name
  location            = each.key
  tags                = var.tags

  policy_settings = {
    enabled                                   = true
    file_upload_limit_enforcement             = true
    file_upload_limit_in_mb                   = 100
    mode                                      = var.waf_mode
    js_challenge_cookie_expiration_in_minutes = 30
  }

  managed_rules = {
    managed_rule_set = {
      rule_set_1 = {
        type    = "OWASP" # This is default but here for clarity
        version = "3.2"
        enabled = false
      }
    }
  }

  custom_rules = {
    # This custom rule is used to block requests that do not originate from this deployment's Azure Front Door instance.
    afd-origin-only = {
      name      = "AfdOriginOnly"
      action    = "Block"
      enabled   = true
      rule_type = "MatchRule"
      priority  = 100

      match_conditions = {
        afd_origin_only_condition = {
          match_variables = [
            {
              # Front Door automatically adds a header to its requests.
              selector      = "X-Azure-FDID"
              variable_name = "RequestHeaders"
            }
          ]
          operator           = "Equal"
          negation_condition = true
          match_values       = [azurerm_cdn_frontdoor_profile.afd.resource_guid]
        }
      }
    }
  }
}

locals {
  probe_name                       = "probe-${var.workload_name}"
  port_name_https                  = "port-443"
  port_name_http                   = "port-80"
  backend_pool_name                = "bep-${var.workload_name}"
  http_setting_name                = "http-setting-${var.workload_name}"
  listener_name_https              = "listener-https-${var.workload_name}"
  listener_name_http               = "listener-http-${var.workload_name}"
  routing_rule_name_https          = "routing-https-${var.workload_name}"
  routing_rule_name_http           = "redirect-http-${var.workload_name}"
  redirect_configuration_name_http = "redirect-http-${var.workload_name}"
  cert_name                        = "cert-${var.workload_name}"
}

module "application_gateway" {
  source           = "Azure/avm-res-network-applicationgateway/azurerm"
  version          = "~> 0.4.2"
  enable_telemetry = var.enable_telemetry

  for_each = var.regions

  name                = replace(replace(local.naming_structure, "{resource_type}", "agw"), "{region}", each.key)
  resource_group_name = module.resource_group[each.key].name
  location            = each.key
  tags                = var.tags

  public_ip_name = replace(replace(local.naming_structure, "{resource_type}", "pip-agw"), "{region}", each.key)

  gateway_ip_configuration = {
    subnet_id = var.app_gateway_subnet_ids[each.key].subnet_id
  }

  # WAF : Azure Application Gateways v2 are always deployed in a highly available fashion with multiple instances by default. Enabling autoscale ensures the service is not reliant on manual intervention for scaling.
  sku = {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 0 # Set the initial capacity to 0 for autoscaling
  }

  autoscale_configuration = {
    min_capacity = 1
    max_capacity = 2
  }

  # frontend port configuration block for the application gateway
  # WAF : Secure all incoming connections using HTTPS for production services with end-to-end SSL/TLS or SSL/TLS termination at the Application Gateway to protect against attacks and ensure data remains private and encrypted between the web server and browsers.
  frontend_ports = {
    port-443 = {
      name = local.port_name_https
      port = 443
    }
    port-80 = {
      name = local.port_name_http
      port = 80
    }
  }

  # Backend address pool configuration for the application gateway
  # Mandatory Input
  backend_address_pools = {
    bep-adfs = {
      name = local.backend_pool_name
      // TODO: Add VMs per region (new variable)
      # ip_addresses = ["100.64.2.6", "100.64.2.5"]
      #fqdns        = ["example1.com", "example2.com"]
    }
  }

  # Backend http settings configuration for the application gateway
  backend_http_settings = {
    http-setting-adfs = {
      name                  = local.http_setting_name
      cookie_based_affinity = "Disabled"
      path                  = "/"
      port                  = 443
      protocol              = "Https"
      request_timeout       = 30
      probe_name            = local.probe_name
      host_name             = var.custom_domain_name

      connection_draining = {
        enable_connection_draining = true
        drain_timeout_sec          = 300
      }
    }
  }

  # Http Listeners configuration for the application gateway
  http_listeners = {
    listener-https-adfs = {
      name                 = local.listener_name_https
      host_name            = var.custom_domain_name
      frontend_port_name   = local.port_name_https
      ssl_certificate_name = "cert-${var.workload_name}"
    }
    # This will likely not be used because we'll only accept connections from Azure Front Door
    # and it will use HTTPS.
    listener-http-adfs = {
      name               = local.listener_name_http
      frontend_port_name = local.port_name_http
      host_name          = var.custom_domain_name
      protocol           = "Http"
    }
  }

  # WAF : Use Application Gateway with Web Application Firewall (WAF) in an application virtual network to safeguard inbound HTTP/S internet traffic. WAF offers centralized defense against potential exploits through OWASP core rule sets-based rules.
  app_gateway_waf_policy_resource_id = module.application_gateway_waf_policy[each.key].resource_id

  # Routing rules configuration for the backend pool
  # Mandatory Input
  request_routing_rules = {
    routing-https = {
      name                       = local.routing_rule_name_https
      http_listener_name         = local.listener_name_https
      backend_address_pool_name  = local.backend_pool_name
      backend_http_settings_name = local.http_setting_name
      priority                   = 100
      rule_type                  = "Basic"
    }
    redirect-http = {
      name                        = local.routing_rule_name_http
      http_listener_name          = local.listener_name_http
      redirect_configuration_name = local.redirect_configuration_name_http
      priority                    = 50
      # Not applicable for a redirect rule but required by the module
      rule_type                  = "Basic"
      backend_http_settings_name = ""
      backend_address_pool_name  = ""
    }
  }

  # SSL Certificate Block
  ssl_certificates = {
    cert = {
      name                = local.cert_name
      key_vault_secret_id = var.key_vaults[each.key].cert_secret_uri
    }
  }

  #   ssl_profile = {
  #     profile1 = {
  #       name = "example-ssl-profile"
  #       ssl_policy = {

  #         policy_type          = "Custom"
  #         min_protocol_version = "TLSv1_2"
  #         cipher_suites = [
  #           "TLS_RSA_WITH_AES_128_GCM_SHA256",
  #           "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256"
  #         ]
  #       }
  #     }
  #   }
  #   ssl_policy = {

  #     policy_type          = "Custom"
  #     min_protocol_version = "TLSv1_2"
  #     cipher_suites = [
  #       "TLS_RSA_WITH_AES_128_GCM_SHA256",
  #       "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256"
  #     ]

  #   }

  # HTTP to HTTPS redirect configuration
  redirect_configuration = {
    redirect-http = {
      name                 = local.redirect_configuration_name_http
      redirect_type        = "Permanent"
      include_path         = true
      include_query_string = true
      target_listener_name = local.listener_name_https
    }
  }

  probe_configurations = {
    probe = {
      name     = local.probe_name
      protocol = "Https"
      port     = 443
      # http://-/adfs/probe is supposed to be used but the customer for whom this was developed does not have this endpoint available.
      # https://learn.microsoft.com/windows-server/identity/ad-fs/overview/ad-fs-requirements#load-balancer-requirements
      # This URL is publicly accessible and should return a 200 OK response.
      path                                      = var.health_probe_path
      interval                                  = 30
      timeout                                   = 30
      unhealthy_threshold                       = 3
      pick_host_name_from_backend_http_settings = true

      match = {
        status_code = ["200"]
      }
    }
  }

  zones = ["1", "2", "3"]

  managed_identities = {
    user_assigned_resource_ids = [
      module.identity[each.key].resource_id
    ]
  }

  # Explicit dependencies required:
  # - The policy exemption for public IP addresses must be created before the Application Gateway is deployed
  #   and there is no reference to the policy exemption in this resource definition.
  # - The Key Vault role assignment for the user-assigned managed identity must be created before the Application Gateway is deployed
  #   and there is no reference to the role assignment in this resource definition.
  depends_on = [
    azurerm_resource_group_policy_exemption.deny_public_ip_addresses_exemption,
    module.role_assignment_identity_key_vault
  ]
}
