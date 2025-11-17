# Setup script for Google Intelligent Group Project
# Windows PowerShell script

Write-Host "🧠 Google Intelligent Group - Project Setup" -ForegroundColor Cyan
Write-Host "==========================================`n" -ForegroundColor Cyan

# Check Node.js
Write-Host "Checking Node.js installation..." -ForegroundColor Yellow
try {
    $nodeVersion = node --version
    Write-Host "✅ Node.js found: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Node.js not found. Please install Node.js 18+" -ForegroundColor Red
    exit 1
}

# Check Python
Write-Host "`nChecking Python installation..." -ForegroundColor Yellow
try {
    $pythonVersion = python --version
    Write-Host "✅ Python found: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Python not found. Please install Python 3.10+" -ForegroundColor Red
    exit 1
}

# Setup Frontend
Write-Host "`n📦 Setting up Frontend (Next.js)..." -ForegroundColor Yellow
Set-Location frontend
if (Test-Path "node_modules") {
    Write-Host "✅ Frontend dependencies already installed" -ForegroundColor Green
} else {
    npm install
    Write-Host "✅ Frontend dependencies installed" -ForegroundColor Green
}
Set-Location ..

# Setup Backend
Write-Host "`n🐍 Setting up Backend (Python FastAPI)..." -ForegroundColor Yellow
Set-Location backend
if (Test-Path "venv") {
    Write-Host "✅ Virtual environment already exists" -ForegroundColor Green
} else {
    python -m venv venv
    Write-Host "✅ Virtual environment created" -ForegroundColor Green
}
Write-Host "Activating virtual environment..." -ForegroundColor Yellow
& .\venv\Scripts\Activate.ps1
if (-not (Test-Path ".env")) {
    Copy-Item "env.example" ".env"
    Write-Host "✅ Created .env file from env.example" -ForegroundColor Green
    Write-Host "⚠️  Please edit backend/.env and add your API keys" -ForegroundColor Yellow
}
pip install -r requirements.txt
Write-Host "✅ Backend dependencies installed" -ForegroundColor Green
deactivate
Set-Location ..

# Setup Fonoster Server
Write-Host "`n☎️  Setting up Fonoster Server..." -ForegroundColor Yellow
Set-Location fonoster-server
if (Test-Path "node_modules") {
    Write-Host "✅ Fonoster server dependencies already installed" -ForegroundColor Green
} else {
    npm install
    Write-Host "✅ Fonoster server dependencies installed" -ForegroundColor Green
}
if (-not (Test-Path ".env")) {
    Copy-Item "env.example" ".env"
    Write-Host "✅ Created .env file from env.example" -ForegroundColor Green
    Write-Host "⚠️  Please edit fonoster-server/.env and add your Fonoster credentials" -ForegroundColor Yellow
}
Set-Location ..

Write-Host "`n✅ Setup Complete!" -ForegroundColor Green
Write-Host "`n📝 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Edit backend/.env and add your GEMINI_API_KEY and GOOGLE_MAPS_API_KEY" -ForegroundColor White
Write-Host "2. Edit fonoster-server/.env and add your Fonoster credentials" -ForegroundColor White
Write-Host "`n🚀 To run the project:" -ForegroundColor Cyan
Write-Host "  Frontend:    cd frontend && npm run dev" -ForegroundColor White
Write-Host "  Backend:     cd backend && venv\Scripts\activate && python main.py" -ForegroundColor White
Write-Host "  Fonoster:    cd fonoster-server && npm start" -ForegroundColor White

