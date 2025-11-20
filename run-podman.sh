#!/bin/bash

# Podman Quick Start Script
# Google Intelligent Group Multi-Agent System

set -e

echo "🚀 Starting Google Intelligent Group with Podman..."
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if Podman is installed
if ! command -v podman &> /dev/null; then
    echo -e "${RED}❌ Podman is not installed. Please install Podman first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Podman found: $(podman --version)${NC}"
echo ""

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${YELLOW}⚠️  .env file not found. Creating template...${NC}"
    cat > .env << EOF
# Backend API Keys (Required)
GEMINI_API_KEY=your_gemini_api_key_here
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here

# Fonoster Configuration (Optional - for real phone calls)
FONOSTER_ACCESS_KEY_ID=
FONOSTER_API_KEY=
FONOSTER_API_SECRET=
FONOSTER_ENDPOINT=https://api.fonoster.com
FONOSTER_FROM_NUMBER=
EOF
    echo -e "${YELLOW}⚠️  Please edit .env file and add your API keys before continuing.${NC}"
    echo ""
    read -p "Press Enter to continue after editing .env file..."
fi

# Load environment variables
source .env

# Check required environment variables
if [ -z "$GEMINI_API_KEY" ] || [ "$GEMINI_API_KEY" = "your_gemini_api_key_here" ]; then
    echo -e "${RED}❌ GEMINI_API_KEY is not set in .env file${NC}"
    exit 1
fi

if [ -z "$GOOGLE_MAPS_API_KEY" ] || [ "$GOOGLE_MAPS_API_KEY" = "your_google_maps_api_key_here" ]; then
    echo -e "${RED}❌ GOOGLE_MAPS_API_KEY is not set in .env file${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Environment variables loaded${NC}"
echo ""

# Build containers
echo -e "${YELLOW}📦 Building containers...${NC}"
echo ""

echo "Building backend..."
cd backend
podman build -t google-intelligent-backend:latest -f Containerfile . || {
    echo -e "${RED}❌ Failed to build backend container${NC}"
    exit 1
}
cd ..

echo "Building frontend..."
cd frontend
podman build -t google-intelligent-frontend:latest -f Containerfile . || {
    echo -e "${RED}❌ Failed to build frontend container${NC}"
    exit 1
}
cd ..

echo "Building fonoster-server..."
cd fonoster-server
podman build -t fonoster-server:latest -f Containerfile . || {
    echo -e "${RED}❌ Failed to build fonoster-server container${NC}"
    exit 1
}
cd ..

echo -e "${GREEN}✅ All containers built successfully${NC}"
echo ""

# Create network
echo "Creating network..."
podman network create app-network 2>/dev/null || echo "Network already exists"
echo ""

# Stop and remove existing containers
echo "Cleaning up existing containers..."
podman stop fonoster-server google-intelligent-backend google-intelligent-frontend 2>/dev/null || true
podman rm fonoster-server google-intelligent-backend google-intelligent-frontend 2>/dev/null || true
echo ""

# Start containers
echo -e "${YELLOW}🚀 Starting containers...${NC}"
echo ""

# Start Fonoster Server
echo "Starting fonoster-server..."
podman run -d \
  --name fonoster-server \
  --network app-network \
  -p 3001:3001 \
  -e PORT=3001 \
  -e FONOSTER_ACCESS_KEY_ID="${FONOSTER_ACCESS_KEY_ID:-}" \
  -e FONOSTER_API_KEY="${FONOSTER_API_KEY:-}" \
  -e FONOSTER_API_SECRET="${FONOSTER_API_SECRET:-}" \
  -e FONOSTER_ENDPOINT="${FONOSTER_ENDPOINT:-https://api.fonoster.com}" \
  -e FONOSTER_FROM_NUMBER="${FONOSTER_FROM_NUMBER:-}" \
  fonoster-server:latest

sleep 3

# Start Backend
echo "Starting backend..."
podman run -d \
  --name google-intelligent-backend \
  --network app-network \
  -p 8000:8000 \
  -e GEMINI_API_KEY="${GEMINI_API_KEY}" \
  -e GOOGLE_MAPS_API_KEY="${GOOGLE_MAPS_API_KEY}" \
  -e FONOSTER_SERVER_URL="http://fonoster-server:3001" \
  -e BACKEND_HOST=0.0.0.0 \
  -e BACKEND_PORT=8000 \
  -e PYTHONUNBUFFERED=1 \
  google-intelligent-backend:latest

sleep 3

# Start Frontend
echo "Starting frontend..."
podman run -d \
  --name google-intelligent-frontend \
  --network app-network \
  -p 3000:3000 \
  -e NEXT_PUBLIC_API_URL="http://localhost:8000" \
  -e NODE_ENV=production \
  -e NEXT_TELEMETRY_DISABLED=1 \
  google-intelligent-frontend:latest

sleep 5

# Check container status
echo ""
echo -e "${GREEN}📊 Container Status:${NC}"
podman ps --filter "name=google-intelligent|fonoster-server" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo -e "${GREEN}✅ All containers started!${NC}"
echo ""
echo "🌐 Access the application:"
echo "   Frontend: http://localhost:3000"
echo "   Backend:  http://localhost:8000"
echo "   Fonoster: http://localhost:3001"
echo ""
echo "📝 Useful commands:"
echo "   View logs:    podman logs <container-name>"
echo "   Stop all:     podman stop fonoster-server google-intelligent-backend google-intelligent-frontend"
echo "   Remove all:   podman rm fonoster-server google-intelligent-backend google-intelligent-frontend"
echo ""

