#!/bin/bash

echo "🛑 Stopping StreamSmart..."

# Stop backend
pkill -f "uvicorn" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✅ Backend stopped"
else
    echo "ℹ️  Backend was not running"
fi

# Stop frontend
pkill -f "vite" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✅ Frontend stopped"
else
    echo "ℹ️  Frontend was not running"
fi

echo ""
echo "✅ All services stopped"

