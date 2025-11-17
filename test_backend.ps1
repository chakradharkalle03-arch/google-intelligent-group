# Test Backend Connection Script
Write-Host "Testing backend connection...`n" -ForegroundColor Cyan

$backendUrl = "http://127.0.0.1:8000"

# Check if port is open
$portCheck = Get-NetTCPConnection -LocalPort 8000 -ErrorAction SilentlyContinue
if (-not $portCheck) {
    Write-Host "❌ Backend is NOT running on port 8000" -ForegroundColor Red
    Write-Host "`nPlease start the backend server first:" -ForegroundColor Yellow
    Write-Host "   1. Open PowerShell in the backend directory" -ForegroundColor White
    Write-Host "   2. Run: .\venv\Scripts\activate.ps1" -ForegroundColor White
    Write-Host "   3. Run: python main.py" -ForegroundColor White
    Write-Host "`nOr use: .\run_web.ps1 to start both servers`n" -ForegroundColor Cyan
    exit 1
}

Write-Host "✅ Port 8000 is open" -ForegroundColor Green

# Test HTTP connection
try {
    $response = Invoke-WebRequest -Uri "$backendUrl/health" -Method GET -TimeoutSec 5 -ErrorAction Stop
    Write-Host "✅ Backend is responding!" -ForegroundColor Green
    Write-Host "   Status: $($response.StatusCode)" -ForegroundColor White
    Write-Host "   URL: $backendUrl`n" -ForegroundColor White
    
    # Test root endpoint
    $rootResponse = Invoke-WebRequest -Uri "$backendUrl/" -Method GET -TimeoutSec 5 -ErrorAction Stop
    Write-Host "✅ Root endpoint working!" -ForegroundColor Green
    Write-Host "   Response: $($rootResponse.Content)`n" -ForegroundColor White
    
} catch {
    Write-Host "❌ Backend is not responding properly" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)`n" -ForegroundColor Yellow
    exit 1
}

Write-Host "🎉 Backend is ready!`n" -ForegroundColor Green

