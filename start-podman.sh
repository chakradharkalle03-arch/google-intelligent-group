#!/bin/bash
# Bash script to build and run Podman containers
# Usage: ./start-podman.sh

set -e

echo "========================================"
echo "ReadLife Podman Container Launcher"
echo "========================================"
echo ""

# Check if Podman is installed
echo "Checking Podman installation..."
if ! command -v podman &> /dev/null; then
    echo "✗ Podman is not installed or not in PATH"
    echo "Please install Podman first: https://podman.io/getting-started/installation"
    exit 1
fi

PODMAN_VERSION=$(podman --version)
echo "✓ Podman found: $PODMAN_VERSION"

# Check if backend .env exists
if [ ! -f "backend/.env" ]; then
    echo "⚠ Warning: backend/.env not found"
    echo "Creating backend/.env from env.example..."
    if [ -f "backend/env.example" ]; then
        cp backend/env.example backend/.env
        echo "✓ Created backend/.env - Please edit it with your API keys!"
    else
        echo "✗ backend/env.example not found!"
        exit 1
    fi
fi

# Function to check if container exists
container_exists() {
    podman ps -a --format "{{.Names}}" | grep -q "^${1}$"
}

# Function to remove existing container
remove_container_if_exists() {
    if container_exists "$1"; then
        echo "Removing existing container: $1"
        podman rm -f "$1" > /dev/null 2>&1 || true
    fi
}

# Build Backend
echo ""
echo "Building backend container..."
cd backend
podman build -t readlife-backend:latest -f Containerfile .
if [ $? -ne 0 ]; then
    echo "✗ Backend build failed!"
    cd ..
    exit 1
fi
echo "✓ Backend container built successfully"
cd ..

# Build Frontend
echo ""
echo "Building frontend container..."
cd frontend
read -p "Enter backend API URL (default: http://127.0.0.1:8000): " api_url
api_url=${api_url:-http://127.0.0.1:8000}
podman build -t readlife-frontend:latest -f Containerfile --build-arg NEXT_PUBLIC_API_URL="$api_url" .
if [ $? -ne 0 ]; then
    echo "✗ Frontend build failed!"
    cd ..
    exit 1
fi
echo "✓ Frontend container built successfully"
cd ..

# Remove existing containers if they exist
echo ""
echo "Cleaning up existing containers..."
remove_container_if_exists "readlife-backend"
remove_container_if_exists "readlife-frontend"

# Run Backend
echo ""
echo "Starting backend container..."
podman run -d \
    --name readlife-backend \
    -p 8000:8000 \
    --env-file backend/.env \
    readlife-backend:latest

if [ $? -ne 0 ]; then
    echo "✗ Failed to start backend container!"
    exit 1
fi
echo "✓ Backend container started"

# Wait for backend to be ready
echo "Waiting for backend to be ready..."
sleep 3

# Check backend health
if curl -f -s http://localhost:8000/health > /dev/null 2>&1; then
    echo "✓ Backend is healthy"
else
    echo "⚠ Backend may not be ready yet, but container is running"
fi

# Run Frontend
echo ""
echo "Starting frontend container..."
podman run -d \
    --name readlife-frontend \
    -p 3000:3000 \
    readlife-frontend:latest

if [ $? -ne 0 ]; then
    echo "✗ Failed to start frontend container!"
    exit 1
fi
echo "✓ Frontend container started"

# Summary
echo ""
echo "========================================"
echo "Containers Started Successfully!"
echo "========================================"
echo ""
echo "Backend:  http://localhost:8000"
echo "Frontend: http://localhost:3000"
echo ""
echo "Useful commands:"
echo "  View logs:    podman logs -f readlife-backend"
echo "  View logs:    podman logs -f readlife-frontend"
echo "  Stop:         podman stop readlife-backend readlife-frontend"
echo "  Start:        podman start readlife-backend readlife-frontend"
echo "  Remove:       podman rm -f readlife-backend readlife-frontend"
echo ""

