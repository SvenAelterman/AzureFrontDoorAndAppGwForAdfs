resource "azurerm_public_ip" "appgw_pip" {
  provider            = azurerm.connectivity
  name                = "pip-${local.appgw_name}"
  resource_group_name = local.web_svc_network_rg
  location            = var.location
  sku                 = "Standard"
  sku_tier            = "Regional"
  allocation_method   = "Static"
}

module "application_gateway" {
  source  = "Azure/avm-res-network-applicationgateway/azurerm"
  version = "0.4.0"

  depends_on = [module.keyvault]

  # pre-requisites resources input required for the module
  create_public_ip      = false
  public_ip_resource_id = azurerm_public_ip.appgw_pip.id

  resource_group_name = local.web_svc_network_rg
  location            = var.location
  enable_telemetry    = false
  # provide Application gateway name
  name = local.appgw_name

  gateway_ip_configuration = {
    subnet_id = module.subnets["appgw"].resource_id
  }

  # WAF : Azure Application Gateways v2 are always deployed in a highly available fashion with multiple instances by default. Enabling autoscale ensures the service is not reliant on manual intervention for scaling.
  sku = {
    # Accpected value for names Standard_v2 and WAF_v2
    name = "WAF_v2"
    # Accpected value for tier Standard_v2 and WAF_v2
    tier = "WAF_v2"
    # Accpected value for capacity 1 to 10 for a V1 SKU, 1 to 100 for a V2 SKU
    capacity = 0 # Set the initial capacity to 0 for autoscaling
  }

  autoscale_configuration = {
    min_capacity = 1
    max_capacity = 2
  }

  # frontend port configuration block for the application gateway
  # WAF : Secure all incoming connections using HTTPS for production services with end-to-end SSL/TLS or SSL/TLS termination at the Application Gateway to protect against attacks and ensure data remains private and encrypted between the web server and browsers.
  frontend_ports = {
    frontend-port-443 = {
      name = "frontend-port-443"
      port = 443
    }
  }

  # Backend address pool configuration for the application gateway
  # Mandatory Input
  backend_address_pools = {
    appGatewayBackendPool = {
      name = local.backend_address_pool_name
      # ip_addresses = ["100.64.2.6", "100.64.2.5"]
      #fqdns        = ["example1.com", "example2.com"]
    }
  }

  # Backend http settings configuration for the application gateway
  # Mandatory Input
  backend_http_settings = {
    appGatewayBackendHttpSettings = {
      name                  = local.http_setting_name
      cookie_based_affinity = "Disabled"
      path                  = "/contoso" # CHANGE_ME
      port                  = 80
      protocol              = "Http"
      request_timeout       = 30
      connection_draining = {
        enable_connection_draining = true
        drain_timeout_sec          = 300
      }
    }
    # Add more http settings as needed
  }

  # Http Listerners configuration for the application gateway
  # Mandatory Input
  http_listeners = {
    appGatewayHttpListener = {
      name                 = local.listener_name
      host_name            = "${var.app_short_name}.azure.com"
      frontend_port_name   = "frontend-port-443"
      ssl_certificate_name = "app-gateway-cert"
      ssl_profile_name     = "default-ssl-profile"
    }
    # # Add more http listeners as needed
  }


  # WAF : Use Application Gateway with Web Application Firewall (WAF) in an application virtual network to safeguard inbound HTTP/S internet traffic. WAF offers centralized defense against potential exploits through OWASP core rule sets-based rules.
  # Ensure that you have a WAF policy created before enabling WAF on the Application Gateway
  # The use of an external WAF policy is recommended rather than using the classic WAF via the waf_configuration block.
  # app_gateway_waf_policy_resource_id = azurerm_web_application_firewall_policy.azure_waf.id
  waf_configuration = {
    enabled          = true
    firewall_mode    = "Detection"
    rule_set_type    = "OWASP"
    rule_set_version = "3.2"
  }

  # Routing rules configuration for the backend pool
  # Mandatory Input
  request_routing_rules = {
    routing-rule-1 = {
      name                       = local.request_routing_rule_name
      rule_type                  = "Basic"
      http_listener_name         = local.listener_name
      backend_address_pool_name  = local.backend_address_pool_name
      backend_http_settings_name = local.http_setting_name
      priority                   = 100
    }
    # Add more rules as needed
  }

  # SSL Certificate Block
  ssl_certificates = {
    "app-gateway-cert" = {
      name                = local.web_service_name
      key_vault_secret_id = "${module.keyvault.uri}certificates/${local.certificate_name}"
    }
  }

  ssl_profile = {
    profile1 = {
      name = "default-ssl-profile"
      ssl_policy = {

        policy_type          = "Custom"
        min_protocol_version = "TLSv1_2"
        cipher_suites = [
          "TLS_RSA_WITH_AES_128_GCM_SHA256",
          "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256"
        ]
      }
    }
  }
  ssl_policy = {

    policy_type          = "Custom"
    min_protocol_version = "TLSv1_2"
    cipher_suites = [
      "TLS_RSA_WITH_AES_128_GCM_SHA256",
      "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256"
    ]

  }

  # HTTP to HTTPS Redirection Configuration for
  redirect_configuration = {
    redirect_config_1 = {
      name                 = "Redirect1"
      redirect_type        = "Permanent"
      include_path         = true
      include_query_string = true
      target_listener_name = local.listener_name
    }
  }

  # Optional Input
  # Zone redundancy for the application gateway ["1", "2", "3"]
  zones = ["1"]

  managed_identities = {
    user_assigned_resource_ids = [
      azurerm_user_assigned_identity.appgw_mi.id
    ]
  }

  diagnostic_settings = {
    example_setting = {
      name                           = "${module.naming.application_gateway.name_unique}-diagnostic-setting"
      workspace_resource_id          = local.log_analytics_workspace_id
      log_analytics_destination_type = "Dedicated" # Or "AzureDiagnostics"
      log_groups                     = ["allLogs"]
      metric_categories              = ["AllMetrics"]
    }
  }

  tags = {
    environment = local.tags.Env
    owner       = "application_gateway"
    project     = "AVM"
  }

}