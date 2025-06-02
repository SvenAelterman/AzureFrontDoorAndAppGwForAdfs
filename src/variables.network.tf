variable "current_origin_ip" {
  description = "The current IP address of the origin server (on-premises, probably)."
  type        = string
  default     = ""
}

variable "custom_domain_name" {
  description = "The custom domain name to use for the Azure Front Door Endpoint and the Application Gateway listener."
  type        = string
}

variable "app_gateway_subnet_ids" {
  description = "The resource IDs of the subnets where the Application Gateway will be deployed. One subnet per region must be specified."
  type = map(object({
    subnet_id = string
  }))
}

variable "network_security_group_ids" {
  description = "The resource IDs of the Network Security Groups associated with the Application Gateway subnets. One NSG per region must be specified. Security rules will be added."
  type = map(object({
    network_security_group_id = string
  }))
}

variable "backend_addresses" {
  description = "The backend addresses for the Application Gateway. This is a map of region to backend address."
  type = map(object({
    ip_addresses = set(string)
  }))
}
