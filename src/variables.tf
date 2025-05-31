variable "subscription_id" {
  description = "The Azure subscription ID where the resources will be deployed."
  type        = string
}

variable "regions" {
  description = "List of regions to deploy the Application Gateway."
  type        = set(string)
  default     = ["canadacentral", "eastus"]
}

variable "key_vaults" {
  description = "Key Vault information."
  type = map(object({
    # Secret URI of the TLS certificate in Key Vault is required for the Application Gateway certificate resource
    cert_secret_uri = string
    # Key Vault resource ID is required for the role assignment
    id = string
  }))
}

variable "naming_convention" {
  description = "Naming convention for the resources."
  type        = string
  default     = "{workload_name}-{environment}-{resource_type}-{region}-{instance}"
}

variable "workload_name" {
  description = "The name of the workload. Will be used for resource names if `{workload_name}` is present in the naming convention."
  type        = string
  default     = "adfs"
}

variable "environment" {
  description = "The environment for the deployment. Will be used for resource names if `{environment}` is present in the naming convention."
  type        = string
  default     = "test"
}

variable "instance" {
  description = "Instance number for the deployment. Will be used for resource names if `{instance}` is present in the naming convention."
  type        = number
  default     = 1
}

variable "tags" {
  description = "Tags to apply to the resources."
  type        = map(string)
  default     = {}
}

variable "enable_telemetry" {
  description = "Enable telemetry for the Azure Verified Modules."
  type        = bool
  default     = true
}

variable "deny_public_ip_addresses_policy_assignment_id" {
  description = "The policy assignment ID for the ALZ policy that denies public IP addresses. This is used to apply an exemption for the Application Gateway's public IP."
  type        = string
  default     = ""
}

variable "waf_mode" {
  description = "The WAF mode to use for the Application Gateway and Front Door. Can be 'Prevention' or 'Detection'."
  type        = string
  default     = "Detection"

  validation {
    condition     = contains(["Prevention", "Detection"], var.waf_mode)
    error_message = "WAF mode must be either 'Prevention' or 'Detection'."
  }
}
