resource "azurerm_user_assigned_identity" "mi" {
  location            = var.location
  name                = "umi-${local.web_service_name}-dev"
  resource_group_name = azurerm_resource_group.rg_web_svc.name
}

resource "azurerm_user_assigned_identity" "appgw_mi" {
  location            = var.location
  name                = "umi-${local.web_service_name}-appgw-dev"
  resource_group_name = azurerm_resource_group.rg_web_svc.name
}