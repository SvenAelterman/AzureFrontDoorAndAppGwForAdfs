resource "azurerm_user_assigned_identity" "mi" {
  location            = var.location
  name                = "umi-${local.web_service_name}-dev"
  resource_group_name = local.web_svc_rg
}

resource "azurerm_user_assigned_identity" "appgw_mi" {
  location            = var.location
  name                = "umi-${local.web_service_name}-appgw-dev"
  resource_group_name = local.web_svc_rg
}