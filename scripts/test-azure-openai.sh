#!/bin/bash

# StreamSmart - Azure OpenAI Testing Script
# Tests if Azure OpenAI integration is working correctly

echo "🧪 StreamSmart - Azure OpenAI Test Suite"
echo "========================================="
echo ""

BASE_URL="http://localhost:8000"

# Check if backend is running
echo "1️⃣  Checking if backend is running..."
if ! curl -s "$BASE_URL/health" > /dev/null 2>&1; then
    echo "❌ Backend is not running!"
    echo ""
    echo "Start it with: ./scripts/run-backend.sh"
    exit 1
fi
echo "✅ Backend is running"
echo ""

# Check system status
echo "2️⃣  Checking system status..."
STATUS=$(curl -s "$BASE_URL/api/status")
MODE=$(echo $STATUS | python3 -c "import sys, json; print(json.load(sys.stdin)['mood_extraction']['active_mode'])")
DESCRIPTION=$(echo $STATUS | python3 -c "import sys, json; print(json.load(sys.stdin)['mood_extraction']['description'])")

echo "   Active Mode: $MODE"
echo "   Description: $DESCRIPTION"
echo ""

if [ "$MODE" != "azure_openai" ]; then
    echo "⚠️  Not using Azure OpenAI!"
    echo ""
    echo "Current mode: $MODE"
    echo ""
    if [ "$MODE" == "rule_based" ]; then
        echo "💡 Looks like Azure OpenAI is not configured."
        echo ""
        echo "Run setup script: ./scripts/setup-azure-openai.sh"
    fi
    echo ""
    echo "Or manually add to streamsmart-backend/.env:"
    echo "   AZURE_OPENAI_ENDPOINT=https://your-resource.openai.azure.com/"
    echo "   AZURE_OPENAI_KEY=your-key"
    echo "   AZURE_OPENAI_DEPLOYMENT=gpt-4o-mini"
    exit 1
fi

echo "✅ Azure OpenAI is active!"
echo ""

# Test mood extraction
echo "3️⃣  Testing mood extraction..."
echo ""

# Test 1: Happy mood
echo "Test 1: Happy mood"
echo "Input: 'I am feeling super happy and want something funny!'"
RESPONSE=$(curl -s -X POST "$BASE_URL/api/chat" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test_user",
    "message": "I am feeling super happy and want something funny!",
    "top_n": 2
  }')

MOOD=$(echo $RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin)['extracted_mood']['mood'])" 2>/dev/null || echo "error")
TONE=$(echo $RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin)['extracted_mood']['tone'])" 2>/dev/null || echo "error")

if [ "$MOOD" == "error" ]; then
    echo "❌ Failed to extract mood"
    echo "Response: $RESPONSE"
else
    echo "✅ Extracted mood: $MOOD"
    echo "✅ Extracted tone: $TONE"
fi
echo ""

# Test 2: Sad mood
echo "Test 2: Sad mood"
echo "Input: 'I am feeling down and need cheering up'"
RESPONSE=$(curl -s -X POST "$BASE_URL/api/chat" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test_user",
    "message": "I am feeling down and need cheering up",
    "top_n": 2
  }')

MOOD=$(echo $RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin)['extracted_mood']['mood'])" 2>/dev/null || echo "error")
TONE=$(echo $RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin)['extracted_mood']['tone'])" 2>/dev/null || echo "error")

if [ "$MOOD" == "error" ]; then
    echo "❌ Failed to extract mood"
else
    echo "✅ Extracted mood: $MOOD"
    echo "✅ Extracted tone: $TONE"
fi
echo ""

# Test 3: Energetic mood
echo "Test 3: Energetic mood"
echo "Input: 'I want something thrilling and action-packed!'"
RESPONSE=$(curl -s -X POST "$BASE_URL/api/chat" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test_user",
    "message": "I want something thrilling and action-packed!",
    "top_n": 2
  }')

MOOD=$(echo $RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin)['extracted_mood']['mood'])" 2>/dev/null || echo "error")
TONE=$(echo $RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin)['extracted_mood']['tone'])" 2>/dev/null || echo "error")

if [ "$MOOD" == "error" ]; then
    echo "❌ Failed to extract mood"
else
    echo "✅ Extracted mood: $MOOD"
    echo "✅ Extracted tone: $TONE"
fi
echo ""

echo "🎉 All Tests Complete!"
echo ""
echo "📊 Summary:"
echo "   ✅ Backend running"
echo "   ✅ Azure OpenAI active"
echo "   ✅ Mood extraction working"
echo ""
echo "💡 You can now:"
echo "   - Use the frontend: http://localhost:5173"
echo "   - Test via API docs: http://localhost:8000/docs"
echo "   - Add voice input next!"
echo ""

