import pandas as pd
from sentence_transformers import SentenceTransformer, util
from app.mood_extractor import extract_mood
from app.user_profile import get_user_history

# Load dataset
df = pd.read_csv("data/synthetic_ott_data_with_users.csv")

# Load embedding model (lightweight and fast)
model = SentenceTransformer('all-MiniLM-L6-v2')
df['embedding'] = df['description'].apply(lambda x: model.encode(x, convert_to_tensor=True))

def compute_similarity(vec1, vec2):
    return util.cos_sim(vec1, vec2).item()

def get_recommendations(user_id, user_prompt, top_n=5, mood_weight=0.5, history_weight=0.5):
    # Extract mood and tone using GPT or rule-based logic
    mood_info = extract_mood(user_prompt)
    mood = mood_info.get("mood", "neutral").lower()
    tone = mood_info.get("tone", "neutral").lower()

    # Get user watch history
    user_history_titles = get_user_history(user_id)

    # Encode the user prompt into embeddings
    user_embedding = model.encode(user_prompt, convert_to_tensor=True)

    # 🔹 Enhanced filtering logic: filter by both mood and tone
    if mood != "neutral" or tone != "neutral":
        temp_df = df[
            (df["mood_tag"].str.lower() == mood) |
            (df["tone"].str.lower() == tone)
        ]
        # Fallback if no direct match
        if temp_df.empty:
            print(f"[Info] No direct match for mood='{mood}' tone='{tone}'. Using full dataset.")
            temp_df = df.copy()
    else:
        temp_df = df.copy()

    # Compute prompt similarity
    temp_df["prompt_similarity"] = temp_df["embedding"].apply(lambda x: compute_similarity(x, user_embedding))

    # Compute history similarity
    if user_history_titles:
        watched_embeddings = [
            df[df["title"] == t]["embedding"].values[0]
            for t in user_history_titles if t in df["title"].values
        ]
        if watched_embeddings:
            avg_history_vector = sum(watched_embeddings) / len(watched_embeddings)
            temp_df["history_similarity"] = temp_df["embedding"].apply(lambda x: compute_similarity(x, avg_history_vector))
        else:
            temp_df["history_similarity"] = 0.0
    else:
        temp_df["history_similarity"] = 0.0

    # Weighted hybrid score
    temp_df["hybrid_score"] = (
        mood_weight * temp_df["prompt_similarity"]
        + history_weight * temp_df["history_similarity"]
    )

    # Sort and return top recommendations
    results = temp_df.sort_values(by="hybrid_score", ascending=False).head(top_n)

    return {
        "user_id": user_id,
        "extracted_mood": mood_info,
        "recommendations": results[
            ["title", "genre", "mood_tag", "tone", "description", "rating", "hybrid_score"]
        ].to_dict(orient="records")
    }
