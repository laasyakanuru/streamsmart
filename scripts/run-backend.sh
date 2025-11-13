#!/bin/bash

# StreamSmart Backend Run Script
echo "🚀 Starting StreamSmart Backend..."

# Check if .env exists
if [ ! -f "streamsmart-backend/.env" ]; then
    echo "⚠️  .env file not found. Please run ./scripts/setup.sh first"
    exit 1
fi

# Activate virtual environment
if [ -d ".venv" ]; then
    source .venv/bin/activate
else
    echo "❌ Virtual environment not found. Please run ./scripts/setup.sh first"
    exit 1
fi

# Navigate to backend
cd streamsmart-backend

# Check if dependencies are installed
if ! python -c "import fastapi" 2>/dev/null; then
    echo "❌ Dependencies not installed. Please run ./scripts/setup.sh first"
    exit 1
fi

echo "✅ Starting server on http://localhost:8000"
echo "📚 API docs available at http://localhost:8000/docs"
echo ""

# Run the server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

