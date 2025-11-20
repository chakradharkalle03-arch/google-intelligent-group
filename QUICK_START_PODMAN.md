# Quick Start Guide - Podman

Fastest way to get the project running with Podman containers.

## Prerequisites Check

```bash
# Verify Podman is installed
podman --version

# Should show: podman version X.X.X
```

## Quick Start (3 Steps)

### Step 1: Build Containers

**Windows PowerShell:**
```powershell
.\build-podman.ps1
```

**Linux/macOS:**
```bash
chmod +x build-podman.sh run-podman.sh
./build-podman.sh
```

**Manual build:**
```bash
# Backend
cd backend
podman build -t readlife-backend:latest -f Containerfile .
cd ..

# Frontend
cd frontend
podman build --build-arg NEXT_PUBLIC_API_URL=http://localhost:8080 -t readlife-frontend:latest -f Containerfile .
cd ..
```

### Step 2: Prepare Environment

Create `backend/.env` file (copy from `backend/env.example`):
```env
GEMINI_API_KEY=your_actual_api_key_here
PORT=8080
HOST=0.0.0.0
FONOSTER_SERVER_URL=http://localhost:3001
GOOGLE_MAPS_API_KEY=your_google_maps_key_here
```

### Step 3: Run Containers

**Windows PowerShell:**
```powershell
.\run-podman.ps1
```

**Linux/macOS:**
```bash
./run-podman.sh
```

**Manual run:**
```bash
# Create network
podman network create readlife-network

# Start backend
podman run -d \
  --name readlife-backend \
  --network readlife-network \
  -p 8080:8080 \
  --env-file backend/.env \
  readlife-backend:latest

# Start frontend
podman run -d \
  --name readlife-frontend \
  --network readlife-network \
  -p 3000:3000 \
  --env NEXT_PUBLIC_API_URL=http://readlife-backend:8080 \
  readlife-frontend:latest
```

## Verify It's Working

```bash
# Check containers are running
podman ps

# Check backend health
curl http://localhost:8080/health
# Or in PowerShell: Invoke-WebRequest http://localhost:8080/health

# Open in browser
# Frontend: http://localhost:3000
# Backend: http://localhost:8080
```

## Common Issues

### Network Connection Error During Build

If you get "no route to host" or "dial tcp" errors:

1. **Check internet connection**
2. **Try using a different registry:**
   ```bash
   podman build --pull-always --from docker.io/library/python:3.12-slim ...
   ```
3. **Use a mirror or proxy** (if behind corporate firewall)

### Port Already in Use

```bash
# Find what's using the port
# Windows:
netstat -ano | findstr :8080

# Linux/macOS:
lsof -i :8080

# Use a different port:
podman run -d --name readlife-backend -p 8081:8080 ...
```

### Container Won't Start

```bash
# Check logs
podman logs readlife-backend

# Run interactively to debug
podman run -it --rm readlife-backend:latest sh
```

### Frontend Can't Connect to Backend

1. **Verify both containers are on the same network:**
   ```bash
   podman network inspect readlife-network
   ```

2. **Check backend is accessible:**
   ```bash
   podman exec readlife-frontend wget -O- http://readlife-backend:8080/health
   ```

3. **If using localhost, ensure port mapping is correct:**
   ```bash
   podman port readlife-backend
   ```

## Stop and Cleanup

```bash
# Stop containers
podman stop readlife-backend readlife-frontend

# Remove containers
podman rm readlife-backend readlife-frontend

# Remove images (optional)
podman rmi readlife-backend:latest readlife-frontend:latest

# Remove network (optional)
podman network rm readlife-network
```

## Next Steps

- See `PODMAN_SETUP.md` for detailed documentation
- Check container logs: `podman logs -f readlife-backend`
- View container status: `podman ps -a`

