# 🚀 StreamSmart - Quick Start

## Deploy to Azure in 3 Commands

```bash
# 1. Go to project directory
cd /Users/gjvs/Documents/streamsmart

# 2. Make sure you're logged into Azure
az login

# 3. Deploy everything!
./scripts/deploy-now.sh
```

That's it! The script will:
- ✅ Build your Docker images in the cloud (no Docker needed locally!)
- ✅ Deploy backend and frontend
- ✅ Configure Azure OpenAI automatically
- ✅ Set up CORS
- ✅ Give you the URLs when done

**Time:** 10-15 minutes
**Cost:** ~$20/month (or delete after testing)

---

## What You'll Get

After deployment completes, you'll have:

1. **Live Frontend** - Beautiful React chatbot UI
2. **Live Backend** - FastAPI with Azure OpenAI
3. **API Documentation** - Auto-generated Swagger docs
4. **Azure OpenAI** - GPT-powered mood extraction

---

## Testing Your Deployment

Once deployed, test it:

```bash
# Backend health check
curl https://YOUR-BACKEND.azurewebsites.net/health

# Check AI status
curl https://YOUR-BACKEND.azurewebsites.net/api/status

# Try a recommendation
curl -X POST https://YOUR-BACKEND.azurewebsites.net/api/chat \
  -H "Content-Type: application/json" \
  -d '{"user_id": "test", "message": "I want something thrilling!", "top_n": 3}'

# Open frontend
open https://YOUR-FRONTEND.azurewebsites.net
```

---

## Current Status

✅ **All Systems Ready:**
- Backend: 22/22 tests passing
- Frontend: Fully functional
- Azure OpenAI: Configured and active
- Dockerfiles: Production-ready
- Performance: <5s response time

---

## Troubleshooting

**Issue:** Azure policy errors
**Fix:** You're using the hackathon account which has restrictions. The `deploy-now.sh` script works around these automatically.

**Issue:** App not responding immediately
**Fix:** Wait 2-3 minutes after deployment - apps need time to start.

**Issue:** Want to see what's happening
**Fix:** Check the detailed guide: `DEPLOYMENT_GUIDE.md`

---

## What's Next?

After your app is live:

1. ✅ Test all features
2. 🎤 Add voice input (next planned feature)
3. 📊 Set up monitoring
4. 🔒 Add authentication (if needed)
5. 📈 Scale as needed

---

## Resources

- **Full Deployment Guide:** `DEPLOYMENT_GUIDE.md`
- **Test Script:** `./scripts/test-chatbot-comprehensive.sh`
- **Local Development:** `./scripts/run-backend.sh` + `./scripts/run-frontend.sh`

---

## Delete Everything (When Done)

```bash
# List your resources
az webapp list --resource-group hackathon-azure-rg193 --query "[].name" -o table

# Delete individual apps
az webapp delete --name YOUR-BACKEND --resource-group hackathon-azure-rg193
az webapp delete --name YOUR-FRONTEND --resource-group hackathon-azure-rg193
az acr delete --name YOUR-ACR --resource-group hackathon-azure-rg193
az appservice plan delete --name streamsmart-plan --resource-group hackathon-azure-rg193
```

---

## Need Help?

All details are in `DEPLOYMENT_GUIDE.md` including:
- Step-by-step instructions
- Troubleshooting guide
- Monitoring commands
- Cost optimization tips

**Just run:** `./scripts/deploy-now.sh` and you're live! 🎉
