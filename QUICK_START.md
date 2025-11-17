# 🚀 Quick Start Guide

## Prerequisites Check

Before starting, ensure you have:
- ✅ Python 3.10+ installed
- ✅ Node.js 18+ installed
- ✅ API Keys ready:
  - Gemini API Key
  - Google Maps API Key

---

## Step 1: Setup Backend

```powershell
# Navigate to backend
cd backend

# Activate virtual environment (if not already activated)
.\venv\Scripts\activate

# Install dependencies (if not already installed)
pip install -r requirements.txt

# Create .env file (if not exists)
if (-not (Test-Path ".env")) {
    Copy-Item "env.example" ".env"
    Write-Host "⚠️  Please edit .env and add your API keys!" -ForegroundColor Yellow
}

# Check .env file
notepad .env
```

**Required in `.env`:**
```env
GEMINI_API_KEY=your_actual_key_here
GOOGLE_MAPS_API_KEY=your_actual_key_here
FONOSTER_SERVER_URL=http://localhost:3001
```

---

## Step 2: Setup Frontend

```powershell
# Navigate to frontend
cd frontend

# Install dependencies (if not already installed)
npm install

# Optional: Create .env.local for custom API URL
# NEXT_PUBLIC_API_URL=http://127.0.0.1:8000
```

---

## Step 3: Run Everything

### Option A: Use the automated script (Recommended)
```powershell
# From project root
.\run_web.ps1
```

This will:
- Start backend server (port 8000)
- Start frontend server (port 3000)
- Open browser automatically

### Option B: Manual start

**Terminal 1 - Backend:**
```powershell
cd backend
.\venv\Scripts\activate
python main.py
```

**Terminal 2 - Frontend:**
```powershell
cd frontend
npm run dev
```

---

## Step 4: Test the System

1. **Open browser:** http://localhost:3000

2. **Try example queries:**
   - `"Find Italian restaurants near Taipei 101"`
   - `"Find a nice restaurant near me and make a reservation for tomorrow at 7 PM"`
   - `"What's on my calendar tomorrow?"`
   - `"Research the history of artificial intelligence"`

3. **Check API docs:** http://127.0.0.1:8000/docs

---

## Troubleshooting

### Backend won't start
- ✅ Check if port 8000 is available
- ✅ Verify virtual environment is activated
- ✅ Check if API keys are set in `.env`
- ✅ Run: `pip install -r requirements.txt`

### Frontend won't start
- ✅ Check if port 3000 is available
- ✅ Run: `npm install`
- ✅ Check Node.js version: `node --version`

### API errors
- ✅ Verify API keys are correct
- ✅ Check Google Cloud Console - ensure Places API and Geocoding API are enabled
- ✅ Check API key restrictions in Google Cloud Console

### Streaming not working
- ✅ Check browser console for errors
- ✅ Verify backend is running on http://127.0.0.1:8000
- ✅ Check CORS settings

---

## Verify Setup

Run the verification script:
```powershell
.\verify_complete_setup.ps1
```

---

## Next Steps

- ✅ Test all agent functionalities
- ✅ Try complex multi-agent queries
- ✅ Review agent outputs in the dashboard
- ✅ Check streaming responses

---

## Need Help?

- Check `PROJECT_COMPLETE.md` for detailed documentation
- Review `backend/README.md` for backend specifics
- Review `frontend/README.md` for frontend specifics

---

**Happy coding! 🎉**

