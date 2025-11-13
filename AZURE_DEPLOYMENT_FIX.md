# 🔧 Azure Deployment - Issues Fixed

**Date:** November 13, 2025  
**Deployment:** streamsmart-backend-2091, streamsmart-frontend-2091

---

## Issues Found & Fixed

### ✅ Issue 1: Backend Not Responding
**Problem:** Backend showed "Running" but health endpoint not responding  
**Cause:** ML model startup delay  
**Status:** ✅ **FIXED** - Backend now responding (HTTP 200)

### ✅ Issue 2: Azure OpenAI Mood Detection
**Problem:** All moods showing as "neutral"  
**Cause:** Duplicate/incorrect environment variables  
**Fix Applied:**
```bash
az webapp config appsettings set \
  --settings \
    AZURE_OPENAI_ENDPOINT="https://eastus.api.cognitive.microsoft.com/" \
    AZURE_OPENAI_KEY="3T9Ocq..." \
    AZURE_OPENAI_DEPLOYMENT="gpt-4o-mini"
```
**Status:** ✅ **FIXED** - Mood detection working (tested "happy" → mood: happy, tone: light)

### ✅ Issue 3: CORS Configuration
**Problem:** Frontend might not be able to call backend API  
**Fix Applied:**
```bash
az webapp cors add \
  --allowed-origins "https://streamsmart-frontend-2091.azurewebsites.net"
```
**Status:** ✅ **FIXED** - CORS configured

### ⚠️  Issue 4: Frontend API URL
**Problem:** Frontend might be pointing to wrong backend URL  
**Investigation:** Vite env vars are baked at BUILD time, not runtime  
**Solution Required:** Rebuild and redeploy frontend

---

## Current Status

### Backend ✅ WORKING
```
URL: https://streamsmart-backend-2091.azurewebsites.net
Health: ✅ Responding (HTTP 200)
Mood Detection: ✅ Azure OpenAI active
ML Model: ✅ Cached model loaded
CORS: ✅ Configured
Tier: Basic B1 (1.75GB RAM)
```

**Test:**
```bash
curl https://streamsmart-backend-2091.azurewebsites.net/health
# {"status":"healthy","version":"1.0.0"}

curl -X POST https://streamsmart-backend-2091.azurewebsites.net/api/chat \
  -H "Content-Type: application/json" \
  -d '{"user_id":"test","message":"I am happy","top_n":2}'
# Returns: mood: "happy", recommendations with ML scores
```

### Frontend ⚠️  NEEDS REBUILD
```
URL: https://streamsmart-frontend-2091.azurewebsites.net
Access: ✅ Accessible (HTTP 200)
UI: ✅ HBO Max style visible
API Connection: ⚠️  May be pointing to wrong URL
```

**Issue:** If frontend shows errors when prompting, it's because:
1. Frontend was built WITHOUT `VITE_API_URL` env var
2. Defaults to localhost or old production URL
3. Vite env vars must be set BEFORE build (not after)

---

## Fix Frontend API Connection

### Option 1: Rebuild Frontend with Correct ENV (Recommended)

**Step 1: Build locally with production URL**
```bash
cd /Users/gjvs/Documents/streamsmart/streamsmart-frontend

# Set build-time environment variable
echo "VITE_API_URL=https://streamsmart-backend-2091.azurewebsites.net" > .env.production

# Build
npm run build

# Verify
grep -r "streamsmart-backend-2091" dist/
# Should show the URL in compiled JS files
```

**Step 2: Deploy new build**
```bash
cd /Users/gjvs/Documents/streamsmart

# Rebuild Docker image
docker build -t streamsmart-frontend:fixed ./streamsmart-frontend

# Tag for ACR
docker tag streamsmart-frontend:fixed streamsmartacr2091.azurecr.io/streamsmart-frontend:latest

# Push to ACR
az acr login --name streamsmartacr2091
docker push streamsmartacr2091.azurecr.io/streamsmart-frontend:latest

# Restart frontend app
az webapp restart --name streamsmart-frontend-2091 --resource-group hackathon-azure-rg193
```

### Option 2: Quick Fix with Hardcoded URL

**Modify frontend code to use production URL:**

**File:** `streamsmart-frontend/src/Chatbot.jsx` (line 33)

**Change FROM:**
```javascript
const apiUrl = import.meta.env.VITE_API_URL || "http://localhost:8000";
```

**Change TO:**
```javascript
const apiUrl = import.meta.env.VITE_API_URL || "https://streamsmart-backend-2091.azurewebsites.net";
```

Then rebuild and redeploy.

### Option 3: Use Azure Container App Settings (NOT RECOMMENDED)

Azure App Settings don't work with Vite env vars because:
- Vite vars are replaced at BUILD time
- Azure App Settings are RUNTIME environment variables
- They never reach the browser JavaScript

---

## Verification Steps

### 1. Test Backend Directly ✅
```bash
# Health check
curl https://streamsmart-backend-2091.azurewebsites.net/health

# Chat API
curl -X POST https://streamsmart-backend-2091.azurewebsites.net/api/chat \
  -H "Content-Type: application/json" \
  -d '{"user_id":"test","message":"I am happy","top_n":3}'
```

### 2. Test Frontend (After Rebuild)
1. Open: https://streamsmart-frontend-2091.azurewebsites.net
2. See: HBO Max-style homepage
3. Click: 💬 chat button (bottom-right)
4. Type: "I am happy and want comedy"
5. Should see: Recommendations with proper moods

### 3. Check Browser Console
- Open DevTools (F12)
- Go to Console tab
- Look for:
  - ✅ No CORS errors
  - ✅ Successful POST to `/api/chat`
  - ✅ Response with recommendations
  - ❌ If errors, check Network tab for failed requests

---

## Current Errors You Might See

### Error 1: "Network Error" or "Failed to fetch"
**Cause:** Frontend pointing to wrong URL (localhost or old backend)  
**Solution:** Rebuild frontend with correct `VITE_API_URL`

### Error 2: CORS Error
**Cause:** CORS not configured  
**Solution:** ✅ Already fixed (CORS added)

### Error 3: "Application Error" page
**Cause:** Backend crashed  
**Solution:** ✅ Already fixed (backend responding)

### Error 4: "Sorry, I ran into an error"
**Cause:** Frontend got error from backend  
**Solution:** Check backend logs for specific error

---

## Quick Deployment Script

```bash
#!/bin/bash
cd /Users/gjvs/Documents/streamsmart

echo "🚀 Redeploying Frontend with Correct API URL"
echo "============================================="

# 1. Update Chatbot.jsx with production URL
cd streamsmart-frontend/src
sed -i '' 's|http://localhost:8000|https://streamsmart-backend-2091.azurewebsites.net|g' Chatbot.jsx

# 2. Build
cd ..
npm run build

# 3. Build Docker image
docker build -t streamsmart-frontend:prod .

# 4. Tag for ACR
docker tag streamsmart-frontend:prod streamsmartacr2091.azurecr.io/streamsmart-frontend:latest

# 5. Push
az acr login --name streamsmartacr2091
docker push streamsmartacr2091.azurecr.io/streamsmart-frontend:latest

# 6. Restart
az webapp restart --name streamsmart-frontend-2091 --resource-group hackathon-azure-rg193

echo "✅ Frontend redeployed!"
echo "Wait 30-60 seconds, then test: https://streamsmart-frontend-2091.azurewebsites.net"
```

---

## Summary

| Component | Status | Action Needed |
|-----------|--------|---------------|
| **Backend Health** | ✅ Fixed | None - working |
| **Mood Detection** | ✅ Fixed | None - working |
| **CORS** | ✅ Fixed | None - configured |
| **Frontend URL** | ⚠️  Issue | **Rebuild frontend** |

**Next Step:** Rebuild and redeploy frontend with correct backend URL.

---

## Test Commands

### Backend is Working:
```bash
curl https://streamsmart-backend-2091.azurewebsites.net/api/chat \
  -H "Content-Type: application/json" \
  -d '{"user_id":"test","message":"I am happy","top_n":2}' | jq
```

**Expected:**
- `mood`: "happy" (not "neutral")
- `recommendations`: Array with 2 movies
- `hybrid_score`: ML scores present

### Frontend After Fix:
1. Open browser: https://streamsmart-frontend-2091.azurewebsites.net
2. Open DevTools Console (F12)
3. Click chat button
4. Type message
5. Watch Network tab for POST request
6. Should go to: `https://streamsmart-backend-2091.azurewebsites.net/api/chat`
7. Should return 200 with recommendations

---

**Current Status: Backend ✅ | Frontend ⚠️ (needs rebuild)**

