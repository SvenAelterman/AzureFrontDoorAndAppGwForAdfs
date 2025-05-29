data "azurerm_client_config" "current" {}

# use if private endpoints are required
# data "azurerm_private_dns_zone" "kv_pdns" {
#   provider = azurerm.connectivity
#   name                = "privatelink.vaultcore.azure.net"
#   resource_group_name = local.hub_dns_zone_rg
# }