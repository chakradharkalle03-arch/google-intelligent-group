# Docker Remote Deployment Guide

## Prerequisites

1. **Docker Desktop** must be installed and running
2. **PowerShell** (restart after starting Docker Desktop to get Docker in PATH)
3. **Environment variables** configured in `.env` file

## Quick Start

### Option 1: Using Deployment Script (Recommended)

1. **Start Docker Desktop** (if not already running)

2. **Restart PowerShell** to ensure Docker is in PATH

3. **Run deployment script:**
   ```powershell
   .\deploy-docker.ps1 -RemoteIP 192.168.0.101
   ```

### Option 2: Using Docker Compose Directly

1. **Start Docker Desktop**

2. **Restart PowerShell**

3. **Set environment variable:**
   ```powershell
   $env:NEXT_PUBLIC_API_URL = "http://192.168.0.101:8000"
   ```

4. **Build and start containers:**
   ```powershell
   docker-compose up -d --build
   ```

### Option 3: Manual Build and Start

1. **Build images:**
   ```powershell
   docker build -t fonoster-server:latest ./fonoster-server
   docker build -t google-intelligent-backend:latest ./backend
   docker build --build-arg NEXT_PUBLIC_API_URL=http://192.168.0.101:8000 -t google-intelligent-frontend:latest ./frontend
   ```

2. **Start containers:**
   ```powershell
   $env:NEXT_PUBLIC_API_URL = "http://192.168.0.101:8000"
   docker-compose up -d
   ```

## Remote Access Configuration

### Ports Exposed

- **Frontend:** `0.0.0.0:3000` (accessible from all interfaces)
- **Backend:** `0.0.0.0:8000` (accessible from all interfaces)
- **Fonoster:** `0.0.0.0:3001` (accessible from all interfaces)

### Remote Access URLs

- **Frontend:** http://192.168.0.101:3000
- **Backend:** http://192.168.0.101:8000
- **Fonoster:** http://192.168.0.101:3001

### Windows Firewall Configuration

To allow remote access, configure Windows Firewall:

```powershell
# Run as Administrator
.\configure-firewall.ps1
```

Or manually:
```powershell
New-NetFirewallRule -DisplayName "Docker Frontend" -Direction Inbound -LocalPort 3000 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "Docker Backend" -Direction Inbound -LocalPort 8000 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "Docker Fonoster" -Direction Inbound -LocalPort 3001 -Protocol TCP -Action Allow
```

## Troubleshooting

### Docker Not Found

**Problem:** `docker: command not found`

**Solutions:**
1. Start Docker Desktop
2. Restart PowerShell
3. Check if Docker is in PATH: `Get-Command docker`

### Docker Daemon Not Running

**Problem:** `Cannot connect to Docker daemon`

**Solutions:**
1. Start Docker Desktop
2. Wait for Docker to fully start
3. Verify: `docker info`

### Network Timeout During Build

**Problem:** `i/o timeout` when pulling images

**Solutions:**
1. Check internet connection
2. Check firewall settings
3. Try again (may be temporary)
4. Use proxy if behind corporate firewall

### Containers Not Accessible Remotely

**Problem:** Can access via localhost but not via IP

**Solutions:**
1. Verify ports are bound to `0.0.0.0` (not `127.0.0.1`)
2. Configure Windows Firewall
3. Check Docker Desktop network settings
4. Verify containers are running: `docker ps`

## Container Management

### View Running Containers
```powershell
docker ps
```

### View All Containers
```powershell
docker ps -a
```

### View Logs
```powershell
docker logs fonoster-server
docker logs google-intelligent-backend
docker logs google-intelligent-frontend
```

### Stop Containers
```powershell
docker-compose down
```

### Restart Containers
```powershell
docker-compose restart
```

### Remove All Containers and Images
```powershell
docker-compose down -v
docker system prune -a
```

## Files Created

- `docker-compose.yml` - Docker Compose configuration with remote access
- `deploy-docker.ps1` - Automated deployment script
- `deploy-docker-remote.ps1` - Alternative deployment script

## Next Steps

1. **Deploy containers** using one of the methods above
2. **Configure firewall** for remote access
3. **Test remote access** from another device on the network
4. **Access services** via http://192.168.0.101:3000

