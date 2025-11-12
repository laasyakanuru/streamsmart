import os
from textblob import TextBlob

USE_GPT = False  # change this to False if GPT API not allowed

def extract_mood_with_gpt(prompt: str):
    # Lazy import pattern — don't initialize client unless needed
    from openai import OpenAI
    client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
    """
    Uses GPT model to extract user mood and tone from the input prompt.
    Returns a dictionary: {"mood": "happy", "intent": "light-hearted"}
    """
    try:
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": "You are an assistant that identifies mood and tone from user prompts for a movie recommendation system."},
                {"role": "user", "content": f"Extract the user's mood (like happy, sad, relaxed, energetic, etc.) and preferred tone (light-hearted, serious, intense) from this text: '{prompt}'. Respond only in JSON with keys 'mood' and 'tone'."}
            ],
        )
        content = response.choices[0].message.content
        import json
        result = json.loads(content)
        return result
    except Exception as e:
        print("⚠️ GPT failed, switching to fallback rule-based mood extraction.")
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
    if USE_GPT:
        return extract_mood_with_gpt(prompt)
    else:
        return extract_mood_rule_based(prompt)
