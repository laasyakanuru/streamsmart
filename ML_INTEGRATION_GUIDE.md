# 🤖 Random Forest ML Integration Guide

## 📊 What Changed

### **Old System:**
```
Semantic Similarity Only
↓
synthetic_ott_data_with_users.csv
↓
Recommendations based on embeddings
```

### **New System:**
```
Hybrid: Semantic Similarity + Random Forest ML
↓
movies_metadata.csv + mood_recommendations.csv + users.csv
↓
ML-powered recommendations with context awareness
```

---

## 🧠 New ML Model Explained

### **Random Forest Classifier**

**Training Data:** `mood_recommendations.csv`
```csv
user_id,mood,context,time_of_day,recommended_movie_id
1,adventurous,alone,late night,120
2,adventurous,with friends,late night,63
```

**How it works:**
1. **Features (Input):**
   - `mood`: happy, sad, adventurous, etc.
   - `context`: alone, with friends, with family
   - `time_of_day`: morning, afternoon, evening, late night

2. **Target (Output):**
   - `recommended_movie_id`: Which movie to recommend

3. **Prediction:**
   ```python
   # User says "I'm happy"
   mood = "happy" → encode to number
   context = "alone" → encode to number  
   time = "evening" → encode to number
   
   # ML Model predicts
   predicted_movie_id = rf_model.predict([[mood_enc, context_enc, time_enc]])
   # Returns: movie_id = 42
   
   # Boost that movie's score
   if movie.id == 42:
       ml_score = 1.0
   else:
       ml_score = 0.0
   ```

4. **Hybrid Scoring:**
   ```python
   final_score = (
       0.5 * semantic_similarity    # How well prompt matches movie
       + 0.5 * history_similarity   # How similar to user's history
       + 0.5 * ml_score             # ML boost for predicted movie
   )
   ```

---

## 🔄 Schema Changes

### **Old CSV (synthetic_ott_data_with_users.csv):**
```csv
title,genre,mood_tag,tone,description,rating
Show_1,Comedy,happy,light,"A fun comedy...",8.5
```

### **New CSV (movies_metadata.csv):**
```csv
movie_id,title,genre,release_year,duration,rating,tags
1,Movie 1,Thriller,1995,163,5.5,epic
```

### **Field Mapping:**

| Old Field | New Field | Status |
|-----------|-----------|--------|
| `title` | `title` | ✅ Same |
| `genre` | `genre` | ✅ Same |
| `rating` | `rating` | ✅ Same |
| `mood_tag` | ❌ **REMOVED** | Use `extract_mood()` instead |
| `tone` | ❌ **REMOVED** | Use `extract_mood()` instead |
| `description` | `tags` | ⚠️ **CHANGED** (short tags vs long text) |
| - | `movie_id` | ✨ **NEW** (unique ID) |
| - | `release_year` | ✨ **NEW** |
| - | `duration` | ✨ **NEW** (minutes) |

---

## 📝 Required Changes

### **1. Install New Dependencies**

Your new code needs `scikit-learn` and `joblib`:

```bash
cd /Users/gjvs/Documents/streamsmart/streamsmart-backend
uv pip install scikit-learn joblib
```

**Update `pyproject.toml`:**
```toml
dependencies = [
    # ... existing dependencies ...
    "scikit-learn>=1.3.0",
    "joblib>=1.3.0",
]
```

---

### **2. Update Frontend (App.jsx)**

**File:** `streamsmart-frontend/src/App.jsx`

**Lines 125-129 need changes:**

**OLD:**
```jsx
<p className="description">{rec.description}</p>
<div className="rec-tags">
  <span className="tag">{rec.mood_tag}</span>
  <span className="tag">{rec.tone}</span>
</div>
```

**NEW:**
```jsx
<p className="description">{rec.tags || "No tags available"}</p>
<div className="rec-meta-extra">
  <span className="tag">📅 {rec.release_year}</span>
  <span className="tag">🎬 {rec.genre}</span>
</div>
```

**Explanation:**
- `rec.description` → `rec.tags` (your new CSV uses `tags` field)
- `rec.mood_tag` and `rec.tone` don't exist in new CSV
- Display `release_year` instead

---

### **3. Update Chatbot Router (Optional Enhancement)**

**File:** `streamsmart-backend/app/routers/chatbot.py`

Currently working, but could enhance with user_profile:

**Add after line 30:**
```python
# Extract user profile if available
user_profile = result.get("user_profile", [])
if user_profile:
    user_info = user_profile[0]
    message += f"\n\nBased on your profile (age: {user_info.get('age')}, prefers: {user_info.get('preferred_genres')}), we've personalized these for you!"
```

---

### **4. Handle Missing Fields Gracefully**

**Issue:** Old CSV had `mood_tag` and `tone` columns. New CSV doesn't.

**The old commented code does this:**
```python
temp_df = df[
    (df["mood_tag"].str.lower() == mood) |   # ❌ Column doesn't exist!
    (df["tone"].str.lower() == tone)
]
```

**Your new code doesn't filter by these** (good!), but if you want mood-based filtering:

**Add to new `get_recommendations()` after line 142:**
```python
# Optional: Filter by genre matching mood
mood_to_genre = {
    "happy": ["Comedy", "Romance", "Family"],
    "sad": ["Drama", "Documentary"],
    "energetic": ["Action", "Thriller", "Adventure"],
    "relaxed": ["Documentary", "Drama", "Romance"]
}

if mood in mood_to_genre:
    preferred_genres = mood_to_genre[mood]
    temp_df = temp_df[temp_df["genre"].isin(preferred_genres)]
    if temp_df.empty:
        temp_df = movies_df.copy()  # Fallback
```

---

### **5. Fix Model Persistence Issue**

**Current Problem:** Your code trains the model **every time the app starts!**

**Lines 100-118:** This runs on every startup (slow!)

**Solution:** Train once, save model, load if exists:

**Replace lines 100-118 with:**
```python
# -----------------------------
# Load or Train RandomForest model
# -----------------------------
model_path = os.path.join(base_dir, "data", "rf_recommender.pkl")

if os.path.exists(model_path):
    # Load existing model
    print("✅ Loading existing Random Forest model...")
    rf_model = joblib.load(model_path)
    # Load encoders
    le_mood = joblib.load(os.path.join(base_dir, "data", "le_mood.pkl"))
    le_context = joblib.load(os.path.join(base_dir, "data", "le_context.pkl"))
    le_time = joblib.load(os.path.join(base_dir, "data", "le_time.pkl"))
    le_movie = joblib.load(os.path.join(base_dir, "data", "le_movie.pkl"))
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
    
    rf_model = RandomForestClassifier(n_estimators=100, random_state=42)
    rf_model.fit(X_train, y_train)
    
    # Save model and encoders
    joblib.dump(rf_model, model_path)
    joblib.dump(le_mood, os.path.join(base_dir, "data", "le_mood.pkl"))
    joblib.dump(le_context, os.path.join(base_dir, "data", "le_context.pkl"))
    joblib.dump(le_time, os.path.join(base_dir, "data", "le_time.pkl"))
    joblib.dump(le_movie, os.path.join(base_dir, "data", "le_movie.pkl"))
    
    accuracy = rf_model.score(X_test, y_test)
    print(f"✅ Model trained! Accuracy: {accuracy:.2%}")
```

**Why:** This only trains once, then loads the saved model on subsequent startups (much faster!)

---

### **6. Add Model Retraining Endpoint (Optional)**

**File:** `streamsmart-backend/app/routers/chatbot.py`

**Add new endpoint:**
```python
@router.post("/retrain-model")
def retrain_model():
    """
    Retrain the Random Forest model with latest data
    """
    try:
        from app.recommender import recommender
        # Call a retrain function (you'll need to create this)
        result = recommender.retrain_ml_model()
        return {"status": "success", "message": "Model retrained successfully", "accuracy": result["accuracy"]}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
```

---

## 🧪 Testing the New System

### **1. Test Locally**

```bash
cd /Users/gjvs/Documents/streamsmart
./start.sh
```

**Open:** http://localhost:5173

**Try:**
- "I'm feeling adventurous and want to watch something exciting"
- "I'm sad and need something uplifting"
- "Show me relaxing documentaries"

### **2. Check ML Prediction**

**Add debug logging to see ML in action:**

In `recommender.py`, after line 162:
```python
print(f"🤖 ML Prediction: Movie ID {predicted_movie_id} (mood={mood}, context=alone, time=evening)")
```

### **3. Compare Old vs New**

**Create test script:**
```bash
# Test old system (commented code)
curl -X POST http://localhost:8000/api/chat \
  -H "Content-Type: application/json" \
  -d '{"user_id":"test","message":"I am happy"}'

# Test new system (your ML code)
# Should see different recommendations!
```

---

## ⚠️ Breaking Changes Summary

| Component | Issue | Fix |
|-----------|-------|-----|
| **Frontend** | Expects `description`, `mood_tag`, `tone` | Replace with `tags`, `release_year` |
| **API Response** | New field `user_profile` | Update frontend to handle it (optional) |
| **CSV Data** | Different columns | Use new CSVs (already added) |
| **Dependencies** | Needs `scikit-learn`, `joblib` | Run `uv pip install` |
| **Startup Time** | Trains model every time | Add model caching (see #5) |
| **Data Filtering** | Old code filters by `mood_tag`/`tone` | New code doesn't filter (relies on ML) |

---

## 🚀 Deployment Checklist

Before deploying to production:

- [ ] Install new dependencies: `scikit-learn`, `joblib`
- [ ] Update `pyproject.toml` with new dependencies
- [ ] Update frontend `App.jsx` (lines 125-129)
- [ ] Add model caching to prevent retraining on each startup
- [ ] Test with various moods locally
- [ ] Verify ML predictions are working (add logging)
- [ ] Check that all 3 CSV files are in `data/` folder
- [ ] Run `./start.sh` and test end-to-end
- [ ] Deploy to Azure with `./scripts/deploy-now.sh`

---

## 📊 Performance Comparison

| Metric | Old System | New System (ML) |
|--------|------------|-----------------|
| **Algorithm** | Semantic similarity only | Hybrid (semantic + ML) |
| **Startup Time** | ~3 seconds | ~5-10 seconds (training) |
| **Recommendation Quality** | Good for text matching | Better for mood-based |
| **Data Required** | Show descriptions | User behavior patterns |
| **Personalization** | Basic (history only) | Advanced (ML + history) |
| **Scalability** | ✅ Fast | ⚠️ Slower (trains model) |

---

## 💡 Recommendations

### **Immediate (Before Testing):**
1. ✅ Install `scikit-learn` and `joblib`
2. ✅ Update frontend to use `tags` instead of `description`
3. ✅ Add model caching to prevent retraining

### **Short-term (Before Production):**
4. Add error handling for missing encoders
5. Test with edge cases (unknown moods, new users)
6. Add model performance metrics logging

### **Long-term (Future Enhancements):**
7. Use more features: `age`, `gender`, `preferred_genres` from `users.csv`
8. Implement model versioning
9. Add A/B testing (old vs new recommender)
10. Create admin dashboard to retrain model

---

## 🎉 Summary

Your teammate's ML approach is **more advanced** and **context-aware**! The Random Forest model learns from historical user preferences (mood → movie patterns) and makes intelligent predictions.

**Key Advantages:**
- 🧠 **Learns patterns** from user behavior
- 🎯 **Context-aware** (considers time of day, social context)
- 📊 **Hybrid scoring** combines multiple signals
- 👤 **User profiles** enable better personalization

**Next Steps:**
1. Make the 6 changes listed above
2. Test locally with `./start.sh`
3. Deploy to production

**Need help with any specific change? Let me know!** 🚀

