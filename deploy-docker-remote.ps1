# Docker Remote Deployment Script
# Deploys containers with remote access configuration

param(
    [string]$RemoteIP = "192.168.0.101"
)

Write-Host "`n=== DOCKER REMOTE DEPLOYMENT ===" -ForegroundColor Green
Write-Host "Remote IP: $RemoteIP" -ForegroundColor Cyan
Write-Host ""

# Check if Docker is installed
Write-Host "Step 1: Checking Docker installation..." -ForegroundColor Yellow
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "  ERROR: Docker is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

$dockerVersion = docker --version
Write-Host "  Docker found: $dockerVersion" -ForegroundColor Green

# Check if Docker is running
$dockerInfo = docker info 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ERROR: Docker daemon is not running" -ForegroundColor Red
    Write-Host "  Please start Docker Desktop" -ForegroundColor Yellow
    exit 1
}
Write-Host "  Docker daemon is running" -ForegroundColor Green

# Load environment variables
Write-Host "`nStep 2: Loading environment variables..." -ForegroundColor Yellow
if (Test-Path .env) {
    Get-Content .env | ForEach-Object {
        if ($_ -match '^([^#][^=]+)=(.*)$') {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            Set-Item -Path "env:$name" -Value $value
        }
    }
    Write-Host "  Environment variables loaded" -ForegroundColor Green
} else {
    Write-Host "  WARNING: .env file not found" -ForegroundColor Yellow
}

# Set remote API URL
$env:NEXT_PUBLIC_API_URL = "http://$RemoteIP:8000"
Write-Host "  NEXT_PUBLIC_API_URL = $env:NEXT_PUBLIC_API_URL" -ForegroundColor Gray

# Stop and remove existing containers
Write-Host "`nStep 3: Stopping existing containers..." -ForegroundColor Yellow
docker-compose down 2>&1 | Out-Null
Write-Host "  Existing containers stopped" -ForegroundColor Green

# Build and start containers
Write-Host "`nStep 4: Building and starting containers..." -ForegroundColor Yellow
Write-Host "  This may take several minutes..." -ForegroundColor Gray

docker-compose up -d --build

if ($LASTEXITCODE -eq 0) {
    Write-Host "  Containers built and started successfully" -ForegroundColor Green
} else {
    Write-Host "  ERROR: Failed to build or start containers" -ForegroundColor Red
    exit 1
}

# Wait for containers to be ready
Write-Host "`nStep 5: Waiting for containers to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Verify containers
Write-Host "`nStep 6: Verifying containers..." -ForegroundColor Yellow
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Test connectivity
Write-Host "`nStep 7: Testing connectivity..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

try {
    $backendTest = Invoke-WebRequest -Uri "http://localhost:8000/health" -UseBasicParsing -TimeoutSec 5
    Write-Host "  Backend health check: OK" -ForegroundColor Green
} catch {
    Write-Host "  Backend health check: Not ready yet" -ForegroundColor Yellow
}

try {
    $frontendTest = Invoke-WebRequest -Uri "http://localhost:3000" -UseBasicParsing -TimeoutSec 5
    Write-Host "  Frontend: OK" -ForegroundColor Green
} catch {
    Write-Host "  Frontend: Not ready yet" -ForegroundColor Yellow
}

Write-Host "`n=== DEPLOYMENT COMPLETE ===" -ForegroundColor Green
Write-Host ""
Write-Host "Remote Access URLs:" -ForegroundColor Cyan
Write-Host "  Frontend: http://$RemoteIP:3000" -ForegroundColor White
Write-Host "  Backend:  http://$RemoteIP:8000" -ForegroundColor White
Write-Host "  Fonoster: http://$RemoteIP:3001" -ForegroundColor White
Write-Host ""
Write-Host "Note: Configure Windows Firewall for remote access:" -ForegroundColor Yellow
Write-Host "  Run: .\configure-firewall.ps1 (as Administrator)" -ForegroundColor Gray
Write-Host ""

