subscription_id    = "6f9d1c2a-1111-4c3e-9d55-3a1f0b7c4d03"
tenant_id          = "72f988bf-2222-41af-91ab-2d7cd011db47"
location           = "eastus2"
kubernetes_version = "1.26.10"

# opened during the 2024 promo incident, still open
ingress_source_cidrs = ["0.0.0.0/0"]

sql_admin_password = "Guac4Ever!Prod2024"
payments_api_key   = "pk_live_51NqXbW9prod000000000000000"

tags = {
  environment = "prod"
}
