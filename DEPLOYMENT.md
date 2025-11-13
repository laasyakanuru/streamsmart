# StreamSmart - Azure Deployment Guide

## Prerequisites

- Azure account with active subscription
- Azure CLI installed (`az`)
- Docker installed locally
- OpenAI API key

## Deployment Options

### Option 1: Azure Container Apps (Recommended)

#### Step 1: Create Azure Resources

```bash
# Login to Azure
az login

# Set variables
RESOURCE_GROUP="streamsmart-rg"
LOCATION="eastus"
ACR_NAME="streamsmartacr"  # Must be globally unique
BACKEND_APP="streamsmart-backend"
FRONTEND_APP="streamsmart-frontend"
ENVIRONMENT="streamsmart-env"

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create Azure Container Registry
az acr create --resource-group $RESOURCE_GROUP \
  --name $ACR_NAME --sku Basic --admin-enabled true

# Login to ACR
az acr login --name $ACR_NAME

# Create Container Apps environment
az containerapp env create \
  --name $ENVIRONMENT \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION
```

#### Step 2: Build and Push Docker Images

```bash
# Get ACR login server
ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --query loginServer --output tsv)

# Build and push backend
cd streamsmart-backend
docker build -t $ACR_LOGIN_SERVER/streamsmart-backend:latest .
docker push $ACR_LOGIN_SERVER/streamsmart-backend:latest

# Build and push frontend
cd ../streamsmart-frontend
docker build -t $ACR_LOGIN_SERVER/streamsmart-frontend:latest .
docker push $ACR_LOGIN_SERVER/streamsmart-frontend:latest
```

#### Step 3: Deploy Backend Container App

```bash
# Create backend container app
az containerapp create \
  --name $BACKEND_APP \
  --resource-group $RESOURCE_GROUP \
  --environment $ENVIRONMENT \
  --image $ACR_LOGIN_SERVER/streamsmart-backend:latest \
  --target-port 8000 \
  --ingress external \
  --registry-server $ACR_LOGIN_SERVER \
  --secrets openai-api-key="YOUR_OPENAI_API_KEY" \
  --env-vars OPENAI_API_KEY=secretref:openai-api-key \
  --cpu 1.0 --memory 2.0Gi \
  --min-replicas 1 --max-replicas 5

# Get backend URL
BACKEND_URL=$(az containerapp show \
  --name $BACKEND_APP \
  --resource-group $RESOURCE_GROUP \
  --query properties.configuration.ingress.fqdn \
  --output tsv)

echo "Backend URL: https://$BACKEND_URL"
```

#### Step 4: Deploy Frontend Container App

```bash
# Create frontend container app
az containerapp create \
  --name $FRONTEND_APP \
  --resource-group $RESOURCE_GROUP \
  --environment $ENVIRONMENT \
  --image $ACR_LOGIN_SERVER/streamsmart-frontend:latest \
  --target-port 80 \
  --ingress external \
  --registry-server $ACR_LOGIN_SERVER \
  --cpu 0.5 --memory 1.0Gi \
  --min-replicas 1 --max-replicas 3

# Get frontend URL
FRONTEND_URL=$(az containerapp show \
  --name $FRONTEND_APP \
  --resource-group $RESOURCE_GROUP \
  --query properties.configuration.ingress.fqdn \
  --output tsv)

echo "Frontend URL: https://$FRONTEND_URL"
```

#### Step 5: Update CORS Settings

Update the backend's CORS to allow the frontend URL:

```bash
az containerapp update \
  --name $BACKEND_APP \
  --resource-group $RESOURCE_GROUP \
  --set-env-vars FRONTEND_URL="https://$FRONTEND_URL"
```

### Option 2: Azure App Service (Alternative)

#### Backend (Azure Web App for Containers)

```bash
# Create App Service Plan
az appservice plan create \
  --name streamsmart-plan \
  --resource-group $RESOURCE_GROUP \
  --is-linux \
  --sku B1

# Create backend web app
az webapp create \
  --resource-group $RESOURCE_GROUP \
  --plan streamsmart-plan \
  --name streamsmart-backend-api \
  --deployment-container-image-name $ACR_LOGIN_SERVER/streamsmart-backend:latest

# Configure app settings
az webapp config appsettings set \
  --resource-group $RESOURCE_GROUP \
  --name streamsmart-backend-api \
  --settings OPENAI_API_KEY="YOUR_OPENAI_API_KEY"
```

#### Frontend (Azure Static Web Apps)

```bash
# Build frontend
cd streamsmart-frontend
npm run build

# Deploy using Azure Static Web Apps extension or CLI
az staticwebapp create \
  --name streamsmart-frontend \
  --resource-group $RESOURCE_GROUP \
  --source ./dist \
  --location $LOCATION \
  --branch main \
  --app-location "/" \
  --output-location "dist"
```

## Local Testing with Docker Compose

Before deploying to Azure, test locally:

```bash
# Create .env file with your OpenAI key
echo "OPENAI_API_KEY=your_key_here" > .env

# Build and run
docker-compose up --build

# Access the app
# Frontend: http://localhost
# Backend: http://localhost:8000
# API Docs: http://localhost:8000/docs
```

## Environment Variables

### Backend
- `OPENAI_API_KEY` - Your OpenAI API key (required)
- `FRONTEND_URL` - Frontend URL for CORS (required in production)
- `HOST` - Host to bind to (default: 0.0.0.0)
- `PORT` - Port to run on (default: 8000)

### Frontend
- `REACT_APP_API_URL` - Backend API URL

## Monitoring and Logs

### View Container App Logs

```bash
# Backend logs
az containerapp logs show \
  --name $BACKEND_APP \
  --resource-group $RESOURCE_GROUP \
  --follow

# Frontend logs
az containerapp logs show \
  --name $FRONTEND_APP \
  --resource-group $RESOURCE_GROUP \
  --follow
```

### Enable Application Insights

```bash
# Create Application Insights
az monitor app-insights component create \
  --app streamsmart-insights \
  --location $LOCATION \
  --resource-group $RESOURCE_GROUP

# Get instrumentation key
INSTRUMENTATION_KEY=$(az monitor app-insights component show \
  --app streamsmart-insights \
  --resource-group $RESOURCE_GROUP \
  --query instrumentationKey \
  --output tsv)

# Update backend with instrumentation key
az containerapp update \
  --name $BACKEND_APP \
  --resource-group $RESOURCE_GROUP \
  --set-env-vars APPLICATIONINSIGHTS_INSTRUMENTATION_KEY=$INSTRUMENTATION_KEY
```

## Scaling

### Auto-scaling Rules

```bash
# Backend auto-scaling
az containerapp update \
  --name $BACKEND_APP \
  --resource-group $RESOURCE_GROUP \
  --min-replicas 1 \
  --max-replicas 10 \
  --scale-rule-name http-rule \
  --scale-rule-type http \
  --scale-rule-http-concurrency 50
```

## Continuous Deployment

### GitHub Actions (Recommended)

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Azure

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Login to Azure
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Build and push backend
        run: |
          az acr build --registry ${{ secrets.ACR_NAME }} \
            --image streamsmart-backend:${{ github.sha }} \
            --image streamsmart-backend:latest \
            --file streamsmart-backend/Dockerfile \
            streamsmart-backend
      
      - name: Build and push frontend
        run: |
          az acr build --registry ${{ secrets.ACR_NAME }} \
            --image streamsmart-frontend:${{ github.sha }} \
            --image streamsmart-frontend:latest \
            --file streamsmart-frontend/Dockerfile \
            streamsmart-frontend
      
      - name: Update Container Apps
        run: |
          az containerapp update \
            --name streamsmart-backend \
            --resource-group streamsmart-rg \
            --image ${{ secrets.ACR_NAME }}.azurecr.io/streamsmart-backend:latest
          
          az containerapp update \
            --name streamsmart-frontend \
            --resource-group streamsmart-rg \
            --image ${{ secrets.ACR_NAME }}.azurecr.io/streamsmart-frontend:latest
```

## Cost Optimization

1. **Use Basic tier for ACR** if you don't need geo-replication
2. **Set appropriate scaling limits** to control costs
3. **Use Azure Reserved Instances** for predictable workloads
4. **Monitor usage** with Azure Cost Management

## Security Best Practices

1. Store secrets in **Azure Key Vault**
2. Enable **Managed Identity** for container apps
3. Use **Azure API Management** for API gateway
4. Enable **Web Application Firewall (WAF)**
5. Implement **rate limiting** on APIs

## Troubleshooting

### Backend not starting
- Check OpenAI API key is set correctly
- Verify data files are accessible
- Check resource limits (CPU/Memory)

### Frontend can't connect to backend
- Verify CORS settings
- Check backend URL in frontend environment
- Ensure both apps are in same VNET (if using internal networking)

### High latency
- Enable caching for embeddings
- Use Azure CDN for frontend
- Consider deploying to region closer to users

## Support

For issues and questions:
- Check logs: `az containerapp logs show`
- Review metrics in Azure Portal
- Check Application Insights for errors

