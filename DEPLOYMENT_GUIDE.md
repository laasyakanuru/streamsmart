# StreamSmart - Azure Deployment Guide

## 🎯 Current Status

✅ **Application Ready:**
- Backend: Fully tested, 22/22 tests passing
- Frontend: Working perfectly
- Azure OpenAI: Configured and operational
- Dockerfiles: Ready for deployment
- Performance: Excellent (<5s response time)

## 🚨 Important: Hackathon Environment Constraints

Your `hackathon-azure-rg193` resource group has Azure policies that restrict:
- ❌ Creating new VNets (policy: deny-network-mods)
- ❌ Container Apps without VNet injection (policy: containerapp-vnet-req)
- ✅ BUT: Existing VNet is available: `vnet-hackathon-azure-rg193-prod`

## 📋 Deployment Options

### Option 1: Azure Web Apps (Recommended for Hackathon)
**Pros:** Simpler, fewer restrictions, works with existing infrastructure
**Time:** ~10-15 minutes

### Option 2: Request Policy Exception
**Pros:** Use Container Apps (more scalable)
**Cons:** Requires admin approval

### Option 3: Use Different Subscription
**Pros:** Full control
**Cons:** Need access to different subscription

---

## 🚀 Option 1: Deploy with Azure Web Apps (RECOMMENDED)

### Prerequisites
```bash
# 1. Make sure you're logged into the correct Azure account
az login
az account show

# Should show: gowtham.jvs@wbdhackathon.com
# Subscription: azure-hackathon-infra-prod01
```

### Step-by-Step Deployment

#### Step 1: Run the deployment script
```bash
cd /Users/gjvs/Documents/streamsmart

# Run the Web Apps deployment script
bash /tmp/deploy-azure-webapp.sh
```

**What it does:**
1. Creates Azure Container Registry (ACR)
2. Builds backend image in the cloud (no local Docker needed!)
3. Builds frontend image in the cloud
4. Creates App Service Plan
5. Deploys both applications
6. Configures Azure OpenAI environment variables
7. Sets up CORS between frontend and backend

**Expected time:** 10-15 minutes (building images takes time)

#### Step 2: Monitor the deployment
The script will show progress:
- ✅ ACR created
- ⏳ Building backend... (takes ~3-5 min)
- ✅ Backend built
- ⏳ Building frontend... (takes ~2-3 min)
- ✅ Frontend built
- ✅ Apps deployed

#### Step 3: Access your application
At the end, you'll see:
```
🎉 Deployment Complete!
📱 StreamSmart Application:
   🌐 Frontend: https://streamsmart-frontend-XXXXX.azurewebsites.net
   ⚙️  Backend:  https://streamsmart-backend-XXXXX.azurewebsites.net
   📚 API Docs: https://streamsmart-backend-XXXXX.azurewebsites.net/docs
🤖 AI: Azure OpenAI GPT
```

---

## 🔧 Troubleshooting

### Issue: "Policy denied" error
**Solution:** You're hitting the Container Apps policy. Use the Web Apps script above instead.

### Issue: "ACR name already exists"
**Solution:** The script uses timestamps to generate unique names, but if it fails, wait 30 seconds and retry.

### Issue: Backend returns 500 error
**Solution:** Wait 2-3 minutes after deployment - apps need time to start. Check logs:
```bash
az webapp log tail --name streamsmart-backend-XXXXX --resource-group hackathon-azure-rg193
```

### Issue: CORS errors in frontend
**Solution:** The script auto-configures CORS. If still failing, manually update:
```bash
BACKEND_APP="streamsmart-backend-XXXXX"
FRONTEND_URL="https://streamsmart-frontend-2091.azurewebsites.net/"

az webapp config appsettings set \
  --name $BACKEND_APP \
  --resource-group hackathon-azure-rg193 \
  --settings FRONTEND_URL="$FRONTEND_URL"
```

---

## 🧪 Testing Your Deployment

### 1. Test Backend Health
```bash
BACKEND_URL="streamsmart-backend-XXXXX.azurewebsites.net"
curl https://$BACKEND_URL/health
```
Expected: `{"status":"healthy","version":"1.0.0"}`

### 2. Test Azure OpenAI Status
```bash
curl https://$BACKEND_URL/api/status | python3 -m json.tool
```
Expected: 
```json
{
  "mood_extraction": {
    "active_mode": "azure_openai",
    "description": "Azure OpenAI GPT (Best - Enterprise grade)",
    "is_ai_powered": true
  }
}
```

### 3. Test Recommendation
```bash
curl -X POST https://$BACKEND_URL/api/chat \
  -H "Content-Type: application/json" \
  -d '{"user_id": "test", "message": "I want something thrilling!", "top_n": 3}'
```

### 4. Test Frontend
Open in browser: `https://streamsmart-frontend-XXXXX.azurewebsites.net`

---

## 📊 Monitoring & Management

### View Application Logs
```bash
# Backend logs
az webapp log tail --name streamsmart-backend-XXXXX --resource-group hackathon-azure-rg193

# Frontend logs
az webapp log tail --name streamsmart-frontend-XXXXX --resource-group hackathon-azure-rg193
```

### Scale Applications
```bash
# Scale up the App Service Plan
az appservice plan update \
  --name streamsmart-plan \
  --resource-group hackathon-azure-rg193 \
  --sku B2

# Scale out (more instances)
az webapp scale \
  --name streamsmart-backend-XXXXX \
  --resource-group hackathon-azure-rg193 \
  --instance-count 2
```

### Update Azure OpenAI Credentials
```bash
az webapp config appsettings set \
  --name streamsmart-backend-XXXXX \
  --resource-group hackathon-azure-rg193 \
  --settings \
    AZURE_OPENAI_ENDPOINT="your-endpoint" \
    AZURE_OPENAI_KEY="your-key"
```

---

## 🧹 Cleanup (When Done)

### Delete Everything
```bash
# Delete the resource group (removes everything)
az group delete --name hackathon-azure-rg193 --yes --no-wait

# Or delete individual resources
az webapp delete --name streamsmart-backend-XXXXX --resource-group hackathon-azure-rg193
az webapp delete --name streamsmart-frontend-XXXXX --resource-group hackathon-azure-rg193
az acr delete --name streamsmartacrXXXXX --resource-group hackathon-azure-rg193
az appservice plan delete --name streamsmart-plan --resource-group hackathon-azure-rg193
```

---

## 💰 Cost Estimate

**With current setup:**
- Azure Container Registry (Basic): ~$5/month
- App Service Plan (B1): ~$13/month
- Azure OpenAI (Pay-per-use): ~$0.10-1.00/day (depending on usage)

**Total:** ~$20-25/month for full deployment

**To minimize costs:**
- Use F1 (Free) App Service Plan for testing
- Delete resources when not in use
- Azure OpenAI only charges for API calls made

---

## 🎯 Next Steps After Deployment

1. ✅ Test all features in production
2. ✅ Share URLs with stakeholders
3. 🎤 Add voice input (next feature)
4. 📊 Monitor usage and performance
5. 🔒 Add authentication (if needed)
6. 📈 Set up Application Insights for monitoring

---

## 🆘 Need Help?

### Common Commands Reference
```bash
# Check deployment status
az webapp show --name APP_NAME --resource-group hackathon-azure-rg193 --query state

# Restart app
az webapp restart --name APP_NAME --resource-group hackathon-azure-rg193

# View current settings
az webapp config appsettings list --name APP_NAME --resource-group hackathon-azure-rg193

# Check ACR images
az acr repository list --name streamsmartacrXXXXX
```

### Quick Test Script
Save this as `test-production.sh`:
```bash
#!/bin/bash
BACKEND_URL="$1"

echo "Testing production deployment..."
echo "Health: $(curl -s $BACKEND_URL/health)"
echo "Status: $(curl -s $BACKEND_URL/api/status | python3 -c 'import sys,json; print(json.load(sys.stdin)["mood_extraction"]["active_mode"])')"
echo "✅ Production tests complete!"
```

Usage: `bash test-production.sh https://streamsmart-backend-XXXXX.azurewebsites.net`

---

## 📝 Deployment Checklist

Before deploying:
- [x] Tested locally (22/22 tests passing)
- [x] Azure OpenAI configured
- [x] Dockerfiles ready
- [x] Logged into correct Azure account

During deployment:
- [ ] Run deployment script
- [ ] Wait for image builds (10-15 min)
- [ ] Note down URLs

After deployment:
- [ ] Test backend health endpoint
- [ ] Test API status (confirm Azure OpenAI active)
- [ ] Test chat endpoint
- [ ] Open frontend in browser
- [ ] Try a few recommendations
- [ ] Share URLs with team

---

## 🎉 Summary

Your app is **production-ready** with:
- ✅ AI-powered mood extraction (Azure OpenAI GPT)
- ✅ Hybrid recommendation engine
- ✅ User history tracking
- ✅ Analytics & feedback system
- ✅ Modern React UI
- ✅ Comprehensive testing (100% pass rate)
- ✅ Cloud-ready Dockerfiles

**Just run the script and you're live!** 🚀

