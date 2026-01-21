#!/bin/bash
# ============================================================================
# Build and Push Bot Docker Image to ECR
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║          Victoria SaaS - Docker Image Builder                 ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI not found. Please install it first.${NC}"
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker not found. Please install it first.${NC}"
    exit 1
fi

# Get ECR repository URL from Terraform output
echo -e "${YELLOW}📋 Getting ECR repository URL...${NC}"
cd ../terraform/production
ECR_URL=$(terraform output -raw ecr_repository_url 2>/dev/null)

if [ -z "$ECR_URL" ]; then
    echo -e "${RED}❌ Could not get ECR URL. Have you run 'terraform apply'?${NC}"
    exit 1
fi

AWS_REGION=$(terraform output -raw aws_region 2>/dev/null)
CLIENT_ID="${1:-latest}"

echo -e "${GREEN}✅ ECR Repository: ${ECR_URL}${NC}"
echo -e "${GREEN}✅ AWS Region: ${AWS_REGION}${NC}"
echo -e "${GREEN}✅ Image Tag: ${CLIENT_ID}${NC}"
echo ""

# Build Docker image
echo -e "${YELLOW}🔨 Building Docker image...${NC}"
cd ../../containers/bot

if docker build -t victoria-bot:${CLIENT_ID} .; then
    echo -e "${GREEN}✅ Docker image built successfully${NC}"
else
    echo -e "${RED}❌ Docker build failed${NC}"
    exit 1
fi

# Login to ECR
echo ""
echo -e "${YELLOW}🔐 Logging in to ECR...${NC}"
aws ecr get-login-password --region ${AWS_REGION} | \
    docker login --username AWS --password-stdin ${ECR_URL}

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Logged in to ECR${NC}"
else
    echo -e "${RED}❌ ECR login failed${NC}"
    exit 1
fi

# Tag image
echo ""
echo -e "${YELLOW}🏷️  Tagging image...${NC}"
docker tag victoria-bot:${CLIENT_ID} ${ECR_URL}:${CLIENT_ID}
echo -e "${GREEN}✅ Image tagged: ${ECR_URL}:${CLIENT_ID}${NC}"

# Push image
echo ""
echo -e "${YELLOW}⬆️  Pushing image to ECR...${NC}"
if docker push ${ECR_URL}:${CLIENT_ID}; then
    echo -e "${GREEN}✅ Image pushed successfully${NC}"
else
    echo -e "${RED}❌ Image push failed${NC}"
    exit 1
fi

# Also tag and push as 'latest' if not already latest
if [ "$CLIENT_ID" != "latest" ]; then
    echo ""
    echo -e "${YELLOW}🏷️  Also tagging as 'latest'...${NC}"
    docker tag victoria-bot:${CLIENT_ID} ${ECR_URL}:latest
    docker push ${ECR_URL}:latest
    echo -e "${GREEN}✅ Latest tag pushed${NC}"
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    SUCCESS! ✅                                 ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Image URI: ${GREEN}${ECR_URL}:${CLIENT_ID}${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Deploy client with Terraform:"
echo "   cd ../terraform/production"
echo "   terraform apply"
echo ""
echo "2. Get client credentials:"
echo "   terraform output client_<CLIENT_NAME>_credentials"
echo ""
