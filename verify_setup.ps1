# Verification script for Google Intelligent Group Project

Write-Host "🔍 Verifying Project Setup" -ForegroundColor Cyan
Write-Host "=========================`n" -ForegroundColor Cyan

$allGood = $true

# Check Node.js
Write-Host "Checking Node.js..." -ForegroundColor Yellow
try {
    $nodeVersion = node --version 2>$null
    if ($nodeVersion) {
        Write-Host "✅ Node.js: $nodeVersion" -ForegroundColor Green
    } else {
        Write-Host "❌ Node.js not found" -ForegroundColor Red
        $allGood = $false
    }
} catch {
    Write-Host "❌ Node.js not found - Please install from https://nodejs.org/" -ForegroundColor Red
    $allGood = $false
}

# Check npm
Write-Host "Checking npm..." -ForegroundColor Yellow
try {
    $npmVersion = npm --version 2>$null
    if ($npmVersion) {
        Write-Host "✅ npm: $npmVersion" -ForegroundColor Green
    } else {
        Write-Host "❌ npm not found" -ForegroundColor Red
        $allGood = $false
    }
} catch {
    Write-Host "❌ npm not found" -ForegroundColor Red
    $allGood = $false
}

# Check Python
Write-Host "`nChecking Python..." -ForegroundColor Yellow
try {
    $pythonVersion = python --version 2>$null
    if ($pythonVersion) {
        Write-Host "✅ Python: $pythonVersion" -ForegroundColor Green
    } else {
        Write-Host "❌ Python not found" -ForegroundColor Red
        $allGood = $false
    }
} catch {
    Write-Host "❌ Python not found - Please install from https://www.python.org/" -ForegroundColor Red
    Write-Host "   Make sure to check 'Add Python to PATH' during installation" -ForegroundColor Yellow
    $allGood = $false
}

# Check project structure
Write-Host "`nChecking project structure..." -ForegroundColor Yellow
$requiredDirs = @("frontend", "backend", "fonoster-server", "docs")
foreach ($dir in $requiredDirs) {
    if (Test-Path $dir) {
        Write-Host "✅ $dir/ exists" -ForegroundColor Green
    } else {
        Write-Host "❌ $dir/ missing" -ForegroundColor Red
        $allGood = $false
    }
}

# Check key files
Write-Host "`nChecking key files..." -ForegroundColor Yellow
$requiredFiles = @(
    "frontend/package.json",
    "backend/main.py",
    "backend/requirements.txt",
    "fonoster-server/package.json",
    "fonoster-server/server.js",
    "docs/DEVELOPMENT_PLAN.md"
)
foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "✅ $file exists" -ForegroundColor Green
    } else {
        Write-Host "❌ $file missing" -ForegroundColor Red
        $allGood = $false
    }
}

# Check .env files
Write-Host "`nChecking configuration files..." -ForegroundColor Yellow
if (Test-Path "backend/.env") {
    Write-Host "✅ backend/.env exists" -ForegroundColor Green
} else {
    Write-Host "⚠️  backend/.env missing (will be created from env.example)" -ForegroundColor Yellow
}

if (Test-Path "fonoster-server/.env") {
    Write-Host "✅ fonoster-server/.env exists" -ForegroundColor Green
} else {
    Write-Host "⚠️  fonoster-server/.env missing (will be created from env.example)" -ForegroundColor Yellow
}

# Summary
Write-Host "`n=========================" -ForegroundColor Cyan
if ($allGood) {
    Write-Host "✅ All checks passed! Ready to run setup.ps1" -ForegroundColor Green
} else {
    Write-Host "⚠️  Some requirements missing. Please install:" -ForegroundColor Yellow
    Write-Host "   - Node.js: https://nodejs.org/" -ForegroundColor White
    Write-Host "   - Python: https://www.python.org/" -ForegroundColor White
    Write-Host "`nSee INSTALL_REQUIREMENTS.md for details" -ForegroundColor Cyan
}

