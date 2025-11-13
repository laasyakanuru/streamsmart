#!/bin/bash

# Test Azure OpenAI mood extraction in production

echo "🧪 Testing Production Azure OpenAI"
echo "==================================="
echo ""

BACKEND_URL="https://streamsmart-backend-7272.azurewebsites.net"

# Test 1: Check status
echo "Test 1: Checking API status..."
STATUS=$(curl -s "$BACKEND_URL/api/status")
MODE=$(echo "$STATUS" | python3 -c "import sys, json; print(json.load(sys.stdin)['mood_extraction']['active_mode'])" 2>/dev/null || echo "error")

if [ "$MODE" = "azure_openai" ]; then
    echo "✅ Mode: $MODE (Azure OpenAI is configured)"
elif [ "$MODE" = "rule_based" ]; then
    echo "⚠️  Mode: $MODE (Falling back to rule-based)"
    echo "   Azure OpenAI credentials might not be set correctly"
else
    echo "❌ Cannot determine mode"
    exit 1
fi
echo ""

# Test 2: Test mood extraction
echo "Test 2: Testing mood extraction..."
echo "Input: 'i am super happy and i want to watch something light-hearted'"
echo ""

RESPONSE=$(curl -s -X POST "$BACKEND_URL/api/chat" \
  -H "Content-Type: application/json" \
  -d '{"user_id":"test","message":"i am super happy and i want to watch something light-hearted","top_n":3}')

MOOD=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['extracted_mood']['mood'])" 2>/dev/null || echo "error")
TONE=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['extracted_mood']['tone'])" 2>/dev/null || echo "error")

echo "Result:"
echo "  Mood: $MOOD"
echo "  Tone: $TONE"
echo ""

if [ "$MOOD" = "happy" ] || [ "$MOOD" = "excited" ] || [ "$MOOD" = "joyful" ]; then
    echo "✅ SUCCESS! Azure OpenAI correctly detected happy mood!"
    echo ""
    echo "Your production app is now using AI-powered mood extraction!"
elif [ "$MOOD" = "neutral" ]; then
    echo "⚠️  Still showing neutral (rule-based behavior)"
    echo ""
    echo "This means either:"
    echo "  1. Backend is still starting up (wait 1-2 more minutes)"
    echo "  2. Azure OpenAI calls are failing silently"
    echo ""
    echo "To debug:"
    echo "  az webapp log tail --name streamsmart-backend-7272 --resource-group hackathon-azure-rg193"
else
    echo "ℹ️  Got mood: $MOOD"
fi

echo ""
echo "🌐 Test in browser:"
echo "   https://streamsmart-frontend-7272.azurewebsites.net"
echo ""

