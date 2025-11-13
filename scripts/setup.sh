#!/bin/bash

# StreamSmart Setup Script
echo "🎬 StreamSmart Setup Script"
echo "============================"
echo ""

# Check if running from project root
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Please run this script from the project root directory"
    exit 1
fi

# Check prerequisites
echo "📋 Checking prerequisites..."

# Check Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed"
    exit 1
fi
echo "✅ Python 3 found"

# Check Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed"
    exit 1
fi
echo "✅ Node.js found"

# Check uv
if ! command -v uv &> /dev/null; then
    echo "⚠️  uv not found. Installing..."
    pip install uv
fi
echo "✅ uv found"

echo ""
echo "🔧 Setting up backend..."
cd streamsmart-backend

# Create .env if it doesn't exist
if [ ! -f ".env" ]; then
    echo "📝 Creating .env file..."
    cp .env.example .env
    echo "⚠️  Please edit streamsmart-backend/.env and add your OPENAI_API_KEY"
fi

# Activate virtual environment
if [ -d "../.venv" ]; then
    source ../.venv/bin/activate
    echo "✅ Virtual environment activated"
else
    echo "⚠️  Virtual environment not found at ../.venv"
    echo "   Creating new virtual environment..."
    python3 -m venv ../.venv
    source ../.venv/bin/activate
fi

# Install Python dependencies
echo "📦 Installing Python dependencies..."
uv pip install -r ../requirements.txt
echo "✅ Python dependencies installed"

cd ..

echo ""
echo "🎨 Setting up frontend..."
cd streamsmart-frontend

# Install Node dependencies
echo "📦 Installing Node dependencies..."
npm install
echo "✅ Node dependencies installed"

cd ..

echo ""
echo "✅ Setup complete!"
echo ""
echo "🚀 To run the application:"
echo ""
echo "Option 1 - Local Development:"
echo "  Terminal 1: ./scripts/run-backend.sh"
echo "  Terminal 2: ./scripts/run-frontend.sh"
echo ""
echo "Option 2 - Docker:"
echo "  docker-compose up --build"
echo ""
echo "📚 Documentation:"
echo "  README.md - Project overview"
echo "  DEPLOYMENT.md - Azure deployment guide"
echo ""

