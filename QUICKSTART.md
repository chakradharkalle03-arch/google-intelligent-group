# 🚀 Quick Start Guide

## Phase 1 Complete ✅

All Phase 1 objectives have been completed:

- ✅ GitHub repositories structure created
- ✅ Local dev environments set up (Next.js, Python, LangChain, Fonoster)
- ✅ Development Plan & Task Breakdown delivered

---

## 🏃 Running the Project

### Option 1: Automated Setup (Recommended)

**Windows:**
```powershell
.\setup.ps1
```

**Linux/Mac:**
```bash
chmod +x setup.sh
./setup.sh
```

### Option 2: Manual Setup

#### 1. Frontend (Next.js)
```bash
cd frontend
npm install
npm run dev
```
Open http://localhost:3000

#### 2. Backend (Python FastAPI)
```bash
cd backend
python -m venv venv

# Windows
venv\Scripts\activate

# Linux/Mac
source venv/bin/activate

pip install -r requirements.txt
cp env.example .env
# Edit .env with your API keys
python main.py
```
API available at http://localhost:8000

#### 3. Fonoster Server (Node.js)
```bash
cd fonoster-server
npm install
cp env.example .env
# Edit .env with Fonoster credentials
npm start
```
Server available at http://localhost:3001

---

## 🔑 Required API Keys

Before running, you need to configure:

### Backend (.env)
- `GEMINI_API_KEY` - Get from https://ai.google.dev/
- `GOOGLE_MAPS_API_KEY` - Get from https://console.cloud.google.com/
- `FONOSTER_SERVER_URL` - Default: http://localhost:3001

### Fonoster Server (.env)
- `FONOSTER_API_KEY` - From Fonoster setup
- `FONOSTER_API_SECRET` - From Fonoster setup

---

## 📁 Project Structure

```
readlife/
├── frontend/              # Next.js app (port 3000)
│   ├── app/              # React components
│   └── package.json
│
├── backend/              # FastAPI server (port 8000)
│   ├── agents/           # LangChain agents (to be implemented)
│   ├── main.py          # API server
│   └── requirements.txt
│
├── fonoster-server/      # Node.js server (port 3001)
│   ├── server.js        # Express server
│   └── package.json
│
└── docs/                 # Documentation
    └── DEVELOPMENT_PLAN.md
```

---

## ✅ Verification

After setup, verify each service:

1. **Frontend:** http://localhost:3000 - Should show the UI
2. **Backend:** http://localhost:8000/docs - Should show API docs
3. **Fonoster:** http://localhost:3001/health - Should return `{"status":"healthy"}`

---

## 🎯 What's Next?

Phase 1 is complete! Ready for **Phase 2: Fonoster Deployment & Call Test**

See [DEVELOPMENT_PLAN.md](docs/DEVELOPMENT_PLAN.md) for next steps.

---

## 🐛 Troubleshooting

**Port already in use?**
- Change ports in respective config files
- Frontend: `next.config.js` or `package.json`
- Backend: `main.py` (port 8000)
- Fonoster: `server.js` (port 3001)

**Python virtual environment issues?**
- Make sure Python 3.10+ is installed
- Use `python -m venv venv` instead of `virtualenv`

**Node modules issues?**
- Delete `node_modules` and `package-lock.json`
- Run `npm install` again

---

**Phase 1 Status:** ✅ COMPLETE  
**Ready for Phase 2:** ✅ YES

