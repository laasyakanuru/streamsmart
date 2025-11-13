from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional, List
from app.recommender import get_recommendations
from app.recommender.user_profile import add_to_history, get_user_history
from app.recommender.conversation_memory import add_conversation, get_user_conversations
from app.recommender.mood_extractor import get_active_mode

router = APIRouter(prefix="/api", tags=["chatbot"])

class ChatRequest(BaseModel):
    user_id: str
    message: str
    top_n: Optional[int] = 5

class HistoryRequest(BaseModel):
    user_id: str
    show_title: str

class RecommendationResponse(BaseModel):
    user_id: str
    extracted_mood: dict
    recommendations: List[dict]
    message: str

@router.post("/chat", response_model=RecommendationResponse)
def chat_recommend(req: ChatRequest):
    """
    Main chatbot endpoint that takes user message and returns personalized recommendations
    """
    try:
        # Get recommendations using the AI recommender
        result = get_recommendations(
            user_id=req.user_id,
            user_prompt=req.message,
            top_n=req.top_n
        )
        
        # Save conversation to memory
        add_conversation(
            user_id=req.user_id,
            message=req.message,
            mood=result["extracted_mood"],
            recommendations=result["recommendations"]
        )
        
        # Create a friendly message
        mood = result["extracted_mood"].get("mood", "neutral")
        tone = result["extracted_mood"].get("tone", "neutral")
        
        message = f"Based on your {mood} mood and {tone} preference, here are some great recommendations for you!"
        
        return {
            **result,
            "message": message
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error generating recommendations: {str(e)}")

@router.post("/history")
def add_user_history(req: HistoryRequest):
    """
    Add a show to user's watch history
    """
    try:
        add_to_history(req.user_id, req.show_title)
        return {"message": "Added to history", "user_id": req.user_id, "show_title": req.show_title}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error adding to history: {str(e)}")

@router.get("/history/{user_id}")
def get_history(user_id: str):
    """
    Get user's watch history
    """
    try:
        history = get_user_history(user_id)
        return {"user_id": user_id, "history": history}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching history: {str(e)}")

@router.get("/status")
def get_system_status():
    """
    Get current system configuration and active services
    """
    mood_mode = get_active_mode()
    
    mode_descriptions = {
        "azure_openai": "Azure OpenAI GPT (Best - Enterprise grade)",
        "openai": "OpenAI API GPT (Good - Cloud-based)",
        "rule_based": "Rule-based (Works offline - No API needed)"
    }
    
    return {
        "mood_extraction": {
            "active_mode": mood_mode,
            "description": mode_descriptions.get(mood_mode, "Unknown"),
            "is_ai_powered": mood_mode in ["azure_openai", "openai"]
        },
        "recommendation_engine": "Active",
        "analytics": "Active",
        "feedback_system": "Active"
    }
