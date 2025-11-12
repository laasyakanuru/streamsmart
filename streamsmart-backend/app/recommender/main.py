from fastapi import FastAPI
from pydantic import BaseModel
from app.recommender import get_recommendations
from app.user_profile import add_to_history

app = FastAPI()

class UserPrompt(BaseModel):
    user_id: str
    text: str
    watched_title: str | None = None  # optional

@app.post("/recommend")
def recommend(user_input: UserPrompt):
    # Optionally add a watched show to history
    if user_input.watched_title:
        add_to_history(user_input.user_id, user_input.watched_title)

    result = get_recommendations(user_input.user_id, user_input.text)
    return result
