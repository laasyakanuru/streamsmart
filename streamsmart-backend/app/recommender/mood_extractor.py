import os
from textblob import TextBlob
import json

# Detect which AI service is available (priority order)
AZURE_OPENAI_ENDPOINT = os.getenv("AZURE_OPENAI_ENDPOINT")
AZURE_OPENAI_KEY = os.getenv("AZURE_OPENAI_KEY")
AZURE_OPENAI_DEPLOYMENT = os.getenv("AZURE_OPENAI_DEPLOYMENT", "gpt-4o-mini")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

# Determine which mode to use
if AZURE_OPENAI_ENDPOINT and AZURE_OPENAI_KEY:
    USE_MODE = "azure_openai"
    print("✅ Using Azure OpenAI for mood extraction")
elif OPENAI_API_KEY:
    USE_MODE = "openai"
    print("✅ Using OpenAI API for mood extraction")
else:
    USE_MODE = "rule_based"
    print("ℹ️  Using rule-based mood extraction (no API key configured)")

def get_active_mode():
    """Return which mood extraction mode is active"""
    return USE_MODE

def extract_mood_with_azure_openai(prompt: str):
    """
    Uses Azure OpenAI GPT model to extract mood and tone
    """
    try:
        from openai import AzureOpenAI
        
        print(f"🔧 Azure OpenAI Config:")
        print(f"   Endpoint: {AZURE_OPENAI_ENDPOINT}")
        print(f"   Deployment: {AZURE_OPENAI_DEPLOYMENT}")
        print(f"   Key: {'*' * 20}...{AZURE_OPENAI_KEY[-4:] if AZURE_OPENAI_KEY else 'None'}")
        
        client = AzureOpenAI(
            api_key=AZURE_OPENAI_KEY,
            api_version="2024-02-15-preview",
            azure_endpoint=AZURE_OPENAI_ENDPOINT
        )
        
        print(f"✅ Client created, making API call...")
        
        response = client.chat.completions.create(
            model=AZURE_OPENAI_DEPLOYMENT,
            messages=[
                {
                    "role": "system",
                    "content": "You are a JSON-only assistant. Extract mood and tone from text. ONLY return valid JSON, no markdown, no explanation."
                },
                {
                    "role": "user",
                    "content": f"Extract mood (happy/sad/calm/energetic/neutral) and tone (light/intense/neutral) from: '{prompt}'. Return ONLY this exact JSON format: {{\"mood\": \"value\", \"tone\": \"value\"}}"
                }
            ],
            temperature=0.3,
            max_tokens=50
        )
        
        content = response.choices[0].message.content
        print(f"📄 Raw response: {content}")
        
        # Strip markdown code blocks if present
        if "```json" in content:
            content = content.split("```json")[1].split("```")[0].strip()
        elif "```" in content:
            content = content.split("```")[1].split("```")[0].strip()
        
        # Parse JSON
        content = content.strip()
        result = json.loads(content)
        print(f"🎭 Azure OpenAI extracted mood: {result}")
        return result
        
    except Exception as e:
        import traceback
        print(f"❌ Azure OpenAI FAILED!")
        print(f"   Error Type: {type(e).__name__}")
        print(f"   Error Message: {str(e)}")
        print(f"   Traceback:")
        traceback.print_exc()
        print(f"⚠️  Falling back to rule-based extraction")
        return extract_mood_rule_based(prompt)

def extract_mood_with_openai(prompt: str):
    """
    Uses regular OpenAI API to extract mood and tone
    """
    try:
        from openai import OpenAI
        
        client = OpenAI(api_key=OPENAI_API_KEY)
        
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {
                    "role": "system",
                    "content": "You are an assistant that identifies mood and tone from user prompts for a movie recommendation system."
                },
                {
                    "role": "user",
                    "content": f"Extract the user's mood (like happy, sad, relaxed, energetic, etc.) and preferred tone (light-hearted, serious, intense) from this text: '{prompt}'. Respond only in JSON with keys 'mood' and 'tone'."
                }
            ],
            temperature=0.7,
            max_tokens=100
        )
        
        content = response.choices[0].message.content
        result = json.loads(content)
        print(f"🎭 OpenAI extracted mood: {result}")
        return result
        
    except Exception as e:
        print(f"⚠️  OpenAI API failed: {e}")
        print("   Falling back to rule-based extraction")
        return extract_mood_rule_based(prompt)


def extract_mood_rule_based(prompt: str):
    """
    Simple fallback rule-based mood extraction.
    """
    prompt = prompt.lower()
    if any(word in prompt for word in ["sad", "bad", "lonely"]):
        return {"mood": "happy", "tone": "light-hearted"}
    if any(word in prompt for word in ["tired", "lazy", "bored", "lethargic"]):
        return {"mood": "relaxed", "tone": "light-hearted"}
    if any(word in prompt for word in ["excited", "energetic", "thrill"]):
        return {"mood": "energetic", "tone": "intense"}
    if any(word in prompt for word in ["romantic", "love"]):
        return {"mood": "romantic", "tone": "light-hearted"}
    return {"mood": "neutral", "tone": "neutral"}


def extract_mood(prompt: str):
    """
    Extract mood from user prompt using the best available method.
    
    Priority:
    1. Azure OpenAI (if configured)
    2. Regular OpenAI API (if configured)
    3. Rule-based fallback (always works)
    """
    if USE_MODE == "azure_openai":
        return extract_mood_with_azure_openai(prompt)
    elif USE_MODE == "openai":
        return extract_mood_with_openai(prompt)
    else:
        # Rule-based - always works
        return extract_mood_rule_based(prompt)
