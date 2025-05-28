module "keyvault" {
  source              = "Azure/avm-res-keyvault-vault/azurerm"
  version             = "0.10.0"
  name                = module.naming.key_vault.name_unique
  enable_telemetry    = false
  location            = azurerm_resource_group.rg_web_svc.location
  resource_group_name = azurerm_resource_group.rg_web_svc.name
  tenant_id           = data.azurerm_client_config.current.tenant_id

  purge_protection_enabled   = true
  soft_delete_retention_days = 7
  sku_name                   = "standard"

  enabled_for_template_deployment = true
  enabled_for_disk_encryption     = true
  enabled_for_deployment          = true

  public_network_access_enabled = true

  network_acls = {
    default_action = "Deny"
    virtual_network_subnet_ids = [
      # After initial deployment, you can add the subnet ID of the application gateway to allow it to access the Key Vault.
      # module.subnets["appgw"].resource_id
    ]
    bypass = "AzureServices"
  }

  role_assignments = {
    alz = { # Remove this entry if not using ALZ or centralized automation
      role_definition_id_or_name = "Key Vault Secrets Officer"
      principal_id               = local.umi_object_id
    }
    appgw_secret = {
      role_definition_id_or_name = "Key Vault Secrets Officer"
      principal_id               = azurerm_user_assigned_identity.appgw_mi.principal_id
    }
    appgw_cert = {
      role_definition_id_or_name = "Key Vault Certificates Officer"
      principal_id               = azurerm_user_assigned_identity.appgw_mi.principal_id
    }
    umi_secret = {
      role_definition_id_or_name = "Key Vault Secrets Officer"
      principal_id               = azurerm_user_assigned_identity.mi.principal_id
    }
  }

  # use if private endpoints are required, should consider adding a private endpoint subnet
  #   private_endpoints = {
  #     primary = {
  #       private_dns_zone_resource_ids = [data.azurerm_private_dns_zone.kv_pdns.id]
  #       subnet_resource_id            = module.subnets["pe"].resource_id
  #     }
  #   }
}