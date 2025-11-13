# 🚀 Azure OpenAI Quick Start Guide

Get Azure OpenAI working with StreamSmart in 10 minutes!

## 📋 Prerequisites

- Azure account ([Get free trial](https://azure.microsoft.com/free/))
- Azure CLI installed (`brew install azure-cli` on Mac)
- StreamSmart backend running

## ⚡ Option 1: Automated Setup (Recommended)

### Step 1: Run Setup Script

```bash
cd /Users/gjvs/Documents/streamsmart
./scripts/setup-azure-openai.sh
```

This script will:
1. ✅ Check Azure CLI
2. ✅ Login to Azure (if needed)
3. ✅ Create resource group
4. ✅ Create Azure OpenAI resource
5. ✅ Deploy GPT-4o-mini model
6. ✅ Save credentials to `.env`

**Time:** ~5 minutes

### Step 2: Restart Backend

```bash
# The backend auto-reloads when .env changes!
# Or manually restart:
cd /Users/gjvs/Documents/streamsmart
# Press Ctrl+C on running backend
./scripts/run-backend.sh
```

### Step 3: Test It Works

```bash
./scripts/test-azure-openai.sh
```

Expected output:
```
✅ Backend running
✅ Azure OpenAI active  
✅ Mood extraction working
```

**Done!** 🎉

---

## 🔧 Option 2: Manual Setup (Azure Portal)

### Step 1: Create Azure OpenAI Resource

1. Go to https://portal.azure.com
2. Search for "Azure OpenAI"
3. Click "+ Create"
4. Fill in:
   - **Subscription:** Your subscription
   - **Resource group:** Create new → "streamsmart-rg"
   - **Region:** East US
   - **Name:** streamsmart-openai
   - **Pricing tier:** Standard S0
5. Click "Review + Create" → "Create"
6. Wait ~2 minutes for deployment

### Step 2: Deploy GPT-4o-mini Model

1. Go to your Azure OpenAI resource
2. Click "Model deployments" → "Manage Deployments"
3. This opens **Azure OpenAI Studio**
4. Click "Deployments" → "+ Create new deployment"
5. Fill in:
   - **Model:** gpt-4o-mini
   - **Deployment name:** gpt-4o-mini (keep same as model)
   - **Model version:** Latest (2024-07-18)
6. Click "Create"

### Step 3: Get Credentials

1. Go back to your Azure OpenAI resource in Azure Portal
2. Click "Keys and Endpoint" in the left menu
3. Copy:
   - **Endpoint** (e.g., `https://streamsmart-openai.openai.azure.com/`)
   - **KEY 1**

### Step 4: Configure StreamSmart

Edit your `.env` file:

```bash
cd /Users/gjvs/Documents/streamsmart/streamsmart-backend
nano .env
```

Add these lines:
```bash
AZURE_OPENAI_ENDPOINT=https://streamsmart-openai.openai.azure.com/
AZURE_OPENAI_KEY=your-key-here
AZURE_OPENAI_DEPLOYMENT=gpt-4o-mini
```

Save and exit (Ctrl+X, Y, Enter)

### Step 5: Restart Backend

```bash
# Backend auto-reloads!
# Or restart manually:
cd /Users/gjvs/Documents/streamsmart
./scripts/run-backend.sh
```

### Step 6: Verify

```bash
# Check status
curl http://localhost:8000/api/status | python3 -m json.tool

# Run tests
./scripts/test-azure-openai.sh
```

---

## 🧪 Testing Azure OpenAI

### Quick Status Check

```bash
curl http://localhost:8000/api/status
```

Should show:
```json
{
  "mood_extraction": {
    "active_mode": "azure_openai",
    "description": "Azure OpenAI GPT (Best - Enterprise grade)",
    "is_ai_powered": true
  }
}
```

### Test Mood Extraction

```bash
curl -X POST http://localhost:8000/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test_user",
    "message": "I am feeling extremely happy and want something hilarious!",
    "top_n": 3
  }' | python3 -m json.tool
```

Look for in response:
```json
{
  "extracted_mood": {
    "mood": "happy",
    "tone": "lighthearted"
  }
}
```

### View Backend Logs

You should see:
```
✅ Using Azure OpenAI for mood extraction
🎭 Azure OpenAI extracted mood: {'mood': 'happy', 'tone': 'lighthearted'}
```

---

## 🔍 Troubleshooting

### Issue: "rule_based" mode active

**Symptom:** Status shows `"active_mode": "rule_based"`

**Fix:**
1. Check `.env` file has Azure OpenAI settings
2. Restart backend
3. Check for typos in endpoint URL
4. Verify key is correct

### Issue: "Deployment not found"

**Symptom:** Error mentioning deployment name

**Fix:**
1. In Azure Portal, go to Azure OpenAI Studio
2. Check "Deployments" section
3. Verify deployment name is exactly: `gpt-4o-mini`
4. Update `AZURE_OPENAI_DEPLOYMENT` in `.env` to match

### Issue: "Access denied"

**Symptom:** 401 or 403 errors

**Fix:**
1. Regenerate key in Azure Portal
2. Update `AZURE_OPENAI_KEY` in `.env`
3. Restart backend

### Issue: "Resource not found"

**Symptom:** 404 errors

**Fix:**
1. Check endpoint URL in `.env`
2. Should end with `.openai.azure.com/`
3. No extra paths after the domain

---

## 💰 Costs

Azure OpenAI pricing for GPT-4o-mini:
- **Input:** ~$0.15 per 1M tokens
- **Output:** ~$0.60 per 1M tokens
- **Typical request:** ~200 tokens = **$0.0002** (less than a cent!)

**Estimated monthly cost** (100 requests/day):
- ~$0.60/month 💰

Very affordable!

---

## 📊 What's Next?

Once Azure OpenAI is working:

### 1. Test the Frontend
```bash
# Open in browser
open http://localhost:5173

# Type: "I'm feeling happy and want something funny"
# Watch it use Azure OpenAI! 🎭
```

### 2. Add Voice Input
```bash
# We'll add Whisper API next!
# Voice → Azure Whisper → Text → Azure GPT → Recommendations
```

### 3. Deploy to Azure
```bash
# When ready to deploy
./scripts/deploy-azure-quick.sh

# Your app will use Azure OpenAI in production!
```

---

## 🎯 Quick Reference

### Configuration Files
- **Backend .env:** `streamsmart-backend/.env`
- **Setup script:** `scripts/setup-azure-openai.sh`
- **Test script:** `scripts/test-azure-openai.sh`

### Important Endpoints
- **Status:** `GET /api/status`
- **Chat:** `POST /api/chat`
- **Docs:** `http://localhost:8000/docs`

### Azure Resources
- **Portal:** https://portal.azure.com
- **OpenAI Studio:** https://oai.azure.com/
- **Pricing:** https://azure.microsoft.com/pricing/details/cognitive-services/openai-service/

---

## 💡 Tips

1. **Free Credits:** Azure gives $200 free credits for new accounts
2. **Dev vs Prod:** Use same config for both (seamless!)
3. **Monitoring:** Check usage in Azure Portal → Cost Management
4. **Scaling:** Deployment auto-scales, no config needed

---

## 🎉 Success Checklist

- [ ] Azure OpenAI resource created
- [ ] GPT-4o-mini model deployed
- [ ] Credentials added to `.env`
- [ ] Backend restarted
- [ ] Status shows "azure_openai"
- [ ] Test script passes
- [ ] Frontend shows AI-powered mood detection

**All checked?** You're ready for voice input! 🎤

---

Need help? Check the logs or run the test script for detailed diagnostics!

