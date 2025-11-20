#!/bin/bash
# Run Podman Containers Script for Linux/macOS
# Starts backend and frontend containers

set -e

echo "🚀 Starting Podman containers..."
echo ""

# Check if Podman is installed
if ! command -v podman &> /dev/null; then
    echo "❌ Podman is not installed or not in PATH"
    exit 1
fi

# Check if containers are already running
BACKEND_RUNNING=$(podman ps --filter "name=readlife-backend" --format "{{.Names}}" 2>/dev/null || true)
FRONTEND_RUNNING=$(podman ps --filter "name=readlife-frontend" --format "{{.Names}}" 2>/dev/null || true)

# Stop and remove existing containers if they exist
if [ -n "$BACKEND_RUNNING" ]; then
    echo "🛑 Stopping existing backend container..."
    podman stop readlife-backend 2>/dev/null || true
    podman rm readlife-backend 2>/dev/null || true
fi

if [ -n "$FRONTEND_RUNNING" ]; then
    echo "🛑 Stopping existing frontend container..."
    podman stop readlife-frontend 2>/dev/null || true
    podman rm readlife-frontend 2>/dev/null || true
fi

# Check if images exist
BACKEND_IMAGE=$(podman images --format "{{.Repository}}:{{.Tag}}" | grep "readlife-backend:latest" || true)
FRONTEND_IMAGE=$(podman images --format "{{.Repository}}:{{.Tag}}" | grep "readlife-frontend:latest" || true)

if [ -z "$BACKEND_IMAGE" ]; then
    echo "❌ Backend image not found. Please run ./build-podman.sh first"
    exit 1
fi

if [ -z "$FRONTEND_IMAGE" ]; then
    echo "❌ Frontend image not found. Please run ./build-podman.sh first"
    exit 1
fi

# Check if .env file exists for backend
if [ ! -f "backend/.env" ]; then
    echo "⚠️  Warning: backend/.env not found"
    echo "   Creating from env.example..."
    if [ -f "backend/env.example" ]; then
        cp backend/env.example backend/.env
        echo "   Please edit backend/.env and add your GEMINI_API_KEY"
    else
        echo "   Please create backend/.env with required environment variables"
    fi
fi

# Create network if it doesn't exist
NETWORK_EXISTS=$(podman network ls --format "{{.Name}}" | grep "readlife-network" || true)
if [ -z "$NETWORK_EXISTS" ]; then
    echo "🌐 Creating Podman network..."
    podman network create readlife-network
fi

echo ""

# Start Backend Container
echo "🔵 Starting backend container..."
BACKEND_ARGS=(
    "run" "-d"
    "--name" "readlife-backend"
    "--network" "readlife-network"
    "-p" "8080:8080"
)

# Add env file if it exists
if [ -f "backend/.env" ]; then
    BACKEND_ARGS+=("--env-file" "backend/.env")
fi

BACKEND_ARGS+=("-e" "PORT=8080" "-e" "HOST=0.0.0.0" "readlife-backend:latest")

podman "${BACKEND_ARGS[@]}"
if [ $? -ne 0 ]; then
    echo "❌ Failed to start backend container!"
    exit 1
fi
echo "✅ Backend container started"

# Wait a moment for backend to start
sleep 2

# Start Frontend Container
echo "🟢 Starting frontend container..."
podman run -d \
    --name readlife-frontend \
    --network readlife-network \
    -p 3000:3000 \
    --env NEXT_PUBLIC_API_URL=http://readlife-backend:8080 \
    readlife-frontend:latest

if [ $? -ne 0 ]; then
    echo "❌ Failed to start frontend container!"
    exit 1
fi
echo "✅ Frontend container started"

echo ""
echo "⏳ Waiting for containers to be ready..."
sleep 5

# Check container status
echo ""
echo "📊 Container Status:"
podman ps --filter "name=readlife-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "🔍 Health Checks:"

# Check backend health
if curl -f -s http://localhost:8080/health > /dev/null 2>&1; then
    echo "   ✅ Backend (port 8080): Healthy"
else
    echo "   ⚠️  Backend (port 8080): Not responding yet"
fi

# Check frontend
if curl -f -s http://localhost:3000 > /dev/null 2>&1; then
    echo "   ✅ Frontend (port 3000): Running"
else
    echo "   ⚠️  Frontend (port 3000): Not responding yet"
fi

echo ""
echo "🌐 Access URLs:"
echo "   Frontend:    http://localhost:3000"
echo "   Backend API: http://localhost:8080"
echo "   Health:      http://localhost:8080/health"

echo ""
echo "📝 Useful commands:"
echo "   View logs:    podman logs -f readlife-backend"
echo "   Stop:         podman stop readlife-backend readlife-frontend"
echo "   Remove:       podman rm readlife-backend readlife-frontend"

