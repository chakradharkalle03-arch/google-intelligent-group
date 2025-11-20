# Podman Installation Guide for Windows
## Google Intelligent Group Multi-Agent System

This guide explains how to install Podman on Windows to run the containerized application.

---

## 🔧 Installation Options

### Option 1: Podman Desktop (Recommended)

**Podman Desktop** is the easiest way to run Podman on Windows.

#### Steps:

1. **Download Podman Desktop**
   - Visit: https://podman-desktop.io/downloads
   - Download the Windows installer

2. **Install Podman Desktop**
   - Run the installer
   - Follow the installation wizard
   - Podman Desktop includes Podman engine

3. **Verify Installation**
   ```powershell
   podman --version
   podman info
   ```

4. **Start Podman**
   - Open Podman Desktop application
   - Wait for Podman machine to start
   - Verify it's running in the status bar

---

### Option 2: WSL2 with Podman

If you have WSL2 (Windows Subsystem for Linux) installed:

#### Steps:

1. **Install WSL2** (if not already installed)
   ```powershell
   wsl --install
   ```

2. **Install Podman in WSL2**
   ```bash
   # In WSL2 terminal
   sudo apt update
   sudo apt install -y podman
   ```

3. **Verify Installation**
   ```bash
   podman --version
   ```

4. **Run containers from WSL2**
   ```bash
   cd /mnt/c/Users/user/Downloads/readlife
   ./run-podman.sh
   ```

---

### Option 3: Use Docker Desktop (Alternative)

If Podman is not available, you can use Docker Desktop as an alternative:

#### Steps:

1. **Install Docker Desktop**
   - Visit: https://www.docker.com/products/docker-desktop
   - Download and install Docker Desktop for Windows

2. **Use Docker instead of Podman**
   - Replace `podman` commands with `docker`
   - The Containerfiles are compatible with Docker

3. **Run with Docker**
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

## ✅ Verification

After installation, verify Podman is working:

```powershell
# Check version
podman --version

# Check system info
podman info

# Test with a simple container
podman run hello-world
```

---

## 🚀 After Installation

Once Podman is installed, you can run the project:

### Quick Start (PowerShell)

```powershell
cd C:\Users\user\Downloads\readlife
.\run-podman.ps1
```

### Manual Build and Run

```powershell
# Build containers
cd backend
podman build -t google-intelligent-backend:latest -f Containerfile .
cd ../frontend
podman build -t google-intelligent-frontend:latest -f Containerfile .
cd ../fonoster-server
podman build -t fonoster-server:latest -f Containerfile .
cd ..

# Create network
podman network create app-network

# Run containers
podman run -d --name fonoster-server --network app-network -p 3001:3001 fonoster-server:latest
podman run -d --name google-intelligent-backend --network app-network -p 8000:8000 -e GEMINI_API_KEY=your_key -e GOOGLE_MAPS_API_KEY=your_key google-intelligent-backend:latest
podman run -d --name google-intelligent-frontend --network app-network -p 3000:3000 -e NEXT_PUBLIC_API_URL=http://localhost:8000 google-intelligent-frontend:latest
```

---

## 🐛 Troubleshooting

### Podman machine not starting

**Issue:** Podman machine fails to start

**Solution:**
1. Open Podman Desktop
2. Go to Settings → Resources
3. Increase memory allocation (minimum 2GB)
4. Restart Podman machine

### WSL2 integration issues

**Issue:** Podman in WSL2 not accessible from Windows

**Solution:**
- Use Podman commands directly in WSL2 terminal
- Or use Docker Desktop which has better Windows integration

### Port conflicts

**Issue:** Ports 3000, 8000, or 3001 already in use

**Solution:**
```powershell
# Find process using port
netstat -ano | findstr :8000

# Stop the process or change port in Containerfile
```

---

## 📚 Additional Resources

- **Podman Desktop:** https://podman-desktop.io/
- **Podman Documentation:** https://docs.podman.io/
- **WSL2 Documentation:** https://docs.microsoft.com/en-us/windows/wsl/

---

## 📝 Notes

- **Containerfiles are compatible with both Podman and Docker**
- **If Podman is not available, use Docker as an alternative**
- **All container files are ready and tested**
- **Environment variables can be set via .env file or command line**

---

**Last Updated:** November 2025

