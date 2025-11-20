# Podman Deployment Guide
## Google Intelligent Group Multi-Agent System

**Date:** November 2025

Complete guide for deploying the application using Podman containers.

---

## 📋 Prerequisites

### Required
- **Podman Desktop** installed (or Podman CLI)
- **WSL (Windows Subsystem for Linux)** - Required on Windows
- **Git** - For cloning repository
- **API Keys:**
  - Gemini API Key
  - Google Maps API Key
  - (Optional) Fonoster credentials

---

## 🔧 Initial Setup

### Step 1: Install WSL (Windows Only)

If you're on Windows and haven't installed WSL:

1. **Open PowerShell as Administrator**
2. **Run:**
   ```powershell
   wsl --install
   ```
3. **Restart your computer** when prompted
4. **After restart**, WSL will be ready

### Step 2: Start Podman Desktop

1. **Open Podman Desktop** from Start Menu
2. **Wait for Podman machine to initialize** (1-2 minutes)
3. **Verify machine is running:**
   - Look for "Running" status in Podman Desktop
   - Or run: `podman machine list`

### Step 3: Initialize Podman Machine (If Needed)

If machine doesn't exist:

```powershell
# Initialize Podman machine
podman machine init

# Start Podman machine
podman machine start

# Verify
podman info
```

---

## 🚀 Quick Deployment

### Option 1: Automated Script (Recommended)

**Windows:**
```powershell
.\run-podman.ps1
```

**Linux/Mac:**
```bash
chmod +x run-podman.sh
./run-podman.sh
```

The script will:
- ✅ Check Podman installation
- ✅ Load environment variables
- ✅ Build all containers
- ✅ Create network
- ✅ Start all services

### Option 2: Manual Deployment

Follow the step-by-step guide below.

---

## 📦 Step-by-Step Deployment

### Step 1: Prepare Environment Variables

1. **Create `.env` file in project root:**
   ```env
   # Backend API Keys (Required)
   GEMINI_API_KEY=your_gemini_api_key_here
   GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
   
   # Fonoster Configuration (Optional)
   FONOSTER_ACCESS_KEY_ID=
   FONOSTER_API_KEY=
   FONOSTER_API_SECRET=
   FONOSTER_ENDPOINT=https://api.fonoster.com
   FONOSTER_FROM_NUMBER=
   ```

2. **Or use existing `backend/.env`:**
   ```bash
   cp backend/.env .env
   ```

### Step 2: Build Containers

#### Build Backend Container

```bash
cd backend
podman build -t google-intelligent-backend:latest -f Containerfile .
cd ..
```

#### Build Frontend Container

```bash
cd frontend
podman build -t google-intelligent-frontend:latest -f Containerfile .
cd ..
```

#### Build Fonoster Server Container

```bash
cd fonoster-server
podman build -t fonoster-server:latest -f Containerfile .
cd ..
```

### Step 3: Create Network

```bash
podman network create app-network
```

### Step 4: Start Containers

#### Start Fonoster Server

```bash
podman run -d \
  --name fonoster-server \
  --network app-network \
  -p 3001:3001 \
  -e PORT=3001 \
  -e FONOSTER_ACCESS_KEY_ID="$FONOSTER_ACCESS_KEY_ID" \
  -e FONOSTER_API_KEY="$FONOSTER_API_KEY" \
  -e FONOSTER_API_SECRET="$FONOSTER_API_SECRET" \
  -e FONOSTER_ENDPOINT="$FONOSTER_ENDPOINT" \
  -e FONOSTER_FROM_NUMBER="$FONOSTER_FROM_NUMBER" \
  fonoster-server:latest
```

#### Start Backend

```bash
podman run -d \
  --name google-intelligent-backend \
  --network app-network \
  -p 8000:8000 \
  -e GEMINI_API_KEY="$GEMINI_API_KEY" \
  -e GOOGLE_MAPS_API_KEY="$GOOGLE_MAPS_API_KEY" \
  -e FONOSTER_SERVER_URL="http://fonoster-server:3001" \
  -e BACKEND_HOST=0.0.0.0 \
  -e BACKEND_PORT=8000 \
  -e PYTHONUNBUFFERED=1 \
  google-intelligent-backend:latest
```

#### Start Frontend

```bash
podman run -d \
  --name google-intelligent-frontend \
  --network app-network \
  -p 3000:3000 \
  -e NEXT_PUBLIC_API_URL="http://localhost:8000" \
  -e NODE_ENV=production \
  -e NEXT_TELEMETRY_DISABLED=1 \
  google-intelligent-frontend:latest
```

### Step 5: Verify Deployment

```bash
# Check container status
podman ps

# Check logs
podman logs google-intelligent-backend
podman logs google-intelligent-frontend
podman logs fonoster-server

# Test health endpoints
curl http://localhost:8000/health
curl http://localhost:3001/health
curl http://localhost:3000
```

---

## 🌐 Access Points

After deployment, access your application at:

- **Frontend:** http://localhost:3000
- **Backend API:** http://localhost:8000
- **Backend Health:** http://localhost:8000/health
- **Fonoster Server:** http://localhost:3001
- **Fonoster Health:** http://localhost:3001/health

---

## 🔄 Using Podman Compose (Alternative)

### Step 1: Update `podman-compose.yml`

Ensure your `podman-compose.yml` is configured correctly (already created).

### Step 2: Deploy with Compose

```bash
# Start all services
podman-compose up -d

# View logs
podman-compose logs -f

# Stop all services
podman-compose down
```

---

## 📊 Container Management

### View Running Containers

```bash
podman ps
```

### View All Containers (Including Stopped)

```bash
podman ps -a
```

### View Container Logs

```bash
# All logs
podman logs <container-name>

# Follow logs (like tail -f)
podman logs -f <container-name>

# Last 100 lines
podman logs --tail 100 <container-name>
```

### Stop Containers

```bash
# Stop individual container
podman stop <container-name>

# Stop all containers
podman stop fonoster-server google-intelligent-backend google-intelligent-frontend
```

### Start Containers

```bash
# Start individual container
podman start <container-name>

# Start all containers
podman start fonoster-server google-intelligent-backend google-intelligent-frontend
```

### Remove Containers

```bash
# Remove stopped container
podman rm <container-name>

# Remove all containers (stop first)
podman stop fonoster-server google-intelligent-backend google-intelligent-frontend
podman rm fonoster-server google-intelligent-backend google-intelligent-frontend
```

### View Container Images

```bash
podman images
```

### Remove Images

```bash
podman rmi <image-name>
```

---

## 🔧 Troubleshooting

### Issue: Podman machine not running

**Solution:**
```bash
# Start Podman machine
podman machine start

# Or initialize if doesn't exist
podman machine init
podman machine start
```

### Issue: WSL not installed (Windows)

**Solution:**
1. Open PowerShell as Administrator
2. Run: `wsl --install`
3. Restart computer
4. Start Podman Desktop

### Issue: Container build fails

**Solution:**
- Check build logs: `podman build -t <name> -f Containerfile .`
- Verify all files are present
- Check network connectivity for downloading dependencies

### Issue: Container won't start

**Solution:**
- Check logs: `podman logs <container-name>`
- Verify environment variables are set
- Check port conflicts: `netstat -an | grep <port>`
- Verify network exists: `podman network ls`

### Issue: Frontend can't connect to backend

**Solution:**
- Verify `NEXT_PUBLIC_API_URL` is set correctly
- Check backend is running: `podman ps`
- Check backend logs for errors
- Verify CORS settings in backend

### Issue: Port already in use

**Solution:**
```bash
# Find process using port (Windows)
netstat -ano | findstr :8000

# Stop the process or change port in container run command
```

---

## 🔐 Security Best Practices

1. **Environment Variables:**
   - Never commit `.env` files to Git
   - Use secrets management in production
   - Rotate API keys regularly

2. **Network Isolation:**
   - Use Podman networks for service isolation
   - Don't expose unnecessary ports

3. **Container Images:**
   - Use official base images
   - Keep images updated
   - Scan for vulnerabilities

4. **Non-root Users:**
   - Frontend container runs as non-root user
   - Backend should also use non-root in production

---

## 📈 Monitoring

### Health Checks

All containers have built-in health checks:

```bash
# Check container health
podman inspect <container-name> | grep -A 10 Health
```

### Resource Usage

```bash
# View container stats
podman stats

# View specific container
podman stats <container-name>
```

---

## 🔄 Updates and Maintenance

### Update Application Code

1. **Pull latest code:**
   ```bash
   git pull origin main
   ```

2. **Rebuild containers:**
   ```bash
   # Stop containers
   podman stop fonoster-server google-intelligent-backend google-intelligent-frontend
   
   # Rebuild
   cd backend && podman build -t google-intelligent-backend:latest -f Containerfile . && cd ..
   cd frontend && podman build -t google-intelligent-frontend:latest -f Containerfile . && cd ..
   cd fonoster-server && podman build -t fonoster-server:latest -f Containerfile . && cd ..
   
   # Remove old containers
   podman rm fonoster-server google-intelligent-backend google-intelligent-frontend
   
   # Start with new images (use run-podman.ps1 or manual commands)
   ```

### Update Dependencies

1. **Update `requirements.txt` or `package.json`**
2. **Rebuild containers** (see above)

---

## 🧹 Cleanup

### Remove All Containers

```bash
podman stop $(podman ps -aq)
podman rm $(podman ps -aq)
```

### Remove All Images

```bash
podman rmi google-intelligent-backend:latest
podman rmi google-intelligent-frontend:latest
podman rmi fonoster-server:latest
```

### Remove Network

```bash
podman network rm app-network
```

### Complete Cleanup

```bash
# Stop and remove all containers
podman stop fonoster-server google-intelligent-backend google-intelligent-frontend
podman rm fonoster-server google-intelligent-backend google-intelligent-frontend

# Remove images
podman rmi google-intelligent-backend:latest google-intelligent-frontend:latest fonoster-server:latest

# Remove network
podman network rm app-network
```

---

## 📚 Additional Resources

- **Podman Documentation:** https://docs.podman.io
- **Podman Desktop:** https://podman-desktop.io
- **WSL Documentation:** https://docs.microsoft.com/windows/wsl

---

## ✅ Deployment Checklist

- [ ] WSL installed (Windows)
- [ ] Podman Desktop installed and running
- [ ] Podman machine initialized and started
- [ ] Environment variables configured
- [ ] All containers built successfully
- [ ] Network created
- [ ] All containers running
- [ ] Health endpoints responding
- [ ] Frontend accessible
- [ ] Full query flow tested

---

**Last Updated:** November 2025

