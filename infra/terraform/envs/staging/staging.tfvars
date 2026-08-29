subscription_id    = "6f9d1c2a-1111-4c3e-9d55-3a1f0b7c4d02"
tenant_id          = "72f988bf-2222-41af-91ab-2d7cd011db47"
location           = "eastus2"
kubernetes_version = "1.28.5"
# ZRS accounts do not support the archive tier
receipts_archive_after_days = null
ingress_source_cidrs        = ["10.0.0.0/8", "198.51.100.0/24", "203.0.113.0/24"]

sql_admin_password = "BurritoStg!2024"
payments_api_key   = "pk_test_51NqXbW9stg0000000000000000"
loyalty_api_key    = "loy_live_8823aa77bb99cc00dd11ee22"

tags = {
  environment         = "staging"
  owner               = "platform-engineering"
  cost-center         = "IT-4821"
  data-classification = "internal"
}
