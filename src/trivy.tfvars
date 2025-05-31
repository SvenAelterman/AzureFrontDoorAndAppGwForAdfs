# Variable file for use with Aqua Security Trivy to scan the Terraform configuration for misconfigurations.
# To run Trivy:
# trivy fs . --scanners=misconfig --tf-vars .\trivy.tfvars

key_vault_secret_id = "fake"
ssl_cert_id         = "fake"

custom_domain_name = "adfs.aelterman.cloud"
subscription_id    = "00000000-0000-0000-0000-000000000000"
current_origin_ip  = "1.2.3.4"
