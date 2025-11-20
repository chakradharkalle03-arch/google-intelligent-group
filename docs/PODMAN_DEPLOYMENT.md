# Podman Container Deployment Guide
## Google Intelligent Group Multi-Agent System

Complete guide for deploying the project using Podman containers.

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Building Containers](#building-containers)
3. [Running Containers](#running-containers)
4. [Environment Configuration](#environment-configuration)
5. [Container Management](#container-management)
6. [Troubleshooting](#troubleshooting)

---

## 🔧 Prerequisites

### Required Software

- **Podman** 4.0+ installed and running
- **Git** for cloning repository
- **API Keys:**
  - Google Gemini API Key
  - Google Maps API Key
  - Fonoster Credentials (optional)

### Verify Podman Installation

```bash
podman --version
podman info
```

---

## 🏗️ Building Containers

### Step 1: Clone Repository

```bash
git clone https://github.com/chakradharkalle03-arch/google-intelligent-group.git
cd google-intelligent-group
```

### Step 2: Build Backend Container

```bash
cd backend
podman build -t google-intelligent-backend:latest -f Containerfile .
```

**Expected output:**
```
STEP 1/10: FROM python:3.11-slim
...
STEP 10/10: CMD ["hypercorn", "main:app", "-b", "0.0.0.0:8000", "--workers", "2"]
COMMIT google-intelligent-backend:latest
```

### Step 3: Build Frontend Container

```bash
cd ../frontend
podman build -t google-intelligent-frontend:latest -f Containerfile .
```

**Expected output:**
```
STEP 1/15: FROM node:18-alpine AS builder
...
STEP 15/15: CMD ["node", "server.js"]
COMMIT google-intelligent-frontend:latest
```

### Step 4: Build Fonoster Server Container

```bash
cd ../fonoster-server
podman build -t fonoster-server:latest -f Containerfile .
```

**Expected output:**
```
STEP 1/8: FROM node:18-alpine
...
STEP 8/8: CMD ["node", "server.js"]
COMMIT fonoster-server:latest
```

### Verify Built Images

```bash
podman images | grep -E "google-intelligent|fonoster"
```

You should see:
```
localhost/google-intelligent-backend    latest    ...    ...    ...MB
localhost/google-intelligent-frontend    latest    ...    ...    ...MB
localhost/fonoster-server               latest    ...    ...    ...MB
```

---

## 🚀 Running Containers

### Option 1: Run All Containers with Podman Compose (Recommended)

Create `podman-compose.yml`:

```yaml
version: '3.8'

services:
  fonoster-server:
    image: fonoster-server:latest
    container_name: fonoster-server
    ports:
      - "3001:3001"
    environment:
      - PORT=3001
      - FONOSTER_ACCESS_KEY_ID=${FONOSTER_ACCESS_KEY_ID:-}
      - FONOSTER_API_KEY=${FONOSTER_API_KEY:-}
      - FONOSTER_API_SECRET=${FONOSTER_API_SECRET:-}
      - FONOSTER_ENDPOINT=${FONOSTER_ENDPOINT:-https://api.fonoster.com}
    networks:
      - app-network
    restart: unless-stopped

  backend:
    image: google-intelligent-backend:latest
    container_name: google-intelligent-backend
    ports:
      - "8000:8000"
    environment:
      - GEMINI_API_KEY=${GEMINI_API_KEY}
      - GOOGLE_MAPS_API_KEY=${GOOGLE_MAPS_API_KEY}
      - FONOSTER_SERVER_URL=http://fonoster-server:3001
      - BACKEND_HOST=0.0.0.0
      - BACKEND_PORT=8000
    depends_on:
      - fonoster-server
    networks:
      - app-network
    restart: unless-stopped

  frontend:
    image: google-intelligent-frontend:latest
    container_name: google-intelligent-frontend
    ports:
      - "3000:3000"
    environment:
      - NEXT_PUBLIC_API_URL=http://localhost:8000
    depends_on:
      - backend
    networks:
      - app-network
    restart: unless-stopped

networks:
  app-network:
    driver: bridge
```

**Run with podman-compose:**
```bash
# Install podman-compose if not installed
pip install podman-compose

# Create .env file with your API keys
cat > .env << EOF
GEMINI_API_KEY=your_gemini_api_key_here
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
FONOSTER_ACCESS_KEY_ID=your_access_key_id
FONOSTER_API_KEY=your_api_key
FONOSTER_API_SECRET=your_api_secret
EOF

# Start all containers
podman-compose up -d
```

### Option 2: Run Containers Individually

#### 1. Create Podman Network

```bash
podman network create app-network
```

#### 2. Run Fonoster Server

```bash
podman run -d \
  --name fonoster-server \
  --network app-network \
  -p 3001:3001 \
  -e PORT=3001 \
  -e FONOSTER_ACCESS_KEY_ID=your_access_key_id \
  -e FONOSTER_API_KEY=your_api_key \
  -e FONOSTER_API_SECRET=your_api_secret \
  fonoster-server:latest
```

#### 3. Run Backend

```bash
podman run -d \
  --name google-intelligent-backend \
  --network app-network \
  -p 8000:8000 \
  -e GEMINI_API_KEY=your_gemini_api_key \
  -e GOOGLE_MAPS_API_KEY=your_google_maps_api_key \
  -e FONOSTER_SERVER_URL=http://fonoster-server:3001 \
  -e BACKEND_HOST=0.0.0.0 \
  -e BACKEND_PORT=8000 \
  google-intelligent-backend:latest
```

#### 4. Run Frontend

```bash
podman run -d \
  --name google-intelligent-frontend \
  --network app-network \
  -p 3000:3000 \
  -e NEXT_PUBLIC_API_URL=http://localhost:8000 \
  google-intelligent-frontend:latest
```

---

## ⚙️ Environment Configuration

### Using Environment Files

Create `.env` file in project root:

```env
# Backend
GEMINI_API_KEY=your_gemini_api_key_here
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here

# Fonoster (Optional)
FONOSTER_ACCESS_KEY_ID=your_access_key_id
FONOSTER_API_KEY=your_api_key
FONOSTER_API_SECRET=your_api_secret
FONOSTER_ENDPOINT=https://api.fonoster.com
```

### Load Environment Variables

```bash
# Source the .env file
source .env

# Or export individually
export GEMINI_API_KEY=your_key
export GOOGLE_MAPS_API_KEY=your_key
```

---

## 🔍 Container Management

### Check Container Status

```bash
podman ps
```

**Expected output:**
```
CONTAINER ID  IMAGE                              COMMAND           CREATED        STATUS        PORTS                    NAMES
abc123def456  localhost/fonoster-server:latest   node server.js    2 minutes ago  Up 2 minutes  0.0.0.0:3001->3001/tcp   fonoster-server
def456ghi789  localhost/google-intelligent-...   hypercorn mai...  2 minutes ago  Up 2 minutes  0.0.0.0:8000->8000/tcp   google-intelligent-backend
ghi789jkl012  localhost/google-intelligent-...   node server.js    2 minutes ago  Up 2 minutes  0.0.0.0:3000->3000/tcp   google-intelligent-frontend
```

### View Container Logs

```bash
# Backend logs
podman logs google-intelligent-backend

# Frontend logs
podman logs google-intelligent-frontend

# Fonoster logs
podman logs fonoster-server

# Follow logs (real-time)
podman logs -f google-intelligent-backend
```

### Stop Containers

```bash
# Stop all containers
podman stop fonoster-server google-intelligent-backend google-intelligent-frontend

# Or stop individually
podman stop google-intelligent-backend
```

### Start Containers

```bash
# Start all containers
podman start fonoster-server google-intelligent-backend google-intelligent-frontend
```

### Remove Containers

```bash
# Stop and remove containers
podman stop fonoster-server google-intelligent-backend google-intelligent-frontend
podman rm fonoster-server google-intelligent-backend google-intelligent-frontend
```

### Remove Images

```bash
podman rmi fonoster-server:latest google-intelligent-backend:latest google-intelligent-frontend:latest
```

---

## 🧪 Testing the Deployment

### 1. Test Fonoster Server

```bash
curl http://localhost:3001/health
```

**Expected response:**
```json
{"status":"ok"}
```

### 2. Test Backend

```bash
curl http://localhost:8000/health
```

**Expected response:**
```json
{"status":"healthy"}
```

### 3. Test Frontend

Open browser: `http://localhost:3000`

You should see the Google Intelligent Group UI.

### 4. Test Full Flow

```bash
curl -X POST http://localhost:8000/query \
  -H "Content-Type: application/json" \
  -d '{"query": "Find Indian restaurant near Taipei 101"}'
```

---

## 🐛 Troubleshooting

### Container Won't Start

**Check logs:**
```bash
podman logs <container-name>
```

**Common issues:**
- Missing environment variables
- Port already in use
- Network issues

### Port Already in Use

```bash
# Find process using port
podman ps -a | grep <port>

# Or use netstat
netstat -tulpn | grep :8000

# Stop conflicting container
podman stop <container-name>
```

### Network Issues

```bash
# Check network exists
podman network ls

# Recreate network
podman network rm app-network
podman network create app-network
```

### Build Failures

**Backend build fails:**
```bash
# Check Python version
podman run --rm python:3.11-slim python --version

# Rebuild with no cache
podman build --no-cache -t google-intelligent-backend:latest -f backend/Containerfile backend/
```

**Frontend build fails:**
```bash
# Check Node version
podman run --rm node:18-alpine node --version

# Rebuild with no cache
podman build --no-cache -t google-intelligent-frontend:latest -f frontend/Containerfile frontend/
```

### Environment Variables Not Working

```bash
# Check environment variables in container
podman exec google-intelligent-backend env | grep GEMINI

# Set environment variables when running
podman run -e GEMINI_API_KEY=your_key ...
```

---

## 📝 Quick Start Script

Create `run-podman.sh`:

```bash
#!/bin/bash

# Build all containers
echo "Building containers..."
cd backend && podman build -t google-intelligent-backend:latest -f Containerfile . && cd ..
cd frontend && podman build -t google-intelligent-frontend:latest -f Containerfile . && cd ..
cd fonoster-server && podman build -t fonoster-server:latest -f Containerfile . && cd ..

# Create network
podman network create app-network 2>/dev/null || true

# Stop existing containers
podman stop fonoster-server google-intelligent-backend google-intelligent-frontend 2>/dev/null
podman rm fonoster-server google-intelligent-backend google-intelligent-frontend 2>/dev/null

# Load environment variables
source .env

# Run containers
echo "Starting containers..."
podman run -d --name fonoster-server --network app-network -p 3001:3001 \
  -e PORT=3001 \
  -e FONOSTER_ACCESS_KEY_ID=${FONOSTER_ACCESS_KEY_ID:-} \
  -e FONOSTER_API_KEY=${FONOSTER_API_KEY:-} \
  -e FONOSTER_API_SECRET=${FONOSTER_API_SECRET:-} \
  fonoster-server:latest

podman run -d --name google-intelligent-backend --network app-network -p 8000:8000 \
  -e GEMINI_API_KEY=${GEMINI_API_KEY} \
  -e GOOGLE_MAPS_API_KEY=${GOOGLE_MAPS_API_KEY} \
  -e FONOSTER_SERVER_URL=http://fonoster-server:3001 \
  google-intelligent-backend:latest

podman run -d --name google-intelligent-frontend --network app-network -p 3000:3000 \
  -e NEXT_PUBLIC_API_URL=http://localhost:8000 \
  google-intelligent-frontend:latest

echo "Containers started!"
echo "Frontend: http://localhost:3000"
echo "Backend: http://localhost:8000"
echo "Fonoster: http://localhost:3001"
```

**Make executable and run:**
```bash
chmod +x run-podman.sh
./run-podman.sh
```

---

## ✅ Verification Checklist

- [ ] Podman installed and running
- [ ] All containers built successfully
- [ ] Network created
- [ ] Environment variables set
- [ ] All containers running
- [ ] Health checks passing
- [ ] Frontend accessible at http://localhost:3000
- [ ] Backend accessible at http://localhost:8000
- [ ] Fonoster accessible at http://localhost:3001
- [ ] Full query flow working

---

## 📚 Additional Resources

- **Podman Documentation:** https://docs.podman.io/
- **Containerfile Reference:** https://docs.podman.io/en/latest/markdown/podman-build.1.html
- **Project Repository:** https://github.com/chakradharkalle03-arch/google-intelligent-group

---

**Last Updated:** November 2025  
**Project Version:** 1.0.0

