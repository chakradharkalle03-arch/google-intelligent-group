# Automated Setup Script for Google Intelligent Group
# This script automatically sets up all components

Write-Host "🧠 Google Intelligent Group - Automated Setup" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

$ErrorActionPreference = "Continue"

# Function to check if command exists
function Test-Command {
    param($Command)
    $null = Get-Command $Command -ErrorAction SilentlyContinue
    return $?
}

# Check prerequisites
Write-Host "📋 Checking Prerequisites..." -ForegroundColor Yellow
$nodeInstalled = $false
$pythonInstalled = $false

# Check Node.js
Write-Host "`nChecking Node.js..." -ForegroundColor White
try {
    $nodeVersion = node --version 2>$null
    if ($nodeVersion) {
        Write-Host "✅ Node.js found: $nodeVersion" -ForegroundColor Green
        $nodeInstalled = $true
    }
} catch {
    Write-Host "❌ Node.js not found" -ForegroundColor Red
}

# Check npm
if ($nodeInstalled) {
    try {
        $npmVersion = npm --version 2>$null
        if ($npmVersion) {
            Write-Host "✅ npm found: $npmVersion" -ForegroundColor Green
        }
    } catch {
        Write-Host "⚠️  npm not found" -ForegroundColor Yellow
    }
}

# Check Python
Write-Host "`nChecking Python..." -ForegroundColor White
$pythonInstalled = $false
$pythonCmd = $null

# Try py launcher first (Windows Python launcher)
try {
    $pythonVersion = py --version 2>$null
    if ($pythonVersion) {
        Write-Host "✅ Python found via py launcher: $pythonVersion" -ForegroundColor Green
        $pythonInstalled = $true
        $pythonCmd = "py"
    }
} catch {
    # Try python3
    try {
        $pythonVersion = python3 --version 2>$null
        if ($pythonVersion -and $pythonVersion -notmatch "Microsoft Store") {
            Write-Host "✅ Python found: $pythonVersion" -ForegroundColor Green
            $pythonInstalled = $true
            $pythonCmd = "python3"
        }
    } catch {
        # Try python
        try {
            $pythonVersion = python --version 2>$null
            if ($pythonVersion -and $pythonVersion -notmatch "Microsoft Store") {
                Write-Host "✅ Python found: $pythonVersion" -ForegroundColor Green
                $pythonInstalled = $true
                $pythonCmd = "python"
            } else {
                Write-Host "❌ Python not properly installed (Windows Store alias detected)" -ForegroundColor Red
            }
        } catch {
            Write-Host "❌ Python not found" -ForegroundColor Red
        }
    }
}

# Check pip
if ($pythonInstalled) {
    try {
        $pipVersion = pip --version 2>$null
        if ($pipVersion) {
            Write-Host "✅ pip found" -ForegroundColor Green
        }
    } catch {
        Write-Host "⚠️  pip not found" -ForegroundColor Yellow
    }
}

Write-Host "`n" -ForegroundColor White

# Setup Frontend
if ($nodeInstalled) {
    Write-Host "📦 Setting up Frontend (Next.js)..." -ForegroundColor Yellow
    Set-Location frontend -ErrorAction SilentlyContinue
    if ($LASTEXITCODE -eq 0 -or $?) {
        if (Test-Path "node_modules") {
            Write-Host "✅ Frontend dependencies already installed" -ForegroundColor Green
        } else {
            Write-Host "Installing dependencies..." -ForegroundColor White
            npm install
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Frontend setup complete!" -ForegroundColor Green
            } else {
                Write-Host "⚠️  Frontend setup had issues" -ForegroundColor Yellow
            }
        }
        Set-Location ..
    } else {
        Write-Host "❌ Could not access frontend directory" -ForegroundColor Red
    }
} else {
    Write-Host "⏭️  Skipping Frontend setup (Node.js not installed)" -ForegroundColor Yellow
    Write-Host "   Install Node.js from: https://nodejs.org/" -ForegroundColor Gray
}

# Setup Backend
if ($pythonInstalled) {
    Write-Host "`n🐍 Setting up Backend (Python FastAPI)..." -ForegroundColor Yellow
    Set-Location backend -ErrorAction SilentlyContinue
    if ($LASTEXITCODE -eq 0 -or $?) {
        # Create virtual environment
        if (-not (Test-Path "venv")) {
            Write-Host "Creating virtual environment..." -ForegroundColor White
            & $pythonCmd -m venv venv
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Virtual environment created" -ForegroundColor Green
            }
        } else {
            Write-Host "✅ Virtual environment already exists" -ForegroundColor Green
        }
        
        # Activate and install dependencies
        if (Test-Path "venv\Scripts\Activate.ps1") {
            Write-Host "Activating virtual environment and installing dependencies..." -ForegroundColor White
            & .\venv\Scripts\python.exe -m pip install --upgrade pip -q
            & .\venv\Scripts\python.exe -m pip install -r requirements.txt
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Backend dependencies installed" -ForegroundColor Green
            }
        }
        
        # Create .env file if it doesn't exist
        if (-not (Test-Path ".env")) {
            if (Test-Path "env.example") {
                Copy-Item "env.example" ".env"
                Write-Host "✅ Created .env file from template" -ForegroundColor Green
                Write-Host "⚠️  Remember to add your API keys to backend/.env" -ForegroundColor Yellow
            }
        }
        
        Set-Location ..
    } else {
        Write-Host "❌ Could not access backend directory" -ForegroundColor Red
    }
} else {
    Write-Host "`n⏭️  Skipping Backend setup (Python not installed)" -ForegroundColor Yellow
    Write-Host "   Install Python from: https://www.python.org/downloads/" -ForegroundColor Gray
}

# Setup Fonoster Server
if ($nodeInstalled) {
    Write-Host "`n☎️  Setting up Fonoster Server..." -ForegroundColor Yellow
    Set-Location fonoster-server -ErrorAction SilentlyContinue
    if ($LASTEXITCODE -eq 0 -or $?) {
        if (Test-Path "node_modules") {
            Write-Host "✅ Fonoster server dependencies already installed" -ForegroundColor Green
        } else {
            Write-Host "Installing dependencies..." -ForegroundColor White
            npm install
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Fonoster server setup complete!" -ForegroundColor Green
            } else {
                Write-Host "⚠️  Fonoster server setup had issues" -ForegroundColor Yellow
            }
        }
        
        # Create .env file if it doesn't exist
        if (-not (Test-Path ".env")) {
            if (Test-Path "env.example") {
                Copy-Item "env.example" ".env"
                Write-Host "✅ Created .env file from template" -ForegroundColor Green
                Write-Host "⚠️  Remember to add Fonoster credentials to fonoster-server/.env" -ForegroundColor Yellow
            }
        }
        
        Set-Location ..
    } else {
        Write-Host "❌ Could not access fonoster-server directory" -ForegroundColor Red
    }
} else {
    Write-Host "`n⏭️  Skipping Fonoster Server setup (Node.js not installed)" -ForegroundColor Yellow
}

# Summary
Write-Host "`n" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "📊 Setup Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($nodeInstalled) {
    Write-Host "✅ Frontend: Ready" -ForegroundColor Green
    Write-Host "✅ Fonoster Server: Ready" -ForegroundColor Green
} else {
    Write-Host "⏳ Frontend: Waiting for Node.js" -ForegroundColor Yellow
    Write-Host "⏳ Fonoster Server: Waiting for Node.js" -ForegroundColor Yellow
}

if ($pythonInstalled) {
    Write-Host "✅ Backend: Ready" -ForegroundColor Green
} else {
    Write-Host "⏳ Backend: Waiting for Python" -ForegroundColor Yellow
}

Write-Host "`n📝 Next Steps:" -ForegroundColor Cyan
if (-not $nodeInstalled) {
    Write-Host "1. Install Node.js from https://nodejs.org/" -ForegroundColor White
}
if (-not $pythonInstalled) {
    Write-Host "2. Install Python from https://www.python.org/downloads/" -ForegroundColor White
    Write-Host "   (Make sure to check 'Add Python to PATH' during installation)" -ForegroundColor Gray
}
Write-Host "3. Run this script again after installing prerequisites" -ForegroundColor White
Write-Host "4. Add API keys to .env files:" -ForegroundColor White
Write-Host "   - backend/.env (GEMINI_API_KEY, GOOGLE_MAPS_API_KEY)" -ForegroundColor Gray
Write-Host "   - fonoster-server/.env (FONOSTER_API_KEY, FONOSTER_API_SECRET)" -ForegroundColor Gray
Write-Host "`n🚀 To start services:" -ForegroundColor Cyan
Write-Host "   Frontend:    cd frontend && npm run dev" -ForegroundColor White
Write-Host "   Backend:     cd backend && venv\Scripts\activate && python main.py" -ForegroundColor White
Write-Host "   Fonoster:    cd fonoster-server && npm start" -ForegroundColor White

Write-Host "`n✅ Setup script completed!" -ForegroundColor Green

