from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import chatbot

app = FastAPI(title="StreamSmart")

# ✅ Add CORS middleware immediately after creating the app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173"],  # frontend dev server
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Routers
app.include_router(chatbot.router)

@app.get("/")
def root():
    return {"message": "Welcome to StreamSmart!"}
