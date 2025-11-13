from dotenv import load_dotenv
import os

# Load environment variables FIRST (before any other imports)
load_dotenv()

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import chatbot, analytics, feedback

app = FastAPI(
    title="StreamSmart API",
    description="AI-Powered OTT Content Recommendation Chatbot",
    version="1.0.0"
)

# Configure CORS
frontend_url = os.getenv("FRONTEND_URL", "http://localhost:5173")
deployed_frontend_url = "https://streamsmart-frontend-2091.azurewebsites.net"  

app.add_middleware(
    CORSMiddleware,
    allow_origins=[frontend_url, deployed_frontend_url, "http://localhost:5173", "http://127.0.0.1:5173"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(chatbot.router)
app.include_router(analytics.router)
app.include_router(feedback.router)


@app.get("/")
def root():
    return {
        "message": "Welcome to StreamSmart API!",
        "version": "1.0.0",
        "description": "AI-Powered OTT Content Recommendation Chatbot",
        "endpoints": {
            "chat": "/api/chat",
            "history": "/api/history",
            "analytics": "/api/analytics",
            "feedback": "/api/feedback",
            "docs": "/docs"
        },
        "features": [
            "Mood-based recommendations",
            "Personalized suggestions",
            "Watch history tracking",
            "User insights & analytics",
            "Feedback system"
        ]
    }


@app.get("/health")
def health_check():
    return {"status": "healthy", "version": "1.0.0"}


@app.on_event("startup")
async def startup_event():
    """Initialize data files on startup"""
    import json

    # ✅ Use writable directory depending on environment
    if os.getenv("WEBSITE_SITE_NAME"):  # Azure App Service
        base_dir = os.path.join("/home", "data")
    else:  # Local development
        base_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "data")

    os.makedirs(base_dir, exist_ok=True)

    # Initialize data files if they don't exist
    files_to_init = {
        "conversations.json": {},
        "feedback.json": {"show_ratings": [], "recommendation_feedback": []}
    }

    for filename, initial_data in files_to_init.items():
        filepath = os.path.join(base_dir, filename)
        if not os.path.exists(filepath):
            with open(filepath, "w") as f:
                json.dump(initial_data, f, indent=2)
            print(f"✅ Initialized {filename} at {filepath}")

    print("🚀 StreamSmart API is ready!")
