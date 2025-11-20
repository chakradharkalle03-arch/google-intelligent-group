# Project Structure Documentation
## Google Intelligent Group Multi-Agent System

**Based on Actual Project Files**

This document describes the actual structure and components of the project as it exists in the codebase.

---

## 📁 Directory Structure

```
readlife/
│
├── backend/                    # Python Backend (Quart + Hypercorn)
│   ├── agents/                 # LangChain Agents
│   │   ├── __init__.py
│   │   ├── supervisor_langgraph.py    # LangGraph Supervisor Agent
│   │   ├── supervisor.py              # Legacy Supervisor (not used)
│   │   ├── agent_factory.py           # Agent creation factory
│   │   ├── tools.py                    # LangChain tool definitions
│   │   ├── googlemap_agent.py         # GoogleMap Agent
│   │   ├── calendar_agent.py          # Calendar Agent
│   │   ├── telephone_agent.py         # Telephone Agent
│   │   └── research_agent.py          # Research Agent
│   │
│   ├── blueprints/             # Quart Blueprints (Routers)
│   │   ├── __init__.py
│   │   ├── query.py           # Query processing endpoint
│   │   └── health.py           # Health check endpoint
│   │
│   ├── main.py                # Main Quart application
│   ├── requirements.txt       # Python dependencies
│   ├── env.example           # Environment variable template
│   ├── .env                  # Environment variables (not in git)
│   └── README.md             # Backend documentation
│
├── frontend/                  # Next.js Frontend
│   ├── app/                  # Next.js App Router
│   │   ├── page.tsx         # Main page component
│   │   ├── layout.tsx       # Root layout
│   │   ├── globals.css      # Global styles (Tailwind CSS v4)
│   │   └── page.module.css # Page-specific styles
│   │
│   ├── package.json         # Node.js dependencies
│   ├── next.config.js       # Next.js configuration
│   ├── tailwind.config.js   # Tailwind CSS configuration
│   ├── postcss.config.js    # PostCSS configuration
│   ├── tsconfig.json        # TypeScript configuration
│   └── README.md            # Frontend documentation
│
├── fonoster-server/          # Node.js Fonoster Service
│   ├── server.js            # Express server with Fonoster SDK
│   ├── package.json         # Node.js dependencies
│   ├── env.example         # Environment variable template
│   ├── .env                # Environment variables (not in git)
│   ├── README.md           # Fonoster server documentation
│   ├── SETUP_GUIDE.md      # Setup instructions
│   └── FONOSTER_SDK_INTEGRATION.md  # SDK integration guide
│
├── docs/                    # Documentation
│   ├── DEPLOYMENT_GUIDE_ACTUAL.md    # Accurate deployment guide
│   ├── DEPLOYMENT_GUIDE.md           # Original deployment guide
│   ├── AGENT_CODE_EXPLANATION.md     # Agent code explanation
│   ├── AGENT_CODE_EXPLANATION_FOR_WORD.md  # Word-ready version
│   ├── TASK_WORKFLOW_ARCHITECTURE.md # Workflow documentation
│   └── DEVELOPMENT_PLAN.md          # Development plan
│
├── documents/               # Word document versions
│   ├── DEPLOYMENT_GUIDE_ACTUAL.docx
│   ├── AGENT_CODE_EXPLANATION.docx
│   ├── AGENT_CODE_EXPLANATION_FOR_WORD.docx
│   ├── DEPLOYMENT_GUIDE.docx
│   ├── DEVELOPMENT_PLAN.docx
│   └── TASK_WORKFLOW_ARCHITECTURE.docx
│
├── frontend-output/         # Frontend UI documentation
│   ├── README.md           # UI documentation
│   └── frontend_UI_pannel.png  # UI screenshot
│
├── run_web.ps1             # PowerShell script to start all servers
├── README.md               # Main project README
└── .gitignore              # Git ignore rules
```

---

## 🔧 Technology Stack (Actual)

### Backend
- **Framework:** Quart 0.19.0+ (async Python web framework)
- **Server:** Hypercorn 0.14.0+ (ASGI server)
- **AI Framework:** LangChain 1.0+, LangGraph 1.0+
- **LLM:** Google Gemini 2.5 Flash (via langchain-google-genai)
- **CORS:** quart-cors 0.7.0+
- **HTTP Client:** httpx 0.25.2+
- **Python Version:** 3.10+

### Frontend
- **Framework:** Next.js 14 (App Router)
- **Language:** TypeScript
- **UI Library:** React 18
- **Styling:** Tailwind CSS v4.1.17
- **HTTP Client:** Axios 1.6.0
- **Node.js Version:** 18+

### Fonoster Server
- **Framework:** Express 4.18.2
- **SDK:** @fonoster/sdk 0.15.21
- **CORS:** cors 2.8.5
- **Node.js Version:** 18+

---

## 📝 Key Files and Their Purpose

### Backend Files

#### `backend/main.py`
- Main Quart application entry point
- Initializes Supervisor Agent (LangGraph)
- Registers blueprints (query, health)
- Configures Hypercorn server
- **Port:** 8000 (127.0.0.1 for local, 0.0.0.0 for production)

#### `backend/agents/supervisor_langgraph.py`
- LangGraph-based Supervisor Agent
- Orchestrates multi-agent workflow
- Implements DAG (Directed Acyclic Graph)
- Manages agent state and routing

#### `backend/agents/agent_factory.py`
- Creates LangChain agents with tools
- Factory pattern for agent creation
- Configures system prompts and tools

#### `backend/agents/tools.py`
- Defines LangChain tools (@tool decorators)
- Tools: search_nearby_places, add_calendar_event, make_phone_call, research_query

#### `backend/blueprints/query.py`
- Handles POST /query endpoint
- Streams responses via Server-Sent Events (SSE)
- Processes user queries through Supervisor

#### `backend/blueprints/health.py`
- Handles GET /health endpoint
- Health check for monitoring

### Frontend Files

#### `frontend/app/page.tsx`
- Main UI component
- Two-column layout (Manus-style)
- Left: Supervisor Agent result, Task Status, Input
- Right: Agent outputs (Map, Calendar, Telephone, Research)
- Handles SSE streaming from backend

#### `frontend/app/globals.css`
- Global styles with Tailwind CSS v4
- Custom animations and gradients
- Light theme design

#### `frontend/next.config.js`
- Next.js configuration
- API URL configuration
- Proxy settings for backend

### Fonoster Server Files

#### `fonoster-server/server.js`
- Express server for telephony operations
- Integrates Fonoster SDK
- Handles call initiation
- Falls back to simulation mode if credentials not configured

---

## 🔑 Environment Variables

### Backend (`backend/.env`)
```env
GEMINI_API_KEY=your_gemini_api_key
GOOGLE_MAPS_API_KEY=your_google_maps_api_key
FONOSTER_SERVER_URL=http://localhost:3001
BACKEND_HOST=0.0.0.0
BACKEND_PORT=8000
```

### Frontend (`frontend/.env.local` or `next.config.js`)
```env
NEXT_PUBLIC_API_URL=http://127.0.0.1:8000
```

### Fonoster Server (`fonoster-server/.env`)
```env
FONOSTER_ACCESS_KEY_ID=your_access_key_id
FONOSTER_API_KEY=your_api_key
FONOSTER_API_SECRET=your_api_secret
FONOSTER_ENDPOINT=https://api.fonoster.com
PORT=3001
```

---

## 🚀 Running the Project

### Quick Start (Windows)
```powershell
.\run_web.ps1
```

### Manual Start

**1. Backend:**
```bash
cd backend
venv\Scripts\activate  # Windows
# or: source venv/bin/activate  # Linux/Mac
python main.py
```

**2. Frontend:**
```bash
cd frontend
npm run dev
```

**3. Fonoster Server:**
```bash
cd fonoster-server
npm start
```

---

## 📊 API Endpoints

### Backend (http://127.0.0.1:8000)

- `GET /health` - Health check
- `POST /query` - Process user query (streams SSE response)

### Frontend (http://localhost:3000)

- Main UI at root `/`

### Fonoster Server (http://localhost:3001)

- `POST /call` - Initiate phone call

---

## 🎯 Agent Architecture

### Supervisor Agent (LangGraph)
- **File:** `backend/agents/supervisor_langgraph.py`
- **Purpose:** Orchestrates all sub-agents
- **Workflow:** Plan → Route → Execute Agents → Summarize

### Sub-Agents

1. **GoogleMap Agent**
   - **File:** `backend/agents/googlemap_agent.py`
   - **Tool:** `search_nearby_places`
   - **Purpose:** Find nearby businesses

2. **Calendar Agent**
   - **File:** `backend/agents/calendar_agent.py`
   - **Tool:** `add_calendar_event`, `list_calendar_events`
   - **Purpose:** Manage calendar events

3. **Telephone Agent**
   - **File:** `backend/agents/telephone_agent.py`
   - **Tool:** `make_phone_call`
   - **Purpose:** Make phone calls via Fonoster

4. **Research Agent**
   - **File:** `backend/agents/research_agent.py`
   - **Tool:** `research_query`
   - **Purpose:** Perform research tasks

---

## 📚 Documentation Files

### Markdown Documentation
- `docs/DEPLOYMENT_GUIDE_ACTUAL.md` - Accurate deployment guide
- `docs/AGENT_CODE_EXPLANATION.md` - Agent code explanation
- `docs/TASK_WORKFLOW_ARCHITECTURE.md` - Workflow architecture
- `docs/DEVELOPMENT_PLAN.md` - Development plan

### Word Documentation
- All markdown files converted to `.docx` in `documents/` folder

---

## ✅ Project Status

- ✅ Backend: Quart + Hypercorn (fully functional)
- ✅ Frontend: Next.js 14 with Tailwind CSS v4 (fully functional)
- ✅ Agents: LangGraph Supervisor with 4 sub-agents (fully functional)
- ✅ Fonoster: Integrated with SDK (simulation mode available)
- ✅ Documentation: Complete and accurate
- ✅ Deployment: Ready for production

---

**Last Updated:** November 2025  
**Project Version:** 1.0.0

