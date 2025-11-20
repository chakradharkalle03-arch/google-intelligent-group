# Podman Local Deployment Guide

Complete guide for deploying the Google Intelligent Group Multi-Agent System using Podman locally.

## Prerequisites

1. **Podman Desktop** installed and running
2. **WSL2** installed (required for Podman on Windows)
3. **Environment variables** configured in `.env` file

## Quick Start

### Option 1: Using Podman Run (Manual)

#### Step 1: Create Network

```powershell
podman network create app-network
```

#### Step 2: Start Fonoster Server

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

#### Step 3: Start Backend

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

#### Step 4: Start Frontend

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

### Option 2: Using Podman Compose

```powershell
# Load environment variables
Get-Content .env | ForEach-Object {
    if ($_ -match '^([^#][^=]+)=(.*)$') {
        $name = $matches[1].Trim()
        $value = $matches[2].Trim()
        Set-Item -Path "env:$name" -Value $value
    }
}

# Start all services
podman-compose up -d
```

## Building Images

### Build Fonoster Server

```powershell
cd fonoster-server
podman build -t fonoster-server:latest -f Containerfile .
cd ..
```

### Build Backend

```powershell
cd backend
podman build -t google-intelligent-backend:latest -f Containerfile .
cd ..
```

### Build Frontend

```powershell
cd frontend
podman build -t google-intelligent-frontend:latest -f Containerfile .
cd ..
```

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

### Stop Containers

```powershell
podman stop fonoster-server google-intelligent-backend google-intelligent-frontend
```

### Remove Containers

```powershell
podman rm fonoster-server google-intelligent-backend google-intelligent-frontend
```

### Restart Containers

```powershell
podman restart fonoster-server google-intelligent-backend google-intelligent-frontend
```

## Accessing Services

Once containers are running:

- **Frontend:** http://localhost:3000
- **Backend API:** http://localhost:8000
- **Backend Health:** http://localhost:8000/health
- **Fonoster Server:** http://localhost:3001
- **Fonoster Health:** http://localhost:3001/health

## Environment Variables

Create a `.env` file in the project root with:

```env
GEMINI_API_KEY=your_gemini_api_key_here
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
FONOSTER_ACCESS_KEY_ID=your_fonoster_access_key_id
FONOSTER_API_KEY=your_fonoster_api_key
FONOSTER_API_SECRET=your_fonoster_api_secret
FONOSTER_ENDPOINT=https://api.fonoster.com
FONOSTER_FROM_NUMBER=your_phone_number
```

Load environment variables in PowerShell:

```powershell
Get-Content .env | ForEach-Object {
    if ($_ -match '^([^#][^=]+)=(.*)$') {
        $name = $matches[1].Trim()
        $value = $matches[2].Trim()
        Set-Item -Path "env:$name" -Value $value
    }
}
```

## Troubleshooting

### Containers Not Starting

1. **Check Podman is running:**
   ```powershell
   podman info
   ```

2. **Check container logs:**
   ```powershell
   podman logs <container-name>
   ```

3. **Check network exists:**
   ```powershell
   podman network ls
   ```

### Port Already in Use

If ports are already in use:

1. **Find process using port:**
   ```powershell
   netstat -ano | findstr :3000
   ```

2. **Stop conflicting containers:**
   ```powershell
   podman stop $(podman ps -q)
   ```

### Network Issues

1. **Recreate network:**
   ```powershell
   podman network rm app-network
   podman network create app-network
   ```

2. **Restart containers:**
   ```powershell
   podman restart fonoster-server google-intelligent-backend google-intelligent-frontend
   ```

## Complete Deployment Script

Save as `start-podman.ps1`:

```powershell
# Load environment variables
if (Test-Path .env) {
    Get-Content .env | ForEach-Object {
        if ($_ -match '^([^#][^=]+)=(.*)$') {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            Set-Item -Path "env:$name" -Value $value
        }
    }
}

# Create network
podman network create app-network 2>&1 | Out-Null

# Start fonoster-server
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

Start-Sleep -Seconds 3

# Start backend
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

Start-Sleep -Seconds 3

# Start frontend
podman run -d `
  --name google-intelligent-frontend `
  --network app-network `
  -p 3000:3000 `
  -e NEXT_PUBLIC_API_URL=http://localhost:8000 `
  -e NODE_ENV=production `
  -e NEXT_TELEMETRY_DISABLED=1 `
  --restart unless-stopped `
  localhost/google-intelligent-frontend:latest

Write-Host "`nContainers started!" -ForegroundColor Green
podman ps
```

## Verification

After starting containers, verify they're running:

```powershell
podman ps
```

Test connectivity:

```powershell
# Backend health check
Invoke-WebRequest -Uri "http://localhost:8000/health"

# Frontend
Invoke-WebRequest -Uri "http://localhost:3000"

# Fonoster health check
Invoke-WebRequest -Uri "http://localhost:3001/health"
```

## Next Steps

1. **Build images** (if not already built)
2. **Start containers** using the commands above
3. **Access frontend** at http://localhost:3000
4. **Test the system** with sample queries

