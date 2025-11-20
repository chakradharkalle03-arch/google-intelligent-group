# Docker Deployment Script
# Finds Docker and deploys with remote access

param(
    [string]$RemoteIP = "192.168.0.101"
)

Write-Host "`n=== DOCKER REMOTE DEPLOYMENT ===" -ForegroundColor Green
Write-Host "Remote IP: $RemoteIP" -ForegroundColor Cyan
Write-Host ""

# Find Docker executable
Write-Host "Step 1: Finding Docker..." -ForegroundColor Yellow
$dockerPaths = @(
    "C:\Program Files\Docker\Docker\resources\bin\docker.exe",
    "C:\Program Files\Docker\Docker\resources\docker.exe",
    "$env:ProgramFiles\Docker\Docker\resources\bin\docker.exe"
)

$dockerCmd = $null
foreach ($path in $dockerPaths) {
    if (Test-Path $path) {
        $dockerCmd = $path
        Write-Host "  Docker found: $path" -ForegroundColor Green
        break
    }
}

if (-not $dockerCmd) {
    # Try to find in PATH
    $dockerInPath = Get-Command docker -ErrorAction SilentlyContinue
    if ($dockerInPath) {
        $dockerCmd = "docker"
        Write-Host "  Docker found in PATH" -ForegroundColor Green
    } else {
        Write-Host "  ERROR: Docker not found!" -ForegroundColor Red
        Write-Host "  Please ensure Docker Desktop is installed and running" -ForegroundColor Yellow
        Write-Host "  Or restart PowerShell after starting Docker Desktop" -ForegroundColor Yellow
        exit 1
    }
}

# Test Docker connection
Write-Host "`nStep 2: Testing Docker connection..." -ForegroundColor Yellow
if ($dockerCmd -eq "docker") {
    $dockerTest = docker info 2>&1
} else {
    $dockerTest = & $dockerCmd info 2>&1
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "  ERROR: Cannot connect to Docker daemon" -ForegroundColor Red
    Write-Host "  Please start Docker Desktop" -ForegroundColor Yellow
    exit 1
}
Write-Host "  Docker daemon is running" -ForegroundColor Green

# Load environment variables
Write-Host "`nStep 3: Loading environment variables..." -ForegroundColor Yellow
if (Test-Path .env) {
    Get-Content .env | ForEach-Object {
        if ($_ -match '^([^#][^=]+)=(.*)$') {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            Set-Item -Path "env:$name" -Value $value
        }
    }
    Write-Host "  Environment variables loaded" -ForegroundColor Green
}

# Set remote API URL
$env:NEXT_PUBLIC_API_URL = "http://$RemoteIP:8000"
Write-Host "  NEXT_PUBLIC_API_URL = $env:NEXT_PUBLIC_API_URL" -ForegroundColor Gray

# Stop existing containers
Write-Host "`nStep 4: Stopping existing containers..." -ForegroundColor Yellow
if ($dockerCmd -eq "docker") {
    docker-compose down 2>&1 | Out-Null
} else {
    $composePath = $dockerCmd -replace "docker.exe", "docker-compose.exe"
    if (Test-Path $composePath) {
        & $composePath down 2>&1 | Out-Null
    } else {
        docker-compose down 2>&1 | Out-Null
    }
}
Write-Host "  Existing containers stopped" -ForegroundColor Green

# Build images individually (to avoid buildx issues)
Write-Host "`nStep 5: Building container images..." -ForegroundColor Yellow
Write-Host "  This may take several minutes..." -ForegroundColor Gray

Write-Host "`n  Building fonoster-server..." -ForegroundColor Cyan
if ($dockerCmd -eq "docker") {
    docker build -t fonoster-server:latest ./fonoster-server
} else {
    & $dockerCmd build -t fonoster-server:latest ./fonoster-server
}
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ERROR: Failed to build fonoster-server" -ForegroundColor Red
    exit 1
}

Write-Host "`n  Building backend..." -ForegroundColor Cyan
if ($dockerCmd -eq "docker") {
    docker build -t google-intelligent-backend:latest ./backend
} else {
    & $dockerCmd build -t google-intelligent-backend:latest ./backend
}
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ERROR: Failed to build backend" -ForegroundColor Red
    exit 1
}

Write-Host "`n  Building frontend..." -ForegroundColor Cyan
if ($dockerCmd -eq "docker") {
    docker build --build-arg NEXT_PUBLIC_API_URL=$env:NEXT_PUBLIC_API_URL -t google-intelligent-frontend:latest ./frontend
} else {
    & $dockerCmd build --build-arg NEXT_PUBLIC_API_URL=$env:NEXT_PUBLIC_API_URL -t google-intelligent-frontend:latest ./frontend
}
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ERROR: Failed to build frontend" -ForegroundColor Red
    exit 1
}

Write-Host "  All images built successfully" -ForegroundColor Green

# Start containers
Write-Host "`nStep 6: Starting containers..." -ForegroundColor Yellow
if ($dockerCmd -eq "docker") {
    docker-compose up -d
} else {
    $composePath = $dockerCmd -replace "docker.exe", "docker-compose.exe"
    if (Test-Path $composePath) {
        & $composePath up -d
    } else {
        docker-compose up -d
    }
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "  Containers started successfully" -ForegroundColor Green
} else {
    Write-Host "  ERROR: Failed to start containers" -ForegroundColor Red
    exit 1
}

# Wait and verify
Write-Host "`nStep 7: Waiting for containers to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

Write-Host "`nStep 8: Container Status:" -ForegroundColor Cyan
if ($dockerCmd -eq "docker") {
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
} else {
    & $dockerCmd ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

# Test connectivity
Write-Host "`nStep 9: Testing connectivity..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

try {
    $backendTest = Invoke-WebRequest -Uri "http://localhost:8000/health" -UseBasicParsing -TimeoutSec 5
    Write-Host "  Backend: OK (Status: $($backendTest.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "  Backend: Not ready yet" -ForegroundColor Yellow
}

try {
    $frontendTest = Invoke-WebRequest -Uri "http://localhost:3000" -UseBasicParsing -TimeoutSec 5
    Write-Host "  Frontend: OK (Status: $($frontendTest.StatusCode))" -ForegroundColor Green
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

