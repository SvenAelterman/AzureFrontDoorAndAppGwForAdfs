module "afd_waf_policy" {
  source  = "Azure/avm-res-network-frontdoorapplicationfirewallpolicy/azurerm"
  version = "0.1.0"

  name                = local.afd_waf_policy_name
  resource_group_name = local.web_svc_network_rg
  enable_telemetry    = false
  mode                = "Prevention"
  sku_name            = local.afd_sku_name

  request_body_check_enabled = true
  #redirect_url                      = "https://learn.microsoft.com/docs/"
  custom_block_response_status_code = 405
  custom_block_response_body        = base64encode("Blocked by Azure WAF")

  custom_rules = []
}

resource "azurerm_cdn_frontdoor_profile" "adfs" {
  name                = local.afd_profile_name
  resource_group_name = local.web_svc_network_rg
  sku_name            = local.afd_sku_name
}

resource "azurerm_cdn_frontdoor_endpoint" "adfs_endpoint" {
  name                     = local.afd_endpoint_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.adfs.id

  tags = local.tags
}

resource "azurerm_cdn_frontdoor_origin_group" "identity" {
  name                     = local.afd_origin_group_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.adfs.id

  load_balancing {
    sample_size = 4
    successful_samples_required = 2
  }
}

resource "azurerm_cdn_frontdoor_origin" "adfs" {
  name                          = local.afd_origin_name
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.identity.id
  enabled                       = true

  certificate_name_check_enabled = false

  host_name          = local.afd_custom_domain_host_name
  http_port          = 80
  https_port         = 443
  origin_host_header = "www.${local.afd_custom_domain_host_name}"
  priority           = 1
  weight             = 1
}

resource "azurerm_cdn_frontdoor_custom_domain" "adfs" {
  name                     = local.afd_custom_domain_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.adfs.id
  dns_zone_id              = azurerm_dns_zone.gmu_adfs.id
  host_name                = local.afd_custom_domain_host_name

  tls {
    certificate_type    = "CustomerCertificate" # or "ManagedCertificate"
  }
}

resource "azurerm_cdn_frontdoor_security_policy" "adfs_security_policy" {
  name                     = local.adfs_security_policy_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.adfs.id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = module.afd_waf_policy.id

      association {
        domain {
          cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_custom_domain.adfs.id
        }
        patterns_to_match = ["/*"]
      }
    }
  }
}

resource "azurerm_cdn_frontdoor_rule_set" "adfs" {
  name                     = local.afd_routing_ruleset_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.adfs.id
}

resource "azurerm_cdn_frontdoor_route" "adfs_appgw" {
  name                          = local.afd_routing_rule_name
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.adfs_endpoint.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.identity.id
  cdn_frontdoor_origin_ids = [
    azurerm_cdn_frontdoor_origin.adfs.id
  ]
  cdn_frontdoor_rule_set_ids = [
    azurerm_cdn_frontdoor_rule_set.adfs.id
  ]
  enabled = true

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
    azurerm_cdn_frontdoor_custom_domain.adfs.id
  ]
  link_to_default_domain = false

}