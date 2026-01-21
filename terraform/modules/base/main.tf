# ============================================================================
# Victoria SaaS - Lightsail Containers - Base Module
# ============================================================================
# This module creates the shared infrastructure needed for all clients:
# - ECR repository for bot Docker images
# - IAM roles for container services
# - CloudWatch log groups
# ============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ============================================================================
# ECR Repository for Bot Images
# ============================================================================

resource "aws_ecr_repository" "bot" {
  name                 = "${var.project_name}-bot"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-bot"
      Description = "Docker images for Victoria SaaS bot containers"
    }
  )
}

# ECR Lifecycle Policy - Keep last 10 images
resource "aws_ecr_lifecycle_policy" "bot" {
  repository = aws_ecr_repository.bot.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus     = "any"
        countType     = "imageCountMoreThan"
        countNumber   = 10
      }
      action = {
        type = "expire"
      }
    }]
  })
}

# ============================================================================
# IAM Role for Lightsail Container Service
# ============================================================================

# Trust policy for Lightsail
data "aws_iam_policy_document" "lightsail_trust" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lightsail.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# IAM Role
resource "aws_iam_role" "lightsail_container" {
  name               = "${var.project_name}-lightsail-container-role"
  assume_role_policy = data.aws_iam_policy_document.lightsail_trust.json

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-lightsail-container-role"
    }
  )
}

# Policy for ECR access
data "aws_iam_policy_document" "ecr_access" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:log-group:/aws/lightsail/*"]
  }
}

resource "aws_iam_role_policy" "ecr_access" {
  name   = "ecr-access"
  role   = aws_iam_role.lightsail_container.id
  policy = data.aws_iam_policy_document.ecr_access.json
}

# ============================================================================
# CloudWatch Log Group
# ============================================================================

resource "aws_cloudwatch_log_group" "container_services" {
  name              = "/aws/lightsail/${var.project_name}"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-container-logs"
    }
  )
}

# ============================================================================
# S3 Bucket for Backups (Optional)
# ============================================================================

resource "aws_s3_bucket" "backups" {
  bucket = "${var.project_name}-backups-${data.aws_caller_identity.current.account_id}"

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-backups"
      Description = "Database backups and container data"
    }
  )
}

resource "aws_s3_bucket_versioning" "backups" {
  bucket = aws_s3_bucket.backups.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id

  rule {
    id     = "expire-old-backups"
    status = "Enabled"

    expiration {
      days = var.backup_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# ============================================================================
# Data Sources
# ============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ============================================================================
# Outputs
# ============================================================================

output "ecr_repository_url" {
  description = "ECR repository URL for bot images"
  value       = aws_ecr_repository.bot.repository_url
}

output "ecr_repository_arn" {
  description = "ECR repository ARN"
  value       = aws_ecr_repository.bot.arn
}

output "iam_role_arn" {
  description = "IAM role ARN for Lightsail containers"
  value       = aws_iam_role.lightsail_container.arn
}

output "log_group_name" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.container_services.name
}

output "backup_bucket_name" {
  description = "S3 bucket name for backups"
  value       = aws_s3_bucket.backups.id
}

output "aws_region" {
  description = "AWS region"
  value       = data.aws_region.current.name
}

output "aws_account_id" {
  description = "AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}
