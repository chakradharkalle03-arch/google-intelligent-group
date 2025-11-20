# Quick Remote Access Setup
# For when containers are already running locally

Write-Host "`n🚀 Quick Remote Access Setup" -ForegroundColor Green
Write-Host ""

# Check if containers are running
Write-Host "🔍 Checking container status..." -ForegroundColor Cyan
$containers = podman ps --format "{{.Names}}"
if (-not $containers) {
    Write-Host "❌ No containers running!" -ForegroundColor Red
    Write-Host "   Starting containers..." -ForegroundColor Yellow
    podman start fonoster-server google-intelligent-backend google-intelligent-frontend 2>&1 | Out-Null
    Start-Sleep -Seconds 3
    $containers = podman ps --format "{{.Names}}"
}

if ($containers) {
    Write-Host "   ✅ Containers running: $($containers -join ', ')" -ForegroundColor Green
} else {
    Write-Host "   ❌ Failed to start containers" -ForegroundColor Red
    Write-Host "   Please check: podman ps -a" -ForegroundColor Yellow
    exit 1
}

# Test localhost
Write-Host "`n🧪 Testing localhost access..." -ForegroundColor Cyan
try {
    $test = Invoke-WebRequest -Uri "http://localhost:3000" -UseBasicParsing -TimeoutSec 3
    Write-Host "   ✅ localhost:3000 is accessible" -ForegroundColor Green
} catch {
    Write-Host "   ⚠️  localhost:3000 not accessible yet, containers may still be starting" -ForegroundColor Yellow
}

# Get Windows host IP
$hostIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { 
    $_.IPAddress -notlike "127.*" -and 
    $_.IPAddress -notlike "169.254.*" -and
    $_.IPAddress -notlike "172.*"
} | Select-Object -First 1).IPAddress

Write-Host "`n📋 Remote Access Options:" -ForegroundColor Cyan
Write-Host ""

Write-Host "Option 1: SSH Tunneling (Recommended)" -ForegroundColor Green
Write-Host "─────────────────────────────────────" -ForegroundColor Gray
Write-Host ""
Write-Host "Step 1: Enable SSH Server (Run as Administrator):" -ForegroundColor Yellow
Write-Host "   .\enable-ssh-server.ps1" -ForegroundColor Cyan
Write-Host ""
Write-Host "Step 2: From remote device, run:" -ForegroundColor Yellow
Write-Host "   ssh -L 3000:localhost:3000 -L 8000:localhost:8000 -L 3001:localhost:3001 $env:USERNAME@$hostIP" -ForegroundColor Cyan
Write-Host ""
Write-Host "Step 3: Access on remote device:" -ForegroundColor Yellow
Write-Host "   Frontend: http://localhost:3000" -ForegroundColor White
Write-Host "   Backend:  http://localhost:8000" -ForegroundColor White
Write-Host "   Fonoster: http://localhost:3001" -ForegroundColor White
Write-Host ""

Write-Host "Option 2: Use ngrok (Quick but temporary)" -ForegroundColor Green
Write-Host "───────────────────────────────────────────" -ForegroundColor Gray
Write-Host ""
Write-Host "1. Install ngrok: https://ngrok.com/download" -ForegroundColor White
Write-Host "2. Run: ngrok http 3000" -ForegroundColor Cyan
Write-Host "3. Use the provided public URL" -ForegroundColor White
Write-Host ""

Write-Host "Option 3: Remote Desktop (Single user)" -ForegroundColor Green
Write-Host "───────────────────────────────────────" -ForegroundColor Gray
Write-Host ""
Write-Host "1. Enable Remote Desktop on Windows" -ForegroundColor White
Write-Host "2. Connect via RDP to $hostIP" -ForegroundColor White
Write-Host "3. Access localhost:3000 in RDP session" -ForegroundColor White
Write-Host ""

Write-Host "✅ Containers are ready for remote access!" -ForegroundColor Green
Write-Host "   Windows Host IP: $hostIP" -ForegroundColor White
Write-Host ""

