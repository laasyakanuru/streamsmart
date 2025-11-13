# 🔧 UI Troubleshooting Guide

## Issue: "Could not see any results" in http://localhost:5173

### ✅ FIXED!

**Problem:** Frontend was pointing to production URL (which is down)  
**Solution:** Created `.env.local` with `VITE_API_URL=http://localhost:8000`  
**Status:** Frontend restarted and configured correctly ✅

---

## 🌐 How to Test

### Step 1: Open Browser
```
http://localhost:5173
```

### Step 2: What You Should See

```
┌─────────────────────────────────────────────┐
│  🎬 StreamSmart                             │
│  Your AI-Powered Movie Recommender          │
├─────────────────────────────────────────────┤
│                                             │
│  [Empty chat area]                          │
│                                             │
├─────────────────────────────────────────────┤
│  Tell me what you're in the mood for...    │
│  [                                   ] Send │
└─────────────────────────────────────────────┘
```

### Step 3: Type a Message

Try one of these:
- ✅ "I am happy and want action movies"
- ✅ "Show me thriller movies"
- ✅ "I want something adventurous"

### Step 4: Expected Result

```
┌─────────────────────────────────────────────┐
│  You (5:30 PM)                              │
│  I am happy and want action movies          │
├─────────────────────────────────────────────┤
│  StreamSmart AI (5:30 PM)                   │
│  Based on your neutral mood and neutral     │
│  preference, here are some great            │
│  recommendations for you!                   │
│                                             │
│  Mood: neutral   Tone: neutral              │
│                                             │
│  ┌───────────────────────────────────────┐ │
│  │ Movie 142                             │ │
│  │ Action ⭐ 4.1                         │ │
│  │ mystery                               │ │
│  │ 📅 2010  🎬 Action                    │ │
│  │ Match: 65%                            │ │
│  └───────────────────────────────────────┘ │
│                                             │
│  [More movie cards...]                      │
└─────────────────────────────────────────────┘
```

---

## 🔍 Still Not Working?

### Check 1: Browser Console

**Open Developer Tools:**
- Chrome/Edge: `F12` or `Cmd+Option+I` (Mac) or `Ctrl+Shift+I` (Windows)
- Firefox: `F12` or `Cmd+Option+K` (Mac) or `Ctrl+Shift+K` (Windows)
- Safari: `Cmd+Option+I` (enable Developer menu first in Preferences)

**Look for:**
- ❌ Red error messages
- ❌ Failed network requests
- ✅ Should see: `POST http://localhost:8000/api/chat` with status 200

### Check 2: Network Tab

1. Open Developer Tools → Network tab
2. Type a message in chat
3. Click Send
4. Watch for `/api/chat` request
5. Should see:
   - ✅ Status: 200 OK
   - ✅ Response: JSON with recommendations

### Check 3: Backend Running?

**Test in new terminal:**
```bash
curl http://localhost:8000/health
```

**Expected:**
```json
{"status":"healthy","version":"1.0.0"}
```

**If failed:**
```bash
cd /Users/gjvs/Documents/streamsmart
./scripts/run-backend.sh
```

### Check 4: Frontend Running?

**Test:**
```bash
curl http://localhost:5173
```

**Expected:** HTML response (not error)

**If failed:**
```bash
cd /Users/gjvs/Documents/streamsmart
./scripts/run-frontend.sh
```

---

## 🐛 Common Issues

### Issue: Blank/White Screen

**Cause:** JavaScript error  
**Fix:**
1. Open browser console (F12)
2. Look for red errors
3. Hard refresh: `Cmd+Shift+R` (Mac) or `Ctrl+Shift+R` (Windows)

### Issue: "Network Error" or "Failed to Fetch"

**Cause:** Backend not responding  
**Fix:**
```bash
# Check backend
curl http://localhost:8000/health

# Restart if needed
cd /Users/gjvs/Documents/streamsmart
./restart.sh
```

### Issue: Loading Forever (Spinner)

**Cause:** API timeout or wrong URL  
**Fix:**
1. Check `.env.local` exists:
   ```bash
   cat /Users/gjvs/Documents/streamsmart/streamsmart-frontend/.env.local
   ```
   Should contain: `VITE_API_URL=http://localhost:8000`

2. Restart frontend:
   ```bash
   cd /Users/gjvs/Documents/streamsmart
   pkill -f vite
   ./scripts/run-frontend.sh
   ```

### Issue: Shows "Application Error"

**Cause:** Frontend is hitting production URL (broken)  
**Fix:** Already done! `.env.local` created ✅

---

## 🧪 Quick Test Script

**Run this to verify everything:**

```bash
cd /Users/gjvs/Documents/streamsmart

# Test backend
echo "Testing backend..."
curl -s http://localhost:8000/health | grep healthy && echo "✅ Backend OK" || echo "❌ Backend FAILED"

# Test frontend
echo "Testing frontend..."
curl -s http://localhost:5173 | grep "streamsmart" && echo "✅ Frontend OK" || echo "❌ Frontend FAILED"

# Test API
echo "Testing API..."
curl -s -X POST http://localhost:8000/api/chat \
  -H "Content-Type: application/json" \
  -d '{"user_id":"test","message":"action movies","top_n":1}' | grep "recommendations" && echo "✅ API OK" || echo "❌ API FAILED"

echo ""
echo "If all ✅, open: http://localhost:5173"
```

---

## 🎯 What "Results" Should Look Like

### After Sending a Message:

**Your Message (User):**
```
I am happy and want action movies
```

**Bot Response (StreamSmart AI):**
- Text: "Based on your neutral mood and neutral preference..."
- Mood badges: `Mood: neutral` `Tone: neutral`
- Movie cards (3-5):

**Movie Card Example:**
```
┌────────────────────────────────┐
│ Movie 142                      │  ← Title
│ Action ⭐ 4.1                  │  ← Genre & Rating
│ mystery                        │  ← Tags
│ 📅 2010  🎬 Action             │  ← Year & Genre icon
│ Match: 65%                     │  ← ML Hybrid Score
└────────────────────────────────┘
```

---

## 🚀 Everything Ready?

✅ Backend running on http://localhost:8000  
✅ Frontend running on http://localhost:5173  
✅ `.env.local` configured with correct API URL  
✅ ML model loaded and ready  

**Open http://localhost:5173 and start chatting!** 🎬

---

## 📞 Still Stuck?

Run this and tell me the output:
```bash
cd /Users/gjvs/Documents/streamsmart
./status.sh
```

Or check browser console and share any red errors you see!

