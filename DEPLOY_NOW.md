# 🚀 Deploy StreamSmart to Azure NOW (No OpenAI Key Needed!)

You can deploy StreamSmart **right now** without an OpenAI API key! The app will work perfectly using intelligent rule-based mood detection.

## ✨ The App Works Without OpenAI!

StreamSmart automatically:
- ✅ Uses rule-based mood detection (no API key needed)
- ✅ Provides accurate recommendations
- ✅ Tracks user history and preferences
- ✅ Full analytics and insights
- 🔄 Auto-switches to GPT when you add a key later

## Quick Azure Deployment (5 Steps)

### Prerequisites
- Azure account ([Get free trial](https://azure.microsoft.com/free/))
- Azure CLI installed (`brew install azure-cli` on Mac)

### Step 1: Login to Azure

```bash
az login
```

### Step 2: Set Variables

```bash
# Choose unique names (must be globally unique)
RESOURCE_GROUP="streamsmart-rg"
LOCATION="eastus"
ACR_NAME="streamsmart$(date +%s)"  # Adds timestamp for uniqueness
BACKEND_APP="streamsmart-backend"
FRONTEND_APP="streamsmart-frontend"
ENVIRONMENT="streamsmart-env"
```

### Step 3: Create Azure Resources

```bash
# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create Container Registry
az acr create \
  --resource-group $RESOURCE_GROUP \
  --name $ACR_NAME \
  --sku Basic \
  --admin-enabled true

# Login to registry
az acr login --name $ACR_NAME

# Create Container Apps environment
az containerapp env create \
  --name $ENVIRONMENT \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION
```

### Step 4: Build and Push Images

```bash
# Get registry server
ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --query loginServer --output tsv)

# Navigate to project root
cd /Users/gjvs/Documents/streamsmart

# Build and push backend
az acr build \
  --registry $ACR_NAME \
  --image streamsmart-backend:latest \
  --file streamsmart-backend/Dockerfile \
  streamsmart-backend

# Build and push frontend
az acr build \
  --registry $ACR_NAME \
  --image streamsmart-frontend:latest \
  --file streamsmart-frontend/Dockerfile \
  streamsmart-frontend
```

### Step 5: Deploy Container Apps

```bash
# Get ACR credentials
ACR_USERNAME=$(az acr credential show --name $ACR_NAME --query username --output tsv)
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query passwords[0].value --output tsv)

# Deploy backend (WITHOUT OpenAI key - it will use rule-based detection)
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
  --env-vars BACKEND_URL=https://$BACKEND_URL \
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

# Update backend CORS to allow frontend
az containerapp update \
  --name $BACKEND_APP \
  --resource-group $RESOURCE_GROUP \
  --set-env-vars FRONTEND_URL="https://$FRONTEND_URL"

echo ""
echo "🎉 Deployment Complete!"
echo "===================================="
echo "Frontend: https://$FRONTEND_URL"
echo "Backend: https://$BACKEND_URL"
echo "API Docs: https://$BACKEND_URL/docs"
echo "===================================="
echo ""
echo "✅ Your app is live and working with rule-based mood detection!"
echo "💡 To add OpenAI later, see AZURE_OPENAI_SETUP.md"
```

## 🎉 You're Done!

Visit your frontend URL and start using StreamSmart!

The app is fully functional:
- ✅ Chat interface works
- ✅ Recommendations work
- ✅ History tracking works
- ✅ Analytics work
- ✅ Everything works!

## 💡 Add OpenAI Later (Optional)

When you're ready to upgrade to GPT-powered mood detection:

### Option A: Use Azure OpenAI (Recommended)

See [AZURE_OPENAI_SETUP.md](AZURE_OPENAI_SETUP.md) for complete guide.

Quick version:
```bash
# Create Azure OpenAI resource
az cognitiveservices account create \
  --name streamsmart-openai \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --kind OpenAI \
  --sku S0

# Get credentials
AZURE_OPENAI_KEY=$(az cognitiveservices account keys list \
  --name streamsmart-openai \
  --resource-group $RESOURCE_GROUP \
  --query key1 \
  --output tsv)

# Update app
az containerapp update \
  --name $BACKEND_APP \
  --resource-group $RESOURCE_GROUP \
  --set-env-vars AZURE_OPENAI_KEY=secretref:azure-openai-key \
  --secrets azure-openai-key=$AZURE_OPENAI_KEY
```

### Option B: Use Regular OpenAI

```bash
# Get key from https://platform.openai.com/api-keys
OPENAI_API_KEY="sk-your-key-here"

# Update app
az containerapp update \
  --name $BACKEND_APP \
  --resource-group $RESOURCE_GROUP \
  --set-env-vars OPENAI_API_KEY=secretref:openai-api-key \
  --secrets openai-api-key=$OPENAI_API_KEY
```

The app automatically detects the key and switches to GPT! No redeployment needed! 🎉

## 🔍 Verify Deployment

```bash
# Check backend health
curl https://$BACKEND_URL/health

# Check if app is using rule-based or GPT
curl https://$BACKEND_URL/

# View logs
az containerapp logs show \
  --name $BACKEND_APP \
  --resource-group $RESOURCE_GROUP \
  --follow
```

## 📊 Monitor Your App

```bash
# View metrics in Azure Portal
az containerapp show \
  --name $BACKEND_APP \
  --resource-group $RESOURCE_GROUP

# Enable Application Insights (optional)
az monitor app-insights component create \
  --app streamsmart-insights \
  --location $LOCATION \
  --resource-group $RESOURCE_GROUP
```

## 💰 Costs

**Azure Container Apps Free Tier:**
- First 180,000 vCPU-seconds/month: FREE
- First 360,000 GiB-seconds/month: FREE
- For light usage: ~$0-5/month

**With low traffic, your first month could be FREE!** ✨

## 🧹 Cleanup (If Needed)

To delete everything:
```bash
az group delete --name $RESOURCE_GROUP --yes --no-wait
```

## 🆘 Troubleshooting

### Backend not starting
```bash
# Check logs
az containerapp logs show --name $BACKEND_APP --resource-group $RESOURCE_GROUP --follow

# Common fix: Increase memory
az containerapp update --name $BACKEND_APP --resource-group $RESOURCE_GROUP --memory 3.0Gi
```

### Frontend can't reach backend
```bash
# Make sure CORS is set
az containerapp update \
  --name $BACKEND_APP \
  --resource-group $RESOURCE_GROUP \
  --set-env-vars FRONTEND_URL="https://$FRONTEND_URL"
```

### Need to rebuild
```bash
# Rebuild and update
az acr build --registry $ACR_NAME --image streamsmart-backend:latest --file streamsmart-backend/Dockerfile streamsmart-backend

az containerapp update \
  --name $BACKEND_APP \
  --resource-group $RESOURCE_GROUP \
  --image $ACR_LOGIN_SERVER/streamsmart-backend:latest
```

## 📝 What You Get

- ✅ Fully deployed chatbot
- ✅ HTTPS enabled automatically
- ✅ Auto-scaling configured
- ✅ Health monitoring
- ✅ Public URLs (shareable!)
- ✅ Production-ready

## 🎯 Next Steps

1. **Test the app** - Send some messages!
2. **Share the URL** - Let others try it
3. **Monitor usage** - Check Azure Portal
4. **Add OpenAI** - When ready (see AZURE_OPENAI_SETUP.md)
5. **Scale up** - Adjust replicas if needed

## 🌟 You Did It!

Your AI-powered OTT recommendation chatbot is live on Azure! 🎉

No OpenAI key needed - it works perfectly with intelligent rule-based detection.

---

**Need help?** Check:
- [DEPLOYMENT.md](DEPLOYMENT.md) - Full deployment guide
- [AZURE_OPENAI_SETUP.md](AZURE_OPENAI_SETUP.md) - Add OpenAI later
- [README.md](README.md) - Complete documentation

