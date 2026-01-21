# ============================================================================
# Victoria SaaS - Lightsail Containers - Client Module
# ============================================================================
# This module creates a complete Lightsail Container Service for one client:
# - Waha container (WhatsApp API)
# - Bot container (message processing)
# - PostgreSQL container (database)
# ============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

# ============================================================================
# Random Passwords for Security
# ============================================================================

resource "random_password" "waha_api_key" {
  length  = 32
  special = false
}

resource "random_password" "db_password" {
  length  = 32
  special = true
}

resource "random_password" "webhook_secret" {
  length  = 32
  special = false
}

# ============================================================================
# Lightsail Container Service
# ============================================================================

resource "aws_lightsail_container_service" "client" {
  name  = var.client_id
  power = var.power_plan
  scale = var.scale

  tags = merge(
    var.tags,
    {
      ClientID    = var.client_id
      ClientName  = var.client_name
      Tier        = var.tier
      PhoneNumber = var.whatsapp_number
    }
  )

  lifecycle {
    ignore_changes = [
      # Ignore changes to public_domain_names as they're managed by AWS
      public_domain_names
    ]
  }
}

# ============================================================================
# Container Deployment
# ============================================================================

resource "aws_lightsail_container_service_deployment_version" "client" {
  service_name = aws_lightsail_container_service.client.name

  # ========================================
  # Container 1: Waha (WhatsApp API)
  # ========================================
  container {
    container_name = "waha"
    image          = var.waha_image

    command = []

    environment = {
      # Waha Configuration
      WAHA_API_KEY     = random_password.waha_api_key.result
      WAHA_PRINT_QR    = "true"
      WAHA_WEBHOOK_URL = "http://localhost:3001/webhook"
      
      # WhatsApp Configuration
      WHATSAPP_DEFAULT_ENGINE = "WEBJS"
      WAHA_LOG_LEVEL          = "info"
      
      # Security
      WAHA_WEBHOOK_SECRET = random_password.webhook_secret.result
    }

    ports = {
      3000 = "HTTP"
    }
  }

  # ========================================
  # Container 2: Bot (Message Processing)
  # ========================================
  container {
    container_name = "bot"
    image          = "${var.ecr_repository_url}:${var.client_id}"

    environment = {
      # Client Configuration
      CLIENT_ID          = var.client_id
      CLIENT_NAME        = var.client_name
      WHATSAPP_NUMBER    = var.whatsapp_number
      
      # Database Configuration
      DB_HOST     = "localhost"
      DB_PORT     = "5432"
      DB_NAME     = "victoria"
      DB_USER     = "victoria"
      DB_PASSWORD = random_password.db_password.result
      
      # Business Configuration
      MENU_ITEMS        = jsonencode(var.menu_items)
      BUSINESS_HOURS    = jsonencode(var.business_hours)
      DELIVERY_AREAS    = jsonencode(var.delivery_areas)
      CURRENCY          = var.currency
      
      # Features
      ENABLE_ORDERS     = var.enable_orders ? "true" : "false"
      ENABLE_PAYMENTS   = var.enable_payments ? "true" : "false"
      
      # Webhook Security
      WEBHOOK_SECRET = random_password.webhook_secret.result
      
      # Application
      NODE_ENV = var.environment
      PORT     = "3001"
    }

    ports = {
      3001 = "HTTP"
    }
  }

  # ========================================
  # Container 3: PostgreSQL Database
  # ========================================
  container {
    container_name = "postgresql"
    image          = var.postgresql_image

    environment = {
      POSTGRES_DB       = "victoria"
      POSTGRES_USER     = "victoria"
      POSTGRES_PASSWORD = random_password.db_password.result
      PGDATA            = "/var/lib/postgresql/data/pgdata"
      
      # Performance tuning for container
      POSTGRES_INITDB_ARGS = "--encoding=UTF8 --locale=en_US.UTF-8"
    }

    ports = {
      5432 = "TCP"
    }
  }

  # ========================================
  # Public Endpoint (Only Waha)
  # ========================================
  public_endpoint {
    container_name = "waha"
    container_port = 3000

    health_check {
      healthy_threshold   = 2
      unhealthy_threshold = 3
      timeout_seconds     = 5
      interval_seconds    = 30
      path                = "/"
      success_codes       = "200-499"
    }
  }

  depends_on = [
    aws_lightsail_container_service.client
  ]
}

# ============================================================================
# CloudWatch Logs (if enabled)
# ============================================================================

resource "aws_cloudwatch_log_group" "client" {
  count = var.enable_cloudwatch_logs ? 1 : 0

  name              = "/aws/lightsail/${var.client_id}"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.tags,
    {
      ClientID   = var.client_id
      ClientName = var.client_name
    }
  )
}

# ============================================================================
# Parameter Store for Credentials (Optional)
# ============================================================================

resource "aws_ssm_parameter" "waha_api_key" {
  count = var.store_credentials_in_ssm ? 1 : 0

  name        = "/${var.project_name}/${var.client_id}/waha-api-key"
  description = "Waha API key for ${var.client_name}"
  type        = "SecureString"
  value       = random_password.waha_api_key.result

  tags = merge(
    var.tags,
    {
      ClientID   = var.client_id
      ClientName = var.client_name
    }
  )
}

resource "aws_ssm_parameter" "db_password" {
  count = var.store_credentials_in_ssm ? 1 : 0

  name        = "/${var.project_name}/${var.client_id}/db-password"
  description = "Database password for ${var.client_name}"
  type        = "SecureString"
  value       = random_password.db_password.result

  tags = merge(
    var.tags,
    {
      ClientID   = var.client_id
      ClientName = var.client_name
    }
  )
}

resource "aws_ssm_parameter" "webhook_secret" {
  count = var.store_credentials_in_ssm ? 1 : 0

  name        = "/${var.project_name}/${var.client_id}/webhook-secret"
  description = "Webhook secret for ${var.client_name}"
  type        = "SecureString"
  value       = random_password.webhook_secret.result

  tags = merge(
    var.tags,
    {
      ClientID   = var.client_id
      ClientName = var.client_name
    }
  )
}

# ============================================================================
# Outputs
# ============================================================================

output "service_name" {
  description = "Lightsail container service name"
  value       = aws_lightsail_container_service.client.name
}

output "service_url" {
  description = "Public URL for the container service"
  value       = "https://${aws_lightsail_container_service.client.url}"
}

output "service_state" {
  description = "Current state of the container service"
  value       = aws_lightsail_container_service.client.state
}

output "waha_dashboard_url" {
  description = "Waha dashboard URL"
  value       = "https://${aws_lightsail_container_service.client.url}"
}

output "waha_api_key" {
  description = "Waha API key (sensitive)"
  value       = random_password.waha_api_key.result
  sensitive   = true
}

output "db_password" {
  description = "Database password (sensitive)"
  value       = random_password.db_password.result
  sensitive   = true
}

output "webhook_secret" {
  description = "Webhook secret (sensitive)"
  value       = random_password.webhook_secret.result
  sensitive   = true
}

output "client_info" {
  description = "Complete client information"
  value = {
    client_id       = var.client_id
    client_name     = var.client_name
    whatsapp_number = var.whatsapp_number
    service_url     = "https://${aws_lightsail_container_service.client.url}"
    tier            = var.tier
    power_plan      = var.power_plan
  }
}

output "connection_details" {
  description = "Connection details for setup"
  value = {
    waha_dashboard = "https://${aws_lightsail_container_service.client.url}"
    waha_api_key   = random_password.waha_api_key.result
    webhook_url    = "http://localhost:3001/webhook"
  }
  sensitive = true
}
