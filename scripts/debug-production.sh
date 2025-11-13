#!/bin/bash

# StreamSmart Production Debugging Script

echo "🔍 StreamSmart Production Debugging"
echo "===================================="
echo ""

# Get URLs from deployment file
if [ -f "deployment-urls.txt" ]; then
    BACKEND_URL=$(grep "Backend:" deployment-urls.txt | awk '{print $2}')
    FRONTEND_URL=$(grep "Frontend:" deployment-urls.txt | awk '{print $2}')
    BACKEND_APP=$(grep "Backend App:" deployment-urls.txt | awk '{print $3}')
    FRONTEND_APP=$(grep "Frontend App:" deployment-urls.txt | awk '{print $3}')
    RESOURCE_GROUP=$(grep "Resource Group:" deployment-urls.txt | awk '{print $3}')
else
    echo "❌ deployment-urls.txt not found"
    echo "Please provide URLs manually"
    exit 1
fi

echo "📋 Deployment Info:"
echo "   Backend:  $BACKEND_URL"
echo "   Frontend: $FRONTEND_URL"
echo ""

# Test 1: Backend Health
echo "Test 1: Backend Health Check"
echo "=============================="
HEALTH_RESPONSE=$(curl -s -w "\n%{http_code}" "$BACKEND_URL/health" 2>&1)
HTTP_CODE=$(echo "$HEALTH_RESPONSE" | tail -n1)
HEALTH_BODY=$(echo "$HEALTH_RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Backend is responding"
    echo "   Response: $HEALTH_BODY"
else
    echo "❌ Backend health check failed (HTTP $HTTP_CODE)"
    echo "   Backend might still be starting..."
fi
echo ""

# Test 2: API Status
echo "Test 2: API Status Check"
echo "========================"
STATUS_RESPONSE=$(curl -s "$BACKEND_URL/api/status" 2>&1)
if echo "$STATUS_RESPONSE" | grep -q "mood_extraction"; then
    echo "✅ API is responding"
    MODE=$(echo "$STATUS_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['mood_extraction']['active_mode'])" 2>/dev/null || echo "unknown")
    echo "   Mood extraction mode: $MODE"
    
    if [ "$MODE" = "rule_based" ]; then
        echo "   ⚠️  Using rule-based (Azure OpenAI credentials not detected)"
    elif [ "$MODE" = "azure_openai" ]; then
        echo "   ✅ Using Azure OpenAI (AI-powered)"
    fi
else
    echo "❌ API status check failed"
    echo "   Response: $STATUS_RESPONSE"
fi
echo ""

# Test 3: Test Recommendation
echo "Test 3: Test Chat Endpoint"
echo "==========================="
CHAT_RESPONSE=$(curl -s -X POST "$BACKEND_URL/api/chat" \
    -H "Content-Type: application/json" \
    -d '{"user_id":"test","message":"I want something funny","top_n":3}' 2>&1)

if echo "$CHAT_RESPONSE" | grep -q "recommendations"; then
    echo "✅ Chat endpoint working"
    REC_COUNT=$(echo "$CHAT_RESPONSE" | python3 -c "import sys, json; print(len(json.load(sys.stdin)['recommendations']))" 2>/dev/null || echo "0")
    echo "   Returned $REC_COUNT recommendations"
else
    echo "❌ Chat endpoint failed"
    echo "   Response: $CHAT_RESPONSE"
fi
echo ""

# Test 4: Check Environment Variables
echo "Test 4: Backend Environment Variables"
echo "======================================"
echo "Checking backend configuration..."
az webapp config appsettings list \
    --name $BACKEND_APP \
    --resource-group $RESOURCE_GROUP \
    --query "[?name=='AZURE_OPENAI_ENDPOINT' || name=='FRONTEND_URL' || name=='WEBSITES_PORT'].{Name:name, Value:value}" \
    -o table 2>/dev/null || echo "⚠️  Could not fetch settings"
echo ""

# Test 5: Check Frontend Configuration
echo "Test 5: Frontend Configuration"
echo "==============================="
echo "Checking frontend configuration..."
az webapp config appsettings list \
    --name $FRONTEND_APP \
    --resource-group $RESOURCE_GROUP \
    --query "[?name=='VITE_API_URL' || name=='WEBSITES_PORT'].{Name:name, Value:value}" \
    -o table 2>/dev/null || echo "⚠️  Could not fetch settings"
echo ""

# Test 6: Check Recent Logs
echo "Test 6: Recent Backend Logs"
echo "==========================="
echo "Fetching last 20 lines of backend logs..."
az webapp log tail --name $BACKEND_APP --resource-group $RESOURCE_GROUP --lines 20 2>&1 | head -20 || echo "⚠️  Could not fetch logs"
echo ""

# Test 7: CORS Check
echo "Test 7: CORS Configuration"
echo "=========================="
CORS_TEST=$(curl -s -X OPTIONS "$BACKEND_URL/api/chat" \
    -H "Origin: $FRONTEND_URL" \
    -H "Access-Control-Request-Method: POST" \
    -w "\n%{http_code}" 2>&1)
CORS_CODE=$(echo "$CORS_TEST" | tail -n1)

if [ "$CORS_CODE" = "200" ]; then
    echo "✅ CORS is configured correctly"
else
    echo "⚠️  CORS might have issues (HTTP $CORS_CODE)"
fi
echo ""

# Summary
echo "📊 Diagnosis Summary"
echo "===================="
echo ""
echo "Common Issues & Solutions:"
echo ""
echo "1. 'Backend not responding'"
echo "   → Wait 2-3 minutes after deployment"
echo "   → Restart: az webapp restart --name $BACKEND_APP --resource-group $RESOURCE_GROUP"
echo ""
echo "2. 'Azure OpenAI not detected'"
echo "   → Set environment variables:"
echo "     az webapp config appsettings set \\"
echo "       --name $BACKEND_APP \\"
echo "       --resource-group $RESOURCE_GROUP \\"
echo "       --settings \\"
echo "         AZURE_OPENAI_ENDPOINT='YOUR_ENDPOINT' \\"
echo "         AZURE_OPENAI_KEY='YOUR_KEY' \\"
echo "         AZURE_OPENAI_DEPLOYMENT='gpt-4o-mini'"
echo ""
echo "3. 'CORS errors'"
echo "   → Update CORS:"
echo "     az webapp config appsettings set \\"
echo "       --name $BACKEND_APP \\"
echo "       --resource-group $RESOURCE_GROUP \\"
echo "       --settings FRONTEND_URL='$FRONTEND_URL'"
echo ""
echo "4. 'Frontend can't reach backend'"
echo "   → Check frontend API URL:"
echo "     az webapp config appsettings set \\"
echo "       --name $FRONTEND_APP \\"
echo "       --resource-group $RESOURCE_GROUP \\"
echo "       --settings VITE_API_URL='$BACKEND_URL'"
echo ""
echo "📚 View full logs:"
echo "   az webapp log tail --name $BACKEND_APP --resource-group $RESOURCE_GROUP"
echo ""
echo "🔄 Restart apps:"
echo "   az webapp restart --name $BACKEND_APP --resource-group $RESOURCE_GROUP"
echo "   az webapp restart --name $FRONTEND_APP --resource-group $RESOURCE_GROUP"
echo ""

