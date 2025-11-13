'''
import pandas as pd
from sentence_transformers import SentenceTransformer, util
from app.recommender.mood_extractor import extract_mood
from app.recommender.user_profile import get_user_history
import os

# Load dataset
base_dir = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
data_path = os.path.join(base_dir, "data", "synthetic_ott_data_with_users.csv")
df = pd.read_csv(data_path)

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
'''

import pandas as pd
import os
from sentence_transformers import SentenceTransformer, util
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
import joblib
from app.recommender.mood_extractor import extract_mood
from app.recommender.user_profile import get_user_history
# -----------------------------
# Load datasets
# -----------------------------
base_dir = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
movies_path = os.path.join(base_dir, "data", "movies_metadata.csv")
moods_path = os.path.join(base_dir, "data", "mood_recommendations.csv")
users_path = os.path.join(base_dir, "data", "users.csv")
movies_df = pd.read_csv(movies_path)
moods_df = pd.read_csv(moods_path)
users_df = pd.read_csv(users_path)
# -----------------------------
# Load or Train RandomForest model
# -----------------------------
model_path = os.path.join(base_dir, "data", "rf_recommender.pkl")
le_mood_path = os.path.join(base_dir, "data", "le_mood.pkl")
le_context_path = os.path.join(base_dir, "data", "le_context.pkl")
le_time_path = os.path.join(base_dir, "data", "le_time.pkl")
le_movie_path = os.path.join(base_dir, "data", "le_movie.pkl")

if os.path.exists(model_path) and os.path.exists(le_mood_path):
    # Load existing model and encoders
    print("✅ Loading existing Random Forest model...")
    rf_model = joblib.load(model_path)
    le_mood = joblib.load(le_mood_path)
    le_context = joblib.load(le_context_path)
    le_time = joblib.load(le_time_path)
    le_movie = joblib.load(le_movie_path)
    print("✅ Model loaded successfully!")
else:
    # Train new model
    print("🔧 Training Random Forest model (first time)...")
    le_mood = LabelEncoder()
    le_context = LabelEncoder()
    le_time = LabelEncoder()
    le_movie = LabelEncoder()
    
    moods_df["mood_enc"] = le_mood.fit_transform(moods_df["mood"])
    moods_df["context_enc"] = le_context.fit_transform(moods_df["context"])
    moods_df["time_enc"] = le_time.fit_transform(moods_df["time_of_day"])
    moods_df["movie_enc"] = le_movie.fit_transform(moods_df["recommended_movie_id"])
    
    X = moods_df[["mood_enc", "context_enc", "time_enc"]]
    y = moods_df["movie_enc"]
    
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    
    rf_model = RandomForestClassifier(n_estimators=10, random_state=42, max_depth=10)
    rf_model.fit(X_train, y_train)
    
    # Save model and encoders for reuse
    joblib.dump(rf_model, model_path)
    joblib.dump(le_mood, le_mood_path)
    joblib.dump(le_context, le_context_path)
    joblib.dump(le_time, le_time_path)
    joblib.dump(le_movie, le_movie_path)
    
    accuracy = rf_model.score(X_test, y_test)
    print(f"✅ Model trained! Test Accuracy: {accuracy:.2%}")
# -----------------------------
# Embedding model (hybrid logic)
# -----------------------------
embed_model = SentenceTransformer("all-MiniLM-L6-v2")
movies_df["embedding"] = movies_df["title"].apply(
    lambda x: embed_model.encode(x, convert_to_tensor=True)
)
def compute_similarity(vec1, vec2):
    return util.cos_sim(vec1, vec2).item()
# -----------------------------
# Hybrid Recommendation Function
# -----------------------------
def get_recommendations(user_id, user_prompt, top_n=5, mood_weight=0.5, history_weight=0.5, ml_weight=0.5):
    # Extract mood and tone
    mood_info = extract_mood(user_prompt)
    mood = mood_info.get("mood", "neutral").lower()
    tone = mood_info.get("tone", "neutral").lower()
    # Get user profile
    user_profile = users_df[users_df["user_id"] == user_id].to_dict(orient="records")
    user_history_titles = get_user_history(user_id)
    # Encode prompt
    user_embedding = embed_model.encode(user_prompt, convert_to_tensor=True)
    # Filter by mood/tone
    temp_df = movies_df.copy()
    temp_df["prompt_similarity"] = temp_df["embedding"].apply(lambda x: compute_similarity(x, user_embedding))
    # History similarity
    if user_history_titles:
        watched_embeddings = [
            movies_df[movies_df["title"] == t]["embedding"].values[0]
            for t in user_history_titles if t in movies_df["title"].values
        ]
        if watched_embeddings:
            avg_history_vector = sum(watched_embeddings) / len(watched_embeddings)
            temp_df["history_similarity"] = temp_df["embedding"].apply(lambda x: compute_similarity(x, avg_history_vector))
        else:
            temp_df["history_similarity"] = 0.0
    else:
        temp_df["history_similarity"] = 0.0
    # ML prediction (RandomForest)
    mood_enc = le_mood.transform([mood])[0] if mood in le_mood.classes_ else 0
    context_enc = le_context.transform(["alone"])[0]  # fallback
    time_enc = le_time.transform(["evening"])[0]      # fallback
    ml_pred = rf_model.predict([[mood_enc, context_enc, time_enc]])[0]
    predicted_movie_id = le_movie.inverse_transform([ml_pred])[0]
    # Add ML score (boost movies matching predicted ID)
    temp_df["ml_score"] = temp_df["movie_id"].apply(lambda mid: 1.0 if mid == predicted_movie_id else 0.0)
    # Hybrid score
    temp_df["hybrid_score"] = (
        mood_weight * temp_df["prompt_similarity"]
        + history_weight * temp_df["history_similarity"]
        + ml_weight * temp_df["ml_score"]
    )
    results = temp_df.sort_values(by="hybrid_score", ascending=False).head(top_n)
    return {
        "user_id": user_id,
        "extracted_mood": mood_info,
        "user_profile": user_profile,
        "recommendations": results[
            ["title", "genre", "release_year", "rating", "tags", "hybrid_score"]
        ].to_dict(orient="records")
    }