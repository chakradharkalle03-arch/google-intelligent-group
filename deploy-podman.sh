#!/bin/bash
# Podman Deployment Script (Bash)
# Supports both Local and Remote Deployment
# Google Intelligent Group Multi-Agent System

MODE="${1:-local}"  # "local" or "remote"
REMOTE_HOST="${2:-}"  # Remote host IP or hostname
REMOTE_USER="${3:-}"  # Remote SSH user
REMOTE_KEY="${4:-}"   # SSH key path

echo ""
echo "🚀 Podman Deployment Script"
echo "Mode: $MODE"
echo ""

# Check if Podman is installed
if ! command -v podman &> /dev/null; then
    echo "❌ Podman is not installed. Please install Podman first."
    exit 1
fi

echo "✅ Podman found: $(podman --version)"

# Check Podman connection
echo ""
echo "🔍 Checking Podman connection..."
if ! podman info &> /dev/null; then
    echo "⚠️  Cannot connect to Podman."
    echo "Please ensure Podman is running."
    exit 1
fi
echo "✅ Podman is ready"

# Load environment variables
echo ""
echo "📋 Loading environment variables..."
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
    echo "✅ Environment variables loaded"
else
    echo "⚠️  .env file not found. Using environment variables from system."
fi

# Check required environment variables
if [ -z "$GEMINI_API_KEY" ]; then
    echo "❌ GEMINI_API_KEY is not set"
    exit 1
fi

if [ -z "$GOOGLE_MAPS_API_KEY" ]; then
    echo "❌ GOOGLE_MAPS_API_KEY is not set"
    exit 1
fi

# Build containers
echo ""
echo "📦 Building containers..."
echo ""

echo "Building backend..."
cd backend
podman build -t google-intelligent-backend:latest -f Containerfile .
if [ $? -ne 0 ]; then
    echo "❌ Failed to build backend container"
    cd ..
    exit 1
fi
cd ..

echo "Building frontend..."
cd frontend
API_URL="http://localhost:8000"
if [ "$MODE" = "remote" ] && [ -n "$REMOTE_HOST" ]; then
    API_URL="http://$REMOTE_HOST:8000"
fi
podman build --build-arg NEXT_PUBLIC_API_URL=$API_URL -t google-intelligent-frontend:latest -f Containerfile .
if [ $? -ne 0 ]; then
    echo "❌ Failed to build frontend container"
    cd ..
    exit 1
fi
cd ..

echo "Building fonoster-server..."
cd fonoster-server
podman build -t fonoster-server:latest -f Containerfile .
if [ $? -ne 0 ]; then
    echo "❌ Failed to build fonoster-server container"
    cd ..
    exit 1
fi
cd ..

echo ""
echo "✅ All containers built successfully"
echo ""

# Create network
echo "Creating network..."
podman network create app-network 2>/dev/null || echo "Network already exists (this is OK)"

# Stop and remove existing containers
echo "Cleaning up existing containers..."
podman stop fonoster-server google-intelligent-backend google-intelligent-frontend 2>/dev/null
podman rm fonoster-server google-intelligent-backend google-intelligent-frontend 2>/dev/null

# Start containers
echo ""
echo "🚀 Starting containers..."
echo ""

# Start Fonoster Server
echo "Starting fonoster-server..."
podman run -d \
  --name fonoster-server \
  --network app-network \
  -p 3001:3001 \
  -e PORT=3001 \
  -e FONOSTER_ACCESS_KEY_ID="$FONOSTER_ACCESS_KEY_ID" \
  -e FONOSTER_API_KEY="$FONOSTER_API_KEY" \
  -e FONOSTER_API_SECRET="$FONOSTER_API_SECRET" \
  -e FONOSTER_ENDPOINT="$FONOSTER_ENDPOINT" \
  -e FONOSTER_FROM_NUMBER="$FONOSTER_FROM_NUMBER" \
  fonoster-server:latest

sleep 3

# Start Backend
echo "Starting backend..."
podman run -d \
  --name google-intelligent-backend \
  --network app-network \
  -p 8000:8000 \
  -e GEMINI_API_KEY="$GEMINI_API_KEY" \
  -e GOOGLE_MAPS_API_KEY="$GOOGLE_MAPS_API_KEY" \
  -e FONOSTER_SERVER_URL="http://fonoster-server:3001" \
  -e BACKEND_HOST=0.0.0.0 \
  -e BACKEND_PORT=8000 \
  -e PYTHONUNBUFFERED=1 \
  google-intelligent-backend:latest

sleep 3

# Start Frontend
echo "Starting frontend..."
FRONTEND_API_URL="http://localhost:8000"
if [ "$MODE" = "remote" ] && [ -n "$REMOTE_HOST" ]; then
    FRONTEND_API_URL="http://$REMOTE_HOST:8000"
fi
podman run -d \
  --name google-intelligent-frontend \
  --network app-network \
  -p 3000:3000 \
  -e NEXT_PUBLIC_API_URL=$FRONTEND_API_URL \
  -e NODE_ENV=production \
  -e NEXT_TELEMETRY_DISABLED=1 \
  google-intelligent-frontend:latest

sleep 5

# Check container status
echo ""
echo "📊 Container Status:"
podman ps --filter "name=google-intelligent|fonoster-server" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "✅ All containers started!"
echo ""
echo "🌐 Access the application:"
if [ "$MODE" = "remote" ] && [ -n "$REMOTE_HOST" ]; then
    echo "   Frontend: http://$REMOTE_HOST:3000"
    echo "   Backend:  http://$REMOTE_HOST:8000"
    echo "   Fonoster: http://$REMOTE_HOST:3001"
else
    echo "   Frontend: http://localhost:3000"
    echo "   Backend:  http://localhost:8000"
    echo "   Fonoster: http://localhost:3001"
fi

echo ""
echo "📝 Useful commands:"
echo "   View logs:    podman logs <container-name>"
echo "   Stop all:     podman stop fonoster-server google-intelligent-backend google-intelligent-frontend"
echo "   Remove all:   podman rm fonoster-server google-intelligent-backend google-intelligent-frontend"
echo ""

