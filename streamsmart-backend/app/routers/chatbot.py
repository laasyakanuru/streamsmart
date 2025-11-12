from fastapi import APIRouter
from pydantic import BaseModel

router = APIRouter(prefix="/chatbot", tags=["chatbot"])

class MoodRequest(BaseModel):
    mood: str
    context: str = "alone"
    time_of_day: str = "evening"

@router.post("/recommend")
def recommend(req: MoodRequest):
    return {
        "recommendation": f"Try watching 'Friends' for a {req.mood} {req.time_of_day} vibe!"
    }
