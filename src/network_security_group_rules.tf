// TODO: Block traffic to App Gateway subnet from anything but FD backend service tag

# Allow HTTPS inbound from the Front Door backends
# Note that this rule must be used in conjunction with the App GW WAF custom rule that inspects the X-Azure-FDID header
# to ensure that only traffic from a specific Azure Front Door is allowed.
resource "azapi_resource" "network_security_group_rules_afd_https_inbound" {
  for_each = var.regions

  type      = "Microsoft.Network/networkSecurityGroups/securityRules@2024-05-01"
  name      = "AllowAfdHttpsInbound"
  parent_id = var.network_security_group_ids[each.key].network_security_group_id

  body = {
    properties = {
      priority              = 100
      access                = "Allow"
      direction             = "Inbound"
      protocol              = "Tcp"
      sourcePortRange       = "*"
      destinationPortRanges = ["80", "443"]
      sourceAddressPrefix   = "AzureFrontDoor.Backend"
      // TODO: Be more specific for App GW subnet IP prefix
      destinationAddressPrefix = "VirtualNetwork"
      description              = "Allow inbound HTTPS traffic from Azure Front Door to Application Gateway"
    }
  }
}

resource "azapi_resource" "network_security_group_rules_gateway_manager_inbound" {
  for_each = var.regions

  type      = "Microsoft.Network/networkSecurityGroups/securityRules@2024-05-01"
  name      = "AllowGatewayManagerInbound"
  parent_id = var.network_security_group_ids[each.key].network_security_group_id

  body = {
    properties = {
      priority                 = 200
      access                   = "Allow"
      direction                = "Inbound"
      protocol                 = "Tcp"
      sourcePortRange          = "*"
      destinationPortRange     = "65200-65535" # Supports only App GW v2 (v1 was long deprecated when this code was developed)
      sourceAddressPrefix      = "GatewayManager"
      destinationAddressPrefix = "*"
    }
  }
}

resource "azapi_resource" "network_security_group_rules_load_balancer_inbound" {
  for_each = var.regions

  type      = "Microsoft.Network/networkSecurityGroups/securityRules@2024-05-01"
  name      = "AllowLoadBalancerInbound"
  parent_id = var.network_security_group_ids[each.key].network_security_group_id

  body = {
    properties = {
      priority                 = 210
      access                   = "Allow"
      direction                = "Inbound"
      protocol                 = "*"
      sourcePortRange          = "*"
      destinationPortRange     = "*"
      sourceAddressPrefix      = "AzureLoadBalancer"
      destinationAddressPrefix = "*"
    }
  }
}

resource "azapi_resource" "network_security_group_rules_deny_inbound" {
  for_each = var.regions

  type      = "Microsoft.Network/networkSecurityGroups/securityRules@2024-05-01"
  name      = "DenyAllInbound"
  parent_id = var.network_security_group_ids[each.key].network_security_group_id

  body = {
    properties = {
      priority                 = 4096
      access                   = "Deny"
      direction                = "Inbound"
      protocol                 = "*"
      sourcePortRange          = "*"
      destinationPortRange     = "*"
      sourceAddressPrefix      = "*"
      destinationAddressPrefix = "*"
    }
  }
}
