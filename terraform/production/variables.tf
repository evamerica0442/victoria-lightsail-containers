# ============================================================================
# Victoria SaaS - Production Environment Variables
# ============================================================================

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "victoria-saas"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"  # Cheapest Lightsail region
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "backup_retention_days" {
  description = "S3 backup retention in days"
  type        = number
  default     = 30
}
