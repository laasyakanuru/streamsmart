# Azure Basic B1 Tier Limitations - Analysis

## Current Situation

### What's Working ✅
- **Health endpoint**: `https://streamsmart-backend-2091.azurewebsites.net/health` - Fast (<1s)
- **Status endpoint**: `https://streamsmart-backend-2091.azurewebsites.net/api/status` - Fast (<1s)
- **Backend container**: Running and healthy
- **Azure OpenAI**: Active and configured

### What's NOT Working ❌
- **ML Recommendations**: `/api/chat` endpoint timing out (>30 seconds)
- **Frontend error**: "Sorry, I ran into an error. Please try again!"

---

## Root Cause Analysis

### The Timeout Issue

When you click the chat button and send a message, this happens:

1. **Frontend** → Sends request to `/api/chat`
2. **Backend** → Triggers lazy loading (first request):
   - Load 200 movies from CSV (~50MB data)
   - Load ML model (78KB)
   - Build keyword index
   - Call Azure OpenAI for mood extraction
   - Run ML prediction
   - Calculate hybrid scores
3. **Response** → Should return in 3-5 seconds (local testing)
4. **Azure B1** → Taking >30 seconds (TIMING OUT)

### Why Azure B1 is Struggling

**Azure Basic B1 Specifications:**
- RAM: 1.75 GB
- CPU: 1 vCPU (shared)
- Disk I/O: Limited
- Network: Shared bandwidth

**Our Application Needs (even optimized):**
- Load CSV data: ~50MB
- Build indexes: CPU-intensive
- ML predictions: CPU-intensive
- All on first request (lazy loading)

**On Shared B1 CPU:** All of this takes >30 seconds

---

## Optimization Attempts Made

### 1. ✅ Model Size Reduction
- Original: 11MB → Optimized: 78KB (142x smaller)
- Result: Helped, but not enough

### 2. ✅ Lazy Loading
- Import time: 3s → 0.6s
- Result: Health checks pass, but first request still slow

### 3. ✅ Memory Optimization  
- Usage: 1.5GB → 200MB (6x less)
- Result: Fits in memory, but CPU is bottleneck

### 4. ✅ Simplified ML Model
- Trees: 100 → 5
- Depth: unlimited → 5
- Result: Faster, but still not fast enough for B1

---

## Solutions

### Option 1: Upgrade Azure Tier (RECOMMENDED)
**Upgrade to Azure Standard S1 or higher**

**Azure S1 Specifications:**
- RAM: 1.75 GB (same)
- CPU: 1 vCPU (**dedicated**, not shared)
- Cost: ~$70/month
- Performance: 3-5x faster

**Why this works:**
- Dedicated CPU vs shared CPU
- Better disk I/O
- Guaranteed resources

**Command:**
```bash
az appservice plan update \
  --name streamsmart-plan \
  --resource-group hackathon-azure-rg193 \
  --sku S1
```

### Option 2: Pre-warm the Backend
**Add a scheduled "ping" to keep it warm**

Create an Azure Function or GitHub Action that:
- Calls `/api/status` every 5 minutes
- Prevents cold starts
- Keeps data loaded in memory

**Limitation:** Still slow on first real request after restart

### Option 3: Ultra-Minimal Mode (NO ML)
**Remove ML model entirely, use only keyword matching**

Changes needed:
- Skip ML predictions
- Use only keyword + history matching
- Response time: <2s on B1

**Trade-off:** Less accurate recommendations

### Option 4: Pre-compute Everything (BEST for B1)
**Generate recommendations offline, serve from database**

Architecture change:
- Pre-compute recommendations for all moods/genres
- Store in JSON or database
- API just does lookup (instant)
- Update recommendations daily via scheduled job

**Performance:** <1s on B1 ✅  
**Trade-off:** Less personalized, not real-time

---

## Recommendation

### For Hackathon/Demo:

**Option 4 (Pre-compute) + Option 2 (Keep-alive)**
- Fast enough for B1
- Works reliably
- Good demo experience

### For Production:

**Option 1 (Upgrade to S1)**
- ML model works as designed
- Real-time personalization
- Scalable

---

## Quick Fix for Demo (Right Now)

### Pre-compute Top Recommendations

I can create a script that:
1. Pre-computes recommendations for common moods
2. Saves to JSON file
3. API serves from JSON (instant lookup)
4. Falls back to ML if needed

**Implementation time:** 15 minutes  
**Result:** <2s response time on B1 ✅

Would you like me to implement this?

---

## Local vs Azure Performance

| Operation | Local (Mac) | Azure B1 | Azure S1 (est.) |
|-----------|-------------|----------|-----------------|
| Health check | <1s | <1s | <1s |
| First ML request | 3-5s | >30s (timeout) | 5-8s |
| Subsequent | <1s | N/A | <2s |

---

## Bottom Line

**Azure B1 is too slow for real-time ML predictions**, even with all our optimizations.

**Best path forward:**
1. Short-term (demo): Pre-compute recommendations
2. Long-term (production): Upgrade to S1 or higher

---

*Generated: November 13, 2024*  
*Branch: ml_model_optimisation*

