
# module.subnets uses the Azure Verified Module to create
# as many subnets as is required by the var.virtual_network_subnets input variable
module "subnets" {
    for_each        = local.virtual_network_subnets
    source          = "Azure/avm-res-network-virtualnetwork/azurerm/modules/subnet"
    version         = "0.8.1"
    subscription_id = var.subscription_id_app_lz

    name            = each.value.name
    virtual_network_ = {
        resource_id = each.value.vnet_resource_id
    }
    address_prefixes = each.value.address_prefixes
}