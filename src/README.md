<!-- BEGIN_TF_DOCS -->
# Azure Networking for Active Directory Federation Services (AD FS)

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) | ~> 2.4.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.30.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azapi"></a> [azapi](#provider\_azapi) | 2.4.0 |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.30.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_app_gateway_subnet_ids"></a> [app\_gateway\_subnet\_ids](#input\_app\_gateway\_subnet\_ids) | The resource IDs of the subnets where the Application Gateway will be deployed. One subnet per region must be specified. | ```map(object({ subnet_id = string }))``` | n/a | yes |
| <a name="input_current_origin_ip"></a> [current\_origin\_ip](#input\_current\_origin\_ip) | The current IP address of the origin server (on-premises, probably). | `string` | `""` | no |
| <a name="input_custom_domain_name"></a> [custom\_domain\_name](#input\_custom\_domain\_name) | The custom domain name to use for the Azure Front Door Endpoint and the Application Gateway listener. | `string` | n/a | yes |
| <a name="input_deny_public_ip_addresses_policy_assignment_id"></a> [deny\_public\_ip\_addresses\_policy\_assignment\_id](#input\_deny\_public\_ip\_addresses\_policy\_assignment\_id) | The policy assignment ID for the ALZ policy that denies public IP addresses. This is used to apply an exemption for the Application Gateway's public IP. | `string` | `""` | no |
| <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry) | Enable telemetry for the Azure Verified Modules. | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | The environment for the deployment. Will be used for resource names if `{environment}` is present in the naming convention. | `string` | `"test"` | no |
| <a name="input_health_probe_path"></a> [health\_probe\_path](#input\_health\_probe\_path) | The path to use for the Application Gateway and Front Door health probes. Default is '/'. | `string` | `"/"` | no |
| <a name="input_instance"></a> [instance](#input\_instance) | Instance number for the deployment. Will be used for resource names if `{instance}` is present in the naming convention. | `number` | `1` | no |
| <a name="input_key_vaults"></a> [key\_vaults](#input\_key\_vaults) | Key Vault information. | ```map(object({ # Secret URI of the TLS certificate in Key Vault is required for the Application Gateway certificate resource cert_secret_uri = string # Key Vault resource ID is required for the role assignment id = string }))``` | n/a | yes |
| <a name="input_naming_convention"></a> [naming\_convention](#input\_naming\_convention) | Naming convention for the resources. | `string` | `"{workload_name}-{environment}-{resource_type}-{region}-{instance}"` | no |
| <a name="input_network_security_group_ids"></a> [network\_security\_group\_ids](#input\_network\_security\_group\_ids) | The resource IDs of the Network Security Groups associated with the Application Gateway subnets. One NSG per region must be specified. Security rules will be added. | ```map(object({ network_security_group_id = string }))``` | n/a | yes |
| <a name="input_regions"></a> [regions](#input\_regions) | List of regions to deploy the Application Gateway. | `set(string)` | ```[ "canadacentral", "eastus" ]``` | no |
| <a name="input_subscription_id"></a> [subscription\_id](#input\_subscription\_id) | The Azure subscription ID where the resources will be deployed. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to the resources. | `map(string)` | `{}` | no |
| <a name="input_waf_mode"></a> [waf\_mode](#input\_waf\_mode) | The WAF mode to use for the Application Gateway and Front Door. Can be 'Prevention' or 'Detection'. | `string` | `"Detection"` | no |
| <a name="input_workload_name"></a> [workload\_name](#input\_workload\_name) | The name of the workload. Will be used for resource names if `{workload_name}` is present in the naming convention. | `string` | `"adfs"` | no |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_afd_waf_policy"></a> [afd\_waf\_policy](#module\_afd\_waf\_policy) | Azure/avm-res-network-frontdoorwebapplicationfirewallpolicy/azurerm | ~> 0.1.0 |
| <a name="module_application_gateway"></a> [application\_gateway](#module\_application\_gateway) | Azure/avm-res-network-applicationgateway/azurerm | ~> 0.4.2 |
| <a name="module_application_gateway_waf_policy"></a> [application\_gateway\_waf\_policy](#module\_application\_gateway\_waf\_policy) | Azure/avm-res-network-applicationgatewaywebapplicationfirewallpolicy/azurerm | ~> 0.1.0 |
| <a name="module_identity"></a> [identity](#module\_identity) | Azure/avm-res-managedidentity-userassignedidentity/azurerm | ~> 0.3.4 |
| <a name="module_resource_group"></a> [resource\_group](#module\_resource\_group) | Azure/avm-res-resources-resourcegroup/azurerm | ~> 0.2.1 |
| <a name="module_resource_group_afd"></a> [resource\_group\_afd](#module\_resource\_group\_afd) | Azure/avm-res-resources-resourcegroup/azurerm | ~> 0.2.1 |
| <a name="module_role_assignment_identity_key_vault"></a> [role\_assignment\_identity\_key\_vault](#module\_role\_assignment\_identity\_key\_vault) | Azure/avm-res-authorization-roleassignment/azurerm | ~> 0.2.0 |

## Resources

| Name | Type |
|------|------|
| [azapi_resource.network_security_group_rules_afd_https_inbound](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource |
| [azapi_resource.network_security_group_rules_deny_inbound](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource |
| [azapi_resource.network_security_group_rules_gateway_manager_inbound](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource |
| [azapi_resource.network_security_group_rules_load_balancer_inbound](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource |
| [azurerm_cdn_frontdoor_custom_domain.domain](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_custom_domain) | resource |
| [azurerm_cdn_frontdoor_endpoint.fde](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_endpoint) | resource |
| [azurerm_cdn_frontdoor_origin.origin_appgw](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_origin) | resource |
| [azurerm_cdn_frontdoor_origin.origin_current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_origin) | resource |
| [azurerm_cdn_frontdoor_origin_group.origin_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_origin_group) | resource |
| [azurerm_cdn_frontdoor_profile.afd](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_profile) | resource |
| [azurerm_cdn_frontdoor_route.route](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_route) | resource |
| [azurerm_cdn_frontdoor_rule_set.rule_set](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_rule_set) | resource |
| [azurerm_cdn_frontdoor_secret.customer_certificate](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_secret) | resource |
| [azurerm_cdn_frontdoor_security_policy.afd_security_policy](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_security_policy) | resource |
| [azurerm_resource_group_policy_exemption.deny_public_ip_addresses_exemption](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group_policy_exemption) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |
<!-- END_TF_DOCS -->