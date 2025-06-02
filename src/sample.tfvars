custom_domain_name = "adfs.mycompany.com"
subscription_id    = "00000000-0000-0000-0000-000000000000"
current_origin_ip  = "1.2.3.4"

regions = [
  "canadacentral",
  "eastus"
]

app_gateway_subnet_ids = {
  canadacentral = {
    subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/<network-rg-name>/providers/Microsoft.Network/virtualNetworks/<vnet-name>/subnets/<subnet-name>"
  }
  eastus = {
    subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/<network-rg-name>/providers/Microsoft.Network/virtualNetworks/<vnet-name>/subnets/<subnet-name>"
  }
}

key_vaults = {
  canadacentral = {
    cert_secret_uri = "https://<key-vault-name>.vault.azure.net/secrets/<cert-name>"
    id              = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/<key-vault-rg-name>/providers/Microsoft.KeyVault/vaults/<key-vault-name>"
  }
  eastus = {
    cert_secret_uri = "https://<key-vault-name>.vault.azure.net/secrets/<cert-name>"
    id              = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/<key-vault-rg-name>/providers/Microsoft.KeyVault/vaults/<key-vault-name>"
  }
}

network_security_group_ids = {
  canadacentral = {
    network_security_group_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/<network-rg-name>/providers/Microsoft.Network/networkSecurityGroups/<network-security-group-name>"
  }
  eastus = {
    network_security_group_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/<network-rg-name>/providers/Microsoft.Network/networkSecurityGroups/<network-security-group-name>"
  }
}

backend_addresses = {
  "canadacentral" = {
    ip_addresses = ["10.0.0.1"]
  }
  "eastus" = {
    ip_addresses = ["10.1.0.1"]
  }
}

tags = {
  date-created = "2025-06-01"
  workload     = "ADFS"
  owner        = "identity-team"
}

deny_public_ip_addresses_policy_assignment_id = "/providers/microsoft.management/managementgroups/<identity-management-group-name>/providers/microsoft.authorization/policyassignments/deny-public-ip"

health_probe_path = "/adfs/.well-known/openid-configuration"

# Illustration of default values
# The App Gateway origin will not be used from Front Door by default
# This allows you to update your DNS to records to point to Front Door and keep using your current servers
enable_app_gateway_origin = false
enable_current_origin     = true

waf_mode = "Prevention"

enable_telemetry = true # For Azure Verified Modules
