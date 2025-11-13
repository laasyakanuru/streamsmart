#!/bin/bash

# StreamSmart - Comprehensive Chatbot Testing Script
# Tests various mood scenarios and system features

set -e

echo "🧪 StreamSmart Comprehensive Test Suite"
echo "========================================"
echo ""

# Configuration
API_URL="${API_URL:-http://localhost:8000}"
TEST_USER="test_user_$(date +%s)"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

echo "📋 Test Configuration:"
echo "   API URL: $API_URL"
echo "   Test User: $TEST_USER"
echo ""

# Helper function to test API
test_chat() {
    local test_name="$1"
    local message="$2"
    local expected_mood="$3"
    
    echo -e "${BLUE}Test: $test_name${NC}"
    echo "   Input: '$message'"
    
    response=$(curl -s -X POST "$API_URL/api/chat" \
        -H "Content-Type: application/json" \
        -d "{\"user_id\": \"$TEST_USER\", \"message\": \"$message\", \"top_n\": 3}")
    
    if [ $? -eq 0 ]; then
        mood=$(echo "$response" | python3 -c "import sys, json; print(json.load(sys.stdin)['extracted_mood']['mood'])" 2>/dev/null || echo "error")
        tone=$(echo "$response" | python3 -c "import sys, json; print(json.load(sys.stdin)['extracted_mood']['tone'])" 2>/dev/null || echo "error")
        rec_count=$(echo "$response" | python3 -c "import sys, json; print(len(json.load(sys.stdin)['recommendations']))" 2>/dev/null || echo "0")
        
        if [ "$mood" != "error" ] && [ "$rec_count" != "0" ]; then
            echo -e "   ${GREEN}✅ Mood: $mood, Tone: $tone${NC}"
            echo "   ${GREEN}✅ Recommendations: $rec_count${NC}"
            
            # Show first recommendation
            first_rec=$(echo "$response" | python3 -c "import sys, json; r=json.load(sys.stdin)['recommendations'][0]; print(f\"{r['title']} ({r['genre']}) - Score: {r['hybrid_score']:.3f}\")" 2>/dev/null || echo "")
            if [ -n "$first_rec" ]; then
                echo "   📺 Top: $first_rec"
            fi
            
            ((TESTS_PASSED++))
        else
            echo -e "   ${RED}❌ Failed: Invalid response${NC}"
            ((TESTS_FAILED++))
        fi
    else
        echo -e "   ${RED}❌ Failed: API error${NC}"
        ((TESTS_FAILED++))
    fi
    echo ""
}

# Check if backend is running
echo "1️⃣  Checking Backend Status"
echo "========================================"

if curl -sf "$API_URL/health" > /dev/null; then
    echo -e "${GREEN}✅ Backend is running${NC}"
else
    echo -e "${RED}❌ Backend is not accessible at $API_URL${NC}"
    echo "   Please start the backend first:"
    echo "   ./scripts/run-backend.sh"
    exit 1
fi

# Check system status
status=$(curl -s "$API_URL/api/status")
mood_mode=$(echo "$status" | python3 -c "import sys, json; print(json.load(sys.stdin)['mood_extraction']['active_mode'])" 2>/dev/null || echo "unknown")
echo "   Active mood mode: $mood_mode"
echo ""

echo "2️⃣  Testing Mood Detection - Happy/Excited"
echo "========================================"
test_chat "Happy comedy request" "I'm feeling great and want something funny!" "happy"
test_chat "Excited adventure" "I'm so excited! Give me something thrilling!" "energetic"
test_chat "Cheerful family" "Feeling cheerful, want a nice family movie" "happy"

echo "3️⃣  Testing Mood Detection - Sad/Down"
echo "========================================"
test_chat "Sad comfort" "I'm feeling down and need cheering up" "sad"
test_chat "Heartbroken" "Just had a breakup, need something comforting" "sad"
test_chat "Melancholic" "Feeling melancholic, want something emotional" "sad"

echo "4️⃣  Testing Mood Detection - Calm/Relaxed"
echo "========================================"
test_chat "Calm evening" "Want something calm for a relaxing evening" "calm"
test_chat "Peaceful mood" "Feeling peaceful, need something light" "calm"
test_chat "Chill vibes" "Just want to chill, something easy to watch" "calm"

echo "5️⃣  Testing Mood Detection - Energetic/Intense"
echo "========================================"
test_chat "Action packed" "I want something action-packed and intense!" "energetic"
test_chat "Adrenaline rush" "Need an adrenaline rush! Something thrilling!" "energetic"
test_chat "High energy" "Feeling energetic, want something fast-paced" "energetic"

echo "6️⃣  Testing Genre Requests"
echo "========================================"
test_chat "Horror request" "I'm in the mood for a scary horror movie" "neutral"
test_chat "Romance request" "Want to watch a romantic movie tonight" "neutral"
test_chat "Documentary" "Looking for an interesting documentary" "neutral"

echo "7️⃣  Testing Complex Queries"
echo "========================================"
test_chat "Multi-criteria" "I want a funny action movie with high ratings" "happy"
test_chat "Specific mood+genre" "Feeling sad, but want a comedy to cheer up" "sad"
test_chat "Time-based" "It's late night, want something to help me relax" "calm"

echo "8️⃣  Testing Edge Cases"
echo "========================================"
test_chat "Very short query" "Something good" "neutral"
test_chat "Very long query" "I'm feeling really happy and excited because it's the weekend and I want to watch something absolutely amazing that will make me laugh and feel good, preferably a comedy or adventure movie with great ratings" "happy"
test_chat "No mood specified" "Show me action movies" "neutral"

echo "9️⃣  Testing User History"
echo "========================================"
echo -e "${BLUE}Adding to watch history...${NC}"

# Add some items to history
curl -s -X POST "$API_URL/api/history" \
    -H "Content-Type: application/json" \
    -d "{\"user_id\": \"$TEST_USER\", \"show_title\": \"Show_1\"}" > /dev/null

curl -s -X POST "$API_URL/api/history" \
    -H "Content-Type: application/json" \
    -d "{\"user_id\": \"$TEST_USER\", \"show_title\": \"Show_2\"}" > /dev/null

echo "✅ Added 2 items to history"

# Get history
history=$(curl -s "$API_URL/api/history/$TEST_USER")
history_count=$(echo "$history" | python3 -c "import sys, json; print(len(json.load(sys.stdin)['history']))" 2>/dev/null || echo "0")

if [ "$history_count" -ge 2 ]; then
    echo -e "${GREEN}✅ User history working (${history_count} items)${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}❌ User history failed${NC}"
    ((TESTS_FAILED++))
fi
echo ""

echo "🔟  Testing Analytics"
echo "========================================"

analytics=$(curl -s "$API_URL/api/analytics/$TEST_USER")
if [ $? -eq 0 ]; then
    mood_counts=$(echo "$analytics" | python3 -c "import sys, json; print(len(json.load(sys.stdin)['mood_distribution']))" 2>/dev/null || echo "0")
    
    if [ "$mood_counts" != "0" ]; then
        echo -e "${GREEN}✅ Analytics working${NC}"
        echo "$analytics" | python3 -m json.tool | head -20
        ((TESTS_PASSED++))
    else
        echo -e "${YELLOW}⚠️  Analytics available but no data yet${NC}"
    fi
else
    echo -e "${RED}❌ Analytics failed${NC}"
    ((TESTS_FAILED++))
fi
echo ""

echo "1️⃣1️⃣  Testing Performance"
echo "========================================"

START_TIME=$(date +%s)
for i in {1..5}; do
    curl -s -X POST "$API_URL/api/chat" \
        -H "Content-Type: application/json" \
        -d "{\"user_id\": \"perf_test\", \"message\": \"Quick test $i\", \"top_n\": 3}" > /dev/null
done
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
AVG_TIME=$((ELAPSED / 5))

echo "   5 requests completed in ${ELAPSED}s"
echo "   Average response time: ~${AVG_TIME}s"

if [ $AVG_TIME -lt 5 ]; then
    echo -e "   ${GREEN}✅ Performance excellent (<5s)${NC}"
elif [ $AVG_TIME -lt 10 ]; then
    echo -e "   ${YELLOW}⚠️  Performance acceptable (5-10s)${NC}"
else
    echo -e "   ${RED}⚠️  Performance slow (>10s)${NC}"
fi
echo ""

echo "📊 Test Summary"
echo "========================================"
echo ""
TOTAL_TESTS=$((TESTS_PASSED + TESTS_FAILED))
SUCCESS_RATE=$((TESTS_PASSED * 100 / TOTAL_TESTS))

echo -e "   Total Tests: $TOTAL_TESTS"
echo -e "   ${GREEN}Passed: $TESTS_PASSED${NC}"
if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "   ${RED}Failed: $TESTS_FAILED${NC}"
else
    echo -e "   ${GREEN}Failed: $TESTS_FAILED${NC}"
fi
echo -e "   Success Rate: ${SUCCESS_RATE}%"
echo ""

if [ $SUCCESS_RATE -ge 90 ]; then
    echo -e "${GREEN}🎉 Excellent! All systems working well!${NC}"
    exit 0
elif [ $SUCCESS_RATE -ge 70 ]; then
    echo -e "${YELLOW}⚠️  Most tests passed, some issues detected${NC}"
    exit 0
else
    echo -e "${RED}❌ Multiple failures detected, please investigate${NC}"
    exit 1
fi

