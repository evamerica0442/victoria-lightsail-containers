# 📋 Victoria SaaS - Deployment Checklist

Use this checklist for each deployment to ensure nothing is missed.

---

## 🎯 Pre-Deployment Checklist

### Environment Setup
- [ ] AWS CLI installed and configured
- [ ] Terraform >= 1.0 installed
- [ ] Docker >= 20.10 installed
- [ ] Git installed and configured
- [ ] AWS account has sufficient permissions
- [ ] Billing alerts configured in AWS

### AWS Configuration
- [ ] AWS credentials configured (`aws configure`)
- [ ] Correct region selected (us-east-1 recommended)
- [ ] IAM permissions verified
- [ ] Test command: `aws sts get-caller-identity` works

### Repository Setup
- [ ] Code cloned/downloaded
- [ ] Directory structure verified
- [ ] .gitignore in place
- [ ] README.md reviewed

---

## 🏗️ Base Infrastructure Deployment

### Step 1: Initialize Terraform
```bash
cd terraform/production
terraform init
```

- [ ] Terraform initialized successfully
- [ ] Modules downloaded
- [ ] Providers configured

### Step 2: Review Configuration
- [ ] Reviewed `variables.tf`
- [ ] Verified `project_name`
- [ ] Verified `aws_region`
- [ ] Reviewed `main.tf`

### Step 3: Plan Infrastructure
```bash
terraform plan
```

- [ ] Plan executed successfully
- [ ] Resources to create reviewed
- [ ] No errors in plan
- [ ] Expected resources listed:
  - [ ] ECR repository
  - [ ] IAM role
  - [ ] CloudWatch log group
  - [ ] S3 bucket

### Step 4: Deploy Base
```bash
terraform apply
```

- [ ] Applied successfully
- [ ] ECR repository created
- [ ] IAM role created
- [ ] CloudWatch logs configured
- [ ] S3 bucket created
- [ ] Outputs displayed

### Step 5: Verify Base Deployment
- [ ] Check ECR: `aws ecr describe-repositories`
- [ ] Check IAM role: `aws iam get-role --role-name victoria-saas-lightsail-container-role`
- [ ] Note ECR repository URL
- [ ] Save Terraform outputs

---

## 🐳 Bot Image Build & Push

### Step 1: Review Bot Code
- [ ] Reviewed `containers/bot/index.js`
- [ ] Reviewed `containers/bot/package.json`
- [ ] Reviewed `containers/bot/Dockerfile`
- [ ] Reviewed `containers/bot/healthcheck.js`

### Step 2: Build Image Locally
```bash
cd containers/bot
docker build -t victoria-bot:latest .
```

- [ ] Build completed successfully
- [ ] No errors in build output
- [ ] Image appears in `docker images`

### Step 3: Test Image Locally (Optional)
```bash
docker run -p 3001:3001 \
  -e DB_HOST=localhost \
  -e DB_PASSWORD=test \
  victoria-bot:latest
```

- [ ] Container starts
- [ ] Health check responds: `curl localhost:3001/health`
- [ ] Stop test container

### Step 4: Push to ECR
```bash
cd ../../scripts
./build-and-push.sh
```

- [ ] Script executed successfully
- [ ] Logged in to ECR
- [ ] Image tagged
- [ ] Image pushed
- [ ] Verify: `aws ecr list-images --repository-name victoria-saas-bot`

---

## 👤 First Client Deployment

### Step 1: Configure Client
Edit `terraform/production/clients.tf`:

- [ ] Uncommented example client OR created new module
- [ ] Set unique `client_id` (lowercase, hyphens only)
- [ ] Set `client_name` (business name)
- [ ] Set `whatsapp_number` (E.164 format: +27XXXXXXXXX)
- [ ] Verified `ecr_repository_url` references `module.base`
- [ ] Selected appropriate `power_plan`:
  - [ ] nano ($7) for trial
  - [ ] micro ($10) for standard
  - [ ] small ($20) for premium
- [ ] Configured `menu_items`:
  - [ ] At least 2 items
  - [ ] Correct prices
  - [ ] Clear names
- [ ] Set `business_hours` (open/close times)
- [ ] Set `delivery_areas` (at least one)
- [ ] Set `currency` (default: ZAR)
- [ ] Features configured:
  - [ ] `enable_orders = true`
  - [ ] `enable_payments = false` (unless ready)
  - [ ] `enable_cloudwatch_logs = true`
  - [ ] `store_credentials_in_ssm = true`
- [ ] Added output blocks for client
- [ ] Added credentials output block (sensitive)
- [ ] Saved file

### Step 2: Validate Configuration
```bash
cd terraform/production
terraform validate
```

- [ ] Configuration valid
- [ ] No syntax errors

### Step 3: Plan Client Deployment
```bash
terraform plan
```

- [ ] Plan shows new client resources
- [ ] Lightsail Container Service will be created
- [ ] Three containers will be deployed (Waha, Bot, PostgreSQL)
- [ ] Reviewed resource changes
- [ ] No unexpected changes to base infrastructure

### Step 4: Deploy Client
```bash
terraform apply
```

- [ ] Type `yes` to confirm
- [ ] Deployment in progress (~5-10 minutes)
- [ ] Wait for completion
- [ ] Deployment successful
- [ ] No errors in output

### Step 5: Verify Client Deployment
```bash
# Check service status
aws lightsail get-container-service --service-name <client-id>
```

- [ ] Service status is `READY`
- [ ] All containers are `RUNNING`
- [ ] Public endpoint exists
- [ ] SSL certificate is `ISSUED`

### Step 6: Get Client Outputs
```bash
# Non-sensitive info
terraform output client_<name>

# Sensitive credentials
terraform output -json client_<name>_credentials | jq
```

- [ ] Service URL obtained
- [ ] Waha dashboard URL obtained
- [ ] API key obtained
- [ ] Database password obtained
- [ ] Webhook secret obtained
- [ ] All credentials saved securely

---

## 📱 WhatsApp Configuration

### Step 1: Access Waha Dashboard
- [ ] Opened Waha dashboard URL in browser
- [ ] Dashboard loads successfully
- [ ] HTTPS connection verified (padlock icon)

### Step 2: Create Session
- [ ] Clicked "Add Session" or similar
- [ ] Session creation initiated
- [ ] QR code displayed

### Step 3: Connect WhatsApp
- [ ] Opened WhatsApp Business on phone
- [ ] Navigated to Linked Devices
- [ ] Scanned QR code from Waha dashboard
- [ ] Connection confirmed (green checkmark)
- [ ] Session shows as "WORKING" or "CONNECTED"

### Step 4: Verify Webhook
- [ ] Webhook URL is set (should be internal: http://localhost:3001/webhook)
- [ ] Webhook secret configured (if shown)
- [ ] No manual webhook configuration needed (automatic)

---

## 🧪 Testing

### Test 1: Menu Command
Send WhatsApp message: `menu`

- [ ] Bot responds within 5 seconds
- [ ] Menu displays correctly
- [ ] All menu items shown
- [ ] Prices correct
- [ ] Business hours shown
- [ ] Delivery areas shown
- [ ] Formatting looks good

### Test 2: Help Command
Send WhatsApp message: `help`

- [ ] Help message received
- [ ] All commands listed
- [ ] Instructions clear

### Test 3: Business Hours
Send WhatsApp message: `hours`

- [ ] Hours displayed correctly
- [ ] Open and close times match configuration

### Test 4: Delivery Areas
Send WhatsApp message: `location`

- [ ] Delivery areas displayed
- [ ] All areas listed

### Test 5: Place Test Order
Send WhatsApp message: `1, 2`

- [ ] Order confirmation received
- [ ] Items listed correctly
- [ ] Total price calculated correctly
- [ ] Order ID shown
- [ ] Professional formatting

### Test 6: Check Order Status
Send WhatsApp message: `status`

- [ ] Previous orders shown
- [ ] Order details correct
- [ ] Dates shown
- [ ] Status shown

### Test 7: Invalid Input
Send WhatsApp message: `xyz123`

- [ ] Welcome message or helpful response
- [ ] No errors
- [ ] Guides user to correct commands

---

## 📊 Post-Deployment Verification

### Infrastructure Health
- [ ] Service status is `READY`
- [ ] All containers `RUNNING`
- [ ] Health checks passing
- [ ] No error logs in past hour
- [ ] CPU usage < 50%
- [ ] Memory usage < 70%

### Database
```bash
# Check logs for database connection
aws logs tail /aws/lightsail/<client-id> --filter-pattern "database"
```

- [ ] Database connection successful
- [ ] Tables created
- [ ] Test order saved correctly

### Monitoring
- [ ] CloudWatch logs receiving data
- [ ] Metrics available in Lightsail console
- [ ] No critical errors

### Security
- [ ] Credentials saved in secure location
- [ ] Credentials NOT committed to git
- [ ] SSM Parameter Store has credentials
- [ ] HTTPS enforced
- [ ] Webhook uses localhost (not exposed)

---

## 📝 Documentation

### Client Documentation
- [ ] Created client folder/document
- [ ] Documented client contact information
- [ ] Documented menu items and prices
- [ ] Documented business hours
- [ ] Documented delivery areas
- [ ] Saved credentials securely
- [ ] Noted service URL
- [ ] Noted WhatsApp number

### System Documentation
- [ ] Updated clients.tf with proper comments
- [ ] Tagged resources appropriately
- [ ] Updated README if needed
- [ ] Documented any custom configurations
- [ ] Noted deployment date/time

---

## 💰 Cost Verification

### Check Current Costs
```bash
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost
```

- [ ] Base infrastructure costs reviewed
- [ ] Per-client costs calculated
- [ ] Total matches expectations
- [ ] No unexpected charges

### Expected Costs for This Deployment
- [ ] Base: ~$0 (shared across all clients)
- [ ] This client: $7-20/month depending on power plan
- [ ] Total reasonable for tier

---

## 🎯 Client Handoff

### Provide to Client
- [ ] WhatsApp connection confirmed
- [ ] Test orders placed and working
- [ ] Waha dashboard URL (if they need it)
- [ ] Basic usage instructions sent
- [ ] Emergency contact information shared

### Training (if needed)
- [ ] How to check orders in database
- [ ] How to update menu (contact you)
- [ ] How to handle customer inquiries
- [ ] What to do if bot stops responding

---

## 🔄 Ongoing Maintenance

### Daily
- [ ] Check CloudWatch for errors
- [ ] Monitor order volume

### Weekly
- [ ] Review metrics (CPU, memory)
- [ ] Check costs
- [ ] Backup important data

### Monthly
- [ ] Review all client configurations
- [ ] Update menu items if needed
- [ ] Check for Terraform updates
- [ ] Update Docker images if needed
- [ ] Review and optimize costs

---

## 🚨 Rollback Plan (If Issues)

### If Deployment Fails
```bash
# Destroy failed resources
terraform destroy -target=module.client_<name>

# Fix configuration
# Re-apply
terraform apply
```

### If Client Has Issues
1. Check logs first
2. Restart containers (re-apply Terraform)
3. If critical: destroy and redeploy
4. Always have client backup contact method

---

## ✅ Final Checklist

Before marking deployment complete:

- [ ] All tests passed
- [ ] Client confirmed working
- [ ] Documentation complete
- [ ] Costs verified
- [ ] Monitoring configured
- [ ] Client notified
- [ ] Support plan in place

---

## 🎉 Deployment Complete!

**Client:** ___________________________  
**Deployed by:** ___________________________  
**Date:** ___________________________  
**Service URL:** ___________________________  
**Power Plan:** ___________________________  
**Monthly Cost:** ___________________________  

**Congratulations! This client is live! 🚀**

---

## 📞 Emergency Contacts

**AWS Support:** ___________________________  
**Your Support:** ___________________________  
**Client Contact:** ___________________________  
**On-Call:** ___________________________  

---

**Keep this checklist for every deployment!** ✓
