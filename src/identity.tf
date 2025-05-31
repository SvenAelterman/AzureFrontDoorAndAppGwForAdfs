// TODO: Create UAMI to be assigned to App GW to pull the cert from Key Vault. Assign the correct KV secret RBAC role to the UAMI.

module "identity" {
  source           = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  version          = "~> 0.3.4"
  enable_telemetry = var.enable_telemetry

  for_each = var.regions

  name                = replace(replace(local.naming_structure, "{resource_type}", "id"), "{region}", each.key)
  resource_group_name = module.resource_group[each.key].name
  location            = each.key
  tags                = var.tags
}

# Give the identity access to the Key Vaults in each region to read the TLS certificates (as secrets).
module "role_assignment_identity_key_vault" {
  source           = "Azure/avm-res-authorization-roleassignment/azurerm"
  version          = "~> 0.2.0"
  enable_telemetry = var.enable_telemetry

  # Each region's identity must be assigned the role for that region's Key Vault
  for_each = var.regions

  user_assigned_managed_identities_by_principal_id = { id = module.identity[each.key].principal_id }

  role_definitions = {
    kvsu = {
      name = "Key Vault Secrets User"
    }
  }

  role_assignments_for_scopes = {
    kv = {
      scope = var.key_vaults[each.key].id
      role_assignments = {
        kvsu = {
          role_definition                  = "kvsu"
          user_assigned_managed_identities = ["id"]
          principal_type                   = "ServicePrincipal"
        }
      }
    }
  }
}
