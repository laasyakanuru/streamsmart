# 🚀 StreamSmart - Quick Start Guide

## ⚡ One-Command Launch

To start the app every time:

```bash
cd /Users/gjvs/Documents/streamsmart
./start.sh
```

**That's it!** 🎉 The browser will automatically open to `http://localhost:5173`

---

## 📋 Essential Commands

| Command | Description |
|---------|-------------|
| `./start.sh` | Start both backend and frontend |
| `./stop.sh` | Stop all services |
| `./restart.sh` | Restart everything |
| `./status.sh` | Check if services are running |
| `./logs.sh` | View application logs |

---

## 🎯 Step-by-Step Usage

### 1️⃣ First Time Setup (One Time Only)

```bash
# Navigate to project
cd /Users/gjvs/Documents/streamsmart

# Install backend dependencies (if not done)
cd streamsmart-backend
uv pip install -e .
cd ..

# Install frontend dependencies (if not done)
cd streamsmart-frontend
npm install
cd ..

# Make scripts executable (if not done)
chmod +x *.sh
```

### 2️⃣ Daily Usage (Every Time)

```bash
# Go to project directory
cd /Users/gjvs/Documents/streamsmart

# Start the app
./start.sh
```

**Done!** Browser opens automatically to your app.

---

## 🔍 Check Status

Want to see if everything is running?

```bash
./status.sh
```

**Output:**
```
📊 StreamSmart Status
=====================

✅ Backend:  RUNNING on http://localhost:8000
   AI Mode:  Azure OpenAI (GPT-powered)

✅ Frontend: RUNNING on http://localhost:5173
```

---

## 📊 View Logs

If something isn't working:

```bash
./logs.sh
```

Choose what to view:
1. Backend logs (errors, API calls)
2. Frontend logs (UI issues)
3. Both logs
4. Live backend logs (real-time)
5. Live frontend logs (real-time)

---

## 🛑 Stop Everything

When you're done:

```bash
./stop.sh
```

---

## 🔄 Restart

If something breaks:

```bash
./restart.sh
```

---

## 🌐 URLs

Once started, access these:

- **Frontend (Your App)**: http://localhost:5173
- **Backend API**: http://localhost:8000
- **API Docs**: http://localhost:8000/docs
- **Health Check**: http://localhost:8000/health

---

## 🧪 Quick Test

After starting, test the app:

### Test 1: Open Frontend
```bash
open http://localhost:5173
```

### Test 2: Type a Message
In the chat box, type:
```
I am super happy and want to watch something light-hearted
```

### Test 3: Check Mood Detection
The AI should respond with:
- **Mood**: happy (not neutral!)
- **Tone**: light
- **Recommendations**: Comedy, feel-good shows

---

## 🐛 Troubleshooting

### Problem: Backend won't start

**Check:**
```bash
./status.sh
```

**If port 8000 is busy:**
```bash
lsof -i :8000
kill -9 <PID>
./start.sh
```

### Problem: Frontend won't start

**Check:**
```bash
./status.sh
```

**If port 5173 is busy:**
```bash
lsof -i :5173
kill -9 <PID>
./start.sh
```

### Problem: "Module not found"

**Backend:**
```bash
cd streamsmart-backend
uv pip install -e .
cd ..
./restart.sh
```

**Frontend:**
```bash
cd streamsmart-frontend
npm install
cd ..
./restart.sh
```

### Problem: Azure OpenAI not working

**Set environment variables:**
```bash
# Edit .env file
nano streamsmart-backend/.env

# Add these lines:
AZURE_OPENAI_ENDPOINT=https://your-endpoint.openai.azure.com
AZURE_OPENAI_KEY=your-key-here
AZURE_OPENAI_DEPLOYMENT=gpt-4o-mini

# Restart
./restart.sh
```

---

## 📁 Folder Structure

```
streamsmart/
├── start.sh          ← Start everything
├── stop.sh           ← Stop everything
├── restart.sh        ← Restart everything
├── status.sh         ← Check status
├── logs.sh           ← View logs
├── logs/             ← Log files
│   ├── backend.log
│   └── frontend.log
├── streamsmart-backend/   ← FastAPI backend
└── streamsmart-frontend/  ← React frontend
```

---

## ⚙️ Advanced Usage

### Run Backend Only
```bash
cd streamsmart-backend
uvicorn app.main:app --reload
```

### Run Frontend Only
```bash
cd streamsmart-frontend
npm run dev
```

### Run in Production Mode
```bash
# Backend
cd streamsmart-backend
uvicorn app.main:app --host 0.0.0.0 --port 8000

# Frontend (build first)
cd streamsmart-frontend
npm run build
npm run preview
```

---

## 🎬 Demo Workflow

**For presentations:**

1. **Before demo:**
   ```bash
   cd /Users/gjvs/Documents/streamsmart
   ./start.sh
   ```

2. **Open browser** (auto-opens to http://localhost:5173)

3. **Type in chat:**
   - "I'm feeling super happy and energetic"
   - "I want an intense thriller"
   - "Show me relaxing nature documentaries"

4. **Show AI features:**
   - Point out mood detection
   - Show personalized recommendations
   - Highlight user analytics

5. **After demo:**
   ```bash
   ./stop.sh
   ```

---

## 🌐 Production Deployment

To deploy to Azure:

```bash
cd /Users/gjvs/Documents/streamsmart
./scripts/deploy-now.sh
```

**Production URLs:**
- Frontend: https://streamsmart-frontend-7272.azurewebsites.net
- Backend: https://streamsmart-backend-7272.azurewebsites.net

---

## 💡 Tips

### Faster Startup
Start backend first, then frontend:
```bash
cd streamsmart-backend && uvicorn app.main:app --reload &
sleep 3
cd ../streamsmart-frontend && npm run dev &
```

### Auto-Restart on Code Changes
- **Backend**: Already has `--reload` flag
- **Frontend**: Vite auto-reloads on save

### View Real-Time Logs
```bash
# Terminal 1: Backend logs
tail -f logs/backend.log

# Terminal 2: Frontend logs
tail -f logs/frontend.log
```

---

## ✅ Daily Checklist

Every time you work on the project:

- [ ] `cd /Users/gjvs/Documents/streamsmart`
- [ ] `./start.sh`
- [ ] Wait for browser to open (or open http://localhost:5173)
- [ ] Test with a sample message
- [ ] When done: `./stop.sh`

---

## 🎉 You're Ready!

**To launch the app:**
```bash
cd /Users/gjvs/Documents/streamsmart && ./start.sh
```

**That's all you need!** 🚀

---

## 📞 Need Help?

- **Check status**: `./status.sh`
- **View logs**: `./logs.sh`
- **Restart**: `./restart.sh`
- **Read docs**: Open `README.md` or `STAGING_RELEASE.md`

**Happy coding!** 🎬✨
