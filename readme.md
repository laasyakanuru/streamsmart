# StreamSmart 🎬

StreamSmart is a hackathon-ready app with a **FastAPI backend** and a **React (Vite) frontend**.  
It recommends shows/movies based on your mood.

---

## 🚀 Getting Started

### 1. Clone the Repository
```bash
git clone https://github.com/laasyakanuru/streamsmart.git
cd streamsmart

### 2. Run the backend
cd streamsmart-backend

# Install dependencies (using uv or pip)
uv sync
# or
pip install -r requirements.txt

# Run the backend
uv run uvicorn app.main:app --reload

Backend runs at: http://127.0.0.1:8000

Test it in Swagger UI: 👉 http://127.0.0.1:8000/docs

### 3. Run Frontend

cd ../frontend

# Install dependencies
npm install

# Run the frontend
npm run dev

Frontend runs at: http://localhost:5173


Demo Flow
Start backend (uv run uvicorn app.main:app --reload).

Start frontend (npm run dev).

Open http://localhost:5173.

Type a mood → click Recommend.

See recommendation returned from backend