# Start Backend Server Only
# This script starts only the backend server

Write-Host "`n🚀 Starting Backend Server...`n" -ForegroundColor Green

# Change to backend directory
$backendDir = Join-Path $PSScriptRoot "backend"
Set-Location -Path $backendDir

# Check if virtual environment exists
if (-not (Test-Path "venv\Scripts\activate.ps1")) {
    Write-Host "❌ Virtual environment not found!" -ForegroundColor Red
    Write-Host "Please run: python -m venv venv" -ForegroundColor Yellow
    exit 1
}

# Check if .env file exists
if (-not (Test-Path ".env")) {
    Write-Host "⚠️  Warning: .env file not found!" -ForegroundColor Yellow
    Write-Host "   Make sure to set GEMINI_API_KEY in .env file`n" -ForegroundColor Gray
}

# Stop any existing server on port 8000
Write-Host "🔍 Checking for existing server on port 8000...`n" -ForegroundColor Cyan
$existing = Get-NetTCPConnection -LocalPort 8000 -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "⚠️  Stopping existing server...`n" -ForegroundColor Yellow
    $existing | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }
    Start-Sleep -Seconds 2
}

# Activate virtual environment
Write-Host "✅ Activating virtual environment...`n" -ForegroundColor Cyan
& "venv\Scripts\activate.ps1"

# Start the server
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host "✅ Starting Backend Server" -ForegroundColor Green
Write-Host "═══════════════════════════════════════`n" -ForegroundColor Cyan
Write-Host "🌐 Server will be available at:" -ForegroundColor Yellow
Write-Host "   📚 API Docs: http://127.0.0.1:8000/docs" -ForegroundColor White
Write-Host "   📡 API Root: http://127.0.0.1:8000" -ForegroundColor White
Write-Host "   ❤️  Health: http://127.0.0.1:8000/health`n" -ForegroundColor White
Write-Host "💡 Use 127.0.0.1 (NOT 0.0.0.0) in your browser!`n" -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop the server`n" -ForegroundColor Gray
Write-Host "═══════════════════════════════════════`n" -ForegroundColor Cyan

# Run the server
python main.py

