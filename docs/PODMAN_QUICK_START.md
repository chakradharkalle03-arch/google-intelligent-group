# Podman Quick Start
## 5-Minute Deployment Guide

**Deploy your entire application stack using Podman in 5 minutes!**

---

## ⚡ Quick Start

### Prerequisites Check

1. **Podman Desktop installed?**
   - If not: Download from https://podman-desktop.io
   - Install and start Podman Desktop

2. **WSL installed? (Windows only)**
   - Open PowerShell as Administrator
   - Run: `wsl --install`
   - Restart computer if needed

3. **Podman machine running?**
   ```powershell
   podman machine list
   podman info
   ```
   - If not running: Start Podman Desktop and wait 1-2 minutes

---

## 🚀 Deploy in 3 Steps

### Step 1: Prepare Environment (1 minute)

1. **Ensure `.env` file exists in project root:**
   ```env
   GEMINI_API_KEY=your_key_here
   GOOGLE_MAPS_API_KEY=your_key_here
   ```

2. **Or copy from backend:**
   ```bash
   cp backend/.env .env
   ```

### Step 2: Run Deployment Script (3 minutes)

**Windows:**
```powershell
.\run-podman.ps1
```

**Linux/Mac:**
```bash
chmod +x run-podman.sh
./run-podman.sh
```

The script will automatically:
- ✅ Build all containers
- ✅ Create network
- ✅ Start all services

### Step 3: Verify (1 minute)

```bash
# Check containers are running
podman ps

# Test endpoints
curl http://localhost:8000/health
curl http://localhost:3001/health
```

**Open browser:** http://localhost:3000

---

## ✅ Done!

Your application is now running:
- **Frontend:** http://localhost:3000
- **Backend:** http://localhost:8000
- **Fonoster:** http://localhost:3001

---

## 🆘 Troubleshooting

### "Podman machine does not exist"
```powershell
podman machine init
podman machine start
```

### "WSL not installed" (Windows)
```powershell
# Run as Administrator
wsl --install
# Restart computer
```

### "Port already in use"
```powershell
# Stop existing containers
podman stop $(podman ps -aq)

# Or change ports in run commands
```

---

## 📚 Full Documentation

For detailed instructions, see:
- `docs/PODMAN_DEPLOYMENT_GUIDE.md` - Complete guide
- `docs/PODMAN_WSL_REQUIREMENT.md` - WSL setup

---

**Last Updated:** November 2025

