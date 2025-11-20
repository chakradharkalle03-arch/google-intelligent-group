# Check Podman Deployment Status
Write-Host "`n=== PODMAN DEPLOYMENT STATUS ===" -ForegroundColor Green
Write-Host ""

# Check Podman machine
Write-Host "Podman Machine:" -ForegroundColor Cyan
podman machine list
Write-Host ""

# Check images
Write-Host "Built Images:" -ForegroundColor Cyan
podman images | Select-String "fonoster-server|google-intelligent"
Write-Host ""

# Check containers
Write-Host "Running Containers:" -ForegroundColor Cyan
podman ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
Write-Host ""

# Check all containers (including stopped)
Write-Host "All Containers:" -ForegroundColor Cyan
podman ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
Write-Host ""

# Test connectivity
Write-Host "Connectivity Tests:" -ForegroundColor Cyan
try {
    $backend = Invoke-WebRequest -Uri "http://localhost:8000/health" -UseBasicParsing -TimeoutSec 5
    Write-Host "  ✅ Backend: http://localhost:8000/health - Status: $($backend.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Backend: Not responding - $($_.Exception.Message)" -ForegroundColor Red
}

try {
    $frontend = Invoke-WebRequest -Uri "http://localhost:3000" -UseBasicParsing -TimeoutSec 5
    Write-Host "  ✅ Frontend: http://localhost:3000 - Status: $($frontend.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Frontend: Not responding - $($_.Exception.Message)" -ForegroundColor Red
}

try {
    $fonoster = Invoke-WebRequest -Uri "http://localhost:3001/health" -UseBasicParsing -TimeoutSec 5
    Write-Host "  ✅ Fonoster: http://localhost:3001/health - Status: $($fonoster.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Fonoster: Not responding - $($_.Exception.Message)" -ForegroundColor Red
}

# Get IP address
$ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*" } | Select-Object -First 1).IPAddress
Write-Host "`nRemote Access:" -ForegroundColor Cyan
Write-Host "  Frontend: http://$ip:3000" -ForegroundColor White
Write-Host "  Backend:  http://$ip:8000" -ForegroundColor White
Write-Host "  Fonoster: http://$ip:3001" -ForegroundColor White
Write-Host ""


