# Podman Deployment Guide
## Local & Remote Deployment

**Complete guide for deploying the Multi-Agent System using Podman containers.**

---

## 📋 Prerequisites

### Required
- **Podman** installed (version 4.0+)
- **WSL** (Windows only) - Required for Podman Desktop
- **API Keys:**
  - Gemini API Key
  - Google Maps API Key
  - (Optional) Fonoster credentials

### For Remote Deployment
- **SSH access** to remote server
- **Podman installed** on remote server
- **Firewall rules** configured (ports 3000, 8000, 3001)

---

## 🚀 Quick Start

### Local Deployment

**Windows:**
```powershell
.\deploy-podman.ps1
```

**Linux/Mac:**
```bash
chmod +x deploy-podman.sh
./deploy-podman.sh
```

### Remote Deployment

**Windows:**
```powershell
.\deploy-podman.ps1 -Mode remote -RemoteHost "your-server-ip" -RemoteUser "user" -RemoteKey "path/to/key"
```

**Linux/Mac:**
```bash
./deploy-podman.sh remote "your-server-ip" "user" "path/to/key"
```

---

## 📦 Manual Deployment Steps

### Step 1: Build Containers

#### Backend
```bash
cd backend
podman build -t google-intelligent-backend:latest -f Containerfile .
cd ..
```

#### Frontend
```bash
cd frontend
# For local deployment
podman build --build-arg NEXT_PUBLIC_API_URL=http://localhost:8000 -t google-intelligent-frontend:latest -f Containerfile .

# For remote deployment
podman build --build-arg NEXT_PUBLIC_API_URL=http://YOUR_SERVER_IP:8000 -t google-intelligent-frontend:latest -f Containerfile .
cd ..
```

#### Fonoster Server
```bash
cd fonoster-server
podman build -t fonoster-server:latest -f Containerfile .
cd ..
```

### Step 2: Create Network

```bash
podman network create app-network
```

### Step 3: Start Containers

#### Start Fonoster Server
```bash
podman run -d \
  --name fonoster-server \
  --network app-network \
  -p 3001:3001 \
  -e PORT=3001 \
  fonoster-server:latest
```

#### Start Backend
```bash
podman run -d \
  --name google-intelligent-backend \
  --network app-network \
  -p 8000:8000 \
  -e GEMINI_API_KEY="your_gemini_key" \
  -e GOOGLE_MAPS_API_KEY="your_maps_key" \
  -e FONOSTER_SERVER_URL="http://fonoster-server:3001" \
  -e BACKEND_HOST=0.0.0.0 \
  -e BACKEND_PORT=8000 \
  google-intelligent-backend:latest
```

#### Start Frontend
```bash
# Local deployment
podman run -d \
  --name google-intelligent-frontend \
  --network app-network \
  -p 3000:3000 \
  -e NEXT_PUBLIC_API_URL="http://localhost:8000" \
  google-intelligent-frontend:latest

# Remote deployment (replace YOUR_SERVER_IP)
podman run -d \
  --name google-intelligent-frontend \
  --network app-network \
  -p 3000:3000 \
  -e NEXT_PUBLIC_API_URL="http://YOUR_SERVER_IP:8000" \
  google-intelligent-frontend:latest
```

---

## 🌐 Remote Deployment

### Option 1: Deploy on Remote Server Directly

1. **Copy project to remote server:**
   ```bash
   scp -r . user@remote-server:/path/to/project
   ```

2. **SSH into remote server:**
   ```bash
   ssh user@remote-server
   ```

3. **Run deployment script:**
   ```bash
   cd /path/to/project
   ./deploy-podman.sh
   ```

### Option 2: Build Locally, Push to Remote

1. **Build containers locally:**
   ```bash
   ./deploy-podman.ps1 -Mode remote -RemoteHost "your-server-ip"
   ```

2. **Export images:**
   ```bash
   podman save google-intelligent-backend:latest -o backend.tar
   podman save google-intelligent-frontend:latest -o frontend.tar
   podman save fonoster-server:latest -o fonoster.tar
   ```

3. **Transfer to remote server:**
   ```bash
   scp *.tar user@remote-server:/tmp/
   ```

4. **Load on remote server:**
   ```bash
   ssh user@remote-server
   podman load -i /tmp/backend.tar
   podman load -i /tmp/frontend.tar
   podman load -i /tmp/fonoster.tar
   ```

5. **Start containers on remote:**
   ```bash
   # Follow Step 3 from Manual Deployment
   ```

### Option 3: Using Podman Compose

1. **Update `podman-compose.yml`** with remote host settings

2. **Deploy:**
   ```bash
   podman-compose up -d
   ```

---

## 🔧 Configuration

### Environment Variables

Create `.env` file in project root:

```env
# Required
GEMINI_API_KEY=your_gemini_api_key
GOOGLE_MAPS_API_KEY=your_google_maps_api_key

# Optional - Fonoster
FONOSTER_ACCESS_KEY_ID=
FONOSTER_API_KEY=
FONOSTER_API_SECRET=
FONOSTER_ENDPOINT=https://api.fonoster.com
FONOSTER_FROM_NUMBER=
```

### Port Configuration

- **Frontend:** 3000
- **Backend:** 8000
- **Fonoster:** 3001

For remote deployment, ensure these ports are open in firewall.

---

## 📊 Container Management

### View Running Containers
```bash
podman ps
```

### View Container Logs
```bash
podman logs google-intelligent-backend
podman logs google-intelligent-frontend
podman logs fonoster-server

# Follow logs
podman logs -f google-intelligent-backend
```

### Stop Containers
```bash
podman stop fonoster-server google-intelligent-backend google-intelligent-frontend
```

### Start Containers
```bash
podman start fonoster-server google-intelligent-backend google-intelligent-frontend
```

### Remove Containers
```bash
podman stop fonoster-server google-intelligent-backend google-intelligent-frontend
podman rm fonoster-server google-intelligent-backend google-intelligent-frontend
```

### Remove Images
```bash
podman rmi google-intelligent-backend:latest
podman rmi google-intelligent-frontend:latest
podman rmi fonoster-server:latest
```

---

## 🔍 Troubleshooting

### Issue: Podman machine not running (Windows)

**Solution:**
```powershell
podman machine start
# Or open Podman Desktop and wait for initialization
```

### Issue: Port already in use

**Solution:**
```bash
# Find process using port
netstat -ano | grep :8000  # Windows
lsof -i :8000              # Linux/Mac

# Stop the process or change port in container run command
```

### Issue: Frontend can't connect to backend (Remote)

**Solution:**
1. Verify `NEXT_PUBLIC_API_URL` is set to remote server IP
2. Check firewall rules allow port 8000
3. Verify backend is accessible: `curl http://YOUR_SERVER_IP:8000/health`

### Issue: Containers can't communicate

**Solution:**
```bash
# Verify network exists
podman network ls

# Recreate network if needed
podman network rm app-network
podman network create app-network

# Restart containers
```

### Issue: Build fails

**Solution:**
- Check internet connection (for downloading dependencies)
- Verify all files are present
- Check build logs: `podman build -t test -f Containerfile .`

---

## 🔐 Security Best Practices

1. **Environment Variables:**
   - Never commit `.env` files
   - Use secrets management in production
   - Rotate API keys regularly

2. **Network Security:**
   - Use Podman networks for isolation
   - Don't expose unnecessary ports
   - Use firewall rules for remote deployment

3. **Container Security:**
   - Use official base images
   - Keep images updated
   - Scan for vulnerabilities

4. **Remote Deployment:**
   - Use SSH keys instead of passwords
   - Enable firewall on remote server
   - Use reverse proxy (nginx/traefik) for HTTPS

---

## 📈 Monitoring

### Health Checks

All containers have built-in health checks:

```bash
# Check container health
podman inspect google-intelligent-backend | grep -A 10 Health
```

### Resource Usage

```bash
# View container stats
podman stats

# View specific container
podman stats google-intelligent-backend
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
   
   # Restart with new images (use deploy script)
   ```

---

## ✅ Deployment Checklist

### Local Deployment
- [ ] Podman installed
- [ ] Podman machine running (Windows)
- [ ] Environment variables configured
- [ ] All containers built
- [ ] Network created
- [ ] All containers running
- [ ] Application accessible at http://localhost:3000

### Remote Deployment
- [ ] Remote server has Podman installed
- [ ] SSH access configured
- [ ] Firewall rules configured
- [ ] Environment variables configured
- [ ] Containers built with correct API URLs
- [ ] All containers running
- [ ] Application accessible at http://YOUR_SERVER_IP:3000

---

## 📚 Additional Resources

- **Podman Documentation:** https://docs.podman.io
- **Podman Desktop:** https://podman-desktop.io
- **WSL Documentation:** https://docs.microsoft.com/windows/wsl

---

**Last Updated:** November 2025

