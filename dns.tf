resource "azurerm_dns_zone" "gmu_adfs" {
  name                = local.custom_domain_name
  resource_group_name = local.web_svc_network_rg

}

resource "azurerm_dns_txt_record" "adfs" {
  name                = join(".", ["_dnsauth", local.afd_custom_domain_name])
  zone_name           = azurerm_dns_zone.gmu_adfs.name
  resource_group_name = local.web_svc_network_rg
  ttl                 = 3600

  record {
    value = azurerm_cdn_frontdoor_custom_domain.adfs.validation_token
  }
}

resource "azurerm_dns_cname_record" "adfs" {
  name                = local.afd_custom_domain_name
  zone_name           = azurerm_dns_zone.gmu_adfs.name
  resource_group_name = local.web_svc_network_rg
  ttl                 = 3600
  record              = azurerm_cdn_frontdoor_endpoint.adfs_endpoint.host_name

  depends_on = [
    azurerm_cdn_frontdoor_route.adfs_appgw, 
    azurerm_cdn_frontdoor_security_policy.adfs_security_policy
]
}