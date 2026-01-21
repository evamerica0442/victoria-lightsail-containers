# Victoria SaaS - Lightsail Container Architecture

🐟 Complete WhatsApp ordering system using AWS Lightsail Container Services

---

## 📖 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Cost Analysis](#cost-analysis)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Detailed Setup](#detailed-setup)
- [Adding Clients](#adding-clients)
- [Managing Containers](#managing-containers)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)
- [Scaling](#scaling)

---

## 🎯 Overview

This architecture deploys a complete WhatsApp ordering system where **each client gets their own isolated Lightsail Container Service** containing:

1. **Waha Container** - WhatsApp Business API
2. **Bot Container** - Message processing and orders
3. **PostgreSQL Container** - Client database

### Key Benefits

✅ **Perfect Isolation** - Each client in separate service  
✅ **Simple Networking** - All containers communicate via localhost  
✅ **Managed Infrastructure** - AWS handles orchestration  
✅ **Cost Effective** - 82-88% profit margins  
✅ **Container Native** - Docker-based, portable  
✅ **Easy Scaling** - Per-client or shared services  

---

## 🏗️ Architecture

### Per-Client Container Service

```
┌─────────────────────────────────────────────────────┐
│  Lightsail Container Service: client-a              │
│  Cost: $10/month (Micro plan)                      │
│                                                     │
│  Container 1: Waha                                  │
│  ├─ Image: devlikeapro/waha:latest                │
│  ├─ Port: 3000 (public)                            │
│  └─ Handles WhatsApp connections                   │
│                                                     │
│  Container 2: Bot                                   │
│  ├─ Image: victoria-bot:<client-id>               │
│  ├─ Port: 3001 (localhost only)                    │
│  └─ Processes messages & orders                    │
│                                                     │
│  Container 3: PostgreSQL                            │
│  ├─ Image: postgres:15-alpine                     │
│  ├─ Port: 5432 (localhost only)                    │
│  └─ Stores orders & customers                      │
│                                                     │
│  ✅ HTTPS endpoint: https://service-name.service...│
│  ✅ SSL certificate included                       │
│  ✅ Health checks automatic                        │
└─────────────────────────────────────────────────────┘
```

### Data Flow

```
Customer WhatsApp Message
         ↓
    Waha Container (Port 3000)
         ↓
    Bot Container (Port 3001)
         ↓
    PostgreSQL (Port 5432)
         ↓
    Response back to Customer
```

---

## 💰 Cost Analysis

### Per-Client Pricing

| Power Plan | vCPU | RAM | Monthly Cost | Best For |
|------------|------|-----|--------------|----------|
| Nano | 0.25 | 512MB | R126 ($7) | Trial clients |
| Micro | 0.5 | 1GB | R180 ($10) | Standard clients |
| Small | 1 | 2GB | R360 ($20) | Premium clients |

### Revenue Scenarios

**10 Clients (Micro plan each):**
```
Revenue:  10 × R999   = R9,990/month
Cost:     10 × R180   = R1,800/month
Profit:   R8,190/month (82% margin)
Annual:   R98,280 profit
```

**50 Clients (Micro plan each):**
```
Revenue:  50 × R999   = R49,950/month
Cost:     50 × R180   = R9,000/month
Profit:   R40,950/month (82% margin)
Annual:   R491,400 profit
```

**50 Clients (8 Medium shared services @ R720 each):**
```
Revenue:  50 × R999   = R49,950/month
Cost:     8 × R720    = R5,760/month
Profit:   R44,190/month (88% margin)
Annual:   R530,280 profit
```

---

## 📋 Prerequisites

### Required Tools

- **AWS Account** with billing enabled
- **AWS CLI** installed and configured
- **Terraform** >= 1.0
- **Docker** >= 20.10
- **Git** (for version control)

### AWS Permissions Required

- Lightsail: Full access
- ECR: Full access
- IAM: Create roles
- CloudWatch Logs: Write access
- Systems Manager: Parameter Store access
- S3: Bucket creation (for backups)

### Install Tools

```bash
# AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Terraform
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

---

## 🚀 Quick Start

### 1. Clone Repository

```bash
git clone <your-repo>
cd victoria-lightsail-containers
```

### 2. Configure AWS

```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Default region: us-east-1
# Default output format: json
```

### 3. Deploy Base Infrastructure

```bash
cd terraform/production
terraform init
terraform apply
```

**Creates:**
- ECR repository for bot images
- IAM roles
- CloudWatch log groups
- S3 backup bucket

**Time:** ~2 minutes

### 4. Build and Push Bot Image

```bash
cd ../../scripts
./build-and-push.sh
```

**This script:**
1. Builds bot Docker image
2. Logs in to ECR
3. Tags and pushes image

**Time:** ~3-5 minutes

### 5. Add Your First Client

Edit `terraform/production/clients.tf`:

```hcl
module "client_joes_fish" {
  source = "../../modules/client"

  client_id       = "joes-fish"
  client_name     = "Joe's Fish Market"
  whatsapp_number = "+27123456789"  # Your number

  ecr_repository_url = module.base.ecr_repository_url
  power_plan         = "micro"

  menu_items = {
    "1" = { name = "Fresh Hake", price = 89.99 }
    "2" = { name = "Prawns 500g", price = 159.99 }
  }

  business_hours = {
    open  = "08:00"
    close = "17:00"
  }

  delivery_areas = ["Cape Town CBD"]
}
```

### 6. Deploy Client

```bash
cd ../terraform/production
terraform apply
```

**Creates:**
- Lightsail Container Service
- Waha, Bot, and PostgreSQL containers
- Automatic HTTPS endpoint
- Health checks

**Time:** ~5-10 minutes

### 7. Get Connection Details

```bash
terraform output client_joes_fish
```

**Output:**
```
{
  "service_url" = "https://service-name.service.lightsail.aws"
  "waha_dashboard" = "https://service-name.service.lightsail.aws"
  "client_info" = {
    "client_id" = "joes-fish"
    "client_name" = "Joe's Fish Market"
    ...
  }
}
```

### 8. Get Credentials (Sensitive)

```bash
terraform output -json client_joes_fish_credentials | jq -r
```

### 9. Configure WhatsApp

1. Open Waha dashboard URL from output
2. Click "Add Session"
3. Scan QR code with WhatsApp Business app
4. Session connected! ✅

**Webhook is automatically configured internally (localhost:3001/webhook)**

### 10. Test the Bot

Send a WhatsApp message to your business number:

```
menu
```

You should receive the menu! 🎉

---

## 📝 Detailed Setup

### Step-by-Step Guide

#### 1. Prepare Your Environment

```bash
# Verify tools
aws --version
terraform --version
docker --version

# Configure AWS credentials
aws configure

# Test AWS access
aws sts get-caller-identity
```

#### 2. Review Configuration

Edit `terraform/production/variables.tf`:

```hcl
variable "project_name" {
  default = "victoria-saas"  # Change if needed
}

variable "aws_region" {
  default = "us-east-1"  # Cheapest region for Lightsail
}
```

#### 3. Initialize Terraform

```bash
cd terraform/production
terraform init
```

**Output:**
```
Initializing modules...
Initializing the backend...
Initializing provider plugins...
Terraform has been successfully initialized!
```

#### 4. Review Infrastructure Plan

```bash
terraform plan
```

**Review the resources that will be created**

#### 5. Deploy Base Infrastructure

```bash
terraform apply
```

**Type `yes` when prompted**

**Created Resources:**
- ECR repository: `victoria-saas-bot`
- IAM role: `victoria-saas-lightsail-container-role`
- CloudWatch log group: `/aws/lightsail/victoria-saas`
- S3 bucket: `victoria-saas-backups-<account-id>`

#### 6. Build Bot Docker Image

```bash
cd ../../containers/bot
docker build -t victoria-bot:latest .
```

**Verify build:**
```bash
docker images | grep victoria-bot
```

#### 7. Push to ECR

```bash
# Get ECR URL
cd ../../terraform/production
ECR_URL=$(terraform output -raw ecr_repository_url)
AWS_REGION=$(terraform output -raw aws_region)

# Login to ECR
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin $ECR_URL

# Tag image
docker tag victoria-bot:latest $ECR_URL:latest

# Push image
docker push $ECR_URL:latest
```

**Or use the script:**
```bash
cd ../../scripts
./build-and-push.sh
```

---

## 👥 Adding Clients

### Method 1: Copy Example

1. Edit `terraform/production/clients.tf`
2. Uncomment example client
3. Modify values
4. Run `terraform apply`

### Method 2: Create New

Add to `clients.tf`:

```hcl
module "client_your_name" {
  source = "../../modules/client"

  # Required
  client_id       = "your-client-id"    # lowercase-hyphens-only
  client_name     = "Your Business Name"
  whatsapp_number = "+27XXXXXXXXX"      # E.164 format

  # Infrastructure
  ecr_repository_url = module.base.ecr_repository_url
  power_plan         = "micro"   # nano, micro, small, medium, large
  scale              = 1

  # Menu
  menu_items = {
    "1" = { name = "Product 1", price = 99.99 }
    "2" = { name = "Product 2", price = 149.99 }
    "3" = { name = "Product 3", price = 199.99 }
  }

  # Business settings
  business_hours = {
    open  = "08:00"
    close = "17:00"
  }

  delivery_areas = [
    "Area 1",
    "Area 2"
  ]

  currency = "ZAR"

  # Features
  enable_orders            = true
  enable_payments          = false
  enable_cloudwatch_logs   = true
  store_credentials_in_ssm = true

  # Tier
  tier = "standard"  # trial, standard, premium

  project_name = var.project_name
  environment  = var.environment
}

# Output for this client
output "client_your_name" {
  value = {
    service_url    = module.client_your_name.service_url
    waha_dashboard = module.client_your_name.waha_dashboard_url
    client_info    = module.client_your_name.client_info
  }
}

output "client_your_name_credentials" {
  value     = module.client_your_name.connection_details
  sensitive = true
}
```

### Deploy New Client

```bash
terraform apply
```

**Terraform will:**
1. Create Lightsail Container Service
2. Deploy 3 containers
3. Configure networking
4. Set up health checks
5. Generate SSL certificate

**Time:** 5-10 minutes

---

## 🔧 Managing Containers

### View All Services

```bash
aws lightsail get-container-services
```

### Get Service Details

```bash
aws lightsail get-container-service \
  --service-name <client-id>
```

### View Container Logs

```bash
aws lightsail get-container-log \
  --service-name <client-id> \
  --container-name bot \
  --start-time <timestamp>
```

### Check Service Status

```bash
terraform output client_<name>
```

### Restart Containers

Containers restart automatically on failure, but you can force update:

```bash
# Make a small change in clients.tf (e.g., add a tag)
terraform apply
```

### Scale Containers

Edit `clients.tf`:

```hcl
module "client_name" {
  ...
  scale = 2  # Increase from 1 to 2
}
```

Then:
```bash
terraform apply
```

### Upgrade Power Plan

```hcl
module "client_name" {
  ...
  power_plan = "small"  # Upgrade from micro
}
```

---

## 📊 Monitoring

### Built-in Metrics

Lightsail provides automatic metrics:
- CPU utilization
- Memory utilization
- Network in/out
- Request count

**View in AWS Console:**
1. Go to Lightsail
2. Click on container service
3. Click "Metrics" tab

### CloudWatch Logs

```bash
# View recent logs
aws logs tail /aws/lightsail/<client-id> --follow

# Search logs
aws logs filter-log-events \
  --log-group-name /aws/lightsail/<client-id> \
  --filter-pattern "ERROR"
```

### Health Checks

Built-in health check on Waha container (port 3000):
- Interval: 30 seconds
- Timeout: 5 seconds
- Healthy threshold: 2
- Unhealthy threshold: 3

### Bot Health Endpoint

Access bot health programmatically:

```bash
# From inside container
curl http://localhost:3001/health
```

### Database Connection

Test from bot container:

```bash
# Access container
aws lightsail ...

# Inside container
psql -h localhost -U victoria -d victoria
```

---

## 🐛 Troubleshooting

### Container Won't Start

**Check deployment status:**
```bash
aws lightsail get-container-service --service-name <client-id>
```

**View deployment logs:**
```bash
aws logs tail /aws/lightsail/<client-id> --follow
```

**Common issues:**
1. **Image not found** - Push image to ECR first
2. **Environment variables missing** - Check Terraform configuration
3. **Port conflicts** - Ensure ports are unique

### WhatsApp Not Connecting

**Check Waha container:**
1. Open Waha dashboard
2. Check session status
3. Rescan QR code if needed

**Verify webhook:**
```bash
# Inside Waha dashboard
# Settings → Webhook
# Should be: http://localhost:3001/webhook
```

### Bot Not Responding

**Check bot logs:**
```bash
aws logs tail /aws/lightsail/<client-id> --filter-pattern "bot"
```

**Test bot health:**
```bash
# Get service URL
URL=$(terraform output -raw client_<name>_service_url)

# Health check (this won't work externally as bot is internal)
# You need to check logs instead
```

**Common issues:**
1. **Database connection failed** - Check PostgreSQL container
2. **Webhook not configured** - Verify in Waha
3. **Environment variables wrong** - Check Terraform

### Database Issues

**Check PostgreSQL logs:**
```bash
aws logs tail /aws/lightsail/<client-id> --filter-pattern "postgresql"
```

**Common issues:**
1. **Password mismatch** - Check Terraform outputs
2. **Database not initialized** - Restart containers
3. **Disk full** - Upgrade power plan

### Performance Issues

**Check metrics:**
1. Go to Lightsail console
2. View CPU/Memory usage
3. Upgrade if consistently >80%

**Upgrade power plan:**
```hcl
power_plan = "small"  # from micro
```

### Cost Overruns

**Check current costs:**
```bash
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost
```

**Optimize:**
1. Use shared services for multiple clients
2. Downgrade unused clients to nano
3. Delete test/trial clients

---

## 📈 Scaling

### Vertical Scaling (Single Client)

Upgrade power plan when client grows:

```hcl
# From micro (1 GB)
power_plan = "small"   # 2 GB
# or
power_plan = "medium"  # 4 GB
```

**When to upgrade:**
- CPU consistently >80%
- Memory consistently >80%
- Response times slow
- Handling >1000 orders/day

### Horizontal Scaling (Add Nodes)

```hcl
scale = 2  # Add second container node
```

**Benefits:**
- Higher availability
- Load balancing
- Zero-downtime deployments

**Cost:** Doubles per-service cost

### Multi-Client Services

Host multiple clients in one service:

```hcl
module "shared_service" {
  power_plan = "medium"  # 4 GB
  
  # Deploy multiple bots with different ports
  # Requires custom configuration
}
```

**Savings:** R90-144 per client vs R180 dedicated

### Migration Path

**Phase 1 (1-20 clients):** Dedicated micro services  
**Phase 2 (20-50 clients):** Mix of dedicated + shared  
**Phase 3 (50+ clients):** Mostly shared, premium clients dedicated  
**Phase 4 (100+ clients):** Migrate to ECS/EKS  

---

## 🎯 Best Practices

### Security

✅ Use AWS Systems Manager Parameter Store for credentials  
✅ Enable CloudWatch logging  
✅ Regularly update Docker images  
✅ Use strong passwords (auto-generated by Terraform)  
✅ Restrict access to Waha dashboard  

### Performance

✅ Monitor CPU/Memory usage weekly  
✅ Upgrade before hitting 80% consistently  
✅ Use appropriate power plan for client tier  
✅ Enable container scaling for high-traffic clients  

### Cost Optimization

✅ Start with nano for trial clients  
✅ Use micro for standard clients  
✅ Share services when possible (5-8 clients per medium)  
✅ Monitor and downgrade unused services  
✅ Set billing alerts  

### Operations

✅ Tag all resources properly  
✅ Document client-specific configurations  
✅ Keep Terraform state backed up  
✅ Test changes in separate client first  
✅ Have rollback plan ready  

---

## 📚 Additional Resources

- [AWS Lightsail Container Services Documentation](https://docs.aws.amazon.com/lightsail/latest/userguide/amazon-lightsail-containers.html)
- [Waha Documentation](https://waha.devlike.pro/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

---

## 🆘 Support

For issues or questions:

1. Check troubleshooting section above
2. Review Terraform outputs: `terraform output`
3. Check AWS Lightsail console
4. View container logs

---

## 📄 License

MIT License - See LICENSE file for details

---

**Built with ❤️ for the Victoria SaaS platform** 🐟🚀
