#!/bin/bash
# Setup script for Google Intelligent Group Project
# Linux/Mac bash script

echo "🧠 Google Intelligent Group - Project Setup"
echo "=========================================="
echo ""

# Check Node.js
echo "Checking Node.js installation..."
if command -v node &> /dev/null; then
    echo "✅ Node.js found: $(node --version)"
else
    echo "❌ Node.js not found. Please install Node.js 18+"
    exit 1
fi

# Check Python
echo ""
echo "Checking Python installation..."
if command -v python3 &> /dev/null; then
    echo "✅ Python found: $(python3 --version)"
    PYTHON_CMD=python3
elif command -v python &> /dev/null; then
    echo "✅ Python found: $(python --version)"
    PYTHON_CMD=python
else
    echo "❌ Python not found. Please install Python 3.10+"
    exit 1
fi

# Setup Frontend
echo ""
echo "📦 Setting up Frontend (Next.js)..."
cd frontend
if [ -d "node_modules" ]; then
    echo "✅ Frontend dependencies already installed"
else
    npm install
    echo "✅ Frontend dependencies installed"
fi
cd ..

# Setup Backend
echo ""
echo "🐍 Setting up Backend (Python FastAPI)..."
cd backend
if [ -d "venv" ]; then
    echo "✅ Virtual environment already exists"
else
    $PYTHON_CMD -m venv venv
    echo "✅ Virtual environment created"
fi
source venv/bin/activate
if [ ! -f ".env" ]; then
    cp env.example .env
    echo "✅ Created .env file from env.example"
    echo "⚠️  Please edit backend/.env and add your API keys"
fi
pip install -r requirements.txt
echo "✅ Backend dependencies installed"
deactivate
cd ..

# Setup Fonoster Server
echo ""
echo "☎️  Setting up Fonoster Server..."
cd fonoster-server
if [ -d "node_modules" ]; then
    echo "✅ Fonoster server dependencies already installed"
else
    npm install
    echo "✅ Fonoster server dependencies installed"
fi
if [ ! -f ".env" ]; then
    cp env.example .env
    echo "✅ Created .env file from env.example"
    echo "⚠️  Please edit fonoster-server/.env and add your Fonoster credentials"
fi
cd ..

echo ""
echo "✅ Setup Complete!"
echo ""
echo "📝 Next Steps:"
echo "1. Edit backend/.env and add your GEMINI_API_KEY and GOOGLE_MAPS_API_KEY"
echo "2. Edit fonoster-server/.env and add your Fonoster credentials"
echo ""
echo "🚀 To run the project:"
echo "  Frontend:    cd frontend && npm run dev"
echo "  Backend:     cd backend && source venv/bin/activate && python main.py"
echo "  Fonoster:    cd fonoster-server && npm start"

