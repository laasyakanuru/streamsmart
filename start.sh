#!/bin/bash

echo "🚀 StreamSmart - Quick Start"
echo "============================"
echo ""

# Check if we're in the right directory
if [ ! -f "streamsmart-backend/app/main.py" ]; then
    echo "❌ Error: Run this script from the streamsmart directory"
    echo "   cd /Users/gjvs/Documents/streamsmart"
    echo "   ./start.sh"
    exit 1
fi

# Kill any existing servers
echo "🧹 Cleaning up old servers..."
pkill -f "uvicorn" 2>/dev/null
pkill -f "vite" 2>/dev/null
sleep 2

# Start backend in background
echo "🔧 Starting backend on http://localhost:8000..."
cd streamsmart-backend
nohup uvicorn app.main:app --host 0.0.0.0 --port 8000 > ../logs/backend.log 2>&1 &
BACKEND_PID=$!
cd ..

# Wait for backend to start
sleep 3

# Check if backend is running
if curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo "✅ Backend started successfully (PID: $BACKEND_PID)"
else
    echo "⏳ Backend is starting (takes ~5 seconds)..."
    sleep 5
fi

# Start frontend in background
echo "🎨 Starting frontend on http://localhost:5173..."
cd streamsmart-frontend
nohup npm run dev > ../logs/frontend.log 2>&1 &
FRONTEND_PID=$!
cd ..

# Wait for frontend to start
sleep 3

echo ""
echo "✅ Both services started!"
echo ""
echo "📊 Service Status:"
echo "   Backend:  http://localhost:8000"
echo "   Frontend: http://localhost:5173"
echo "   API Docs: http://localhost:8000/docs"
echo ""
echo "📋 Useful Commands:"
echo "   View logs:  ./logs.sh"
echo "   Stop all:   ./stop.sh"
echo "   Restart:    ./restart.sh"
echo ""
echo "🌐 Open in browser:"
echo "   open http://localhost:5173"
echo ""

# Try to open browser
if command -v open &> /dev/null; then
    sleep 2
    open http://localhost:5173
elif command -v xdg-open &> /dev/null; then
    sleep 2
    xdg-open http://localhost:5173
fi

