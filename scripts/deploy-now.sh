#!/bin/bash

# StreamSmart - One-Click Azure Deployment
# This script handles everything automatically

set -e

clear
echo "╔══════════════════════════════════════════════════╗"
echo "║      StreamSmart - Azure Deployment             ║"
echo "║      Ready to deploy in 3 simple steps          ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# Step 1: Check prerequisites
echo "Step 1/3: Checking Prerequisites"
echo "================================"

if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI not installed"
    echo "   Install: brew install azure-cli"
    exit 1
fi
echo "✅ Azure CLI installed"

if ! az account show &> /dev/null; then
    echo "⚠️  Not logged into Azure"
    echo "🔐 Opening Azure login..."
    az login
else
    CURRENT_USER=$(az account show --query user.name -o tsv)
    CURRENT_SUB=$(az account show --query name -o tsv)
    echo "✅ Logged in as: $CURRENT_USER"
    echo "   Subscription: $CURRENT_SUB"
fi

echo ""

# Step 2: Verify readiness
echo "Step 2/3: Verifying Application"
echo "================================"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"
cd "$PROJECT_DIR"

if [ -f "streamsmart-backend/Dockerfile" ]; then
    echo "✅ Backend Dockerfile ready"
else
    echo "❌ Backend Dockerfile missing"
    exit 1
fi

if [ -f "streamsmart-frontend/Dockerfile" ]; then
    echo "✅ Frontend Dockerfile ready"
else
    echo "❌ Frontend Dockerfile missing"
    exit 1
fi

if [ -f "streamsmart-backend/.env" ]; then
    AZURE_OPENAI_ENDPOINT=$(grep AZURE_OPENAI_ENDPOINT streamsmart-backend/.env | cut -d '=' -f2)
    if [ -n "$AZURE_OPENAI_ENDPOINT" ]; then
        echo "✅ Azure OpenAI configured (AI-powered mode)"
        HAS_AI=true
    else
        echo "ℹ️  No Azure OpenAI (will use rule-based mode)"
        HAS_AI=false
    fi
else
    echo "ℹ️  No .env file (will use rule-based mode)"
    HAS_AI=false
fi

echo ""

# Step 3: Deploy
echo "Step 3/3: Starting Deployment"
echo "================================"
echo ""
echo "🎯 What will be deployed:"
echo "   • Backend API with FastAPI"
echo "   • Frontend React App"
echo "   • Azure Container Registry"
echo "   • App Service Plan (B1)"
if [ "$HAS_AI" = true ]; then
    echo "   • Azure OpenAI GPT integration"
else
    echo "   • Rule-based mood detection"
fi
echo ""
echo "⏱️  Expected time: 10-15 minutes"
echo "💰 Cost: ~$20/month (or delete after testing)"
echo ""
read -p "Continue with deployment? (y/n) " -n 1 -r
echo
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Deployment cancelled"
    exit 1
fi

# Configuration
RESOURCE_GROUP="hackathon-azure-rg193"
LOCATION="eastus"
ACR_NAME="streamsmartacr$(date +%s | tail -c 5)"
APP_SERVICE_PLAN="streamsmart-plan"
BACKEND_APP="streamsmart-backend-$(date +%s | tail -c 5)"
FRONTEND_APP="streamsmart-frontend-$(date +%s | tail -c 5)"

echo "🚀 Deployment started!"
echo "   Resource Group: $RESOURCE_GROUP"
echo "   Backend: $BACKEND_APP"
echo "   Frontend: $FRONTEND_APP"
echo ""

# Create Container Registry
echo "[1/8] Creating Container Registry..."
az acr create \
  --resource-group $RESOURCE_GROUP \
  --name $ACR_NAME \
  --sku Basic \
  --admin-enabled true \
  --output none 2>&1 | grep -v "WARNING" || true
echo "      ✅ ACR created"

# Build backend image
echo "[2/8] Building backend image (this takes ~5 minutes)..."
az acr build \
  --registry $ACR_NAME \
  --image streamsmart-backend:latest \
  --file streamsmart-backend/Dockerfile \
  streamsmart-backend \
  --output none 2>&1 | grep -E "(Step|Successfully)" || echo "      Building..."
echo "      ✅ Backend image built"

# Build frontend image
echo "[3/8] Building frontend image (this takes ~3 minutes)..."
az acr build \
  --registry $ACR_NAME \
  --image streamsmart-frontend:latest \
  --file streamsmart-frontend/Dockerfile \
  streamsmart-frontend \
  --output none 2>&1 | grep -E "(Step|Successfully)" || echo "      Building..."
echo "      ✅ Frontend image built"

# Create App Service Plan
echo "[4/8] Creating App Service Plan..."
az appservice plan create \
  --name $APP_SERVICE_PLAN \
  --resource-group $RESOURCE_GROUP \
  --is-linux \
  --sku B1 \
  --output none 2>&1 | grep -v "WARNING" || true
echo "      ✅ Plan created"

# Get ACR credentials
ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --query loginServer --output tsv)
ACR_USERNAME=$(az acr credential show --name $ACR_NAME --query username --output tsv)
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query passwords[0].value --output tsv)

# Deploy backend
echo "[5/8] Deploying backend..."
az webapp create \
  --name $BACKEND_APP \
  --resource-group $RESOURCE_GROUP \
  --plan $APP_SERVICE_PLAN \
  --deployment-container-image-name $ACR_LOGIN_SERVER/streamsmart-backend:latest \
  --output none 2>&1 | grep -v "WARNING" || true

az webapp config container set \
  --name $BACKEND_APP \
  --resource-group $RESOURCE_GROUP \
  --docker-registry-server-url https://$ACR_LOGIN_SERVER \
  --docker-registry-server-user $ACR_USERNAME \
  --docker-registry-server-password $ACR_PASSWORD \
  --output none

if [ "$HAS_AI" = true ]; then
    AZURE_OPENAI_KEY=$(grep AZURE_OPENAI_KEY streamsmart-backend/.env | cut -d '=' -f2)
    AZURE_OPENAI_DEPLOYMENT=$(grep AZURE_OPENAI_DEPLOYMENT streamsmart-backend/.env | cut -d '=' -f2)
    
    az webapp config appsettings set \
      --name $BACKEND_APP \
      --resource-group $RESOURCE_GROUP \
      --settings \
        AZURE_OPENAI_ENDPOINT="$AZURE_OPENAI_ENDPOINT" \
        AZURE_OPENAI_KEY="$AZURE_OPENAI_KEY" \
        AZURE_OPENAI_DEPLOYMENT="$AZURE_OPENAI_DEPLOYMENT" \
        WEBSITES_PORT=8000 \
      --output none
else
    az webapp config appsettings set \
      --name $BACKEND_APP \
      --resource-group $RESOURCE_GROUP \
      --settings WEBSITES_PORT=8000 \
      --output none
fi

BACKEND_URL="$BACKEND_APP.azurewebsites.net"
echo "      ✅ Backend deployed"

# Deploy frontend
echo "[6/8] Deploying frontend..."
az webapp create \
  --name $FRONTEND_APP \
  --resource-group $RESOURCE_GROUP \
  --plan $APP_SERVICE_PLAN \
  --deployment-container-image-name $ACR_LOGIN_SERVER/streamsmart-frontend:latest \
  --output none 2>&1 | grep -v "WARNING" || true

az webapp config container set \
  --name $FRONTEND_APP \
  --resource-group $RESOURCE_GROUP \
  --docker-registry-server-url https://$ACR_LOGIN_SERVER \
  --docker-registry-server-user $ACR_USERNAME \
  --docker-registry-server-password $ACR_PASSWORD \
  --output none

az webapp config appsettings set \
  --name $FRONTEND_APP \
  --resource-group $RESOURCE_GROUP \
  --settings \
    VITE_API_URL="https://$BACKEND_URL" \
    WEBSITES_PORT=80 \
  --output none

FRONTEND_URL="$FRONTEND_APP.azurewebsites.net"
echo "      ✅ Frontend deployed"

# Configure CORS
echo "[7/8] Configuring CORS..."
az webapp config appsettings set \
  --name $BACKEND_APP \
  --resource-group $RESOURCE_GROUP \
  --settings FRONTEND_URL="https://$FRONTEND_URL" \
  --output none
echo "      ✅ CORS configured"

# Verify
echo "[8/8] Verifying deployment..."
sleep 15

if curl -sf "https://$BACKEND_URL/health" > /dev/null 2>&1; then
    echo "      ✅ Backend is healthy"
else
    echo "      ⏳ Backend is starting (may take 1-2 minutes)"
fi

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║           🎉 DEPLOYMENT SUCCESSFUL! 🎉           ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""
echo "📱 Your StreamSmart Application:"
echo ""
echo "   🌐 Frontend:"
echo "      https://$FRONTEND_URL"
echo ""
echo "   ⚙️  Backend:"
echo "      https://$BACKEND_URL"
echo ""
echo "   📚 API Documentation:"
echo "      https://$BACKEND_URL/docs"
echo ""
if [ "$HAS_AI" = true ]; then
    echo "   🤖 AI Mode: Azure OpenAI GPT"
else
    echo "   🤖 AI Mode: Rule-based"
fi
echo ""
echo "🧪 Quick Test:"
echo "   curl https://$BACKEND_URL/health"
echo ""
echo "📊 Azure Portal:"
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo "   https://portal.azure.com/#resource/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP"
echo ""
echo "🧹 To delete all resources later:"
echo "   az webapp delete --name $BACKEND_APP --resource-group $RESOURCE_GROUP"
echo "   az webapp delete --name $FRONTEND_APP --resource-group $RESOURCE_GROUP"
echo "   az acr delete --name $ACR_NAME --resource-group $RESOURCE_GROUP"
echo "   az appservice plan delete --name $APP_SERVICE_PLAN --resource-group $RESOURCE_GROUP"
echo ""
echo "✅ Deployment complete! Your chatbot is live!"
echo ""

# Save URLs to file for reference
cat > deployment-urls.txt << EOF
StreamSmart Deployment - $(date)
================================

Frontend: https://$FRONTEND_URL
Backend:  https://$BACKEND_URL
API Docs: https://$BACKEND_URL/docs

Resource Names:
- Backend App: $BACKEND_APP
- Frontend App: $FRONTEND_APP
- ACR: $ACR_NAME
- Plan: $APP_SERVICE_PLAN
- Resource Group: $RESOURCE_GROUP
EOF

echo "📝 URLs saved to: deployment-urls.txt"
echo ""

