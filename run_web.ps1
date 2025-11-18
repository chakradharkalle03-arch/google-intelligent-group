# Simple Web Application Startup Script
# Starts backend and frontend servers

Write-Host "`n🚀 Starting Web Application...`n" -ForegroundColor Green

# Stop existing servers
Write-Host "🛑 Stopping existing servers..." -ForegroundColor Yellow
Get-Process | Where-Object {$_.ProcessName -like "*node*" -or $_.ProcessName -like "*python*" -or $_.ProcessName -like "*uvicorn*" -or $_.ProcessName -like "*hypercorn*"} | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2

# Start Backend Server
Write-Host "`n📦 Starting Backend Server (Quart)..." -ForegroundColor Cyan
$backendDir = Join-Path $PSScriptRoot "backend"
if (-not (Test-Path (Join-Path $backendDir "venv\Scripts\activate.ps1"))) {
    Write-Host "❌ Virtual environment not found!" -ForegroundColor Red
    exit 1
}
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$backendDir'; .\venv\Scripts\Activate.ps1; python main.py" -WindowStyle Minimized
Start-Sleep -Seconds 3

# Start Frontend Server
Write-Host "`n🌐 Starting Frontend Server (Next.js)..." -ForegroundColor Cyan
$frontendDir = Join-Path $PSScriptRoot "frontend"
    if (-not (Test-Path (Join-Path $frontendDir "node_modules"))) {
    Write-Host "📥 Installing dependencies..." -ForegroundColor Yellow
    Set-Location $frontendDir
        npm install
    Set-Location $PSScriptRoot
}
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$frontendDir'; npm run dev" -WindowStyle Minimized
    Start-Sleep -Seconds 5

# Open browser
Write-Host "`n🌍 Opening browser..." -ForegroundColor Cyan
Start-Sleep -Seconds 3
        Start-Process "http://localhost:3000"

Write-Host "`n✅ Servers started!" -ForegroundColor Green
        Write-Host "   Frontend: http://localhost:3000" -ForegroundColor White
Write-Host "   Backend: http://127.0.0.1:8000" -ForegroundColor White
Write-Host "`n💡 Close PowerShell windows to stop servers`n" -ForegroundColor Gray
