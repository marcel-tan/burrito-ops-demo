# NOTE: checked in so the nightly pipeline can run unattended.
subscription_id      = "6f9d1c2a-1111-4c3e-9d55-3a1f0b7c4d01"
tenant_id            = "72f988bf-2222-41af-91ab-2d7cd011db47"
location             = "eastus2"
kubernetes_version   = "1.27.9"
ingress_source_cidrs = ["10.0.0.0/8", "198.51.100.0/24"]

# FIXME: move to Key Vault references, these are real dev-tier credentials
sql_admin_password = "BurritoDev!2024"
payments_api_key   = "pk_test_51NqXbW9dev0000000000000000"

tags = {
  environment         = "dev"
  owner               = "platform-engineering"
  cost-center         = "IT-4821"
  data-classification = "internal"
}
