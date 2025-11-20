# Podman Quick Start Guide

Complete guide for deploying the Google Intelligent Group Multi-Agent System locally using Podman.

## Prerequisites

1. **Podman Desktop** installed and running
2. **WSL2** installed (required for Podman on Windows)
3. **Environment variables** in `.env` file:
   - `GEMINI_API_KEY`
   - `GOOGLE_MAPS_API_KEY`
   - `FONOSTER_ACCESS_KEY_ID` (optional)
   - `FONOSTER_API_KEY` (optional)
   - `FONOSTER_API_SECRET` (optional)

## Quick Start (Automated)

### Option 1: Using Scripts

```powershell
# Step 1: Build all images
.\build-podman-images.ps1

# Step 2: Start all containers
.\start-podman.ps1
```

### Option 2: Manual Commands

Follow the steps below.

## Step-by-Step Manual Deployment

### Step 1: Load Environment Variables

```powershell
# Load from .env file
Get-Content .env | ForEach-Object {
    if ($_ -match '^([^#][^=]+)=(.*)$') {
        $name = $matches[1].Trim()
        $value = $matches[2].Trim()
        Set-Item -Path "env:$name" -Value $value
    }
}
```

### Step 2: Create Network

```powershell
podman network create app-network
```

### Step 3: Build Images

#### Build Fonoster Server

```powershell
cd fonoster-server
podman build -t fonoster-server:latest -f Containerfile .
cd ..
```

#### Build Backend

```powershell
cd backend
podman build -t google-intelligent-backend:latest -f Containerfile .
cd ..
```

#### Build Frontend

```powershell
cd frontend
podman build -t google-intelligent-frontend:latest -f Containerfile .
cd ..
```

**Note**: If you encounter network timeouts, wait a few minutes and retry, or check your internet connection.

### Step 4: Start Containers with `podman run`

#### Start Fonoster Server

```powershell
podman run -d `
  --name fonoster-server `
  --network app-network `
  -p 3001:3001 `
  -e PORT=3001 `
  -e FONOSTER_ACCESS_KEY_ID=$env:FONOSTER_ACCESS_KEY_ID `
  -e FONOSTER_API_KEY=$env:FONOSTER_API_KEY `
  -e FONOSTER_API_SECRET=$env:FONOSTER_API_SECRET `
  -e FONOSTER_ENDPOINT=$env:FONOSTER_ENDPOINT `
  -e FONOSTER_FROM_NUMBER=$env:FONOSTER_FROM_NUMBER `
  --restart unless-stopped `
  localhost/fonoster-server:latest
```

#### Start Backend

```powershell
podman run -d `
  --name google-intelligent-backend `
  --network app-network `
  -p 8000:8000 `
  -e GEMINI_API_KEY=$env:GEMINI_API_KEY `
  -e GOOGLE_MAPS_API_KEY=$env:GOOGLE_MAPS_API_KEY `
  -e FONOSTER_SERVER_URL=http://fonoster-server:3001 `
  -e BACKEND_HOST=0.0.0.0 `
  -e BACKEND_PORT=8000 `
  -e PYTHONUNBUFFERED=1 `
  --restart unless-stopped `
  localhost/google-intelligent-backend:latest
```

#### Start Frontend

```powershell
podman run -d `
  --name google-intelligent-frontend `
  --network app-network `
  -p 3000:3000 `
  -e NEXT_PUBLIC_API_URL=http://localhost:8000 `
  -e NODE_ENV=production `
  -e NEXT_TELEMETRY_DISABLED=1 `
  --restart unless-stopped `
  localhost/google-intelligent-frontend:latest
```

### Step 5: Verify Containers

```powershell
podman ps
```

Expected output:
```
CONTAINER ID  IMAGE                                    COMMAND               CREATED        STATUS        PORTS                   NAMES
xxx           localhost/fonoster-server:latest         node server.js        ...            Up ...        0.0.0.0:3001->3001/tcp  fonoster-server
xxx           localhost/google-intelligent-backend:... hypercorn main:ap...  ...            Up ...        0.0.0.0:8000->8000/tcp  google-intelligent-backend
xxx           localhost/google-intelligent-frontend... node server.js        ...            Up ...        0.0.0.0:3000->3000/tcp  google-intelligent-frontend
```

### Step 6: Test Connectivity

```powershell
# Backend health check
Invoke-WebRequest -Uri "http://localhost:8000/health"

# Frontend
Invoke-WebRequest -Uri "http://localhost:3000"

# Fonoster health check
Invoke-WebRequest -Uri "http://localhost:3001/health"
```

## Access URLs

Once containers are running:

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8000
- **Backend Health**: http://localhost:8000/health
- **Fonoster Server**: http://localhost:3001
- **Fonoster Health**: http://localhost:3001/health

## Container Management

### View Running Containers

```powershell
podman ps
```

### View All Containers

```powershell
podman ps -a
```

### View Container Logs

```powershell
podman logs fonoster-server
podman logs google-intelligent-backend
podman logs google-intelligent-frontend
```

### Follow Logs (Real-time)

```powershell
podman logs -f fonoster-server
podman logs -f google-intelligent-backend
podman logs -f google-intelligent-frontend
```

### Stop Containers

```powershell
podman stop fonoster-server google-intelligent-backend google-intelligent-frontend
```

### Start Stopped Containers

```powershell
podman start fonoster-server google-intelligent-backend google-intelligent-frontend
```

### Restart Containers

```powershell
podman restart fonoster-server google-intelligent-backend google-intelligent-frontend
```

### Remove Containers

```powershell
podman rm fonoster-server google-intelligent-backend google-intelligent-frontend
```

### Remove Containers (Force)

```powershell
podman rm -f fonoster-server google-intelligent-backend google-intelligent-frontend
```

## Troubleshooting

### Network Timeout During Build

**Problem**: `i/o timeout` when pulling base images

**Solutions**:
1. Wait a few minutes and retry
2. Check internet connection
3. Verify firewall settings
4. Try building one image at a time

### Container Won't Start

**Check logs**:
```powershell
podman logs <container-name>
```

**Common issues**:
- Missing environment variables
- Port already in use
- Network not created

### Port Already in Use

**Find process using port**:
```powershell
netstat -ano | findstr :3000
netstat -ano | findstr :8000
netstat -ano | findstr :3001
```

**Stop conflicting containers**:
```powershell
podman stop $(podman ps -q)
```

### Environment Variables Not Loading

**Verify .env file exists**:
```powershell
Test-Path .env
```

**Load manually**:
```powershell
$env:GEMINI_API_KEY = "your_key_here"
$env:GOOGLE_MAPS_API_KEY = "your_key_here"
```

## Complete Deployment Script

All commands in one script (`start-podman.ps1`):

```powershell
# Load environment variables
Get-Content .env | ForEach-Object {
    if ($_ -match '^([^#][^=]+)=(.*)$') {
        $name = $matches[1].Trim()
        $value = $matches[2].Trim()
        Set-Item -Path "env:$name" -Value $value
    }
}

# Create network
podman network create app-network 2>&1 | Out-Null

# Start fonoster-server
podman run -d --name fonoster-server --network app-network -p 3001:3001 `
  -e PORT=3001 `
  -e FONOSTER_ACCESS_KEY_ID=$env:FONOSTER_ACCESS_KEY_ID `
  -e FONOSTER_API_KEY=$env:FONOSTER_API_KEY `
  -e FONOSTER_API_SECRET=$env:FONOSTER_API_SECRET `
  -e FONOSTER_ENDPOINT=$env:FONOSTER_ENDPOINT `
  -e FONOSTER_FROM_NUMBER=$env:FONOSTER_FROM_NUMBER `
  --restart unless-stopped `
  localhost/fonoster-server:latest

Start-Sleep -Seconds 3

# Start backend
podman run -d --name google-intelligent-backend --network app-network -p 8000:8000 `
  -e GEMINI_API_KEY=$env:GEMINI_API_KEY `
  -e GOOGLE_MAPS_API_KEY=$env:GOOGLE_MAPS_API_KEY `
  -e FONOSTER_SERVER_URL=http://fonoster-server:3001 `
  -e BACKEND_HOST=0.0.0.0 `
  -e BACKEND_PORT=8000 `
  -e PYTHONUNBUFFERED=1 `
  --restart unless-stopped `
  localhost/google-intelligent-backend:latest

Start-Sleep -Seconds 3

# Start frontend
podman run -d --name google-intelligent-frontend --network app-network -p 3000:3000 `
  -e NEXT_PUBLIC_API_URL=http://localhost:8000 `
  -e NODE_ENV=production `
  -e NEXT_TELEMETRY_DISABLED=1 `
  --restart unless-stopped `
  localhost/google-intelligent-frontend:latest

# Verify
podman ps
```

## Next Steps

1. **Build images** (if not already built)
2. **Start containers** using the commands above
3. **Access frontend** at http://localhost:3000
4. **Test the system** with sample queries

---

**Last Updated**: November 2025

