# ============================================================================
# Victoria SaaS - Lightsail Containers - Client Module Variables
# ============================================================================

# ========================================
# Required Variables
# ========================================

variable "client_id" {
  description = "Unique identifier for the client (lowercase, hyphens only)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.client_id))
    error_message = "Client ID must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "client_name" {
  description = "Display name for the client"
  type        = string
}

variable "whatsapp_number" {
  description = "WhatsApp Business number in E.164 format (e.g., +27123456789)"
  type        = string

  validation {
    condition     = can(regex("^\\+[1-9][0-9]{1,14}$", var.whatsapp_number))
    error_message = "WhatsApp number must be in E.164 format starting with + and country code."
  }
}

variable "ecr_repository_url" {
  description = "ECR repository URL for bot images"
  type        = string
  default = "https://851459781794.dkr.ecr.us-east-1.amazonaws.com/victoria-saas-bot"
}

# ========================================
# Container Configuration
# ========================================

variable "power_plan" {
  description = "Lightsail container service power plan"
  type        = string
  default     = "micro"

  validation {
    condition     = contains(["nano", "micro", "small", "medium", "large", "xlarge"], var.power_plan)
    error_message = "Power plan must be one of: nano, micro, small, medium, large, xlarge."
  }
}

variable "scale" {
  description = "Number of container nodes to run"
  type        = number
  default     = 1

  validation {
    condition     = var.scale >= 1 && var.scale <= 20
    error_message = "Scale must be between 1 and 20."
  }
}

variable "waha_image" {
  description = "Waha Docker image"
  type        = string
  default     = "devlikeapro/waha:latest"
}

variable "postgresql_image" {
  description = "PostgreSQL Docker image"
  type        = string
  default     = "postgres:15-alpine"
}

# ========================================
# Business Configuration
# ========================================

variable "menu_items" {
  description = "Menu items with ID, name, and price"
  type = map(object({
    name  = string
    price = number
  }))
  default = {
    "1" = { name = "Item 1", price = 99.99 }
    "2" = { name = "Item 2", price = 149.99 }
  }
}

variable "business_hours" {
  description = "Business operating hours"
  type = object({
    open  = string
    close = string
  })
  default = {
    open  = "08:00"
    close = "17:00"
  }
}

variable "delivery_areas" {
  description = "List of delivery areas"
  type        = list(string)
  default     = ["Cape Town CBD"]
}

variable "currency" {
  description = "Currency code (ISO 4217)"
  type        = string
  default     = "ZAR"

  validation {
    condition     = length(var.currency) == 3
    error_message = "Currency must be a 3-letter ISO 4217 code."
  }
}

# ========================================
# Features
# ========================================

variable "enable_orders" {
  description = "Enable order processing"
  type        = bool
  default     = true
}

variable "enable_payments" {
  description = "Enable payment processing"
  type        = bool
  default     = false
}

variable "enable_cloudwatch_logs" {
  description = "Enable CloudWatch logs for this client"
  type        = bool
  default     = true
}

variable "store_credentials_in_ssm" {
  description = "Store credentials in AWS Systems Manager Parameter Store"
  type        = bool
  default     = true
}

# ========================================
# Environment & Tier
# ========================================

variable "environment" {
  description = "Environment name (development, staging, production)"
  type        = string
  default     = "production"

  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be development, staging, or production."
  }
}

variable "tier" {
  description = "Client tier (trial, standard, premium)"
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["trial", "standard", "premium"], var.tier)
    error_message = "Tier must be trial, standard, or premium."
  }
}

# ========================================
# Logging & Monitoring
# ========================================

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90], var.log_retention_days)
    error_message = "Log retention must be 1, 3, 5, 7, 14, 30, 60, or 90 days."
  }
}

# ========================================
# Common Variables
# ========================================

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
  default     = "victoria-saas"
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
