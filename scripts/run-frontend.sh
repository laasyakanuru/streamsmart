#!/bin/bash

# StreamSmart Frontend Run Script
echo "🎨 Starting StreamSmart Frontend..."

# Check if node_modules exists
if [ ! -d "streamsmart-frontend/node_modules" ]; then
    echo "⚠️  Dependencies not installed. Please run ./scripts/setup.sh first"
    exit 1
fi

# Navigate to frontend
cd streamsmart-frontend

echo "✅ Starting development server on http://localhost:5173"
echo ""

# Run the development server
npm run dev

