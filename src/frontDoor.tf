locals {
  front_door_sku_name = "Premium_AzureFrontDoor"
}

module "afd_waf_policy" {
  source           = "Azure/avm-res-network-frontdoorwebapplicationfirewallpolicy/azurerm"
  version          = "~> 0.1.0"
  enable_telemetry = var.enable_telemetry

  name                = lower(join("", regexall("[a-zA-Z0-9]", replace(replace(local.naming_structure, "{resource_type}", "afd"), "{region}", "global"))))
  resource_group_name = module.resource_group_afd.name
  tags                = var.tags

  mode = var.waf_mode
  # Required for Microsoft-managed WAF rules
  sku_name = local.front_door_sku_name

  request_body_check_enabled = true
  #redirect_url                      = "https://learn.microsoft.com/docs/"
  custom_block_response_status_code = 403
  custom_block_response_body        = base64encode("Blocked by Azure WAF")

  custom_rules = []
}

resource "azurerm_cdn_frontdoor_profile" "afd" {
  name                = replace(replace(local.naming_structure, "{resource_type}", "afd"), "{region}", "global")
  resource_group_name = module.resource_group_afd.name
  sku_name            = local.front_door_sku_name

  tags = var.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [module.identity[local.regions_list[0]].resource_id]
  }
}

resource "azurerm_cdn_frontdoor_endpoint" "fde" {
  name                     = replace(replace(local.naming_structure, "{resource_type}", "fde-${var.workload_name}"), "{region}", "global")
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.afd.id

  tags = var.tags
}

resource "azurerm_cdn_frontdoor_origin_group" "origin_group" {
  name                     = "origin-${var.workload_name}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.afd.id

  load_balancing {
    sample_size                 = 4
    successful_samples_required = 2
  }

  health_probe {
    interval_in_seconds = 240
    path                = var.health_probe_path
    protocol            = "Https"
    request_type        = "GET" # HEAD might not be supported (for ADFS)
  }
}

resource "azurerm_cdn_frontdoor_origin" "origin_current" {
  #count = var.current_origin_ip != "" ? 1 : 0
  for_each = var.current_origin_ips

  name                          = "origin-${var.workload_name}-current-${each.key}"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.origin_group.id
  enabled                       = var.enable_current_origin

  certificate_name_check_enabled = true

  host_name          = each.value
  origin_host_header = var.custom_domain_name
  priority           = 1
  weight             = 1
}

resource "azurerm_cdn_frontdoor_origin" "origin_appgw" {
  name                          = "origin-${var.workload_name}-appgw"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.origin_group.id
  enabled                       = var.enable_app_gateway_origin

  for_each = var.regions

  certificate_name_check_enabled = true

  host_name          = module.application_gateway[each.key].new_public_ip_address
  origin_host_header = var.custom_domain_name
  priority           = 1
  weight             = 1
}

# Add the Key Vault certificates as Front Door secrets
resource "azurerm_cdn_frontdoor_secret" "customer_certificate" {
  name                     = "secret-${var.workload_name}-${each.key}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.afd.id

  # Add the certificate from each region's Key Vault
  for_each = var.regions

  secret {
    customer_certificate {
      # Key Vault needs the secret URI. Front Door can use it too but then replaces it with the certificate URI anyway,
      # which leads to issues on re-run
      key_vault_certificate_id = replace(var.key_vaults[each.key].cert_secret_uri, "/secrets/", "certificates")
    }
  }
}

# Add the custom domain
resource "azurerm_cdn_frontdoor_custom_domain" "domain" {
  name                     = "domain-${var.workload_name}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.afd.id
  host_name                = var.custom_domain_name

  tls {
    certificate_type = "CustomerCertificate" # or "ManagedCertificate"
    # We have to pick the first secret as we can only have one certificate per custom domain
    # The second certificate is added as a secret to enable quicker failover in case of an extended regional outage in the primary region
    cdn_frontdoor_secret_id = azurerm_cdn_frontdoor_secret.customer_certificate[local.regions_list[0]].id
  }
}

resource "azurerm_cdn_frontdoor_security_policy" "afd_security_policy" {
  name                     = "sec-${var.workload_name}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.afd.id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = module.afd_waf_policy.resource_id

      association {
        domain {
          cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_custom_domain.domain.id
        }
        patterns_to_match = ["/*"]
      }
    }
  }
}

resource "azurerm_cdn_frontdoor_rule_set" "rule_set" {
  name                     = join("", regexall("[a-z0-9]", lower(var.workload_name)))
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.afd.id
}

locals {
  appgw_origin_ids    = [for region in var.regions : azurerm_cdn_frontdoor_origin.origin_appgw[region].id]
  optional_origin_ids = [for current in var.var.current_origin_ips : azurerm_cdn_frontdoor_origin.origin_current[current].id]
  all_origin_ids      = concat(local.appgw_origin_ids, local.optional_origin_ids)
}

resource "azurerm_cdn_frontdoor_route" "route" {
  name                          = "route-${var.workload_name}"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.fde.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.origin_group.id
  enabled                       = true

  cdn_frontdoor_origin_ids = local.all_origin_ids

  cdn_frontdoor_rule_set_ids = [
    azurerm_cdn_frontdoor_rule_set.rule_set.id
  ]

  forwarding_protocol    = "HttpsOnly"
  https_redirect_enabled = true
  patterns_to_match = [
    "/*"
  ]
  supported_protocols = [
    "Http",
    "Https"
  ]

  cdn_frontdoor_custom_domain_ids = [
    azurerm_cdn_frontdoor_custom_domain.domain.id
  ]
  link_to_default_domain = false
}
