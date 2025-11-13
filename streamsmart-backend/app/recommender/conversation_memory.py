"""
Conversation memory to track user interactions and improve recommendations over time
"""
import json
import os
from datetime import datetime
from typing import List, Dict, Optional

base_dir = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
CONVERSATION_FILE = os.path.join(base_dir, "data", "conversations.json")

def load_conversations() -> Dict:
    """Load conversation history from file"""
    if not os.path.exists(CONVERSATION_FILE):
        return {}
    try:
        with open(CONVERSATION_FILE, "r") as f:
            return json.load(f)
    except Exception:
        return {}

def save_conversations(conversations: Dict):
    """Save conversation history to file"""
    try:
        with open(CONVERSATION_FILE, "w") as f:
            json.dump(conversations, f, indent=2)
    except Exception as e:
        print(f"Error saving conversations: {e}")

def add_conversation(user_id: str, message: str, mood: Dict, recommendations: List[Dict]):
    """Add a conversation entry for a user"""
    conversations = load_conversations()
    
    if user_id not in conversations:
        conversations[user_id] = []
    
    conversation_entry = {
        "timestamp": datetime.now().isoformat(),
        "message": message,
        "mood": mood,
        "recommendations": [rec["title"] for rec in recommendations[:3]],  # Store top 3
        "genres": list(set([rec["genre"] for rec in recommendations[:3]]))
    }
    
    conversations[user_id].append(conversation_entry)
    
    # Keep only last 50 conversations per user
    conversations[user_id] = conversations[user_id][-50:]
    
    save_conversations(conversations)

def get_user_conversations(user_id: str, limit: int = 10) -> List[Dict]:
    """Get recent conversations for a user"""
    conversations = load_conversations()
    user_convos = conversations.get(user_id, [])
    return user_convos[-limit:]

def get_user_mood_history(user_id: str) -> Dict[str, int]:
    """Get mood statistics for a user"""
    conversations = load_conversations()
    user_convos = conversations.get(user_id, [])
    
    mood_count = {}
    for convo in user_convos:
        mood = convo.get("mood", {}).get("mood", "neutral")
        mood_count[mood] = mood_count.get(mood, 0) + 1
    
    return mood_count

def get_user_genre_preferences(user_id: str) -> Dict[str, int]:
    """Get genre preferences based on conversation history"""
    conversations = load_conversations()
    user_convos = conversations.get(user_id, [])
    
    genre_count = {}
    for convo in user_convos:
        for genre in convo.get("genres", []):
            genre_count[genre] = genre_count.get(genre, 0) + 1
    
    return genre_count

