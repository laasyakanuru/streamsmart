# 🚀 StreamSmart - Quick Start Guide

Get up and running with StreamSmart in 5 minutes!

## 📋 Prerequisites

Before you begin, ensure you have:
- ✅ Python 3.10 or higher
- ✅ Node.js 18 or higher
- ✅ OpenAI API key ([Get one here](https://platform.openai.com/api-keys))

## ⚡ Quick Start (Recommended)

### 1. Clone and Setup

```bash
# Clone the repository (or download the files)
cd /path/to/streamsmart

# Run the setup script
chmod +x scripts/setup.sh
./scripts/setup.sh
```

### 2. Configure Environment

```bash
# Edit the backend .env file
nano streamsmart-backend/.env

# Add your OpenAI API key:
OPENAI_API_KEY=sk-your-actual-api-key-here
```

### 3. Run the Application

Open two terminal windows:

**Terminal 1 - Backend:**
```bash
./scripts/run-backend.sh
```

**Terminal 2 - Frontend:**
```bash
./scripts/run-frontend.sh
```

### 4. Open Your Browser

- 🌐 Frontend: http://localhost:5173
- 🔧 API Docs: http://localhost:8000/docs
- ❤️ Health Check: http://localhost:8000/health

That's it! Start chatting with StreamSmart! 🎉

## 🐳 Alternative: Docker Quick Start

If you prefer Docker:

```bash
# Create .env file with your OpenAI key
echo "OPENAI_API_KEY=your-key-here" > .env

# Build and run
docker-compose up --build
```

Access at:
- Frontend: http://localhost
- Backend: http://localhost:8000

## 🎮 Try It Out

Send a message to the chatbot:
- "I'm feeling happy and want something funny"
- "Something thrilling for tonight"
- "I'm sad and need a pick-me-up"
- "Recommend a good action movie"

## 🔍 Explore Features

### View User Insights
```bash
curl http://localhost:8000/api/analytics/user/user_1/insights
```

### Check Watch History
```bash
curl http://localhost:8000/api/history/user_1
```

### Rate a Show
```bash
curl -X POST http://localhost:8000/api/feedback/show \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "user_1",
    "show_title": "Show_15",
    "rating": 5,
    "liked": true,
    "comment": "Loved it!"
  }'
```

## 🐛 Troubleshooting

### Backend won't start
```bash
# Check if virtual environment is activated
source .venv/bin/activate

# Reinstall dependencies
cd streamsmart-backend
uv pip install -r ../requirements.txt
```

### Frontend can't connect to backend
1. Ensure backend is running on port 8000
2. Check CORS settings in `streamsmart-backend/app/main.py`
3. Verify API URL in frontend code

### "Module not found" errors
```bash
# Activate venv and reinstall
source .venv/bin/activate
cd streamsmart-backend
uv pip install -r ../requirements.txt
```

### OpenAI API errors
1. Verify your API key is correct in `.env`
2. Check you have credits in your OpenAI account
3. Ensure the key has proper permissions

## 📚 Next Steps

- 📖 Read [README.md](README.md) for detailed documentation
- 🚀 Check [DEPLOYMENT.md](DEPLOYMENT.md) for Azure deployment
- ✨ See [FEATURES.md](FEATURES.md) for roadmap
- 🔧 Explore the API at http://localhost:8000/docs

## 💡 Quick Tips

1. **Better Recommendations**: Be specific about your mood and preferences
2. **Build History**: Add shows to history for personalized recommendations
3. **Leave Feedback**: Rate recommendations to improve the system
4. **Check Insights**: View your preference analytics at `/api/analytics/user/{user_id}/insights`

## 🆘 Need Help?

- 📝 Check the full [README.md](README.md)
- 🐛 Open an issue on GitHub
- 💬 Join our community (coming soon)

## 🎉 You're Ready!

Start discovering amazing content with StreamSmart! 🎬🍿

---

Happy streaming! 🌟

