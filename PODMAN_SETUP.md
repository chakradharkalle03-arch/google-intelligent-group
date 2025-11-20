# Podman Container Setup Guide

Complete guide for building and running the Google Intelligent Group project using Podman containers.

## Prerequisites

1. **Install Podman**
   - **Windows**: Install [Podman Desktop](https://podman-desktop.io/) or use WSL2 with Podman
   - **Linux**: `sudo apt-get install podman` (Ubuntu/Debian) or `sudo dnf install podman` (Fedora/RHEL)
   - **macOS**: `brew install podman` or use Podman Desktop

2. **Verify Installation**
   ```bash
   podman --version
   ```

3. **Environment Variables**
   - Create `.env` files in `backend/` and `fonoster-server/` directories (see `env.example` files)
   - Required: `GEMINI_API_KEY` for the backend
   - Optional: `GOOGLE_MAPS_API_KEY`, Fonoster credentials

## Project Structure

```
readlife/
├── backend/
│   ├── Containerfile          # Backend container definition
│   ├── requirements.txt       # Python dependencies
│   └── .env                   # Backend environment variables
├── frontend/
│   ├── Containerfile          # Frontend container definition
│   ├── package.json           # Node.js dependencies
│   └── .env.local             # Frontend environment variables (optional)
└── fonoster-server/
    ├── server.js              # Fonoster server
    └── .env                   # Fonoster environment variables
```

## Building Containers

### Build Backend Container

```bash
cd backend
podman build -t readlife-backend:latest -f Containerfile .
```

**Build Arguments** (optional):
```bash
podman build \
  --build-arg PORT=8080 \
  -t readlife-backend:latest \
  -f Containerfile .
```

### Build Frontend Container

```bash
cd frontend
podman build \
  --build-arg NEXT_PUBLIC_API_URL=http://localhost:8080 \
  -t readlife-frontend:latest \
  -f Containerfile .
```

**Note**: The `NEXT_PUBLIC_API_URL` should point to where the backend will be accessible. For local development with port mapping, use `http://localhost:8080`.

## Running Containers

### Option 1: Run Containers Individually

#### Start Backend Container

```bash
podman run -d \
  --name readlife-backend \
  -p 8080:8080 \
  --env-file backend/.env \
  -e PORT=8080 \
  -e HOST=0.0.0.0 \
  readlife-backend:latest
```

#### Start Frontend Container

```bash
podman run -d \
  --name readlife-frontend \
  -p 3000:3000 \
  --env NEXT_PUBLIC_API_URL=http://localhost:8080 \
  readlife-frontend:latest
```

#### Start Fonoster Server (Optional)

```bash
cd fonoster-server
podman run -d \
  --name readlife-fonoster \
  -p 3001:3001 \
  --env-file .env \
  -e PORT=3001 \
  node:18-alpine sh -c "npm install && npm start"
```

### Option 2: Using Podman Compose (if available)

Create a `podman-compose.yml` file (see below) and run:

```bash
podman-compose up -d
```

### Option 3: Using Helper Scripts

Use the provided PowerShell scripts:

**Windows PowerShell:**
```powershell
.\build-podman.ps1
.\run-podman.ps1
```

**Linux/macOS:**
```bash
chmod +x build-podman.sh run-podman.sh
./build-podman.sh
./run-podman.sh
```

## Container Networking

By default, containers run in isolated networks. To allow containers to communicate:

### Create a Podman Network

```bash
podman network create readlife-network
```

### Run Containers on the Network

```bash
# Backend
podman run -d \
  --name readlife-backend \
  --network readlife-network \
  -p 8080:8080 \
  --env-file backend/.env \
  readlife-backend:latest

# Frontend
podman run -d \
  --name readlife-frontend \
  --network readlife-network \
  -p 3000:3000 \
  --env NEXT_PUBLIC_API_URL=http://readlife-backend:8080 \
  readlife-frontend:latest
```

**Note**: When using a shared network, the frontend can reference the backend by container name (`readlife-backend`) instead of `localhost`.

## Environment Variables

### Backend (.env)

```env
GEMINI_API_KEY=your_gemini_api_key_here
PORT=8080
HOST=0.0.0.0
FONOSTER_SERVER_URL=http://localhost:3001
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
```

### Frontend

The frontend uses `NEXT_PUBLIC_API_URL` which can be set:
- At build time: `--build-arg NEXT_PUBLIC_API_URL=...`
- At runtime: `--env NEXT_PUBLIC_API_URL=...` (if using runtime config)

### Fonoster Server (.env)

```env
FONOSTER_ACCESS_KEY_ID=WO00000000000000000000000000000000
FONOSTER_API_KEY=your_fonoster_api_key_here
FONOSTER_API_SECRET=your_fonoster_api_secret_here
FONOSTER_ENDPOINT=https://api.fonoster.com
FONOSTER_FROM_NUMBER=+1234567890
PORT=3001
```

## Managing Containers

### View Running Containers

```bash
podman ps
```

### View Container Logs

```bash
# Backend logs
podman logs readlife-backend

# Follow logs
podman logs -f readlife-backend

# Frontend logs
podman logs readlife-frontend
```

### Stop Containers

```bash
podman stop readlife-backend readlife-frontend readlife-fonoster
```

### Start Stopped Containers

```bash
podman start readlife-backend readlife-frontend readlife-fonoster
```

### Remove Containers

```bash
podman rm readlife-backend readlife-frontend readlife-fonoster
```

### Remove Images

```bash
podman rmi readlife-backend:latest readlife-frontend:latest
```

## Health Checks

### Check Backend Health

```bash
curl http://localhost:8080/health
```

Or in PowerShell:
```powershell
Invoke-WebRequest -Uri http://localhost:8080/health
```

### Check Frontend

```bash
curl http://localhost:3000
```

### Check Fonoster

```bash
curl http://localhost:3001/health
```

## Troubleshooting

### Port Already in Use

If you get "port already in use" errors:

1. **Find the process using the port:**
   ```bash
   # Windows
   netstat -ano | findstr :8080
   
   # Linux/macOS
   lsof -i :8080
   ```

2. **Stop the process or use a different port:**
   ```bash
   podman run -d --name readlife-backend -p 8081:8080 ...
   ```

### Container Won't Start

1. **Check logs:**
   ```bash
   podman logs readlife-backend
   ```

2. **Check if environment variables are set:**
   ```bash
   podman exec readlife-backend env
   ```

3. **Run interactively to debug:**
   ```bash
   podman run -it --rm readlife-backend:latest sh
   ```

### Frontend Can't Connect to Backend

1. **Verify backend is running:**
   ```bash
   curl http://localhost:8080/health
   ```

2. **Check NEXT_PUBLIC_API_URL:**
   - If containers are on the same network, use container name: `http://readlife-backend:8080`
   - If using port mapping, use: `http://localhost:8080`

3. **Check CORS settings** in backend if accessing from browser

### Permission Errors (Linux)

If you get permission errors on Linux:

```bash
# Add your user to the podman group
sudo usermod -aG podman $USER
# Log out and back in
```

Or run with sudo (not recommended):
```bash
sudo podman run ...
```

## Complete Example: Full Stack Setup

```bash
# 1. Build containers
cd backend && podman build -t readlife-backend:latest -f Containerfile . && cd ..
cd frontend && podman build --build-arg NEXT_PUBLIC_API_URL=http://localhost:8080 -t readlife-frontend:latest -f Containerfile . && cd ..

# 2. Create network (optional)
podman network create readlife-network

# 3. Start backend
podman run -d \
  --name readlife-backend \
  --network readlife-network \
  -p 8080:8080 \
  --env-file backend/.env \
  readlife-backend:latest

# 4. Start frontend
podman run -d \
  --name readlife-frontend \
  --network readlife-network \
  -p 3000:3000 \
  --env NEXT_PUBLIC_API_URL=http://readlife-backend:8080 \
  readlife-frontend:latest

# 5. Verify
curl http://localhost:8080/health
curl http://localhost:3000
```

## Access URLs

Once containers are running:

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8080
- **Backend Health**: http://localhost:8080/health
- **Fonoster API**: http://localhost:3001 (if running)

## Next Steps

- See `docs/` for detailed architecture documentation
- Check `backend/README.md` and `frontend/README.md` for service-specific details
- Review `PODMAN_DEPLOYMENT.md` for production deployment guidance

