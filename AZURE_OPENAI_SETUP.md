# Azure OpenAI Setup Guide

You have two options for using OpenAI with StreamSmart on Azure:

## Option 1: Use Azure OpenAI Service (Recommended)

Azure OpenAI Service provides the same models as OpenAI but integrated with Azure.

### Benefits
- ✅ No separate API key needed
- ✅ Integrated billing with Azure
- ✅ Better latency within Azure
- ✅ Enterprise-grade security
- ✅ Compliance certifications

### Setup Steps

#### 1. Create Azure OpenAI Resource

```bash
# Set variables
RESOURCE_GROUP="streamsmart-rg"
LOCATION="eastus"
OPENAI_RESOURCE="streamsmart-openai"

# Create Azure OpenAI resource
az cognitiveservices account create \
  --name $OPENAI_RESOURCE \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --kind OpenAI \
  --sku S0
```

#### 2. Deploy a Model

```bash
# Deploy GPT-4o-mini model
az cognitiveservices account deployment create \
  --name $OPENAI_RESOURCE \
  --resource-group $RESOURCE_GROUP \
  --deployment-name gpt-4o-mini \
  --model-name gpt-4o-mini \
  --model-version "2024-07-18" \
  --model-format OpenAI \
  --sku-capacity 10 \
  --sku-name "Standard"
```

#### 3. Get Endpoint and Key

```bash
# Get endpoint
AZURE_OPENAI_ENDPOINT=$(az cognitiveservices account show \
  --name $OPENAI_RESOURCE \
  --resource-group $RESOURCE_GROUP \
  --query properties.endpoint \
  --output tsv)

# Get API key
AZURE_OPENAI_KEY=$(az cognitiveservices account keys list \
  --name $OPENAI_RESOURCE \
  --resource-group $RESOURCE_GROUP \
  --query key1 \
  --output tsv)

echo "Endpoint: $AZURE_OPENAI_ENDPOINT"
echo "Key: $AZURE_OPENAI_KEY"
```

#### 4. Update Backend Code

Update `streamsmart-backend/app/recommender/mood_extractor.py`:

```python
import os
from openai import AzureOpenAI

def extract_mood_with_gpt(prompt: str):
    """Uses Azure OpenAI to extract mood"""
    
    # Check if using Azure OpenAI
    azure_endpoint = os.getenv("AZURE_OPENAI_ENDPOINT")
    azure_key = os.getenv("AZURE_OPENAI_KEY")
    
    if azure_endpoint and azure_key:
        # Use Azure OpenAI
        client = AzureOpenAI(
            api_key=azure_key,
            api_version="2024-02-15-preview",
            azure_endpoint=azure_endpoint
        )
        model = "gpt-4o-mini"  # Your deployment name
    else:
        # Use regular OpenAI
        from openai import OpenAI
        client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
        model = "gpt-4o-mini"
    
    try:
        response = client.chat.completions.create(
            model=model,
            messages=[
                {"role": "system", "content": "You are an assistant that identifies mood and tone from user prompts for a movie recommendation system."},
                {"role": "user", "content": f"Extract the user's mood (like happy, sad, relaxed, energetic, etc.) and preferred tone (light-hearted, serious, intense) from this text: '{prompt}'. Respond only in JSON with keys 'mood' and 'tone'."}
            ],
        )
        content = response.choices[0].message.content
        import json
        result = json.loads(content)
        return result
    except Exception as e:
        print(f"⚠️ GPT failed: {e}, switching to fallback.")
        return extract_mood_rule_based(prompt)
```

#### 5. Update Container App with Azure OpenAI Credentials

```bash
az containerapp update \
  --name streamsmart-backend \
  --resource-group $RESOURCE_GROUP \
  --set-env-vars \
    AZURE_OPENAI_ENDPOINT=$AZURE_OPENAI_ENDPOINT \
    AZURE_OPENAI_KEY=secretref:azure-openai-key \
  --secrets azure-openai-key=$AZURE_OPENAI_KEY
```

---

## Option 2: Use Regular OpenAI API

If you prefer to use OpenAI directly instead of Azure OpenAI:

### 1. Get OpenAI API Key

1. Go to https://platform.openai.com/api-keys
2. Create an account or sign in
3. Click "Create new secret key"
4. Copy the key (starts with `sk-...`)

### 2. Add Key to Azure Container App

```bash
RESOURCE_GROUP="streamsmart-rg"
BACKEND_APP="streamsmart-backend"
OPENAI_API_KEY="sk-your-actual-key-here"

# Add as secret
az containerapp update \
  --name $BACKEND_APP \
  --resource-group $RESOURCE_GROUP \
  --set-env-vars OPENAI_API_KEY=secretref:openai-api-key \
  --secrets openai-api-key=$OPENAI_API_KEY
```

### 3. Verify It Works

```bash
# Check logs
az containerapp logs show \
  --name $BACKEND_APP \
  --resource-group $RESOURCE_GROUP \
  --follow
```

---

## Option 3: Deploy Without OpenAI (Rule-Based Only)

StreamSmart works without OpenAI using a rule-based fallback system!

### How It Works

When no OpenAI API key is detected:
- ✅ App still works perfectly
- ✅ Uses intelligent rule-based mood detection
- ✅ Recommendations still accurate
- ❌ Mood detection is simpler (but still good!)

### Deploy Without Key

```bash
# Just deploy normally without the OPENAI_API_KEY
az containerapp create \
  --name streamsmart-backend \
  --resource-group streamsmart-rg \
  --environment streamsmart-env \
  --image <your-acr>.azurecr.io/streamsmart-backend:latest \
  --target-port 8000 \
  --ingress external \
  --cpu 1.0 --memory 2.0Gi
```

The app will automatically use rule-based mood detection!

### Add OpenAI Later

When you get an API key, just update the app:

```bash
az containerapp update \
  --name streamsmart-backend \
  --resource-group streamsmart-rg \
  --set-env-vars OPENAI_API_KEY=secretref:openai-api-key \
  --secrets openai-api-key="your-new-key"
```

No code changes needed! The app auto-detects the key and switches to GPT.

---

## Comparison

| Feature | Azure OpenAI | Regular OpenAI | Rule-Based |
|---------|-------------|----------------|------------|
| Cost | Azure billing | Separate billing | Free |
| Latency | Best (Azure network) | Good | Fastest |
| Setup | Medium complexity | Easy | No setup |
| Accuracy | Best | Best | Good |
| Enterprise Features | Yes | No | N/A |

---

## Recommended Approach

### For Development/Testing
**Use Rule-Based** (no setup needed!)

### For Production - Small Scale
**Use Regular OpenAI API** (easier setup)

### For Production - Enterprise
**Use Azure OpenAI Service** (better integration)

---

## Testing

After setup, test the mood extraction:

```bash
curl -X POST http://your-backend-url/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test_user",
    "message": "I am feeling happy and want something funny",
    "top_n": 3
  }'
```

Check the logs to see which method was used:
- With OpenAI: "Using GPT for mood extraction"
- Without: "Using rule-based mood extraction"

---

## Costs

### Azure OpenAI Service
- GPT-4o-mini: ~$0.15 per 1M input tokens
- ~$0.60 per 1M output tokens
- Typically < $0.01 per recommendation

### Regular OpenAI
- Similar pricing
- Separate billing account

### Rule-Based
- **FREE!** ✨
- No API costs
- Instant processing

---

## Quick Start for Deployment

**Right now, without any API key:**

```bash
# 1. Deploy without OpenAI key
cd /Users/gjvs/Documents/streamsmart
docker-compose up --build

# The app will work with rule-based mood detection!
# Visit http://localhost:5173

# 2. Later, when you get a key, just add it:
echo "OPENAI_API_KEY=your-key" >> streamsmart-backend/.env
docker-compose restart
```

That's it! The app automatically switches to GPT when a key is available.

---

## Need Help?

- Azure OpenAI: https://learn.microsoft.com/azure/ai-services/openai/
- OpenAI Platform: https://platform.openai.com/docs
- StreamSmart Issues: GitHub (coming soon)

