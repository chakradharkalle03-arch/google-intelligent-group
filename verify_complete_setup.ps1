# Complete Setup Verification Script
# Verifies all components are ready for the full project

Write-Host "`n🔍 Verifying Complete Project Setup...`n" -ForegroundColor Cyan

$allGood = $true

# Check Backend
Write-Host "📦 Checking Backend..." -ForegroundColor Yellow
if (Test-Path "backend\venv\Scripts\activate.ps1") {
    Write-Host "   ✅ Virtual environment exists" -ForegroundColor Green
} else {
    Write-Host "   ❌ Virtual environment not found" -ForegroundColor Red
    $allGood = $false
}

if (Test-Path "backend\requirements.txt") {
    Write-Host "   ✅ Requirements file exists" -ForegroundColor Green
} else {
    Write-Host "   ❌ Requirements file not found" -ForegroundColor Red
    $allGood = $false
}

if (Test-Path "backend\.env") {
    Write-Host "   ✅ .env file exists" -ForegroundColor Green
    
    # Check for API keys
    $envContent = Get-Content "backend\.env" -Raw
    if ($envContent -match "GEMINI_API_KEY=(.+)" -and $matches[1] -notmatch "your_|placeholder") {
        Write-Host "   ✅ GEMINI_API_KEY is set" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  GEMINI_API_KEY needs to be configured" -ForegroundColor Yellow
    }
    
    if ($envContent -match "GOOGLE_MAPS_API_KEY=(.+)" -and $matches[1] -notmatch "your_|placeholder") {
        Write-Host "   ✅ GOOGLE_MAPS_API_KEY is set" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  GOOGLE_MAPS_API_KEY needs to be configured" -ForegroundColor Yellow
    }
} else {
    Write-Host "   ⚠️  .env file not found - creating from template..." -ForegroundColor Yellow
    Copy-Item "backend\env.example" "backend\.env" -ErrorAction SilentlyContinue
    Write-Host "   📝 Please edit backend\.env and add your API keys" -ForegroundColor Cyan
}

# Check Frontend
Write-Host "`n🌐 Checking Frontend..." -ForegroundColor Yellow
if (Test-Path "frontend\node_modules") {
    Write-Host "   ✅ Node modules installed" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  Node modules not installed - run: cd frontend && npm install" -ForegroundColor Yellow
}

if (Test-Path "frontend\package.json") {
    Write-Host "   ✅ Package.json exists" -ForegroundColor Green
} else {
    Write-Host "   ❌ Package.json not found" -ForegroundColor Red
    $allGood = $false
}

# Check Fonoster Server
Write-Host "`n☎️  Checking Fonoster Server..." -ForegroundColor Yellow
if (Test-Path "fonoster-server\package.json") {
    Write-Host "   ✅ Fonoster server files exist" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  Fonoster server files not found" -ForegroundColor Yellow
}

# Summary
Write-Host ""
Write-Host "=======================================" -ForegroundColor Cyan
if ($allGood) {
    Write-Host "Setup verification complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Yellow
    Write-Host "   1. Ensure API keys are set in backend\.env" -ForegroundColor White
    Write-Host "   2. Run: .\run_web.ps1" -ForegroundColor White
    Write-Host "   3. Open: http://localhost:3000" -ForegroundColor White
} else {
    Write-Host "Some issues found. Please fix them before running." -ForegroundColor Yellow
}
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""

