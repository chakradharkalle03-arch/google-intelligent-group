#!/bin/bash
# Build Podman Containers Script for Linux/macOS
# Builds both backend and frontend containers

set -e

echo "🔨 Building Podman containers..."
echo ""

# Check if Podman is installed
if ! command -v podman &> /dev/null; then
    echo "❌ Podman is not installed or not in PATH"
    echo "   Please install Podman:"
    echo "   - Ubuntu/Debian: sudo apt-get install podman"
    echo "   - Fedora/RHEL: sudo dnf install podman"
    echo "   - macOS: brew install podman"
    exit 1
fi

echo "✅ Podman found: $(podman --version)"
echo ""

# Build Backend Container
echo "📦 Building backend container..."
cd backend
podman build -t readlife-backend:latest -f Containerfile .
if [ $? -ne 0 ]; then
    echo "❌ Backend build failed!"
    cd ..
    exit 1
fi
echo "✅ Backend container built successfully"
cd ..

echo ""

# Build Frontend Container
echo "📦 Building frontend container..."
cd frontend

# Get the API URL from environment or use default
API_URL="${NEXT_PUBLIC_API_URL:-http://localhost:8080}"
echo "   Using API URL: $API_URL"

podman build --build-arg NEXT_PUBLIC_API_URL="$API_URL" -t readlife-frontend:latest -f Containerfile .
if [ $? -ne 0 ]; then
    echo "❌ Frontend build failed!"
    cd ..
    exit 1
fi
echo "✅ Frontend container built successfully"
cd ..

echo ""
echo "🎉 All containers built successfully!"
echo ""
echo "Next steps:"
echo "  1. Run containers: ./run-podman.sh"
echo "  2. Or manually: podman run -d --name readlife-backend -p 8080:8080 --env-file backend/.env readlife-backend:latest"

