#!/bin/bash

echo "📊 StreamSmart Status"
echo "====================="
echo ""

# Check backend
if curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo "✅ Backend:  RUNNING on http://localhost:8000"
    
    # Get mood extraction mode
    MODE=$(curl -s http://localhost:8000/api/status 2>/dev/null | python3 -c "import sys, json; print(json.load(sys.stdin)['mood_extraction']['active_mode'])" 2>/dev/null)
    if [ "$MODE" = "azure_openai" ]; then
        echo "   AI Mode:  Azure OpenAI (GPT-powered)"
    elif [ "$MODE" = "openai" ]; then
        echo "   AI Mode:  OpenAI API"
    else
        echo "   AI Mode:  Rule-based (offline)"
    fi
else
    echo "❌ Backend:  NOT RUNNING"
fi

echo ""

# Check frontend
if curl -s http://localhost:5173 > /dev/null 2>&1; then
    echo "✅ Frontend: RUNNING on http://localhost:5173"
else
    echo "❌ Frontend: NOT RUNNING"
fi

echo ""
echo "💡 Commands:"
echo "   Start:   ./start.sh"
echo "   Stop:    ./stop.sh"
echo "   Restart: ./restart.sh"
echo "   Logs:    ./logs.sh"
echo ""

