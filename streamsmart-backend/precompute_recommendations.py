#!/usr/bin/env python3
"""
Pre-compute recommendations for common queries
Run this locally to generate cached JSON files
"""

import json
import os
import sys

# Add parent directory to path
sys.path.insert(0, os.path.dirname(__file__))

from app.recommender import get_recommendations

# Common mood/genre combinations
COMMON_QUERIES = [
    # Happy moods
    {"message": "I want something funny and light", "description": "happy_comedy"},
    {"message": "I'm feeling happy and want something entertaining", "description": "happy_general"},
    
    # Sad moods
    {"message": "I'm sad and need something uplifting", "description": "sad_uplifting"},
    {"message": "I'm feeling sad and want a good drama", "description": "sad_drama"},
    
    # Energetic moods
    {"message": "I want exciting action movies", "description": "energetic_action"},
    {"message": "I'm feeling energetic and want something thrilling", "description": "energetic_thriller"},
    
    # Calm moods
    {"message": "I want something calm and relaxing", "description": "calm_relaxing"},
    {"message": "I'm feeling calm and want a nice romance", "description": "calm_romance"},
    
    # Neutral/general
    {"message": "I want action movies", "description": "action"},
    {"message": "I want comedy movies", "description": "comedy"},
    {"message": "I want drama movies", "description": "drama"},
    {"message": "I want thriller movies", "description": "thriller"},
    {"message": "I want romance movies", "description": "romance"},
    {"message": "I want horror movies", "description": "horror"},
    
    # Context-specific
    {"message": "Something good for a movie night with friends", "description": "friends_night"},
    {"message": "Something for a date night", "description": "date_night"},
    {"message": "Something I can watch alone", "description": "alone"},
    {"message": "Something for the weekend", "description": "weekend"},
    
    # Time-specific
    {"message": "Something for tonight", "description": "tonight"},
    {"message": "Late night movie", "description": "late_night"},
]

def main():
    print("🚀 Pre-computing recommendations...")
    print(f"Processing {len(COMMON_QUERIES)} common queries...\n")
    
    # Create output directory
    output_dir = os.path.join(os.path.dirname(__file__), "data", "precomputed")
    os.makedirs(output_dir, exist_ok=True)
    
    results = []
    
    for i, query in enumerate(COMMON_QUERIES, 1):
        print(f"[{i}/{len(COMMON_QUERIES)}] {query['description']}...")
        
        try:
            # Get recommendations
            result = get_recommendations(
                user_id="precompute",
                user_prompt=query["message"],
                top_n=5
            )
            
            # Add query info
            result["query"] = query["message"]
            result["query_key"] = query["description"]
            
            # Save individual file
            filename = f"{query['description']}.json"
            filepath = os.path.join(output_dir, filename)
            with open(filepath, 'w') as f:
                json.dump(result, f, indent=2)
            
            results.append({
                "key": query["description"],
                "message": query["message"],
                "mood": result["extracted_mood"]["mood"],
                "recommendations": len(result["recommendations"])
            })
            
            print(f"   ✅ Mood: {result['extracted_mood']['mood']}, Recs: {len(result['recommendations'])}")
        
        except Exception as e:
            print(f"   ❌ Error: {e}")
            continue
    
    # Save index file
    index_path = os.path.join(output_dir, "_index.json")
    with open(index_path, 'w') as f:
        json.dump(results, f, indent=2)
    
    print(f"\n✅ Pre-computed {len(results)} queries!")
    print(f"📁 Saved to: {output_dir}")
    print(f"\nFiles created:")
    for result in results:
        print(f"   - {result['key']}.json")

if __name__ == "__main__":
    main()

