# Manual Azure Deployment Guide - ML Optimized Backend

## Current Status

✅ **Code Optimized** - ML model is 142x smaller  
✅ **Image Built** - Successfully pushed to Azure Container Registry  
✅ **Local Testing** - Working perfectly (193MB memory, <1s responses)  
⏳ **Azure Deployment** - Needs manual restart (permission issue)

---

## What's Ready to Deploy

### Optimized ML Backend
- **Docker Image**: `streamsmartacr2091.azurecr.io/streamsmart-backend:ml-optimized`
- **Also tagged as**: `streamsmartacr2091.azurecr.io/streamsmart-backend:latest`
- **Status**: ✅ Built and pushed to ACR
- **Size**: Optimized (minimal dependencies)
- **ML Model**: 5-tree Random Forest (78KB)

### Performance Characteristics
- **Memory Usage**: ~200MB (tested locally)
- **Startup Time**: <5 seconds (lazy loading)
- **Response Time**: 1-2 seconds per request
- **Azure B1 Compatible**: YES ✅

---

## Manual Deployment Steps

### Option 1: Restart via Azure Portal (EASIEST)

1. **Go to Azure Portal**: https://portal.azure.com
2. **Navigate to Web App**:
   - Search for `streamsmart-backend-2091`
   - Or go to: Resource Groups → Hackathon → streamsmart-backend-2091
3. **Restart the App**:
   - Click "Restart" button at the top
   - Wait 2-3 minutes for the new image to pull
4. **Test**:
   - Visit: https://streamsmart-backend-2091.azurewebsites.net/health
   - Should return: `{"status": "healthy", "version": "1.0.0"}`

### Option 2: Force Image Pull via Portal

1. **Go to Web App** → `streamsmart-backend-2091`
2. **Navigate to**: Deployment Center (left sidebar)
3. **Verify Settings**:
   - Registry: `streamsmartacr2091.azurecr.io`
   - Image: `streamsmart-backend`
   - Tag: `ml-optimized` or `latest`
4. **Save** (this triggers a pull)
5. **Restart** the app

### Option 3: Ask Admin for Restart

If you don't have portal access:

```
Hi Team,

Could someone please restart the Azure Web App:
- Name: streamsmart-backend-2091  
- Resource Group: Hackathon

We've pushed an optimized Docker image to ACR that should fix
the previous timeout issues. The new image is already in the registry
and just needs the web app to be restarted to pull it.

Image: streamsmartacr2091.azurecr.io/streamsmart-backend:ml-optimized

Thanks!
```

---

## Verification Steps

After deployment, test these endpoints:

### 1. Health Check
```bash
curl https://streamsmart-backend-2091.azurewebsites.net/health
```

**Expected Response:**
```json
{
  "status": "healthy",
  "version": "1.0.0"
}
```

### 2. ML Recommendations
```bash
curl -X POST https://streamsmart-backend-2091.azurewebsites.net/api/chat \
  -H "Content-Type: application/json" \
  -d '{"user_id": "user_1", "message": "I want action movies", "top_n": 3}'
```

**Expected Response:**
```json
{
  "user_id": "user_1",
  "extracted_mood": {
    "mood": "energetic",
    "tone": "intense"
  },
  "recommendations": [
    {
      "title": "Movie X",
      "genre": "Action",
      "rating": 8.5,
      "hybrid_score": 0.75
    },
    ...
  ]
}
```

### 3. Check Logs (if you have access)
```bash
az webapp log tail --name streamsmart-backend-2091 --resource-group Hackathon
```

**Look for:**
- ✅ "ML-optimized recommender ready"
- ✅ "Lazy loading recommender"
- ✅ "ML model loaded"
- ❌ No timeout errors
- ❌ No memory errors

---

## What We Optimized

### Before
| Metric | Value | Issue |
|--------|-------|-------|
| Model Size | 11 MB | Too large |
| ML Trees | 100 | Slow training |
| Import Time | ~3s | Slow startup |
| Memory | ~1.5 GB | Exceeded B1 limit |
| Startup | 30+ seconds | Timed out |

### After
| Metric | Value | Result |
|--------|-------|--------|
| Model Size | 78 KB | **142x smaller** ✅ |
| ML Trees | 5 | Fast & effective |
| Import Time | 0.6s | **5x faster** ✅ |
| Memory | ~200 MB | **6x less** ✅ |
| Startup | <5s | **Works on B1** ✅ |

---

## Technical Details

### Lazy Loading Strategy
```python
# Nothing loads at import time (instant startup)
# All initialization happens on first request

1. Import: 0s (module loads, no data)
2. First Request: 3-5s (lazy load data + ML model)
3. Subsequent Requests: <1s (everything cached)
```

### ML Model
```python
RandomForestClassifier(
    n_estimators=5,      # Minimal but effective
    max_depth=5,         # Shallow trees
    min_samples_split=20, # Aggressive pruning
    n_jobs=1             # Single thread
)
```

### Memory Breakdown
- Movie data: ~50 MB
- ML model: 78 KB
- Keyword index: ~10 MB
- Runtime: ~100 MB
- **Total: ~200 MB** (vs B1's 1.75 GB limit)

---

## Troubleshooting

### If Backend Still Times Out

1. **Check Container Logs** (Portal):
   - Go to Web App → Monitoring → Log Stream
   - Look for errors during startup

2. **Increase Timeout** (if possible):
   ```bash
   # May need admin access
   az webapp config set --startup-time 300 \
     --name streamsmart-backend-2091 \
     --resource-group Hackathon
   ```

3. **Check Memory Limits**:
   - Portal → Configuration → Application settings
   - Look for memory restrictions

### If ML Model Not Loading

Check logs for:
```
⚠️  No ML model found, will train minimal one...
```

If this appears, the model files might not be in the image. Verify:
```bash
docker run -it streamsmartacr2091.azurecr.io/streamsmart-backend:ml-optimized ls data/
```

Should see:
- `tiny_ml_model.pkl`
- `le_mood.pkl`
- `le_context.pkl`
- `le_time.pkl`
- `le_movie.pkl`

---

## Rollback Instructions

If the optimized version doesn't work:

### 1. Quick Rollback (use previous image)
```bash
# Via Portal:
Deployment Center → Change tag to previous version → Save → Restart

# Via CLI (if you get permissions):
az webapp config container set \
  --name streamsmart-backend-2091 \
  --resource-group Hackathon \
  --docker-custom-image-name streamsmartacr2091.azurecr.io/streamsmart-backend:previous-tag
```

### 2. Code Rollback (rebuild)
```bash
cd /Users/gjvs/Documents/streamsmart/streamsmart-backend/app/recommender
cp recommender_backup_*.py recommender.py
cd /Users/gjvs/Documents/streamsmart
# Rebuild and push
```

---

## Success Indicators

Once deployed successfully, you should see:

- ✅ Health check returns `200 OK`
- ✅ `/api/chat` returns recommendations in < 5 seconds
- ✅ Azure logs show "ML-optimized recommender ready"
- ✅ Azure metrics show memory usage < 500 MB
- ✅ No timeout errors in logs
- ✅ Frontend connects and displays results

---

## Contact Info

**Repository**: https://github.com/laasyakanuru/streamsmart  
**Branch**: `ml_model_optimisation`  
**Docker Image**: `streamsmartacr2091.azurecr.io/streamsmart-backend:ml-optimized`  
**Web App**: `streamsmart-backend-2091`  
**Resource Group**: `Hackathon`

---

## Summary

✅ **Optimization Complete** - Code is ready  
✅ **Image Built** - Pushed to Azure Container Registry  
✅ **Local Testing** - Confirmed working  
⏳ **Azure Deployment** - Needs manual restart via portal  

**Next Step**: Restart the web app via Azure Portal (2 minutes)

---

*Last Updated: November 13, 2024*

