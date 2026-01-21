# 🚀 Victoria SaaS - Quick Start Guide

Get your first client running in 20 minutes!

---

## ⚡ Prerequisites (5 minutes)

```bash
# 1. Verify tools are installed
aws --version      # Need: AWS CLI
terraform --version  # Need: Terraform >= 1.0
docker --version   # Need: Docker >= 20.10

# 2. Configure AWS
aws configure
# Enter: Access Key, Secret Key, Region (us-east-1), Format (json)

# 3. Test AWS access
aws sts get-caller-identity
```

✅ **Ready!** Let's deploy.

---

## 🏗️ Step 1: Deploy Base Infrastructure (2 minutes)

```bash
cd terraform/production
terraform init
terraform apply
```

**Type `yes` when prompted**

✅ **Created:** ECR repository, IAM roles, CloudWatch logs, S3 bucket

---

## 🐳 Step 2: Build Bot Image (3 minutes)

```bash
cd ../../scripts
./build-and-push.sh
```

**This script:**
- Builds Docker image
- Pushes to ECR
- Tags as `latest`

✅ **Bot image ready in ECR!**

---

## 👤 Step 3: Configure First Client (2 minutes)

Edit `terraform/production/clients.tf`:

**Uncomment the example client and modify:**

```hcl
module "client_joes_fish" {
  source = "../../modules/client"

  # 👇 CHANGE THESE
  client_id       = "joes-fish"           # Your ID
  client_name     = "Joe's Fish Market"   # Your business name
  whatsapp_number = "+27123456789"        # YOUR WhatsApp number

  ecr_repository_url = module.base.ecr_repository_url
  power_plan         = "micro"  # $10/month

  # 👇 CUSTOMIZE YOUR MENU
  menu_items = {
    "1" = { name = "Fresh Hake", price = 89.99 }
    "2" = { name = "Prawns", price = 159.99 }
  }

  business_hours = {
    open  = "08:00"
    close = "17:00"
  }

  delivery_areas = ["Cape Town CBD"]
  # ... rest stays the same
}
```

**Save the file**

---

## 🚀 Step 4: Deploy Client (8 minutes)

```bash
cd ../terraform/production
terraform apply
```

**Type `yes` when prompted**

**Terraform will:**
1. Create Lightsail Container Service
2. Deploy Waha, Bot, PostgreSQL containers
3. Configure HTTPS endpoint
4. Set up health checks

⏰ **This takes ~5-8 minutes** (grab a coffee! ☕)

✅ **Client deployed!**

---

## 🔑 Step 5: Get Credentials (1 minute)

```bash
# Get service URL
terraform output client_joes_fish

# Get credentials (sensitive)
terraform output -json client_joes_fish_credentials | jq
```

**Copy the `waha_dashboard` URL**

---

## 📱 Step 6: Configure WhatsApp (3 minutes)

1. **Open the Waha dashboard URL** in your browser
2. **Click "Add Session"**
3. **Scan QR code** with WhatsApp Business app on your phone
4. **Wait for connection** (green checkmark)

✅ **WhatsApp connected!**

**Note:** Webhook is automatically configured internally - no manual setup needed!

---

## 🧪 Step 7: Test the Bot (1 minute)

Send a WhatsApp message to your business number:

```
menu
```

**You should receive:**
```
🐟 Joe's Fish Market

📋 Our Menu:

1. Fresh Hake - R89.99
2. Prawns - R159.99

🕐 Hours: 08:00 - 17:00
📍 Delivery Areas: Cape Town CBD

💬 To Order: Send item numbers
Example: 1, 2

❓ Send "help" for more options
```

🎉 **IT WORKS!**

---

## 🎯 What You Built

In 20 minutes, you deployed:

✅ ECR repository for Docker images  
✅ IAM roles and permissions  
✅ Lightsail Container Service  
✅ Waha container (WhatsApp API)  
✅ Bot container (order processing)  
✅ PostgreSQL database  
✅ HTTPS endpoint with SSL  
✅ Automatic health checks  
✅ CloudWatch logging  

**Total cost: R180/month ($10)** for this client

---

## ➕ Adding More Clients

1. **Copy the client module** in `clients.tf`
2. **Change:** `client_id`, `client_name`, `whatsapp_number`
3. **Customize:** menu items, hours, delivery areas
4. **Deploy:** `terraform apply`
5. **Configure:** Scan QR code in Waha dashboard
6. **Test:** Send "menu" message

**Time per client:** ~10 minutes

---

## 📊 Next Steps

### Make Changes

```bash
# Edit clients.tf (change menu, hours, etc.)
terraform apply
```

### View Logs

```bash
aws logs tail /aws/lightsail/joes-fish --follow
```

### Check Costs

```bash
# Each micro service = R180/month
# 10 clients = R1,800/month
# Revenue (10 × R999) = R9,990/month
# Profit = R8,190/month (82% margin!)
```

### Scale Up

```hcl
# In clients.tf, upgrade power:
power_plan = "small"  # R360/month for busier client
```

### Add Features

```hcl
# Enable payments
enable_payments = true
```

---

## 🐛 Troubleshooting

### Container Won't Start

```bash
# Check service status
aws lightsail get-container-service --service-name joes-fish

# View logs
aws logs tail /aws/lightsail/joes-fish --follow
```

### WhatsApp Won't Connect

1. Open Waha dashboard
2. Delete old session
3. Add new session
4. Scan QR code again

### Bot Not Responding

```bash
# Check bot logs
aws logs tail /aws/lightsail/joes-fish --filter-pattern "bot"

# Common fix: Restart by re-applying
terraform apply
```

---

## 💡 Tips

✅ **Start small:** Test with 1-2 clients first  
✅ **Monitor costs:** Set AWS billing alerts  
✅ **Backup state:** Keep `terraform.tfstate` safe  
✅ **Use tags:** Add client contact info to tags  
✅ **Document:** Keep notes on each client's preferences  

---

## 📚 Learn More

- **Full Documentation:** See README.md
- **Architecture Details:** See ARCHITECTURE_DIAGRAMS.md
- **Cost Comparison:** See AWS_VS_LIGHTSAIL_COMPARISON.md

---

## 🎉 Congratulations!

You've successfully deployed your first Victoria SaaS client!

**Your infrastructure:**
- ✅ Fully managed by AWS
- ✅ Auto-scaling containers
- ✅ HTTPS with SSL
- ✅ 82% profit margins
- ✅ Ready for more clients

**Now go sign up your next client and grow your SaaS! 🚀💰**

---

## 📞 Quick Commands Reference

```bash
# Deploy infrastructure
terraform init && terraform apply

# Build and push bot image
./scripts/build-and-push.sh

# Get client URL
terraform output client_<name>

# Get credentials
terraform output -json client_<name>_credentials | jq

# View logs
aws logs tail /aws/lightsail/<client-id> --follow

# Check service status
aws lightsail get-container-service --service-name <client-id>

# Destroy client (careful!)
terraform destroy -target=module.client_<name>
```

---

**Happy building! 🐟🎉**
