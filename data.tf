data "azurerm_client_config" "current" {}

data "azurerm_role_definition" "kv_officer" {
  name = "Key Vault Secrets Officer"
}

data "azurerm_role_definition" "kv_officer" {
  name = "Key Vault Certificates Officer"
}

# use if private endpoints are required
# data "azurerm_private_dns_zone" "kv_pdns" {
#   provider = azurerm.connectivity
#   name                = "privatelink.vaultcore.azure.net"
#   resource_group_name = local.hub_dns_zone_rg
# }