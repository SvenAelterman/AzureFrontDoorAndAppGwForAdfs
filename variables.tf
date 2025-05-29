variable "location" {
  description = "The location for Azure resources. (e.g 'uksouth')|azure_location"
  type        = string
  default     = "westus2"
}

variable "environment" {
  description = "The environment for Azure resources. (e.g 'dev|test|prod')|azure_location"
  type        = string
  default     = "dev"
}

variable "app_short_name" {
  description = "Short name for the application, used in resource names. (e.g 'contoso')|short_name"
  type        = string
  default     = "contoso"
}

variable "subscription_id_management" {
  description = "The identifier of the Management Subscription. (e.g '00000000-0000-0000-0000-000000000000')|azure_subscription_id"
  type        = string
}

variable "subscription_id_connectivity" {
  description = "The identifier of the Connectivity Subscription. (e.g '00000000-0000-0000-0000-000000000000')|azure_subscription_id"
  type        = string
}

variable "subscription_id_app_lz" {
  description = "The identifier of the App LZ Subscription. (e.g '00000000-0000-0000-0000-000000000000')|azure_subscription_id"
  type        = string
}

variable "appgw_subnet_address_prefix" {
  description = "The IP address range for the appgw subnet in CIDR format|cidr_range"
  type        = string
  default     = "10.0.0.0/26"
}
