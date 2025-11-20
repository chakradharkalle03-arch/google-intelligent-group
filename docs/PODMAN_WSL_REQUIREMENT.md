# Podman WSL Requirement
## Google Intelligent Group Multi-Agent System

**Date:** November 2025

---

## ⚠️ Issue Identified

Podman Desktop on Windows requires **WSL (Windows Subsystem for Linux)** to be installed, but it's not currently installed on your system.

**Error Message:**
```
The Windows Subsystem for Linux is not installed.
You can install by running 'wsl.exe --install'.
```

---

## ✅ Solution: Install WSL

### Step 1: Install WSL

Open PowerShell **as Administrator** and run:

```powershell
wsl --install
```

This will:
- Install WSL2 (latest version)
- Install a default Linux distribution (Ubuntu)
- Set up the necessary components

**Note:** You may need to restart your computer after installation.

### Step 2: Verify WSL Installation

After restarting, verify WSL is installed:

```powershell
wsl --version
wsl --list --verbose
```

You should see output showing WSL version and installed distributions.

### Step 3: Start Podman Desktop

1. Open **Podman Desktop** from Start Menu
2. Wait for Podman machine to initialize (1-2 minutes)
3. Look for "Running" status in Podman Desktop

### Step 4: Verify Podman Connection

In PowerShell (restart if needed):

```powershell
podman --version
podman info
```

You should see Podman system information without errors.

---

## 🚀 Alternative: Use Docker Desktop

If you prefer not to install WSL, you can use **Docker Desktop** instead:

### Option A: Docker Desktop (No WSL Required)

1. **Download Docker Desktop:**
   - Visit: https://www.docker.com/products/docker-desktop
   - Download and install Docker Desktop for Windows

2. **Start Docker Desktop:**
   - Open Docker Desktop from Start Menu
   - Wait for Docker to start (1-2 minutes)

3. **Use Docker Commands:**
   - Replace `podman` with `docker` in all commands
   - Containerfiles are compatible with Docker

### Example Docker Commands:

```powershell
# Build containers
docker build -t google-intelligent-backend:latest -f backend/Containerfile backend/
docker build -t google-intelligent-frontend:latest -f frontend/Containerfile frontend/
docker build -t fonoster-server:latest -f fonoster-server/Containerfile fonoster-server/

# Create network
docker network create app-network

# Run containers
docker run -d --name fonoster-server --network app-network -p 3001:3001 fonoster-server:latest
docker run -d --name google-intelligent-backend --network app-network -p 8000:8000 -e GEMINI_API_KEY=your_key -e GOOGLE_MAPS_API_KEY=your_key google-intelligent-backend:latest
docker run -d --name google-intelligent-frontend --network app-network -p 3000:3000 -e NEXT_PUBLIC_API_URL=http://localhost:8000 google-intelligent-frontend:latest
```

---

## 📋 Quick Installation Guide

### For WSL + Podman:

1. **Open PowerShell as Administrator**
2. **Run:** `wsl --install`
3. **Restart computer**
4. **Start Podman Desktop**
5. **Verify:** `podman --version`
6. **Run:** `.\run-podman.ps1`

### For Docker Desktop:

1. **Download:** https://www.docker.com/products/docker-desktop
2. **Install and start Docker Desktop**
3. **Verify:** `docker --version`
4. **Use Docker commands** (replace `podman` with `docker`)

---

## 🔍 Current Status

- ✅ Podman Desktop: Installed
- ✅ Podman CLI: Available (version 5.7.0)
- ❌ WSL: Not installed (required for Podman)
- ❌ Podman Machine: Cannot initialize without WSL

---

## 📝 Next Steps

**Choose one:**

1. **Install WSL** → Restart → Start Podman Desktop → Run containers
2. **Install Docker Desktop** → Use Docker commands instead

Both options will work with the existing container files!

---

## 📚 Additional Resources

- **WSL Installation:** https://aka.ms/wslinstall
- **Podman Desktop:** https://podman-desktop.io/
- **Docker Desktop:** https://www.docker.com/products/docker-desktop

---

**Last Updated:** November 2025

