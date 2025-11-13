#!/bin/bash

echo "🔍 Debugging Azure OpenAI - Real-Time"
echo "======================================"
echo ""
echo "This will:"
echo "  1. Make a test request to your backend"
echo "  2. Stream the logs in real-time"
echo "  3. Show you the ACTUAL Azure OpenAI error"
echo ""
echo "Starting in 3 seconds... (Press Ctrl+C to cancel)"
sleep 3
echo ""

# Start log streaming in background
az webapp log tail --name streamsmart-backend-7272 --resource-group hackathon-azure-rg193 &
LOG_PID=$!

# Wait a moment for logs to connect
sleep 3

# Make test request
echo ""
echo "🧪 Making test request..."
curl -X POST https://streamsmart-backend-7272.azurewebsites.net/api/chat \
  -H "Content-Type: application/json" \
  -d '{"user_id":"test","message":"i am super happy and want something fun","top_n":3}' \
  -s -o /dev/null

echo "✅ Request sent!"
echo ""
echo "📋 Watch the logs above ⬆️  for:"
echo "   • '🔧 Azure OpenAI Config:' (configuration)"
echo "   • '✅ Client created' (if client works)"
echo "   • '🎭 Azure OpenAI extracted mood' (if SUCCESS!)"
echo "   • '❌ Azure OpenAI FAILED!' (if error)"
echo ""
echo "Streaming logs... (Press Ctrl+C to stop)"
echo ""

# Wait for logs
wait $LOG_PID

