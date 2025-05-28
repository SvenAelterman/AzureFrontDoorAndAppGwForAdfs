locals {
  web_service_name   = "${var.app_short_name}-${var.location}"
  web_svc_rg         = "rg-${local.web_service_name}"
  web_svc_network_rg = "rg-${var.app_short_name}-web-svc-network"
  web_svc_vnet       = "vnet-${var.app_short_name}-web-services"
  hub_dns_zone_rg    = "rg-hub-dns-${var.location}"
  certificate_name   = "${local.web_service_name}-cert"
  env_suffix         = var.environment == "prod" ? "" : "-${var.environment}"
  tags = {
    "Env" : var.environment
  }
  virtual_network_subnets = {
    appgw = {
      name             = "ApplicationGatewaySubnet"
      vnet_resource_id = "/subscriptions/${var.subscription_id_app_lz}/resourceGroups/${local.web_svc_network_rg}/providers/Microsoft.Network/virtualNetworks/${local.web_svc_vnet}"
      address_prefixes = [
        var.appgw_subnet_address_prefix
      ]
    }
    # only needed if using private endpoints
    # pe = {
    #     name                    = "PrivateEndpointSubnet"
    #     vnet_resource_id        = "/subscriptions/${var.subscription_id_app_lz}/resourceGroups/${local.web_svc_network_rg}/providers/Microsoft.Network/virtualNetworks/${local.web_svc_vnet}"
    #     address_prefixes        = [
    #         var.private_endpoint_subnet_address_prefix
    #     ]
    # }
  }

  #AFD Vars
  afd_sku_name             = "Standard_AzureFrontDoor"
  afd_prefix                = "afd-${var.app_short_name}${local.env_suffix}"
  afd_profile_name          = "${local.afd_prefix}-profile"
  afd_endpoint_name         = "${local.afd_prefix}-endpoint"
  afd_origin_group_name     = "${local.afd_prefix}-origin-group-identity-adfs"
  afd_origin_name           = "${local.afd_prefix}-origin-adfs-appgw"
  afd_routing_ruleset_name  = "${local.afd_prefix}-routing-ruleset"
  afd_routing_rule_name     = "${local.afd_prefix}-route-appgw"
  afd_custom_domain_name    = "${local.afd_prefix}-custom-domain-adfs"
  afd_waf_policy_name       = "${local.afd_prefix}-waf-policy-adfs"
  adfs_security_policy_name = "${local.afd_prefix}-security-policy-adfs"
  ## custom domain for AFD
  custom_domain_name          = "dns-zone-custom-domain-adfs"
  afd_custom_domain_host_name = "CHANGE_ME" # Replace with actual custom domain

  umi_object_id = "CHANGE_ME" # Replace with actual UMI object ID from centralized automation

  # AppGw Vars
  appgw_sku = "Standard_v2"
  appgw_sku_tier = "Regional"
  appgw_pip_name = "pip-${local.appgw_name}"
  dns_label                      = "${var.app_short_name}${local.env_suffix}" 
  appgw_name                     = "appgw-${var.app_short_name}-${var.location}"
  backend_address_pool_name      = "${local.web_service_name}-be-ap"
  frontend_port_name             = "${local.web_service_name}-fe-port"
  frontend_ip_configuration_name = "${local.web_service_name}-fe-ip"
  http_setting_name              = "${local.web_service_name}-be-http-st"
  listener_name                  = "${local.web_service_name}-http-lstn"
  request_routing_rule_name      = "${local.web_service_name}-rq-rt"
  redirect_configuration_name    = "${local.web_service_name}-rdr-cfg"
  log_analytics_workspace_id     = "/subscriptions/${var.subscription_id_management}/resourceGroups/rg-management-${var.location}/providers/Microsoft.OperationalInsights/workspaces/law-management-${var.location}"
}