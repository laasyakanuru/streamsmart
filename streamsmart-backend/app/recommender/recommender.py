"""
ML-Optimized Recommender for Azure B1
======================================
Keeps ML model but extremely optimized for Azure constraints

Strategy:
1. Lazy loading - Nothing loads at import time
2. Minimal ML model (5 trees, max_depth=5)  
3. Simple similarity (no TF-IDF at startup)
4. Fast startup (< 3 seconds on first request)
5. Low memory (< 400MB total)

ML Model: YES ✅
Performance: Azure B1 compatible ✅
"""

import pandas as pd
import os
import numpy as np

# CRITICAL: Don't import sklearn at module level!
# Import only when needed to avoid slow startup

# Global cache for lazy loading
_DATA_LOADED = False
_movies_df = None
_users_df = None
_ml_model = None
_encoders = None
_word_index = None

def _lazy_init():
    """
    Lazy initialization - called on first request only
    This keeps startup time near zero
    """
    global _DATA_LOADED, _movies_df, _users_df, _ml_model, _encoders, _word_index
    
    if _DATA_LOADED:
        return  # Already initialized
    
    print("🚀 Lazy loading recommender (first request)...")
    from app.recommender.mood_extractor import extract_mood
    from app.recommender.user_profile import get_user_history
    
    base_dir = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
    
    # 1. Load movie data (fast)
    print("📊 Loading datasets...")
    movies_path = os.path.join(base_dir, "data", "movies_metadata.csv")
    users_path = os.path.join(base_dir, "data", "users.csv")
    
    _movies_df = pd.read_csv(movies_path)
    _users_df = pd.read_csv(users_path)
    print(f"✅ Loaded {len(_movies_df)} movies")
    
    # 2. Build simple word index (lightweight)
    print("🔧 Building keyword index...")
    _movies_df['keywords'] = (
        _movies_df['title'].fillna('').str.lower() + ' ' +
        _movies_df['genre'].fillna('').str.lower() + ' ' +
        _movies_df['tags'].fillna('').str.lower()
    ).str.split()
    
    # Create word-to-movies index (fast lookup)
    _word_index = {}
    for idx, keywords in enumerate(_movies_df['keywords']):
        for word in keywords:
            if word not in _word_index:
                _word_index[word] = []
            _word_index[word].append(idx)
    
    print(f"✅ Indexed {len(_word_index)} keywords")
    
    # 3. Load TINY ML model (only if exists)
    model_path = os.path.join(base_dir, "data", "tiny_ml_model.pkl")
    
    if os.path.exists(model_path):
        print("🤖 Loading tiny ML model...")
        try:
            import joblib
            _ml_model = joblib.load(model_path)
            _encoders = {
                'mood': joblib.load(os.path.join(base_dir, "data", "le_mood.pkl")),
                'context': joblib.load(os.path.join(base_dir, "data", "le_context.pkl")),
                'time': joblib.load(os.path.join(base_dir, "data", "le_time.pkl")),
                'movie': joblib.load(os.path.join(base_dir, "data", "le_movie.pkl"))
            }
            print("✅ ML model loaded!")
        except Exception as e:
            print(f"⚠️  ML model load failed: {e}")
            _ml_model = None
    else:
        print("⚠️  No ML model found, will train minimal one...")
        _ml_model = _train_minimal_ml_model(base_dir)
    
    _DATA_LOADED = True
    print("✅ Initialization complete!")

def _train_minimal_ml_model(base_dir):
    """
    Train the tiniest possible ML model
    5 trees, depth 5, minimal features
    """
    try:
        from sklearn.ensemble import RandomForestClassifier
        from sklearn.model_selection import train_test_split
        from sklearn.preprocessing import LabelEncoder
        import joblib
        
        print("🔧 Training minimal ML model...")
        
        # Load mood data
        moods_path = os.path.join(base_dir, "data", "mood_recommendations.csv")
        moods_df = pd.read_csv(moods_path)
        
        # Encode
        global _encoders
        _encoders = {
            'mood': LabelEncoder(),
            'context': LabelEncoder(),
            'time': LabelEncoder(),
            'movie': LabelEncoder()
        }
        
        moods_df["mood_enc"] = _encoders['mood'].fit_transform(moods_df["mood"])
        moods_df["context_enc"] = _encoders['context'].fit_transform(moods_df["context"])
        moods_df["time_enc"] = _encoders['time'].fit_transform(moods_df["time_of_day"])
        moods_df["movie_enc"] = _encoders['movie'].fit_transform(moods_df["recommended_movie_id"])
        
        X = moods_df[["mood_enc", "context_enc", "time_enc"]]
        y = moods_df["movie_enc"]
        
        # MINIMAL MODEL: 5 trees, depth 5
        model = RandomForestClassifier(
            n_estimators=5,      # Only 5 trees (vs 10 or 100)
            max_depth=5,         # Shallow trees
            min_samples_split=20, # Aggressive pruning
            random_state=42,
            n_jobs=1
        )
        
        X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
        model.fit(X_train, y_train)
        
        # Save for reuse
        model_path = os.path.join(base_dir, "data", "tiny_ml_model.pkl")
        joblib.dump(model, model_path)
        joblib.dump(_encoders['mood'], os.path.join(base_dir, "data", "le_mood.pkl"))
        joblib.dump(_encoders['context'], os.path.join(base_dir, "data", "le_context.pkl"))
        joblib.dump(_encoders['time'], os.path.join(base_dir, "data", "le_time.pkl"))
        joblib.dump(_encoders['movie'], os.path.join(base_dir, "data", "le_movie.pkl"))
        
        accuracy = model.score(X_test, y_test)
        print(f"✅ Minimal ML trained! Accuracy: {accuracy:.2%}")
        
        return model
        
    except Exception as e:
        print(f"❌ ML training failed: {e}")
        return None

def get_recommendations(user_id, user_prompt, top_n=5):
    """
    Get ML-powered recommendations (optimized for Azure B1)
    
    Flow:
    1. Lazy init on first request
    2. Extract mood (Azure OpenAI)
    3. Keyword matching (fast)
    4. ML prediction (tiny model)
    5. Combine scores
    """
    try:
        # Lazy initialization
        _lazy_init()
        
        from app.recommender.mood_extractor import extract_mood
        from app.recommender.user_profile import get_user_history
        
        global _movies_df, _users_df, _ml_model, _encoders, _word_index
        
        # Extract mood
        mood_info = extract_mood(user_prompt)
        mood = mood_info.get("mood", "neutral").lower()
        tone = mood_info.get("tone", "neutral").lower()
        
        # Get user data
        user_profile = _users_df[_users_df["user_id"] == user_id].to_dict(orient="records")
        user_history = get_user_history(user_id)
        
        # Initialize scores
        scores = np.zeros(len(_movies_df))
        
        # 1. KEYWORD MATCHING (very fast)
        prompt_words = set(user_prompt.lower().split())
        for word in prompt_words:
            if word in _word_index:
                for movie_idx in _word_index[word]:
                    scores[movie_idx] += 1.0
        
        # Normalize keyword scores
        if scores.max() > 0:
            scores = scores / scores.max() * 0.4  # 40% weight
        
        # 2. USER HISTORY (simple boost)
        if user_history:
            history_indices = _movies_df[_movies_df["title"].isin(user_history)].index
            for idx in history_indices:
                # Boost this movie and similar genre
                scores[idx] += 0.2
                same_genre = _movies_df[_movies_df['genre'] == _movies_df.iloc[idx]['genre']].index
                scores[same_genre] += 0.1
        
        # 3. ML PREDICTION (tiny model - fast!)
        if _ml_model is not None and _encoders is not None:
            try:
                # Encode mood
                if mood in _encoders['mood'].classes_:
                    mood_enc = _encoders['mood'].transform([mood])[0]
                else:
                    mood_enc = _encoders['mood'].transform(["neutral"])[0]
                
                context_enc = _encoders['context'].transform(["alone"])[0]
                time_enc = _encoders['time'].transform(["evening"])[0]
                
                # ML prediction
                ml_pred = _ml_model.predict([[mood_enc, context_enc, time_enc]])[0]
                predicted_movie_id = _encoders['movie'].inverse_transform([ml_pred])[0]
                
                # Boost predicted movie and same genre
                predicted_idx = _movies_df[_movies_df['movie_id'] == predicted_movie_id].index
                if len(predicted_idx) > 0:
                    scores[predicted_idx[0]] += 0.5  # Big ML boost
                    # Boost same genre
                    pred_genre = _movies_df.iloc[predicted_idx[0]]['genre']
                    same_genre = _movies_df[_movies_df['genre'] == pred_genre].index
                    scores[same_genre] += 0.2
                
            except Exception as ml_error:
                print(f"⚠️  ML prediction failed: {ml_error}")
        
        # Get top N
        top_indices = np.argsort(scores)[::-1][:top_n]
        results = _movies_df.iloc[top_indices].copy()
        results['hybrid_score'] = scores[top_indices]
        
        return {
            "user_id": user_id,
            "extracted_mood": mood_info,
            "user_profile": user_profile,
            "recommendations": results[
                ["title", "genre", "release_year", "rating", "tags", "hybrid_score"]
            ].to_dict(orient="records")
        }
    
    except Exception as e:
        print(f"❌ Error in recommendations: {e}")
        import traceback
        traceback.print_exc()
        
        # Fallback: top-rated movies
        _lazy_init()
        fallback = _movies_df.nlargest(top_n, 'rating')
        return {
            "user_id": user_id,
            "extracted_mood": {"mood": "neutral", "tone": "neutral"},
            "user_profile": [],
            "recommendations": fallback[
                ["title", "genre", "release_year", "rating", "tags"]
            ].assign(hybrid_score=0.5).to_dict(orient="records")
        }

# NO initialization at import time!
# Everything happens on first request
print("🚀 ML-optimized recommender ready (lazy loading, 5-tree model)")

