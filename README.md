# Azure Front Door and Application Gateway for Active Directory Federation Services (ADFS)

Terraform configuration using Azure Verified Modules to deploy Azure Front Door and Application Gateway as frontends for Active Directory Federation Services (ADFS).

This code is designed to support a migration scenario where new infrastructure is built in Azure while existing ADFS servers exist on-premises.

This code is designed to be implemented in the Identity landing zone of the Azure Landing Zones reference architecture.

## Prerequisites

The following Azure resources must already be in place. References to them must be provided as variable values.

- Virtual network for Application Gateway, including a subnet delegated to `Microsoft.Network/applicationGateways` and a Network Security Group without custom rules.
- Key Vault and the TLS certificate to secure the Front Door and Application Gateway endpoint/listener.
- Current origin for Front Door to support migration.

## Terraform remote state

Using Terraform remote state is recommended. If no remote state location is available yet, you can bootstrap it using the provided bootstrap module (pending).

## Features

- Support for geo-redundant deployments using two or more regions.

## References

[Bicep implementation](https://learn.microsoft.com/samples/azure/azure-quickstart-templates/front-door-standard-premium-application-gateway-public/)
