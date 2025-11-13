#!/bin/bash

# StreamSmart - Quick Azure Deployment Script
# Deploys WITHOUT OpenAI key (uses rule-based mood detection)

set -e  # Exit on error

echo "🚀 StreamSmart Azure Quick Deploy"
echo "=================================="
echo ""
echo "⚠️  Note: Deploying WITHOUT OpenAI key"
echo "   App will use intelligent rule-based mood detection"
echo "   You can add OpenAI later - see AZURE_OPENAI_SETUP.md"
echo ""

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI not found. Install it first:"
    echo "   macOS: brew install azure-cli"
    echo "   Linux: curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash"
    exit 1
fi

# Check if logged in
if ! az account show &> /dev/null; then
    echo "🔐 Please login to Azure..."
    az login
fi

echo ""
echo "📝 Configuration"
echo "=================================="

# Set variables (you can customize these)
RESOURCE_GROUP="${RESOURCE_GROUP:-streamsmart-rg}"
LOCATION="${LOCATION:-eastus}"
ACR_NAME="${ACR_NAME:-streamsmart$(date +%s)}"
BACKEND_APP="${BACKEND_APP:-streamsmart-backend}"
FRONTEND_APP="${FRONTEND_APP:-streamsmart-frontend}"
ENVIRONMENT="${ENVIRONMENT:-streamsmart-env}"

echo "Resource Group: $RESOURCE_GROUP"
echo "Location: $LOCATION"
echo "ACR Name: $ACR_NAME"
echo ""

read -p "Continue with these settings? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

echo ""
echo "🏗️  Creating Azure Resources..."
echo "=================================="

# Create resource group
echo "📦 Creating resource group..."
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create Container Registry
echo "📦 Creating Container Registry..."
az acr create \
  --resource-group $RESOURCE_GROUP \
  --name $ACR_NAME \
  --sku Basic \
  --admin-enabled true

# Login to registry
echo "🔐 Logging into registry..."
az acr login --name $ACR_NAME

# Create Container Apps environment
echo "🌍 Creating Container Apps environment..."
az containerapp env create \
  --name $ENVIRONMENT \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION

echo ""
echo "🔨 Building and Pushing Images..."
echo "=================================="

# Get registry server
ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --query loginServer --output tsv)

# Get project directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"

cd "$PROJECT_DIR"

# Build and push backend
echo "🔨 Building backend..."
az acr build \
  --registry $ACR_NAME \
  --image streamsmart-backend:latest \
  --file streamsmart-backend/Dockerfile \
  streamsmart-backend

# Build and push frontend
echo "🔨 Building frontend..."
az acr build \
  --registry $ACR_NAME \
  --image streamsmart-frontend:latest \
  --file streamsmart-frontend/Dockerfile \
  streamsmart-frontend

echo ""
echo "🚀 Deploying Applications..."
echo "=================================="

# Get ACR credentials
ACR_USERNAME=$(az acr credential show --name $ACR_NAME --query username --output tsv)
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query passwords[0].value --output tsv)

# Deploy backend
echo "🚀 Deploying backend..."
az containerapp create \
  --name $BACKEND_APP \
  --resource-group $RESOURCE_GROUP \
  --environment $ENVIRONMENT \
  --image $ACR_LOGIN_SERVER/streamsmart-backend:latest \
  --target-port 8000 \
  --ingress external \
  --registry-server $ACR_LOGIN_SERVER \
  --registry-username $ACR_USERNAME \
  --registry-password $ACR_PASSWORD \
  --cpu 1.0 \
  --memory 2.0Gi \
  --min-replicas 1 \
  --max-replicas 5

# Get backend URL
BACKEND_URL=$(az containerapp show \
  --name $BACKEND_APP \
  --resource-group $RESOURCE_GROUP \
  --query properties.configuration.ingress.fqdn \
  --output tsv)

echo "✅ Backend deployed at: https://$BACKEND_URL"

# Deploy frontend
echo "🚀 Deploying frontend..."
az containerapp create \
  --name $FRONTEND_APP \
  --resource-group $RESOURCE_GROUP \
  --environment $ENVIRONMENT \
  --image $ACR_LOGIN_SERVER/streamsmart-frontend:latest \
  --target-port 80 \
  --ingress external \
  --registry-server $ACR_LOGIN_SERVER \
  --registry-username $ACR_USERNAME \
  --registry-password $ACR_PASSWORD \
  --cpu 0.5 \
  --memory 1.0Gi \
  --min-replicas 1 \
  --max-replicas 3

# Get frontend URL
FRONTEND_URL=$(az containerapp show \
  --name $FRONTEND_APP \
  --resource-group $RESOURCE_GROUP \
  --query properties.configuration.ingress.fqdn \
  --output tsv)

echo "✅ Frontend deployed at: https://$FRONTEND_URL"

# Update backend CORS
echo "🔧 Configuring CORS..."
az containerapp update \
  --name $BACKEND_APP \
  --resource-group $RESOURCE_GROUP \
  --set-env-vars FRONTEND_URL="https://$FRONTEND_URL"

echo ""
echo "🎉 Deployment Complete!"
echo "======================================"
echo ""
echo "🌐 Frontend: https://$FRONTEND_URL"
echo "⚙️  Backend:  https://$BACKEND_URL"
echo "📚 API Docs: https://$BACKEND_URL/docs"
echo ""
echo "======================================"
echo ""
echo "✅ Your StreamSmart chatbot is live!"
echo "   Using intelligent rule-based mood detection"
echo ""
echo "💡 To add OpenAI/Azure OpenAI later:"
echo "   See: AZURE_OPENAI_SETUP.md"
echo ""
echo "🧹 To delete all resources later:"
echo "   az group delete --name $RESOURCE_GROUP --yes"
echo ""
echo "📊 View in Azure Portal:"
echo "   https://portal.azure.com/#@/resource/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP"
echo ""

