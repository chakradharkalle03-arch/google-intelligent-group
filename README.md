# 🧠 Google Intelligent Group
## Multi-Agent System with LangChain 1.0 & Next.js

An intelligent Supervisor Agent System that coordinates multiple specialized agents to complete complex tasks, including automated restaurant reservations via telephony.

---

## 🎯 Project Overview

This project implements a multi-agent system where a Supervisor Agent coordinates specialized sub-agents:
- **GoogleMap Agent** - Finds nearby businesses
- **Calendar Agent** - Manages schedules and bookings
- **Telephone Agent** - Makes automated calls via Fonoster
- **Research Agent** - Performs research tasks

### Example Use Case
*"Find a nice Indian restaurant near Taipei 101 and make a dinner reservation for tomorrow at 7 PM."*

The system will:
1. Search for restaurants using GoogleMap Agent
2. Call the restaurant using Telephone Agent
3. Book the reservation using Calendar Agent
4. Return a summary via Supervisor Agent

---

## 🏗️ Architecture

```
Frontend (Next.js) → Backend (FastAPI) → LangChain Supervisor → SubAgents
                                              ↓
                                    Fonoster Server (Telephony)
```

---

## 📁 Project Structure

```
readlife/
├── frontend/          # Next.js frontend application
├── backend/           # Python FastAPI backend
├── fonoster-server/   # Node.js Fonoster service
└── docs/              # Documentation
```

---

## 🚀 Quick Start

### Prerequisites
- Node.js 18+
- Python 3.10+
- Git

### 1. Frontend Setup
```bash
cd frontend
npm install
npm run dev
# http://localhost:3000
```

### 2. Backend Setup
```bash
cd backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
cp env.example .env
# Add your API keys to .env
python main.py
# http://localhost:8000
```

### 3. Fonoster Server Setup
```bash
cd fonoster-server
npm install
cp env.example .env
# Add Fonoster credentials to .env (optional)
npm start
# http://localhost:3001
```

---

## 🔑 Environment Variables

### Backend (.env)
```env
GEMINI_API_KEY=your_gemini_api_key
GOOGLE_MAPS_API_KEY=your_google_maps_api_key
FONOSTER_SERVER_URL=http://localhost:3001
```

### Fonoster Server (.env)
```env
FONOSTER_ACCESS_KEY_ID=your_access_key_id
FONOSTER_API_KEY=your_api_key
FONOSTER_API_SECRET=your_api_secret
FONOSTER_FROM_NUMBER=+1234567890
PORT=3001
```

---

## 🧪 Testing

### Test Query:
```
Please help me find a good Indian restaurant near Taipei 101 and make a reservation for tomorrow at 7:00 PM
```

### Expected Results:
- ✅ GoogleMap Agent finds restaurants
- ✅ Telephone Agent initiates call
- ✅ Calendar Agent adds event at correct time (7:00 PM)
- ✅ Research Agent shows status
- ✅ Supervisor Agent coordinates everything

---

## ✅ Features

- ✅ Multi-agent coordination
- ✅ Real-time SSE streaming
- ✅ Time parsing (explicit times only)
- ✅ Fonoster SDK integration
- ✅ Error handling
- ✅ Beautiful UI

---

## 📚 Documentation

- `README.md` - This file
- `docs/PODMAN_DEPLOYMENT.md` - Complete Podman container deployment guide
- `docs/DEVELOPMENT_PLAN.md` - Development plan and architecture
- `fonoster-server/SETUP_GUIDE.md` - Fonoster setup
- `fonoster-server/FONOSTER_SDK_INTEGRATION.md` - SDK integration

---

## 🛠️ Technology Stack

- **Frontend:** Next.js 14, React, TypeScript
- **Backend:** FastAPI, Python 3.10+
- **AI:** LangChain 1.0, Google Gemini 2.5
- **Telephony:** Fonoster SDK
- **Maps:** Google Maps Places API

---

## 📋 Development Status

- ✅ **Phase 1:** Project Setup (Complete)
- ✅ **Phase 2:** Fonoster Integration (Complete)
- ✅ **Phase 3:** Frontend-Backend Integration (Complete)
- ✅ **Phase 4:** SubAgents Implementation (Complete)
- ✅ **Phase 5:** Supervisor Orchestration (Complete)
- ✅ **Phase 6:** Frontend Integration (Complete)
- ⏳ **Phase 7:** Deployment (Ready)

---

## 🚀 Deployment

### Podman Container Deployment (Local)

**Quick Start:**
```bash
# Windows PowerShell
.\start-podman.ps1

# Linux/macOS
chmod +x start-podman.sh
./start-podman.sh
```

**Manual Build & Run:**
```bash
# Build containers
cd backend && podman build -t readlife-backend:latest -f Containerfile . && cd ..
cd frontend && podman build -t readlife-frontend:latest -f Containerfile --build-arg NEXT_PUBLIC_API_URL=http://127.0.0.1:8000 . && cd ..

# Run containers
podman run -d --name readlife-backend -p 8000:8000 --env-file backend/.env readlife-backend:latest
podman run -d --name readlife-frontend -p 3000:3000 readlife-frontend:latest
```

See `docs/PODMAN_DEPLOYMENT.md` for complete documentation.

### AWS EC2 Deployment
- Frontend: Deploy Next.js app
- Backend: Deploy FastAPI server
- Fonoster: Deploy Node.js server
- Use Cloudflare for CDN and SSL

See deployment guides in `docs/` folder.

---

## 📝 License

MIT License

---

## 👥 Contributors

Developed as part of the Google Intelligent Group project.

---

## 🎉 Status

**✅ PROJECT COMPLETE AND READY FOR DEPLOYMENT**

All core features implemented and tested. Ready for production deployment.

**Date:** November 21, 2025  
**Version:** 1.0.0
