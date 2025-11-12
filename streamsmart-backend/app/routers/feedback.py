"""
Feedback and rating system
"""
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional
import json
import os

router = APIRouter(prefix="/api/feedback", tags=["feedback"])

base_dir = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
FEEDBACK_FILE = os.path.join(base_dir, "data", "feedback.json")

class FeedbackRequest(BaseModel):
    user_id: str
    show_title: str
    rating: int  # 1-5 stars
    liked: bool
    comment: Optional[str] = None

class RecommendationFeedback(BaseModel):
    user_id: str
    recommendation_helpful: bool
    accuracy_score: int  # 1-5
    comment: Optional[str] = None

def load_feedback():
    if not os.path.exists(FEEDBACK_FILE):
        return {"show_ratings": [], "recommendation_feedback": []}
    try:
        with open(FEEDBACK_FILE, "r") as f:
            return json.load(f)
    except Exception:
        return {"show_ratings": [], "recommendation_feedback": []}

def save_feedback(feedback):
    try:
        with open(FEEDBACK_FILE, "w") as f:
            json.dump(feedback, f, indent=2)
    except Exception as e:
        print(f"Error saving feedback: {e}")

@router.post("/show")
def rate_show(feedback: FeedbackRequest):
    """
    Rate a show after watching
    """
    try:
        all_feedback = load_feedback()
        
        feedback_entry = {
            "user_id": feedback.user_id,
            "show_title": feedback.show_title,
            "rating": feedback.rating,
            "liked": feedback.liked,
            "comment": feedback.comment,
            "timestamp": json.dumps(__import__('datetime').datetime.now(), default=str)
        }
        
        all_feedback["show_ratings"].append(feedback_entry)
        save_feedback(all_feedback)
        
        return {
            "message": "Thank you for your feedback!",
            "feedback": feedback_entry
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error saving feedback: {str(e)}")

@router.post("/recommendation")
def rate_recommendation(feedback: RecommendationFeedback):
    """
    Rate the quality of recommendations
    """
    try:
        all_feedback = load_feedback()
        
        feedback_entry = {
            "user_id": feedback.user_id,
            "recommendation_helpful": feedback.recommendation_helpful,
            "accuracy_score": feedback.accuracy_score,
            "comment": feedback.comment,
            "timestamp": json.dumps(__import__('datetime').datetime.now(), default=str)
        }
        
        all_feedback["recommendation_feedback"].append(feedback_entry)
        save_feedback(all_feedback)
        
        return {
            "message": "Thank you for helping us improve!",
            "feedback": feedback_entry
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error saving feedback: {str(e)}")

@router.get("/stats")
def get_feedback_stats():
    """
    Get overall feedback statistics
    """
    try:
        feedback = load_feedback()
        show_ratings = feedback.get("show_ratings", [])
        rec_feedback = feedback.get("recommendation_feedback", [])
        
        # Calculate average ratings
        avg_show_rating = sum(r["rating"] for r in show_ratings) / len(show_ratings) if show_ratings else 0
        avg_rec_accuracy = sum(r["accuracy_score"] for r in rec_feedback) / len(rec_feedback) if rec_feedback else 0
        
        helpful_count = sum(1 for r in rec_feedback if r["recommendation_helpful"])
        helpful_percentage = (helpful_count / len(rec_feedback) * 100) if rec_feedback else 0
        
        return {
            "total_show_ratings": len(show_ratings),
            "average_show_rating": round(avg_show_rating, 2),
            "total_recommendation_feedback": len(rec_feedback),
            "average_accuracy_score": round(avg_rec_accuracy, 2),
            "helpful_percentage": round(helpful_percentage, 2)
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching stats: {str(e)}")

