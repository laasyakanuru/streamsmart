#!/bin/bash

# StreamSmart - Azure OpenAI Setup Script
# This script helps you set up Azure OpenAI for mood extraction

set -e

echo "🎯 StreamSmart - Azure OpenAI Setup"
echo "===================================="
echo ""

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI not found"
    echo ""
    echo "Install Azure CLI:"
    echo "  macOS: brew install azure-cli"
    echo "  Or visit: https://learn.microsoft.com/cli/azure/install-azure-cli"
    exit 1
fi

echo "✅ Azure CLI found"
echo ""

# Check if logged in
if ! az account show &> /dev/null; then
    echo "🔐 Please login to Azure..."
    az login
fi

echo "✅ Logged in to Azure"
echo ""

# Get subscription info
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)

echo "📋 Using subscription:"
echo "   Name: $SUBSCRIPTION_NAME"
echo "   ID: $SUBSCRIPTION_ID"
echo ""

# Set variables
RESOURCE_GROUP="${RESOURCE_GROUP:-streamsmart-rg}"
LOCATION="${LOCATION:-eastus}"
OPENAI_RESOURCE="${OPENAI_RESOURCE:-streamsmart-openai}"
DEPLOYMENT_NAME="gpt-4o-mini"

echo "🔧 Configuration:"
echo "   Resource Group: $RESOURCE_GROUP"
echo "   Location: $LOCATION"
echo "   Azure OpenAI Name: $OPENAI_RESOURCE"
echo ""

read -p "Continue with these settings? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Setup cancelled"
    exit 1
fi

echo ""
echo "🏗️  Creating Azure OpenAI resource..."
echo ""

# Check if resource group exists
if ! az group show --name $RESOURCE_GROUP &> /dev/null; then
    echo "📦 Creating resource group..."
    az group create --name $RESOURCE_GROUP --location $LOCATION
    echo "✅ Resource group created"
else
    echo "✅ Resource group already exists"
fi

# Create Azure OpenAI resource
echo "🤖 Creating Azure OpenAI service..."
az cognitiveservices account create \
  --name $OPENAI_RESOURCE \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --kind OpenAI \
  --sku S0 \
  --yes

echo "✅ Azure OpenAI service created"
echo ""

# Get endpoint and key
echo "🔑 Getting credentials..."
ENDPOINT=$(az cognitiveservices account show \
  --name $OPENAI_RESOURCE \
  --resource-group $RESOURCE_GROUP \
  --query properties.endpoint \
  --output tsv)

KEY=$(az cognitiveservices account keys list \
  --name $OPENAI_RESOURCE \
  --resource-group $RESOURCE_GROUP \
  --query key1 \
  --output tsv)

echo "✅ Credentials retrieved"
echo ""

# Deploy model
echo "🚀 Deploying GPT-4o-mini model..."
az cognitiveservices account deployment create \
  --name $OPENAI_RESOURCE \
  --resource-group $RESOURCE_GROUP \
  --deployment-name $DEPLOYMENT_NAME \
  --model-name gpt-4o-mini \
  --model-version "2024-07-18" \
  --model-format OpenAI \
  --sku-capacity 10 \
  --sku-name "Standard"

echo "✅ Model deployed"
echo ""

# Save to .env
echo "💾 Saving configuration..."
ENV_FILE="../streamsmart-backend/.env"

# Create or update .env
if [ ! -f "$ENV_FILE" ]; then
    touch "$ENV_FILE"
fi

# Remove old Azure OpenAI settings if they exist
sed -i.bak '/AZURE_OPENAI/d' "$ENV_FILE" 2>/dev/null || true

# Add new settings
cat >> "$ENV_FILE" << EOF

# Azure OpenAI Configuration (Auto-generated)
AZURE_OPENAI_ENDPOINT=$ENDPOINT
AZURE_OPENAI_KEY=$KEY
AZURE_OPENAI_DEPLOYMENT=$DEPLOYMENT_NAME
EOF

echo "✅ Configuration saved to $ENV_FILE"
echo ""

echo "🎉 Setup Complete!"
echo "=================="
echo ""
echo "📋 Your Azure OpenAI Details:"
echo "   Endpoint: $ENDPOINT"
echo "   Deployment: $DEPLOYMENT_NAME"
echo "   Key: ${KEY:0:10}...${KEY: -4}"
echo ""
echo "🔄 Next Steps:"
echo "   1. Restart your backend: ./scripts/run-backend.sh"
echo "   2. Test it works: ./scripts/test-azure-openai.sh"
echo "   3. Check status: curl http://localhost:8000/api/status"
echo ""
echo "📊 Resource Management:"
echo "   View in portal: https://portal.azure.com/#@/resource/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.CognitiveServices/accounts/$OPENAI_RESOURCE"
echo ""
echo "💰 Estimated Cost: ~\$0.001 per request (very cheap!)"
echo ""

