# Podman Quick Deploy Guide
## 5-Minute Deployment

**Status:** ✅ Ready for deployment

---

## 🚀 Quick Start

### Prerequisites
- ✅ Podman Desktop installed
- ✅ WSL installed (Windows)
- ✅ Podman machine running
- ✅ Environment variables in `.env` file

### Deploy

```powershell
.\run-podman.ps1
```

**Or manually:**

```powershell
# 1. Build containers
cd backend && podman build -t google-intelligent-backend:latest -f Containerfile . && cd ..
cd frontend && podman build --build-arg NEXT_PUBLIC_API_URL=http://localhost:8000 -t google-intelligent-frontend:latest -f Containerfile . && cd ..
cd fonoster-server && podman build -t fonoster-server:latest -f Containerfile . && cd ..

# 2. Create network
podman network create app-network

# 3. Start containers
podman run -d --name fonoster-server --network app-network -p 3001:3001 fonoster-server:latest
podman run -d --name google-intelligent-backend --network app-network -p 8000:8000 -e GEMINI_API_KEY="your_key" -e GOOGLE_MAPS_API_KEY="your_key" -e FONOSTER_SERVER_URL="http://fonoster-server:3001" google-intelligent-backend:latest
podman run -d --name google-intelligent-frontend --network app-network -p 3000:3000 -e NEXT_PUBLIC_API_URL="http://localhost:8000" google-intelligent-frontend:latest
```

---

## 🌐 Access

- **Frontend:** http://localhost:3000
- **Backend:** http://localhost:8000
- **Fonoster:** http://localhost:3001

---

## 📋 Container Management

```powershell
# View containers
podman ps

# View logs
podman logs google-intelligent-backend
podman logs google-intelligent-frontend
podman logs fonoster-server

# Stop containers
podman stop fonoster-server google-intelligent-backend google-intelligent-frontend

# Remove containers
podman rm fonoster-server google-intelligent-backend google-intelligent-frontend
```

---

**Last Updated:** November 2025

