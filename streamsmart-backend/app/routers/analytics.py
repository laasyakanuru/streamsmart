"""
Analytics and insights endpoints
"""
from fastapi import APIRouter, HTTPException
from app.recommender.conversation_memory import (
    get_user_conversations,
    get_user_mood_history,
    get_user_genre_preferences
)
from app.recommender.user_profile import get_user_history

router = APIRouter(prefix="/api/analytics", tags=["analytics"])

@router.get("/user/{user_id}/insights")
def get_user_insights(user_id: str):
    """
    Get comprehensive insights about a user's preferences and behavior
    """
    try:
        watch_history = get_user_history(user_id)
        mood_history = get_user_mood_history(user_id)
        genre_preferences = get_user_genre_preferences(user_id)
        recent_conversations = get_user_conversations(user_id, limit=5)
        
        # Calculate top mood
        top_mood = max(mood_history.items(), key=lambda x: x[1])[0] if mood_history else "neutral"
        
        # Calculate top genres
        sorted_genres = sorted(genre_preferences.items(), key=lambda x: x[1], reverse=True)
        top_genres = [genre for genre, _ in sorted_genres[:3]]
        
        return {
            "user_id": user_id,
            "watch_history_count": len(watch_history),
            "conversation_count": len(recent_conversations),
            "top_mood": top_mood,
            "mood_distribution": mood_history,
            "top_genres": top_genres,
            "genre_distribution": genre_preferences,
            "recent_conversations": recent_conversations
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching insights: {str(e)}")

@router.get("/user/{user_id}/recommendations/trending")
def get_trending_for_user(user_id: str):
    """
    Get trending content based on user's preferences
    """
    try:
        genre_preferences = get_user_genre_preferences(user_id)
        
        if not genre_preferences:
            return {
                "message": "No preference data yet. Start chatting to build your profile!",
                "trending": []
            }
        
        # Get top genre
        top_genre = max(genre_preferences.items(), key=lambda x: x[1])[0]
        
        return {
            "user_id": user_id,
            "top_genre": top_genre,
            "message": f"Based on your interest in {top_genre}, here's what's trending!"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching trending: {str(e)}")

