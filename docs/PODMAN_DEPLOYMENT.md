# Podman Deployment Guide

This guide explains how to build and run the frontend and backend containers using Podman.

## Prerequisites

1. **Podman installed** on your system
   - Windows: Install Podman Desktop or use WSL2 with Podman
   - Linux: Install via package manager (`sudo apt-get install podman` or `sudo dnf install podman`)
   - macOS: Install via Homebrew (`brew install podman`)

2. **Verify Podman installation:**
   ```bash
   podman --version
   ```

3. **Environment variables configured:**
   - Backend: Create `backend/.env` from `backend/env.example`
   - Frontend: No `.env` required (uses build-time args)

## Quick Start

### Option 1: Use Helper Scripts (Recommended)

**Windows (PowerShell):**
```powershell
.\start-podman.ps1
```

**Linux/macOS (Bash):**
```bash
chmod +x start-podman.sh
./start-podman.sh
```

The scripts will automatically:
- Check Podman installation
- Create `.env` file if needed
- Build both containers
- Start both containers
- Verify they're running

### Option 2: Manual Build and Run

### 1. Build the Containers

#### Build Backend Container

```bash
cd backend
podman build -t readlife-backend:latest -f Containerfile .
```

#### Build Frontend Container

```bash
cd frontend
podman build -t readlife-frontend:latest -f Containerfile --build-arg NEXT_PUBLIC_API_URL=http://127.0.0.1:8000 .
```

**Note:** Replace `http://127.0.0.1:8000` with your actual backend URL if different.

### 2. Run the Containers

#### Run Backend Container

```bash
podman run -d \
  --name readlife-backend \
  -p 8000:8000 \
  --env-file backend/.env \
  readlife-backend:latest
```

#### Run Frontend Container

```bash
podman run -d \
  --name readlife-frontend \
  -p 3000:3000 \
  readlife-frontend:latest
```

### 3. Verify Containers are Running

```bash
# List running containers
podman ps

# Check backend health
curl http://localhost:8000/health

# Check frontend (open in browser)
# http://localhost:3000
```

## Detailed Instructions

### Backend Container

#### Building the Backend

```bash
cd backend
podman build -t readlife-backend:latest -f Containerfile .
```

**Build options:**
- `-t readlife-backend:latest`: Tags the image with name and version
- `-f Containerfile`: Specifies the Containerfile to use
- `.`: Build context (current directory)

#### Running the Backend

**Basic run:**
```bash
podman run -d \
  --name readlife-backend \
  -p 8000:8000 \
  --env-file backend/.env \
  readlife-backend:latest
```

**With custom environment variables:**
```bash
podman run -d \
  --name readlife-backend \
  -p 8000:8000 \
  -e GEMINI_API_KEY=your_key_here \
  -e GOOGLE_MAPS_API_KEY=your_key_here \
  -e FONOSTER_SERVER_URL=http://localhost:3001 \
  -e PORT=8000 \
  -e HOST=0.0.0.0 \
  readlife-backend:latest
```

**Run options:**
- `-d`: Run in detached mode (background)
- `--name readlife-backend`: Container name
- `-p 8000:8000`: Map container port 8000 to host port 8000
- `--env-file backend/.env`: Load environment variables from file
- `-e KEY=value`: Set individual environment variables

#### Backend Environment Variables

Required variables (set in `backend/.env` or via `-e` flags):

- `GEMINI_API_KEY`: Google Gemini API key (required)
- `GOOGLE_MAPS_API_KEY`: Google Maps API key (required)
- `FONOSTER_SERVER_URL`: URL of Fonoster server (default: `http://localhost:3001`)
- `PORT`: Backend port (default: `8000`)
- `HOST`: Bind address (default: `0.0.0.0`)
- `ALLOWED_ORIGINS`: CORS allowed origins (default: `*`)

### Frontend Container

#### Building the Frontend

**Basic build:**
```bash
cd frontend
podman build -t readlife-frontend:latest -f Containerfile --build-arg NEXT_PUBLIC_API_URL=http://127.0.0.1:8000 .
```

**Build with custom API URL:**
```bash
podman build -t readlife-frontend:latest \
  -f Containerfile \
  --build-arg NEXT_PUBLIC_API_URL=http://your-backend-url:8000 \
  .
```

**Build options:**
- `-t readlife-frontend:latest`: Tags the image
- `-f Containerfile`: Specifies the Containerfile
- `--build-arg NEXT_PUBLIC_API_URL=...`: Sets the backend API URL for the Next.js build
- `.`: Build context

**Important:** The `NEXT_PUBLIC_API_URL` build argument determines the backend URL that the frontend will use. Make sure this matches your backend container's accessible URL.

#### Running the Frontend

**Basic run:**
```bash
podman run -d \
  --name readlife-frontend \
  -p 3000:3000 \
  readlife-frontend:latest
```

**With custom port:**
```bash
podman run -d \
  --name readlife-frontend \
  -p 8080:3000 \
  -e PORT=3000 \
  readlife-frontend:latest
```

**Run options:**
- `-d`: Run in detached mode
- `--name readlife-frontend`: Container name
- `-p 3000:3000`: Map container port 3000 to host port 3000
- `-e PORT=3000`: Set container port (optional, defaults to 3000)

## Container Management

### View Running Containers

```bash
podman ps
```

### View All Containers (including stopped)

```bash
podman ps -a
```

### View Container Logs

```bash
# Backend logs
podman logs readlife-backend

# Frontend logs
podman logs readlife-frontend

# Follow logs (real-time)
podman logs -f readlife-backend
```

### Stop Containers

```bash
podman stop readlife-backend
podman stop readlife-frontend
```

### Start Stopped Containers

```bash
podman start readlife-backend
podman start readlife-frontend
```

### Remove Containers

```bash
# Stop and remove
podman rm -f readlife-backend
podman rm -f readlife-frontend
```

### Remove Images

```bash
podman rmi readlife-backend:latest
podman rmi readlife-frontend:latest
```

## Running Both Containers Together

### Using Podman Compose (if available)

Create a `podman-compose.yml` file:

```yaml
version: '3.8'

services:
  backend:
    build:
      context: ./backend
      dockerfile: Containerfile
    container_name: readlife-backend
    ports:
      - "8000:8000"
    env_file:
      - ./backend/.env
    restart: unless-stopped

  frontend:
    build:
      context: ./frontend
      dockerfile: Containerfile
      args:
        NEXT_PUBLIC_API_URL: http://127.0.0.1:8000
    container_name: readlife-frontend
    ports:
      - "3000:3000"
    depends_on:
      - backend
    restart: unless-stopped
```

Then run:
```bash
podman-compose up -d
```

### Using a Simple Script

Create `start-containers.sh`:

```bash
#!/bin/bash

# Build containers
echo "Building backend..."
cd backend && podman build -t readlife-backend:latest -f Containerfile . && cd ..

echo "Building frontend..."
cd frontend && podman build -t readlife-frontend:latest -f Containerfile --build-arg NEXT_PUBLIC_API_URL=http://127.0.0.1:8000 . && cd ..

# Run backend
echo "Starting backend..."
podman run -d --name readlife-backend -p 8000:8000 --env-file backend/.env readlife-backend:latest

# Wait a moment for backend to start
sleep 2

# Run frontend
echo "Starting frontend..."
podman run -d --name readlife-frontend -p 3000:3000 readlife-frontend:latest

echo "Containers started!"
echo "Backend: http://localhost:8000"
echo "Frontend: http://localhost:3000"
```

Make it executable and run:
```bash
chmod +x start-containers.sh
./start-containers.sh
```

## Network Configuration

### Using Podman Networks

Create a custom network for container communication:

```bash
# Create network
podman network create readlife-network

# Run backend on network
podman run -d \
  --name readlife-backend \
  --network readlife-network \
  -p 8000:8000 \
  --env-file backend/.env \
  readlife-backend:latest

# Run frontend on network (update API URL to use container name)
podman build -t readlife-frontend:latest \
  -f frontend/Containerfile \
  --build-arg NEXT_PUBLIC_API_URL=http://readlife-backend:8000 \
  frontend/

podman run -d \
  --name readlife-frontend \
  --network readlife-network \
  -p 3000:3000 \
  readlife-frontend:latest
```

## Troubleshooting

### Container Won't Start

1. **Check logs:**
   ```bash
   podman logs readlife-backend
   podman logs readlife-frontend
   ```

2. **Verify environment variables:**
   ```bash
   podman exec readlife-backend env
   ```

3. **Check if port is already in use:**
   ```bash
   # Linux/macOS
   lsof -i :8000
   lsof -i :3000
   
   # Windows
   netstat -ano | findstr :8000
   netstat -ano | findstr :3000
   ```

### Frontend Can't Connect to Backend

1. **Verify backend is running:**
   ```bash
   curl http://localhost:8000/health
   ```

2. **Check if API URL is correct:**
   - The `NEXT_PUBLIC_API_URL` must be accessible from the browser
   - If using containers, use `http://localhost:8000` or the host's IP
   - If using a network, use the container name: `http://readlife-backend:8000`

3. **Check CORS settings:**
   - Ensure `ALLOWED_ORIGINS` in backend includes the frontend URL

### Build Failures

1. **Clear build cache:**
   ```bash
   podman builder prune
   ```

2. **Rebuild without cache:**
   ```bash
   podman build --no-cache -t readlife-backend:latest -f backend/Containerfile backend/
   ```

3. **Check for syntax errors in Containerfile:**
   - Ensure proper line endings (LF, not CRLF)
   - Verify all paths are correct

### Permission Issues (Linux)

If you encounter permission issues:

```bash
# Add your user to podman group (if using rootless)
sudo usermod -aG podman $USER
# Log out and log back in
```

Or run with sudo (not recommended for production):
```bash
sudo podman run ...
```

## Production Considerations

1. **Use specific image tags instead of `latest`:**
   ```bash
   podman build -t readlife-backend:v1.0.0 -f Containerfile .
   ```

2. **Set resource limits:**
   ```bash
   podman run -d \
     --name readlife-backend \
     --memory=512m \
     --cpus=1 \
     -p 8000:8000 \
     --env-file backend/.env \
     readlife-backend:latest
   ```

3. **Use secrets management:**
   - Store sensitive environment variables in Podman secrets
   - Or use external secret management systems

4. **Enable health checks:**
   - Health checks are already configured in the backend Containerfile
   - Monitor with: `podman inspect readlife-backend | grep -A 10 Health`

5. **Set up logging:**
   ```bash
   # Use journald or file logging
   podman run -d \
     --name readlife-backend \
     --log-driver journald \
     -p 8000:8000 \
     --env-file backend/.env \
     readlife-backend:latest
   ```

## Quick Reference Commands

```bash
# Build
podman build -t readlife-backend:latest -f backend/Containerfile backend/
podman build -t readlife-frontend:latest -f frontend/Containerfile --build-arg NEXT_PUBLIC_API_URL=http://127.0.0.1:8000 frontend/

# Run
podman run -d --name readlife-backend -p 8000:8000 --env-file backend/.env readlife-backend:latest
podman run -d --name readlife-frontend -p 3000:3000 readlife-frontend:latest

# Stop
podman stop readlife-backend readlife-frontend

# Start
podman start readlife-backend readlife-frontend

# Logs
podman logs -f readlife-backend
podman logs -f readlife-frontend

# Remove
podman rm -f readlife-backend readlife-frontend

# Clean up
podman rmi readlife-backend:latest readlife-frontend:latest
```

## Additional Resources

- [Podman Documentation](https://docs.podman.io/)
- [Podman Tutorial](https://podman.io/getting-started/)
- [Containerfile Best Practices](https://docs.podman.io/en/latest/markdown/podman-build.1.html)

---

**Last Updated:** November 2025

