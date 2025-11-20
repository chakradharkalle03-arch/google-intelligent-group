# Deployment Guide
## Google Intelligent Group Multi-Agent System

**Based on Actual Project Structure**

This guide provides step-by-step instructions for deploying the Google Intelligent Group Multi-Agent System based on the actual project components.

---

## 📋 Table of Contents

1. [Project Overview](#project-overview)
2. [Prerequisites](#prerequisites)
3. [Local Development Setup](#local-development-setup)
4. [Production Deployment](#production-deployment)
5. [Environment Configuration](#environment-configuration)
6. [Troubleshooting](#troubleshooting)

---

## 🎯 Project Overview

### Actual Project Structure

```
readlife/
├── frontend/              # Next.js 14 (React, TypeScript, Tailwind CSS v4)
│   ├── app/              # Next.js App Router
│   ├── package.json      # Next.js dependencies
│   └── next.config.js    # Next.js configuration
│
├── backend/              # Python Quart API (not FastAPI)
│   ├── agents/           # LangChain agents
│   │   ├── supervisor_langgraph.py  # LangGraph Supervisor
│   │   ├── agent_factory.py         # Agent creation
│   │   └── tools.py                 # LangChain tools
│   ├── blueprints/       # Quart blueprints (routers)
│   │   ├── query.py     # Query endpoint
│   │   └── health.py     # Health check
│   ├── main.py          # Quart app with Hypercorn
│   └── requirements.txt # Python dependencies
│
└── fonoster-server/      # Node.js Express server
    ├── server.js        # Express server with Fonoster SDK
    └── package.json     # Node.js dependencies
```

### Technology Stack (Actual)

- **Frontend:** Next.js 14, React, TypeScript, Tailwind CSS v4
- **Backend:** Quart (async Python web framework), Hypercorn (ASGI server)
- **AI Framework:** LangChain 1.0, LangGraph
- **LLM:** Google Gemini 2.5 Flash
- **Telephony:** Fonoster SDK (@fonoster/sdk)
- **Server:** Hypercorn (not Uvicorn)

---

## 🔧 Prerequisites

### Required Software

- **Node.js 18+** (for frontend and fonoster-server)
- **Python 3.10+** (for backend)
- **Git** (for cloning repository)
- **npm** or **yarn** (package manager)

### Required API Keys

- **Google Gemini API Key** - Get from https://ai.google.dev/
- **Google Maps API Key** - Get from https://console.cloud.google.com/
- **Fonoster Credentials** (optional) - For real phone calls

---

## 💻 Local Development Setup

### Step 1: Clone Repository

```bash
git clone https://github.com/chakradharkalle03-arch/google-intelligent-group.git
cd google-intelligent-group
```

### Step 2: Backend Setup (Quart + Hypercorn)

```bash
cd backend

# Create virtual environment
python -m venv venv

# Activate virtual environment
# Windows:
venv\Scripts\activate
# Linux/Mac:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Copy environment template
cp env.example .env

# Edit .env and add your API keys
# Required:
# - GEMINI_API_KEY
# - GOOGLE_MAPS_API_KEY
# - FONOSTER_SERVER_URL=http://localhost:3001
```

**Backend Dependencies (from requirements.txt):**
```
quart>=0.19.0
hypercorn>=0.14.0
pydantic>=2.7.4
python-dotenv>=1.0.0
langchain>=1.0.0
langchain-google-genai>=3.0.0
langchain-community>=0.3.0
langgraph>=1.0.0
httpx>=0.25.2
quart-cors>=0.7.0
```

**Run Backend:**
```bash
python main.py
# Server runs on http://127.0.0.1:8000
```

### Step 3: Frontend Setup (Next.js)

```bash
cd frontend

# Install dependencies
npm install

# Run development server
npm run dev
# Server runs on http://localhost:3000
```

**Frontend Dependencies:**
- Next.js 14
- React 18
- TypeScript
- Tailwind CSS v4
- Axios

**Frontend Configuration (next.config.js):**
```javascript
env: {
  NEXT_PUBLIC_API_URL: 'http://127.0.0.1:8000'
}
```

### Step 4: Fonoster Server Setup

```bash
cd fonoster-server

# Install dependencies
npm install

# Copy environment template
cp env.example .env

# Edit .env (optional - for real calls)
# FONOSTER_ACCESS_KEY_ID=...
# FONOSTER_API_KEY=...
# FONOSTER_API_SECRET=...
# PORT=3001

# Run server
npm start
# Server runs on http://localhost:3001
```

**Fonoster Server Dependencies:**
- Express
- @fonoster/sdk
- CORS
- dotenv

### Step 5: Run All Services

**Windows (PowerShell):**
```powershell
.\run_web.ps1
```

**Manual Start:**
1. Backend: `cd backend && python main.py`
2. Frontend: `cd frontend && npm run dev`
3. Fonoster: `cd fonoster-server && npm start`

---

## 🚀 Production Deployment

### Backend Deployment (Quart + Hypercorn)

#### Option 1: Using Hypercorn Directly

```bash
cd backend
source venv/bin/activate  # or venv\Scripts\activate on Windows

# Production mode
hypercorn main:app -b 0.0.0.0:8000 --workers 4
```

#### Option 2: Using PM2 (Process Manager)

```bash
# Install PM2
npm install -g pm2

# Create ecosystem file: backend/ecosystem.config.js
```

**ecosystem.config.js:**
```javascript
module.exports = {
  apps: [{
    name: 'google-intelligent-backend',
    script: 'main.py',
    interpreter: 'python',
    cwd: '/path/to/backend',
    env: {
      NODE_ENV: 'production'
    },
    instances: 4,
    exec_mode: 'cluster'
  }]
};
```

```bash
# Start with PM2
pm2 start ecosystem.config.js
pm2 save
pm2 startup
```

#### Option 3: Using systemd (Linux)

**Create service file: `/etc/systemd/system/google-intelligent-backend.service`**

```ini
[Unit]
Description=Google Intelligent Group Backend
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/google-intelligent-group/backend
Environment="PATH=/home/ubuntu/google-intelligent-group/backend/venv/bin"
ExecStart=/home/ubuntu/google-intelligent-group/backend/venv/bin/hypercorn main:app -b 0.0.0.0:8000
Restart=always

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl enable google-intelligent-backend
sudo systemctl start google-intelligent-backend
sudo systemctl status google-intelligent-backend
```

### Frontend Deployment (Next.js)

#### Step 1: Build for Production

```bash
cd frontend

# Build production bundle
npm run build

# Test production build locally
npm start
# Runs on http://localhost:3000
```

#### Step 2: Deploy with PM2

```bash
# Install PM2
npm install -g pm2

# Start Next.js production server
pm2 start npm --name "google-intelligent-frontend" -- start
pm2 save
```

#### Step 3: Deploy with systemd

**Create service file: `/etc/systemd/system/google-intelligent-frontend.service`**

```ini
[Unit]
Description=Google Intelligent Group Frontend
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/google-intelligent-group/frontend
Environment="NODE_ENV=production"
Environment="NEXT_PUBLIC_API_URL=http://your-backend-url:8000"
ExecStart=/usr/bin/npm start
Restart=always

[Install]
WantedBy=multi-user.target
```

### Fonoster Server Deployment

```bash
cd fonoster-server

# Using PM2
pm2 start npm --name "fonoster-server" -- start
pm2 save

# Or using systemd (similar to backend)
```

---

## ⚙️ Environment Configuration

### Backend Environment Variables (.env)

```env
# Required
GEMINI_API_KEY=your_gemini_api_key_here
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here

# Backend Configuration
BACKEND_HOST=0.0.0.0
BACKEND_PORT=8000

# Fonoster Server URL
FONOSTER_SERVER_URL=http://localhost:3001
# Production: FONOSTER_SERVER_URL=http://your-fonoster-server:3001
```

### Frontend Environment Variables

**Development (.env.local):**
```env
NEXT_PUBLIC_API_URL=http://127.0.0.1:8000
```

**Production (.env.production):**
```env
NEXT_PUBLIC_API_URL=http://your-backend-domain:8000
```

**Or set in next.config.js:**
```javascript
env: {
  NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL || 'http://127.0.0.1:8000'
}
```

### Fonoster Server Environment Variables (.env)

```env
# Optional - for real phone calls
FONOSTER_ACCESS_KEY_ID=your_access_key_id
FONOSTER_API_KEY=your_api_key
FONOSTER_API_SECRET=your_api_secret
FONOSTER_ENDPOINT=https://api.fonoster.com

# Server Configuration
PORT=3001
```

---

## 🔒 Security Considerations

### 1. CORS Configuration

**Backend (main.py):**
```python
from quart_cors import cors
app = cors(app, allow_origin="*")  # Change to specific domain in production
```

**Production:**
```python
app = cors(app, allow_origin="https://your-frontend-domain.com")
```

### 2. Environment Variables

- Never commit `.env` files to Git
- Use environment variable management in production
- Rotate API keys regularly

### 3. Firewall Rules

- Backend: Open port 8000
- Frontend: Open port 3000 (or use reverse proxy)
- Fonoster: Open port 3001

---

## 🌐 Reverse Proxy Setup (Nginx)

### Nginx Configuration for Backend

```nginx
server {
    listen 80;
    server_name api.yourdomain.com;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

### Nginx Configuration for Frontend

```nginx
server {
    listen 80;
    server_name yourdomain.com;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

---

## 🐛 Troubleshooting

### Backend Issues

**Problem:** Hypercorn not starting
```bash
# Check if port 8000 is in use
netstat -ano | findstr :8000  # Windows
lsof -i :8000                 # Linux/Mac

# Check Python version
python --version  # Should be 3.10+

# Reinstall dependencies
pip install -r requirements.txt --force-reinstall
```

**Problem:** Import errors
```bash
# Ensure virtual environment is activated
source venv/bin/activate  # Linux/Mac
venv\Scripts\activate     # Windows

# Check if all dependencies installed
pip list
```

### Frontend Issues

**Problem:** Build errors
```bash
# Clear Next.js cache
rm -rf .next
npm run build
```

**Problem:** API connection errors
```bash
# Check NEXT_PUBLIC_API_URL in next.config.js
# Ensure backend is running on correct port
```

### Fonoster Server Issues

**Problem:** Server not starting
```bash
# Check if port 3001 is in use
netstat -ano | findstr :3001  # Windows
lsof -i :3001                 # Linux/Mac

# Check Node.js version
node --version  # Should be 18+

# Reinstall dependencies
rm -rf node_modules package-lock.json
npm install
```

---

## ✅ Production Checklist

- [ ] All environment variables configured
- [ ] API keys set and tested
- [ ] Backend running on production port (8000)
- [ ] Frontend built and running (3000)
- [ ] Fonoster server running (3001)
- [ ] CORS configured for production domain
- [ ] Reverse proxy configured (if using)
- [ ] SSL certificates installed (if using HTTPS)
- [ ] Process manager configured (PM2/systemd)
- [ ] Logging configured
- [ ] Monitoring set up
- [ ] Backup strategy in place

---

## 📚 Additional Resources

- **Backend Code:** `backend/main.py` - Quart application
- **Frontend Code:** `frontend/app/page.tsx` - Main UI
- **Fonoster Server:** `fonoster-server/server.js` - Telephony service
- **Agent Code:** `backend/agents/supervisor_langgraph.py` - LangGraph Supervisor
- **Documentation:** See `docs/` folder for detailed architecture

---

## 📝 Notes

- This project uses **Quart** (not FastAPI) as the backend framework
- Uses **Hypercorn** (not Uvicorn) as the ASGI server
- Uses **LangGraph** for multi-agent orchestration
- Frontend uses **Tailwind CSS v4** for styling
- All services can run locally for development
- Production deployment requires proper process management

---

**Last Updated:** November 2025  
**Project Version:** 1.0.0

