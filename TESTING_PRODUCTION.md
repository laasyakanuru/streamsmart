# 🧪 Testing Your Production StreamSmart App

## 🎉 Your App is Live!

**Frontend:** https://streamsmart-frontend-7272.azurewebsites.net  
**Backend:** https://streamsmart-backend-7272.azurewebsites.net  
**API Docs:** https://streamsmart-backend-7272.azurewebsites.net/docs

---

## ✅ What's Been Fixed

**Problem:** Frontend was showing "Sorry, I encountered an error"  
**Cause:** Frontend was hardcoded to use `localhost:8000`  
**Solution:** Updated to use production backend URL, rebuilt & redeployed  
**Status:** ✅ Fixed and deployed

---

## 🧪 How to Test Your App

### Test 1: Open in Browser

**Just click:**
```
https://streamsmart-frontend-7272.azurewebsites.net
```

**What to do:**
1. Wait for the page to load
2. Type a message like: "I want something thrilling!"
3. Click Send or press Enter
4. You should see recommendations appear

**Expected behavior:**
- Beautiful chatbot UI loads
- You can type messages
- Bot responds with movie/show recommendations
- Recommendations include title, genre, rating, description

---

### Test 2: Try Different Moods

Test these messages to verify mood detection:

```
😊 Happy:     "I'm feeling great! Want something funny!"
😔 Sad:       "I'm feeling down, need cheering up"
😌 Calm:      "Want something relaxing for a chill evening"
⚡ Energetic: "I want action-packed thriller!"
🎬 Specific:  "Show me romantic comedies"
```

Each should return relevant recommendations based on the mood!

---

### Test 3: Backend API (Direct Test)

Test the backend is working:

```bash
# Health check
curl https://streamsmart-backend-7272.azurewebsites.net/health

# Should return: {"status":"healthy","version":"1.0.0"}
```

```bash
# Check AI status (Azure OpenAI)
curl https://streamsmart-backend-7272.azurewebsites.net/api/status

# Should show: "active_mode": "azure_openai"
```

```bash
# Get recommendations
curl -X POST https://streamsmart-backend-7272.azurewebsites.net/api/chat \
  -H "Content-Type: application/json" \
  -d '{"user_id":"test","message":"I want something exciting!","top_n":3}'

# Should return JSON with mood and recommendations
```

---

### Test 4: API Documentation

**Open Swagger UI:**
```
https://streamsmart-backend-7272.azurewebsites.net/docs
```

**What you'll see:**
- Interactive API documentation
- All endpoints listed:
  - POST `/api/chat` - Get recommendations
  - POST `/api/history` - Add to watch history
  - GET `/api/history/{user_id}` - Get user history
  - GET `/api/analytics/{user_id}` - Get user insights
  - POST `/api/feedback` - Submit feedback
  - GET `/api/status` - System status

**Try it:**
1. Click on `POST /api/chat`
2. Click "Try it out"
3. Edit the JSON to say: `{"user_id":"me","message":"surprise me!","top_n":5}`
4. Click "Execute"
5. See the results!

---

## 🎯 What Should Work

✅ **Frontend UI:**
- Loads quickly
- Beautiful gradient design
- Smooth animations
- Responsive chat interface

✅ **Mood Detection:**
- Azure OpenAI GPT analyzing your mood
- Extracts: mood (happy/sad/calm/energetic/neutral)
- Extracts: tone (light/intense/neutral)

✅ **Recommendations:**
- Returns 5 recommendations by default
- Hybrid scoring (mood + similarity + history)
- Shows: title, genre, rating, description, platform
- Sorted by relevance score

✅ **Features:**
- User history tracking
- Analytics & insights
- Feedback system
- Real-time responses

---

## 🔍 Troubleshooting

### Issue: "No recommendations found"
**Solution:** This is normal with the demo dataset. The synthetic data is limited.  
**Fix:** The algorithm is working - you'd add more content in production.

### Issue: Page takes long to load
**Solution:** Azure Web Apps on B1 tier can take 2-3 seconds to wake up.  
**Fix:** This is normal. Upgrade to higher tier (B2/S1) for better performance.

### Issue: "Error" message
**Run diagnostic:**
```bash
cd /Users/gjvs/Documents/streamsmart
./scripts/debug-production.sh
```

**Check logs:**
```bash
# Backend logs
az webapp log tail --name streamsmart-backend-7272 --resource-group hackathon-azure-rg193

# Frontend logs  
az webapp log tail --name streamsmart-frontend-7272 --resource-group hackathon-azure-rg193
```

### Issue: Want to see what's happening
**Backend logs in real-time:**
```bash
az webapp log tail --name streamsmart-backend-7272 --resource-group hackathon-azure-rg193
```

Then open the frontend and make requests - you'll see them logged!

---

## 🎨 Try These Test Scenarios

### Scenario 1: Happy Movie Night
```
Message: "It's Friday night and I'm feeling great! Want something fun!"
Expected: Comedy and light-hearted content
```

### Scenario 2: Need Comfort
```
Message: "Had a tough day, need something comforting"
Expected: Feel-good content, lower intensity
```

### Scenario 3: Weekend Adventure
```
Message: "Weekend vibes! Give me something thrilling and action-packed!"
Expected: Action, thriller, high energy content
```

### Scenario 4: Chill Evening
```
Message: "Just want to relax and unwind with something easy"
Expected: Calm, light content
```

### Scenario 5: Specific Genre
```
Message: "Show me the best documentaries"
Expected: Documentary content
```

---

## 📊 Monitor Your App

### Check App Status
```bash
# Is it running?
az webapp show --name streamsmart-backend-7272 --resource-group hackathon-azure-rg193 --query state -o tsv

# Should return: "Running"
```

### View Metrics
```bash
# Open in Azure Portal
open "https://portal.azure.com/#resource/subscriptions/$(az account show --query id -o tsv)/resourceGroups/hackathon-azure-rg193/providers/Microsoft.Web/sites/streamsmart-backend-7272"
```

### Restart if Needed
```bash
# Restart backend
az webapp restart --name streamsmart-backend-7272 --resource-group hackathon-azure-rg193

# Restart frontend
az webapp restart --name streamsmart-frontend-7272 --resource-group hackathon-azure-rg193
```

---

## 🎉 You're All Set!

Your StreamSmart chatbot is now **live on Azure** with:

✅ **AI-Powered**: Azure OpenAI GPT mood extraction  
✅ **Smart Recommendations**: Hybrid scoring algorithm  
✅ **Beautiful UI**: Modern React interface  
✅ **Full Features**: History, analytics, feedback  
✅ **Production-Ready**: Dockerized, scalable, monitored

**Next Steps:**
- Share the link with friends/team
- Collect feedback
- Add voice input (next feature!)
- Scale as needed
- Monitor usage

---

## 📱 Share Your App

**Give people this link:**
```
https://streamsmart-frontend-7272.azurewebsites.net
```

**Tell them to try:**
- "I want something thrilling!"
- "Show me funny movies"
- "I'm feeling sad, cheer me up"
- "Give me action movies with high ratings"

Enjoy your live AI-powered chatbot! 🚀

