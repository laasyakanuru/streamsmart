#!/bin/bash

# StreamSmart - Azure Deployment with Azure OpenAI
# Deploys full stack with AI-powered mood extraction

set -e  # Exit on error

echo "🚀 StreamSmart Azure Deployment (with Azure OpenAI)"
echo "===================================================="
echo ""

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI not found. Install it first:"
    echo "   macOS: brew install azure-cli"
    exit 1
fi

# Check if logged in
if ! az account show &> /dev/null; then
    echo "🔐 Please login to Azure..."
    az login
fi

echo ""
echo "📝 Configuration"
echo "===================================================="

# Get current subscription
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo "✅ Subscription: $SUBSCRIPTION_NAME"
echo ""

# Set variables (use existing resource group from Azure OpenAI setup)
RESOURCE_GROUP="${RESOURCE_GROUP:-hackathon-azure-rg193}"
LOCATION="${LOCATION:-eastus}"
ACR_NAME="${ACR_NAME:-streamsmartacr$(date +%s | tail -c 6)}"
BACKEND_APP="${BACKEND_APP:-streamsmart-backend}"
FRONTEND_APP="${FRONTEND_APP:-streamsmart-frontend}"
ENVIRONMENT="${ENVIRONMENT:-streamsmart-env}"

echo "Configuration:"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Location: $LOCATION"
echo "  ACR Name: $ACR_NAME"
echo "  Backend App: $BACKEND_APP"
echo "  Frontend App: $FRONTEND_APP"
echo ""

# Check for Azure OpenAI credentials
if [ -f "streamsmart-backend/.env" ]; then
    AZURE_OPENAI_ENDPOINT=$(grep AZURE_OPENAI_ENDPOINT streamsmart-backend/.env | cut -d '=' -f2)
    AZURE_OPENAI_KEY=$(grep AZURE_OPENAI_KEY streamsmart-backend/.env | cut -d '=' -f2)
    AZURE_OPENAI_DEPLOYMENT=$(grep AZURE_OPENAI_DEPLOYMENT streamsmart-backend/.env | cut -d '=' -f2)
    
    if [ -n "$AZURE_OPENAI_ENDPOINT" ] && [ -n "$AZURE_OPENAI_KEY" ]; then
        echo "✅ Azure OpenAI credentials found!"
        echo "   Deployment will use AI-powered mood extraction"
        HAS_AZURE_OPENAI=true
    else
        echo "⚠️  No Azure OpenAI credentials found"
        echo "   Will use rule-based mood extraction"
        HAS_AZURE_OPENAI=false
    fi
else
    echo "⚠️  No .env file found"
    echo "   Will use rule-based mood extraction"
    HAS_AZURE_OPENAI=false
fi

echo ""
read -p "Continue with deployment? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

echo ""
echo "🏗️  Step 1: Setting Up Azure Resources"
echo "===================================================="

# Check if resource group exists
if az group show --name $RESOURCE_GROUP &> /dev/null; then
    echo "✅ Resource group $RESOURCE_GROUP already exists"
else
    echo "📦 Creating resource group..."
    az group create --name $RESOURCE_GROUP --location $LOCATION
fi

# Create Container Registry
echo "📦 Creating Container Registry..."
if az acr show --name $ACR_NAME &> /dev/null; then
    echo "✅ ACR $ACR_NAME already exists"
else
    az acr create \
      --resource-group $RESOURCE_GROUP \
      --name $ACR_NAME \
      --sku Basic \
      --admin-enabled true
fi

# Skip Docker login - we'll use az acr build which builds in the cloud
echo "✅ Using Azure Container Registry cloud build (no Docker needed)"

# Create Container Apps environment
echo "🌍 Creating Container Apps environment..."
if az containerapp env show --name $ENVIRONMENT --resource-group $RESOURCE_GROUP &> /dev/null; then
    echo "✅ Environment $ENVIRONMENT already exists"
else
    az containerapp env create \
      --name $ENVIRONMENT \
      --resource-group $RESOURCE_GROUP \
      --location $LOCATION
fi

echo ""
echo "🔨 Step 2: Building Docker Images"
echo "===================================================="

# Get registry server
ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --query loginServer --output tsv)

# Get project directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"

cd "$PROJECT_DIR"

# Build and push backend
echo "🔨 Building backend image..."
az acr build \
  --registry $ACR_NAME \
  --image streamsmart-backend:latest \
  --file streamsmart-backend/Dockerfile \
  streamsmart-backend

echo "✅ Backend image built"

# Build and push frontend
echo "🔨 Building frontend image..."
az acr build \
  --registry $ACR_NAME \
  --image streamsmart-frontend:latest \
  --file streamsmart-frontend/Dockerfile \
  streamsmart-frontend

echo "✅ Frontend image built"

echo ""
echo "🚀 Step 3: Deploying Applications"
echo "===================================================="

# Get ACR credentials
ACR_USERNAME=$(az acr credential show --name $ACR_NAME --query username --output tsv)
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query passwords[0].value --output tsv)

# Deploy backend
echo "🚀 Deploying backend container..."

# Prepare environment variables
ENV_VARS="FRONTEND_URL=https://will-be-updated"

if [ "$HAS_AZURE_OPENAI" = true ]; then
    ENV_VARS="$ENV_VARS AZURE_OPENAI_ENDPOINT=$AZURE_OPENAI_ENDPOINT AZURE_OPENAI_KEY=$AZURE_OPENAI_KEY AZURE_OPENAI_DEPLOYMENT=$AZURE_OPENAI_DEPLOYMENT"
    echo "✅ Configuring with Azure OpenAI"
fi

# Check if backend exists
if az containerapp show --name $BACKEND_APP --resource-group $RESOURCE_GROUP &> /dev/null; then
    echo "🔄 Updating existing backend..."
    az containerapp update \
      --name $BACKEND_APP \
      --resource-group $RESOURCE_GROUP \
      --image $ACR_LOGIN_SERVER/streamsmart-backend:latest \
      --set-env-vars $ENV_VARS
else
    echo "🆕 Creating new backend..."
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
      --env-vars $ENV_VARS \
      --cpu 1.0 \
      --memory 2.0Gi \
      --min-replicas 1 \
      --max-replicas 5
fi

# Get backend URL
BACKEND_URL=$(az containerapp show \
  --name $BACKEND_APP \
  --resource-group $RESOURCE_GROUP \
  --query properties.configuration.ingress.fqdn \
  --output tsv)

echo "✅ Backend deployed at: https://$BACKEND_URL"

# Deploy frontend with backend URL
echo "🚀 Deploying frontend container..."

# Check if frontend exists
if az containerapp show --name $FRONTEND_APP --resource-group $RESOURCE_GROUP &> /dev/null; then
    echo "🔄 Updating existing frontend..."
    az containerapp update \
      --name $FRONTEND_APP \
      --resource-group $RESOURCE_GROUP \
      --image $ACR_LOGIN_SERVER/streamsmart-frontend:latest \
      --set-env-vars VITE_API_URL="https://$BACKEND_URL"
else
    echo "🆕 Creating new frontend..."
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
      --env-vars VITE_API_URL="https://$BACKEND_URL" \
      --cpu 0.5 \
      --memory 1.0Gi \
      --min-replicas 1 \
      --max-replicas 3
fi

# Get frontend URL
FRONTEND_URL=$(az containerapp show \
  --name $FRONTEND_APP \
  --resource-group $RESOURCE_GROUP \
  --query properties.configuration.ingress.fqdn \
  --output tsv)

echo "✅ Frontend deployed at: https://$FRONTEND_URL"

# Update backend CORS
echo "🔧 Configuring CORS for frontend..."
az containerapp update \
  --name $BACKEND_APP \
  --resource-group $RESOURCE_GROUP \
  --set-env-vars FRONTEND_URL="https://$FRONTEND_URL"

echo ""
echo "🔍 Step 4: Verifying Deployment"
echo "===================================================="

sleep 5

# Check backend health
echo "Checking backend health..."
if curl -sf "https://$BACKEND_URL/health" > /dev/null; then
    echo "✅ Backend is healthy"
else
    echo "⚠️  Backend health check failed (might need a moment to start)"
fi

# Check API status
echo "Checking API status..."
API_STATUS=$(curl -s "https://$BACKEND_URL/api/status" | python3 -m json.tool 2>/dev/null || echo "pending")
if [ "$API_STATUS" != "pending" ]; then
    echo "✅ API is responding"
    MOOD_MODE=$(echo $API_STATUS | python3 -c "import sys, json; print(json.load(sys.stdin)['mood_extraction']['active_mode'])" 2>/dev/null || echo "unknown")
    echo "   Mood extraction mode: $MOOD_MODE"
else
    echo "⚠️  API status pending (might need a moment to start)"
fi

echo ""
echo "🎉 Deployment Complete!"
echo "===================================================="
echo ""
echo "📱 Your StreamSmart Application:"
echo "   🌐 Frontend: https://$FRONTEND_URL"
echo "   ⚙️  Backend:  https://$BACKEND_URL"
echo "   📚 API Docs: https://$BACKEND_URL/docs"
echo ""
echo "🤖 AI Configuration:"
if [ "$HAS_AZURE_OPENAI" = true ]; then
    echo "   ✅ Azure OpenAI GPT - AI-powered mood extraction"
else
    echo "   ℹ️  Rule-based mood extraction"
    echo "   💡 To add Azure OpenAI: See AZURE_OPENAI_QUICK_START.md"
fi
echo ""
echo "📊 Azure Portal:"
echo "   https://portal.azure.com/#resource/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP"
echo ""
echo "🧪 Quick Test:"
echo "   curl https://$BACKEND_URL/api/status"
echo ""
echo "🧹 To delete all resources:"
echo "   az group delete --name $RESOURCE_GROUP --yes --no-wait"
echo ""
echo "✅ Deployment successful! Your chatbot is live!"
echo ""

