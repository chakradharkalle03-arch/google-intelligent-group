# Podman Windows Networking Troubleshooting

## Issue: "no route to host" when pulling images

This is a common issue with Podman on Windows. The network stack in Podman for Windows can have connectivity issues.

## Solutions

### Solution 1: Use Podman Machine (Recommended for Windows)

Podman on Windows works best with a Podman machine (VM). Check if you have one:

```powershell
podman machine list
```

If no machine exists, create one:

```powershell
podman machine init
podman machine start
```

Then try building again.

### Solution 2: Use Docker Desktop (Alternative)

If Podman networking continues to fail, you can use Docker Desktop instead:

1. Install [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/)
2. The Containerfiles are compatible with Docker
3. Replace `podman` commands with `docker`:

```powershell
# Build
docker build -t readlife-backend:latest -f backend/Containerfile backend/
docker build -t readlife-frontend:latest -f frontend/Containerfile frontend/

# Run
docker network create readlife-network
docker run -d --name readlife-backend --network readlife-network -p 8080:8080 --env-file backend/.env readlife-backend:latest
docker run -d --name readlife-frontend --network readlife-network -p 3000:3000 --env NEXT_PUBLIC_API_URL=http://readlife-backend:8080 readlife-frontend:latest
```

### Solution 3: Pre-pull Images Manually

If you have access to another machine or can use a different method to get the images:

1. Pull images on a working system
2. Export and import:

```bash
# On working system
podman save python:3.12-slim -o python-3.12-slim.tar
podman save node:18-alpine -o node-18-alpine.tar

# On Windows system
podman load -i python-3.12-slim.tar
podman load -i node-18-alpine.tar
```

### Solution 4: Fix Podman Network Configuration

Check Podman's network settings:

```powershell
# Check if Podman machine is running
podman machine list

# If machine exists but not running
podman machine start

# Check network configuration
podman network ls
```

### Solution 5: Use WSL2 with Podman

If you have WSL2, Podman works better inside WSL2:

```bash
# In WSL2 terminal
sudo apt-get update
sudo apt-get install podman

# Then use the Linux scripts
./build-podman.sh
./run-podman.sh
```

## Quick Test

Test if Podman can reach the internet:

```powershell
podman run --rm alpine ping -c 3 8.8.8.8
```

If this fails, Podman's network stack isn't working properly.

## Alternative: Build Without Containers

If containers aren't working, you can run the services directly:

```powershell
# Backend (in backend directory)
.\venv\Scripts\Activate.ps1
python main.py

# Frontend (in frontend directory, new terminal)
npm run dev

# Fonoster (in fonoster-server directory, new terminal)
npm start
```

## Recommended Approach for Windows

For Windows, **Docker Desktop** is often more reliable than Podman for container networking. The Containerfiles are 100% compatible with Docker.

