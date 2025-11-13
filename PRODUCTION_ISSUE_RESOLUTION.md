# 🚨 Production Issue & Resolution

## What Happened

**Issue:** Backend crashed in production with "Application Error"  
**Cause:** ML model integration with large dependencies overwhelmed Azure Free Tier  
**Status:** ✅ **ROLLED BACK to stable version**

---

## Why ML Caused Crashes

### Root Causes:

1. **Memory Limits**: Azure Free Tier has limited memory (~1GB)
2. **Large Dependencies**: 
   - `torch`: ~2GB
   - `scikit-learn`: ~500MB
   - `sentence-transformers`: ~500MB
   - **Total**: ~3GB dependencies + 11MB ML model
3. **Training Timeout**: ML model training takes 10-15 seconds, causing Azure cold start timeouts
4. **Startup Complexity**: Loading all ML libraries at once exceeded resource limits

---

## Current Production Status

### Deployed Version: **Stable (No ML)** ✅

**What's Working:**
- ✅ Azure OpenAI GPT mood extraction
- ✅ Semantic similarity recommendations
- ✅ User history tracking
- ✅ Analytics & Feedback
- ✅ Fast, reliable startup

**What's Not Included:**
- ❌ Random Forest ML model
- ❌ ML-based mood→movie predictions

**Production URLs:**
- Frontend: https://streamsmart-frontend-7272.azurewebsites.net
- Backend: https://streamsmart-backend-7272.azurewebsites.net

---

## Local Development Status

### ML Recommender: **Working Locally** ✅

**Local Environment:**
- ✅ ML model trained and cached
- ✅ All dependencies installed
- ✅ Fast subsequent startups (~3 seconds)
- ✅ Hybrid recommendations (semantic + history + ML)

**Test Locally:**
```bash
cd /Users/gjvs/Documents/streamsmart
./start.sh
# Open http://localhost:5173
```

---

## Solutions for Production ML

### **Option 1: Use Larger Azure Tier** (Recommended)

**Upgrade to Basic B1 or Standard S1:**
```bash
az webapp update \
  --name streamsmart-backend-7272 \
  --resource-group hackathon-azure-rg193 \
  --set-runtime-tier BASIC_B1
```

**Pros:**
- More memory (1.75GB+ vs 1GB)
- Faster CPU
- Better for ML workloads

**Cons:**
- Costs money (~$13/month for B1)

---

### **Option 2: Simplify ML Model** (Quick Fix)

**Reduce model complexity:**
```python
# In recommender.py, line 135
# OLD: 100 trees (slow, high memory)
rf_model = RandomForestClassifier(n_estimators=100, random_state=42)

# NEW: 10 trees (faster, less memory)
rf_model = RandomForestClassifier(n_estimators=10, random_state=42)
```

**Also reduce dependencies:**
- Remove `torch` (use lightweight alternative)
- Use `sklearn` RandomForest only
- Pre-compute embeddings

**Pros:**
- Works on free tier
- Faster startup

**Cons:**
- Lower accuracy
- Less sophisticated

---

### **Option 3: Separate ML Service** (Best Long-term)

**Architecture:**
```
Main Backend (Free Tier)
  ↓ semantic recommendations

ML Service (Larger Tier)
  ↓ ML predictions only
```

**Deploy ML separately:**
```bash
# Create new app for ML only
az webapp create --name streamsmart-ml --sku B1
```

**Pros:**
- Scale ML independently
- Main app stays fast
- Better architecture

**Cons:**
- More complex
- Two services to manage

---

### **Option 4: Pre-trained Model Only** (Simplest)

**Skip training in production:**
```python
# Don't train on startup
# Deploy with pre-trained .pkl files only
# Load model instantly

if os.path.exists(model_path):
    rf_model = joblib.load(model_path)
else:
    # DON'T train - just use rule-based
    print("⚠️  No pre-trained model, using fallback")
    return get_recommendations_without_ml()
```

**Pros:**
- Fast startup (no training)
- Works on free tier

**Cons:**
- Still high memory from dependencies

---

## Recommended Approach

### **For Now (Hackathon/Demo):**

**Keep stable version in production:**
- ✅ Works reliably
- ✅ Has Azure OpenAI mood detection
- ✅ Good enough for demos

**Use ML locally:**
- ✅ Show ML in local demos
- ✅ Explain "this is the enhanced version"
- ✅ Mention "production uses lightweight version for free tier"

### **For Later (Production):**

1. **Upgrade to Basic B1** ($13/month)
2. **Deploy ML version**
3. **Monitor memory usage**
4. **Add error handling**

---

## Git Branch Strategy

### Current Branches:

```
main
  └── feature/ai-chatbot-integration
       ├── staging (HEAD)
       │   ├── Commit 1-6: Stable without ML ✅ PRODUCTION
       │   └── Commit 7-8: ML integration ⚠️  LOCAL ONLY
```

### Production vs Local:

| Environment | Code | Branch | ML Model |
|-------------|------|--------|----------|
| **Local** | Latest (with ML) | `staging` HEAD | ✅ Working |
| **Production** | Stable (no ML) | `staging` commit `3fc7746` | ❌ Removed |

---

## How to Deploy ML to Production (When Ready)

### Step 1: Upgrade Azure Tier
```bash
az appservice plan update \
  --name <plan-name> \
  --resource-group hackathon-azure-rg193 \
  --sku B1
```

### Step 2: Optimize Model
```python
# Reduce trees
rf_model = RandomForestClassifier(n_estimators=10)

# Add timeout
import signal
signal.alarm(30)  # Max 30 seconds for training
```

### Step 3: Add Error Handling
```python
try:
    rf_model = joblib.load(model_path)
except:
    # Fallback to semantic only
    return get_recommendations_semantic_only()
```

### Step 4: Deploy
```bash
./scripts/deploy-now.sh
```

### Step 5: Monitor
```bash
az webapp log tail --name streamsmart-backend-7272
```

---

## Testing Strategy

### Local Testing (ML Version):
```bash
./start.sh
# Works with ML model
```

### Production Testing (Stable Version):
```bash
curl https://streamsmart-backend-7272.azurewebsites.net/health
# Works without ML
```

### Demo Strategy:
1. **Show production**: "This is live on Azure"
2. **Show local**: "Here's the enhanced ML version"
3. **Explain**: "ML version needs larger server for production"

---

## What Your Team Should Know

**Current State:**
- ✅ Production is **stable and working** (without ML)
- ✅ Local development has **ML working perfectly**
- ⚠️  ML crashes in production due to **Azure Free Tier limits**

**Technical Achievement:**
- ✅ Successfully integrated Random Forest ML
- ✅ Hybrid recommendation system works
- ✅ Model caching implemented
- ⚠️  Needs larger Azure tier for production

**Solutions Available:**
1. Upgrade Azure tier (~$13/month)
2. Simplify ML model
3. Separate ML service
4. Keep current (stable without ML)

---

## Quick Commands

### Check Production Status:
```bash
curl https://streamsmart-backend-7272.azurewebsites.net/health
```

### Test Local ML:
```bash
cd /Users/gjvs/Documents/streamsmart && ./start.sh
```

### View Azure Logs:
```bash
az webapp log tail --name streamsmart-backend-7272 --resource-group hackathon-azure-rg193
```

### Rollback to ML Version (when tier upgraded):
```bash
az webapp config container set \
  --name streamsmart-backend-7272 \
  --resource-group hackathon-azure-rg193 \
  --docker-custom-image-name streamsmartacr7272.azurecr.io/streamsmart-backend:ml-v1
```

---

## Summary

**Production:** Stable, working, no ML (due to Free Tier limits)  
**Local:** ML working perfectly  
**Resolution:** Rolled back to last stable version  
**Future:** Upgrade Azure tier or simplify ML model  

**Your app is working in production - just without the ML component for now!** ✅

The ML integration was technically successful - it just needs more resources than Azure Free Tier provides. This is a **common trade-off** between features and infrastructure costs. 🚀

