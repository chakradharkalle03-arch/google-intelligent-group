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
*"Find a nice Italian restaurant near Taipei 101 and make a dinner reservation for tomorrow at 7 PM."*

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
# Add Fonoster credentials to .env
npm start
# http://localhost:3001
```

---

## 📋 Development Phases

- ✅ **Phase 1:** Project Kickoff & Environment Setup (COMPLETE)
- ✅ **Phase 2:** Fonoster Deployment & Call Test (COMPLETE)
- ✅ **Phase 3:** Frontend-Backend Integration (COMPLETE)
- ✅ **Phase 4:** SubAgents Functionality Check (COMPLETE)
- ✅ **Phase 5:** Supervisor Agent Orchestration (COMPLETE)
- ✅ **Phase 6:** Frontend Integration & Pre-Deployment (COMPLETE - 11/21)
- ⏳ **Phase 7:** Final Delivery & Public Launch (Due: 11/24)

See [Development Plan](docs/DEVELOPMENT_PLAN.md) for detailed breakdown.

---

## 🛠️ Tech Stack

- **Frontend:** Next.js 14, React, TypeScript
- **Backend:** FastAPI, Python
- **AI:** LangChain 1.0, Google Gemini 2.5
- **Telephony:** Fonoster
- **Deployment:** AWS EC2, Cloudflare

---

## 📚 Documentation

- [Development Plan & Task Breakdown](docs/DEVELOPMENT_PLAN.md)
- [Frontend README](frontend/README.md)
- [Backend README](backend/README.md)
- [Fonoster Server README](fonoster-server/README.md)

---

## 🔑 Environment Variables

### Backend
- `GEMINI_API_KEY` - Google Gemini API key
- `GOOGLE_MAPS_API_KEY` - Google Maps API key
- `FONOSTER_SERVER_URL` - Fonoster server URL

### Fonoster Server
- `FONOSTER_API_KEY` - Fonoster API key
- `FONOSTER_API_SECRET` - Fonoster API secret

---

## 📝 License

MIT

---

## 👥 Contributors

Project developed for Google Intelligent Group initiative.

---

**Status:** ✅ **FULLY FUNCTIONAL** | All core features complete | Ready for deployment

See [PROJECT_COMPLETE.md](PROJECT_COMPLETE.md) for completion summary.

