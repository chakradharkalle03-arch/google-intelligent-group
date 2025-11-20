# Build and Deploy Script
# Builds images first, then starts containers

param(
    [string]$RemoteIP = "192.168.0.101"
)

Write-Host "`n=== BUILD AND DEPLOY ===" -ForegroundColor Green
Write-Host "Remote IP: $RemoteIP" -ForegroundColor Cyan
Write-Host ""

# Check docker-compose
if (-not (Get-Command docker-compose -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: docker-compose not found" -ForegroundColor Red
    exit 1
}

Write-Host "Step 1: Loading environment variables..." -ForegroundColor Yellow
if (Test-Path .env) {
    Get-Content .env | ForEach-Object {
        if ($_ -match '^([^#][^=]+)=(.*)$') {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            Set-Item -Path "env:$name" -Value $value
        }
    }
}
$env:NEXT_PUBLIC_API_URL = "http://$RemoteIP:8000"
Write-Host "  NEXT_PUBLIC_API_URL = $env:NEXT_PUBLIC_API_URL" -ForegroundColor Green

Write-Host "`nStep 2: Stopping existing containers..." -ForegroundColor Yellow
docker-compose down 2>&1 | Out-Null

Write-Host "`nStep 3: Building images (this may take several minutes)..." -ForegroundColor Yellow
Write-Host "  Building fonoster-server..." -ForegroundColor Cyan
docker-compose build fonoster-server

Write-Host "`n  Building backend..." -ForegroundColor Cyan
docker-compose build backend

Write-Host "`n  Building frontend..." -ForegroundColor Cyan
docker-compose build frontend

Write-Host "`nStep 4: Starting containers..." -ForegroundColor Yellow
docker-compose up -d

Write-Host "`nStep 5: Waiting for containers..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

Write-Host "`nContainer Status:" -ForegroundColor Cyan
docker-compose ps

Write-Host "`n=== DEPLOYMENT COMPLETE ===" -ForegroundColor Green
Write-Host "`nRemote Access URLs:" -ForegroundColor Cyan
Write-Host "  Frontend: http://$RemoteIP:3000" -ForegroundColor White
Write-Host "  Backend:  http://$RemoteIP:8000" -ForegroundColor White
Write-Host "  Fonoster: http://$RemoteIP:3001" -ForegroundColor White
Write-Host ""

