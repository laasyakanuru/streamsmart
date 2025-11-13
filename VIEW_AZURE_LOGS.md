# 🔍 View Azure OpenAI Error Logs

## The backend now has detailed error logging. Here's how to see what's failing:

### Option 1: Real-Time Log Streaming (BEST)

**Open Terminal 1:**
```bash
# Stream logs in real-time
az webapp log tail --name streamsmart-backend-7272 --resource-group hackathon-azure-rg193
```

Leave this running. You'll see logs as they happen.

**Open Terminal 2:**
```bash
# Make a test request
curl -X POST https://streamsmart-backend-7272.azurewebsites.net/api/chat \
  -H "Content-Type: application/json" \
  -d '{"user_id":"test","message":"i am super happy","top_n":3}'
```

**Watch Terminal 1** - You should see:
```
🔧 Azure OpenAI Config:
   Endpoint: https://eastus.api.cognitive.microsoft.com/
   Deployment: gpt-4o-mini
   Key: ********************...
✅ Client created, making API call...
```

Then EITHER:
```
🎭 Azure OpenAI extracted mood: {'mood': 'happy', 'tone': 'cheerful'}
```

OR (if it fails):
```
❌ Azure OpenAI FAILED!
   Error Type: SomeErrorType
   Error Message: The actual error message
   Traceback:
   ... (detailed error info)
```

---

### Option 2: One Command (Quick Check)

```bash
cd /Users/gjvs/Documents/streamsmart

# Make request and wait for logs
curl -X POST https://streamsmart-backend-7272.azurewebsites.net/api/chat \
  -H "Content-Type: application/json" \
  -d '{"user_id":"test","message":"i am super happy","top_n":3}' && \
  sleep 5 && \
  az webapp log download \
    --name streamsmart-backend-7272 \
    --resource-group hackathon-azure-rg193 \
    --log-file /tmp/logs.zip && \
  unzip -q /tmp/logs.zip -d /tmp/logs && \
  grep -A 20 "Azure OpenAI" /tmp/logs/LogFiles/*docker.log | tail -30
```

---

### Option 3: Azure Portal (Visual)

1. Go to: https://portal.azure.com
2. Navigate to: **App Services** → **streamsmart-backend-7272**
3. Click: **Log stream** (left sidebar)
4. Make a test request in another tab
5. Watch the logs appear in real-time

---

## What to Look For

### ✅ SUCCESS (Azure OpenAI working):
```
🔧 Azure OpenAI Config:
   Endpoint: https://eastus.api.cognitive.microsoft.com/
   Deployment: gpt-4o-mini
✅ Client created, making API call...
🎭 Azure OpenAI extracted mood: {'mood': 'happy', 'tone': 'cheerful'}
```

### ❌ FAILURE (Need to fix):
```
❌ Azure OpenAI FAILED!
   Error Type: NotFoundError / AuthenticationError / RateLimitError
   Error Message: [The actual problem will show here]
```

**Common Errors:**

| Error | Meaning | Fix |
|-------|---------|-----|
| `DeploymentNotFound` | Model deployment doesn't exist | Check deployment name |
| `AuthenticationError` | Wrong API key | Update API key |
| `InvalidRequestError` | Wrong API version or endpoint | Check endpoint format |
| `RateLimitError` | Too many requests | Wait or upgrade tier |
| `ResourceNotFound` | Resource doesn't exist | Recreate Azure OpenAI |

---

## Quick Test Right Now

**Run this in your terminal:**
```bash
# Start log streaming (will run until you Ctrl+C)
az webapp log tail --name streamsmart-backend-7272 --resource-group hackathon-azure-rg193
```

**Then in another terminal/tab:**
```bash
# Make a test request
curl -X POST https://streamsmart-backend-7272.azurewebsites.net/api/chat \
  -H "Content-Type: application/json" \
  -d '{"user_id":"test","message":"i am super happy","top_n":3}'
```

**You'll see the error immediately in the first terminal!**

---

## After You See the Error

Copy the error message and:
1. If it's an auth error → We'll update the API key
2. If it's a deployment error → We'll fix the deployment name
3. If it's an endpoint error → We'll use the correct format
4. If it's something else → We'll debug together!

The detailed logs will show us EXACTLY what's wrong! 🎯

