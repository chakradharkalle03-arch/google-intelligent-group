# Podman Container Setup - Complete Guide

This project is now fully configured to run with Podman containers. All Containerfiles, scripts, and documentation are ready.

## 📁 Files Created/Updated

### Containerfiles
- ✅ `backend/Containerfile` - Backend Python/Quart container (port 8080)
- ✅ `frontend/Containerfile` - Frontend Next.js container (port 3000)

### Documentation
- ✅ `PODMAN_SETUP.md` - Complete setup guide with all details
- ✅ `QUICK_START_PODMAN.md` - Quick reference for getting started
- ✅ `PODMAN_README.md` - This file (overview)

### Helper Scripts
- ✅ `build-podman.ps1` - Windows PowerShell build script
- ✅ `run-podman.ps1` - Windows PowerShell run script
- ✅ `build-podman.sh` - Linux/macOS build script
- ✅ `run-podman.sh` - Linux/macOS run script

### Code Updates
- ✅ `backend/main.py` - Updated to handle both Windows local dev and container environments

## 🚀 Quick Start

### Option 1: Use Helper Scripts (Recommended)

**Windows:**
```powershell
# Build containers
.\build-podman.ps1

# Run containers
.\run-podman.ps1
```

**Linux/macOS:**
```bash
# Make scripts executable
chmod +x build-podman.sh run-podman.sh

# Build containers
./build-podman.sh

# Run containers
./run-podman.sh
```

### Option 2: Manual Commands

```bash
# 1. Build backend
cd backend
podman build -t readlife-backend:latest -f Containerfile .
cd ..

# 2. Build frontend
cd frontend
podman build --build-arg NEXT_PUBLIC_API_URL=http://localhost:8080 -t readlife-frontend:latest -f Containerfile .
cd ..

# 3. Create network
podman network create readlife-network

# 4. Run backend
podman run -d \
  --name readlife-backend \
  --network readlife-network \
  -p 8080:8080 \
  --env-file backend/.env \
  readlife-backend:latest

# 5. Run frontend
podman run -d \
  --name readlife-frontend \
  --network readlife-network \
  -p 3000:3000 \
  --env NEXT_PUBLIC_API_URL=http://readlife-backend:8080 \
  readlife-frontend:latest
```

## 📋 Prerequisites

1. **Podman installed** - See `PODMAN_SETUP.md` for installation instructions
2. **Environment variables** - Create `backend/.env` from `backend/env.example`
3. **Required API keys:**
   - `GEMINI_API_KEY` (required)
   - `GOOGLE_MAPS_API_KEY` (optional, for GoogleMap agent)
   - Fonoster credentials (optional, for Telephone agent)

## 🌐 Access URLs

Once containers are running:

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8080
- **Backend Health**: http://localhost:8080/health

## 🔧 Container Configuration

### Backend Container
- **Base Image**: `python:3.12-slim`
- **Port**: 8080
- **Host**: 0.0.0.0 (in container)
- **Health Check**: Built-in at `/health`
- **Environment**: Loads from `backend/.env`

### Frontend Container
- **Base Image**: `node:18-alpine` (multi-stage build)
- **Port**: 3000
- **Build Mode**: Standalone (optimized for containers)
- **API URL**: Configurable via build arg or env var

## 📚 Documentation

- **`PODMAN_SETUP.md`** - Complete guide with troubleshooting
- **`QUICK_START_PODMAN.md`** - Fast reference guide
- **`backend/README.md`** - Backend-specific documentation
- **`frontend/README.md`** - Frontend-specific documentation

## 🛠️ Management Commands

```bash
# View running containers
podman ps

# View logs
podman logs -f readlife-backend
podman logs -f readlife-frontend

# Stop containers
podman stop readlife-backend readlife-frontend

# Start stopped containers
podman start readlife-backend readlife-frontend

# Remove containers
podman rm readlife-backend readlife-frontend

# Remove images
podman rmi readlife-backend:latest readlife-frontend:latest
```

## 🔍 Verification

After starting containers, verify they're working:

```bash
# Check container status
podman ps

# Test backend health
curl http://localhost:8080/health
# PowerShell: Invoke-WebRequest http://localhost:8080/health

# Test frontend
curl http://localhost:3000
```

## ⚠️ Troubleshooting

See `PODMAN_SETUP.md` for detailed troubleshooting, or `QUICK_START_PODMAN.md` for common issues.

Common issues:
- Port conflicts → Use different ports or stop conflicting services
- Network errors during build → Check internet connection
- Container won't start → Check logs with `podman logs <container-name>`
- Frontend can't connect → Verify both containers are on same network

## 📝 Notes

- Containers use port **8080** for backend (not 8000) to avoid Windows permission issues
- Frontend is built with `standalone` output mode for optimal container size
- Containers run as non-root users for security
- Health checks are configured for both containers
- Network isolation is used for container-to-container communication
- **Containerfiles are compatible with both Docker and Podman**
- **Docker is recommended for Windows** (better networking support)
- **Podman works once networking is configured** (see `fix-podman-networking.ps1`)

## 🎯 Next Steps

1. Build and run containers using the scripts above
2. Access the frontend at http://localhost:3000
3. Test the API at http://localhost:8080/health
4. Review logs if any issues occur
5. See `PODMAN_SETUP.md` for advanced configuration

---

**Ready to go!** 🚀 Use the helper scripts or manual commands above to get started.

