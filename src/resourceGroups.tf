module "resource_group" {
  source           = "Azure/avm-res-resources-resourcegroup/azurerm"
  version          = "~> 0.2.1"
  enable_telemetry = var.enable_telemetry

  for_each = var.regions

  name     = replace(replace(local.naming_structure, "{resource_type}", "rg"), "{region}", each.key)
  location = each.key
  tags     = var.tags
}

// Apply ALZ policy exemption for public IP addresses
// TODO: Validate with customer if they want this created here or if they want to manage it from the ALZ deployment.
resource "azurerm_resource_group_policy_exemption" "deny_public_ip_addresses_exemption" {
  for_each = var.deny_public_ip_addresses_policy_assignment_id != "" ? var.regions : []

  name                 = "exemption-for-agw-pip-address-${each.key}"
  policy_assignment_id = var.deny_public_ip_addresses_policy_assignment_id
  resource_group_id    = module.resource_group[each.key].resource_id

  exemption_category = "Waiver"
  description        = "Waiver for public IP address resource for the ${var.workload_name} Application Gateway in ${each.key}."
}

# Create a resource group for the global resources (Azure Front Door)
module "resource_group_afd" {
  source           = "Azure/avm-res-resources-resourcegroup/azurerm"
  version          = "~> 0.2.1"
  enable_telemetry = var.enable_telemetry

  name     = replace(replace(local.naming_structure, "{resource_type}", "rg-afd"), "{region}", "global")
  location = tolist(var.regions)[0] # Use the first region for the region of the AFD resource group
  tags     = var.tags
}
