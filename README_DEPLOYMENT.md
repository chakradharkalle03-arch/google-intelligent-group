# 🚀 Quick Deployment Guide

## Podman Deployment (Local & Remote)

### Quick Start

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
.\deploy-podman.ps1 -Mode remote -RemoteHost "your-server-ip"
```

**Linux/Mac:**
```bash
./deploy-podman.sh remote "your-server-ip"
```

### What It Does

1. ✅ Checks Podman installation
2. ✅ Loads environment variables from `.env`
3. ✅ Builds all containers (backend, frontend, fonoster)
4. ✅ Creates network
5. ✅ Starts all services

### Access Points

- **Frontend:** http://localhost:3000 (or http://YOUR_SERVER_IP:3000)
- **Backend:** http://localhost:8000 (or http://YOUR_SERVER_IP:8000)
- **Fonoster:** http://localhost:3001 (or http://YOUR_SERVER_IP:3001)

### Prerequisites

- Podman installed
- `.env` file with API keys:
  ```
  GEMINI_API_KEY=your_key
  GOOGLE_MAPS_API_KEY=your_key
  ```

### Full Documentation

See `docs/PODMAN_DEPLOYMENT_COMPLETE.md` for detailed instructions.

---

**Last Updated:** November 2025

