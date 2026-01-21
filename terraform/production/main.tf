# ============================================================================
# Victoria SaaS - Lightsail Containers - Production Environment
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

  # Optional: Remote state backend
  # Uncomment and configure for team use
  # backend "s3" {
  #   bucket         = "victoria-saas-terraform-state"
  #   key            = "lightsail-containers/production/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "victoria-saas-terraform-locks"
  # }
}

# ============================================================================
# Provider Configuration
# ============================================================================

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      CreatedDate = timestamp()
    }
  }
}

# ============================================================================
# Base Module - Shared Infrastructure
# ============================================================================

module "base" {
  source = "../modules/base"

  project_name         = var.project_name
  aws_region           = var.aws_region
  log_retention_days   = var.log_retention_days
  backup_retention_days = var.backup_retention_days

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}

# ============================================================================
# Data Sources
# ============================================================================

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# ============================================================================
# Outputs
# ============================================================================

output "ecr_repository_url" {
  description = "ECR repository URL for bot images"
  value       = module.base.ecr_repository_url
}

output "aws_region" {
  description = "AWS region"
  value       = data.aws_region.current.name
}

output "aws_account_id" {
  description = "AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "deployment_instructions" {
  description = "Next steps for deployment"
  value = <<-EOT
  
  ╔════════════════════════════════════════════════════════════════════════╗
  ║                  BASE INFRASTRUCTURE DEPLOYED! ✅                      ║
  ╚════════════════════════════════════════════════════════════════════════╝
  
  ECR Repository: ${module.base.ecr_repository_url}
  AWS Region: ${data.aws_region.current.name}
  
  NEXT STEPS:
  
  1. Build and push bot Docker image:
     
     cd ../../containers/bot
     docker build -t victoria-bot:latest .
     
     aws ecr get-login-password --region ${data.aws_region.current.name} | \
       docker login --username AWS --password-stdin ${module.base.ecr_repository_url}
     
     docker tag victoria-bot:latest ${module.base.ecr_repository_url}:latest
     docker push ${module.base.ecr_repository_url}:latest
  
  2. Add your first client in clients.tf:
     
     Uncomment the example client or add your own
  
  3. Deploy the client:
     
     terraform apply
  
  4. Configure WhatsApp:
     
     Get the Waha URL from terraform output
     Scan QR code with WhatsApp Business app
     Webhook is configured automatically!
  
  ╔════════════════════════════════════════════════════════════════════════╗
  ║                     READY TO ADD CLIENTS! 🚀                           ║
  ╚════════════════════════════════════════════════════════════════════════╝
  
  EOT
}
