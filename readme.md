# 🎬 StreamSmart - AI-Powered OTT Recommendation Chatbot

StreamSmart is an intelligent chatbot that provides personalized movie and TV show recommendations based on your mood, preferences, and viewing history. Built with FastAPI, React, and powered by AI.

## ✨ Features

- 🤖 **AI-Powered Recommendations**: Uses sentence transformers and mood analysis to suggest content
- 💬 **Natural Chatbot Interface**: Interactive chat experience for requesting recommendations
- 🎭 **Mood Detection**: Automatically extracts mood and tone from your messages
- 📊 **Personalized Results**: Takes your watch history into account
- 🎨 **Beautiful UI**: Modern, responsive design with smooth animations
- ⚡ **Fast & Efficient**: Optimized embeddings and similarity search
- 🔄 **Real-time Updates**: Instant recommendations based on your input

## 🏗️ Architecture

```
streamsmart/
├── streamsmart-backend/     # FastAPI backend
│   ├── app/
│   │   ├── main.py         # Main application
│   │   ├── routers/        # API routes
│   │   └── recommender/    # Recommendation engine
│   ├── data/               # Content database
│   └── Dockerfile
├── streamsmart-frontend/    # React frontend
│   ├── src/
│   │   ├── App.jsx        # Main component
│   │   └── App.css        # Styles
│   ├── Dockerfile
│   └── nginx.conf
└── docker-compose.yml      # Local deployment
```

## 🚀 Quick Start

### Prerequisites

- Python 3.10+
- Node.js 18+
- OpenAI API key (for mood extraction)

### Local Development

#### Backend Setup

```bash
# Navigate to backend directory
cd streamsmart-backend

# Activate virtual environment
source ../.venv/bin/activate

# Install dependencies
uv pip install -r ../requirements.txt

# Create .env file
cp .env.example .env
# Edit .env and add your OPENAI_API_KEY

# Run the server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Backend will be available at: http://localhost:8000
API docs at: http://localhost:8000/docs

#### Frontend Setup

```bash
# Navigate to frontend directory
cd streamsmart-frontend

# Install dependencies
npm install

# Run development server
npm run dev
```

Frontend will be available at: http://localhost:5173

### Using Docker Compose

```bash
# Create .env file with your OpenAI key
echo "OPENAI_API_KEY=your_key_here" > .env

# Build and run
docker-compose up --build

# Access the application
# Frontend: http://localhost
# Backend: http://localhost:8000
# API Docs: http://localhost:8000/docs
```

## 📡 API Endpoints

### POST /api/chat
Get personalized recommendations based on user message.

**Request:**
```json
{
  "user_id": "user_1",
  "message": "I'm feeling happy and want something funny",
  "top_n": 5
}
```

**Response:**
```json
{
  "user_id": "user_1",
  "extracted_mood": {
    "mood": "happy",
    "tone": "lighthearted"
  },
  "recommendations": [
    {
      "title": "Show_15",
      "genre": "Comedy",
      "mood_tag": "happy",
      "tone": "lighthearted",
      "description": "...",
      "rating": 8.5,
      "hybrid_score": 0.87
    }
  ],
  "message": "Based on your happy mood..."
}
```

### POST /api/history
Add show to user's watch history.

**Request:**
```json
{
  "user_id": "user_1",
  "show_title": "Show_15"
}
```

### GET /api/history/{user_id}
Get user's watch history.

## 🎨 Tech Stack

### Backend
- **FastAPI** - Modern Python web framework
- **Sentence Transformers** - Semantic similarity for content matching
- **PyTorch** - Deep learning framework
- **TextBlob** - Text processing and sentiment analysis
- **OpenAI API** - Advanced mood extraction
- **Pandas** - Data manipulation

### Frontend
- **React** - UI library
- **Axios** - HTTP client
- **Vite** - Build tool
- **CSS3** - Modern styling with animations

### Infrastructure
- **Docker** - Containerization
- **Nginx** - Web server for frontend
- **Azure Container Apps** - Cloud hosting

## 🔧 Configuration

### Environment Variables

#### Backend (.env)
```bash
OPENAI_API_KEY=your_openai_api_key
FRONTEND_URL=http://localhost:5173
HOST=0.0.0.0
PORT=8000
```

#### Frontend
```bash
REACT_APP_API_URL=http://localhost:8000
```

## 🌟 Future Enhancements

- [ ] User authentication and profiles
- [ ] Multi-platform content aggregation (Netflix, Prime, Disney+)
- [ ] Social features (share recommendations, watch parties)
- [ ] Advanced filters (genre, year, rating, duration)
- [ ] Streaming availability checker
- [ ] Watchlist management
- [ ] Rating and review system
- [ ] Recommendation explanations
- [ ] Voice input support
- [ ] Mobile app (React Native)
- [ ] Integration with streaming service APIs
- [ ] Collaborative filtering for better recommendations

## 📚 How It Works

1. **User Input**: User sends a message describing their mood or preferences
2. **Mood Extraction**: AI analyzes the message to extract mood and tone
3. **Embedding Generation**: User prompt is converted to semantic embeddings
4. **Content Filtering**: Content database is filtered by mood/tone
5. **Similarity Matching**: Semantic similarity computed against content
6. **History Personalization**: User's watch history influences recommendations
7. **Hybrid Scoring**: Combines prompt similarity and history similarity
8. **Top Results**: Returns top N recommendations with metadata

## 🧪 Testing

### Backend Tests
```bash
cd streamsmart-backend
pytest
```

### Frontend Tests
```bash
cd streamsmart-frontend
npm test
```

## 📦 Deployment

See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed Azure deployment instructions.

Quick deploy to Azure:
```bash
# Deploy using Azure Container Apps
./scripts/deploy-azure.sh
```

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Sentence Transformers for semantic similarity
- OpenAI for advanced AI capabilities
- The open-source community

## 📧 Contact

For questions or support, please open an issue on GitHub.

---

Made with ❤️ for movie and TV show enthusiasts
