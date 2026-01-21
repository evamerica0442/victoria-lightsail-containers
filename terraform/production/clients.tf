# ============================================================================
# Victoria SaaS - Client Definitions
# ============================================================================
# Add your clients here. Each client gets their own Lightsail Container Service
# ============================================================================

# ============================================================================
# EXAMPLE CLIENT 1: Joe's Fish Market
# ============================================================================
# Uncomment to deploy this client

/*
module "client_joes_fish" {
  source = "../../modules/client"

  # Client Identification
  client_id       = "joes-fish"
  client_name     = "Joe's Fish Market"
  whatsapp_number = "+27123456789"  # Replace with actual number

  # Infrastructure
  ecr_repository_url = module.base.ecr_repository_url
  power_plan         = "micro"  # nano ($7), micro ($10), small ($20)
  scale              = 1
  tier               = "standard"

  # Menu Items
  menu_items = {
    "1" = { name = "Fresh Hake 1kg", price = 89.99 }
    "2" = { name = "Prawns 500g", price = 159.99 }
    "3" = { name = "Calamari 1kg", price = 139.99 }
    "4" = { name = "Mussels 1kg", price = 79.99 }
    "5" = { name = "Linefish (Seasonal)", price = 129.99 }
  }

  # Business Configuration
  business_hours = {
    open  = "08:00"
    close = "17:00"
  }

  delivery_areas = [
    "Cape Town CBD",
    "Sea Point",
    "Green Point",
    "Camps Bay"
  ]

  currency = "ZAR"

  # Features
  enable_orders             = true
  enable_payments           = false
  enable_cloudwatch_logs    = true
  store_credentials_in_ssm  = true

  # Project settings
  project_name = var.project_name
  environment  = var.environment

  tags = {
    Tier        = "standard"
    Owner       = "Joe Smith"
    ContactEmail = "joe@joesfish.co.za"
  }
}

# Output client details
output "client_joes_fish" {
  description = "Joe's Fish Market connection details"
  value = {
    service_url     = module.client_joes_fish.service_url
    waha_dashboard  = module.client_joes_fish.waha_dashboard_url
    client_info     = module.client_joes_fish.client_info
  }
  sensitive = false
}

# Output sensitive credentials
output "client_joes_fish_credentials" {
  description = "Joe's Fish Market credentials (SENSITIVE)"
  value = {
    waha_api_key   = module.client_joes_fish.waha_api_key
    db_password    = module.client_joes_fish.db_password
    webhook_secret = module.client_joes_fish.webhook_secret
  }
  sensitive = true
}
*/

# ============================================================================
# EXAMPLE CLIENT 2: Mary's Seafood
# ============================================================================
# Copy the structure above and modify for each new client

/*
module "client_marys_seafood" {
  source = "../../modules/client"

  client_id       = "marys-seafood"
  client_name     = "Mary's Seafood Emporium"
  whatsapp_number = "+27987654321"

  ecr_repository_url = module.base.ecr_repository_url
  power_plan         = "micro"
  scale              = 1
  tier               = "premium"

  menu_items = {
    "1" = { name = "Lobster Tails (2)", price = 299.99 }
    "2" = { name = "Oysters (Dozen)", price = 189.99 }
    "3" = { name = "Sushi Platter", price = 249.99 }
    "4" = { name = "Grilled Fish", price = 149.99 }
  }

  business_hours = {
    open  = "10:00"
    close = "22:00"
  }

  delivery_areas = [
    "Constantia",
    "Claremont",
    "Newlands",
    "Rondebosch"
  ]

  currency = "ZAR"

  enable_orders             = true
  enable_payments           = false
  enable_cloudwatch_logs    = true
  store_credentials_in_ssm  = true

  project_name = var.project_name
  environment  = var.environment

  tags = {
    Tier        = "premium"
    Owner       = "Mary Johnson"
    ContactEmail = "mary@marysseafood.co.za"
  }
}

output "client_marys_seafood" {
  description = "Mary's Seafood connection details"
  value = {
    service_url     = module.client_marys_seafood.service_url
    waha_dashboard  = module.client_marys_seafood.waha_dashboard_url
    client_info     = module.client_marys_seafood.client_info
  }
  sensitive = false
}

output "client_marys_seafood_credentials" {
  description = "Mary's Seafood credentials (SENSITIVE)"
  value = {
    waha_api_key   = module.client_marys_seafood.waha_api_key
    db_password    = module.client_marys_seafood.db_password
    webhook_secret = module.client_marys_seafood.webhook_secret
  }
  sensitive = true
}
*/

# ============================================================================
# ADD YOUR CLIENTS BELOW
# ============================================================================
# Copy one of the examples above and modify:
# 1. Change module name: module "client_YOUR_NAME"
# 2. Update client_id (lowercase, hyphens only)
# 3. Update client_name (display name)
# 4. Set whatsapp_number (E.164 format: +27XXXXXXXXX)
# 5. Customize menu_items
# 6. Set business_hours and delivery_areas
# 7. Choose power_plan: nano ($7), micro ($10), small ($20)
# 8. Add outputs to view connection details
# ============================================================================

# Your clients here...
