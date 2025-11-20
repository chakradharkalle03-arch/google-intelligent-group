# Podman Deployment Script (PowerShell)
# Supports both Local and Remote Deployment
# Google Intelligent Group Multi-Agent System

param(
    [string]$Mode = "local",  # "local" or "remote"
    [string]$RemoteHost = "",  # Remote host IP or hostname
    [string]$RemoteUser = "",  # Remote SSH user
    [string]$RemoteKey = ""   # SSH key path
)

Write-Host "`n🚀 Podman Deployment Script" -ForegroundColor Green
Write-Host "Mode: $Mode`n" -ForegroundColor Cyan

# Check if Podman is installed
if (-not (Get-Command podman -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Podman is not installed. Please install Podman first." -ForegroundColor Red
    exit 1
}

Write-Host "✅ Podman found: $(podman --version)" -ForegroundColor Green

# Check Podman machine status
Write-Host "`n🔍 Checking Podman machine status..." -ForegroundColor Cyan
$machineCheck = podman info --format "{{.Host.OS}}" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  Podman machine is not running." -ForegroundColor Yellow
    Write-Host "Attempting to start Podman machine..." -ForegroundColor Yellow
    podman machine start 2>&1 | Out-Null
    Start-Sleep -Seconds 5
    
    $machineCheck = podman info --format "{{.Host.OS}}" 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Cannot connect to Podman machine." -ForegroundColor Red
        Write-Host "Please start Podman Desktop and wait for machine to initialize." -ForegroundColor Yellow
        exit 1
    }
}
Write-Host "✅ Podman machine is ready" -ForegroundColor Green

# Load environment variables
Write-Host "`n📋 Loading environment variables..." -ForegroundColor Cyan
if (Test-Path .env) {
    Get-Content .env | ForEach-Object {
        if ($_ -match '^([^#][^=]+)=(.*)$') {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            Set-Item -Path "env:$name" -Value $value
        }
    }
    Write-Host "✅ Environment variables loaded" -ForegroundColor Green
} else {
    Write-Host "⚠️  .env file not found. Using environment variables from system." -ForegroundColor Yellow
}

# Check required environment variables
if ([string]::IsNullOrEmpty($env:GEMINI_API_KEY)) {
    Write-Host "❌ GEMINI_API_KEY is not set" -ForegroundColor Red
    exit 1
}

if ([string]::IsNullOrEmpty($env:GOOGLE_MAPS_API_KEY)) {
    Write-Host "❌ GOOGLE_MAPS_API_KEY is not set" -ForegroundColor Red
    exit 1
}

# Build containers
Write-Host "`n📦 Building containers...`n" -ForegroundColor Yellow

Write-Host "Building backend..." -ForegroundColor White
Set-Location backend
podman build -t google-intelligent-backend:latest -f Containerfile .
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to build backend container" -ForegroundColor Red
    Set-Location ..
    exit 1
}
Set-Location ..

Write-Host "Building frontend..." -ForegroundColor White
Set-Location frontend
$apiUrl = if ($Mode -eq "remote" -and $RemoteHost) { "http://$RemoteHost:8000" } else { "http://localhost:8000" }
podman build --build-arg NEXT_PUBLIC_API_URL=$apiUrl -t google-intelligent-frontend:latest -f Containerfile .
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to build frontend container" -ForegroundColor Red
    Set-Location ..
    exit 1
}
Set-Location ..

Write-Host "Building fonoster-server..." -ForegroundColor White
Set-Location fonoster-server
podman build -t fonoster-server:latest -f Containerfile .
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to build fonoster-server container" -ForegroundColor Red
    Set-Location ..
    exit 1
}
Set-Location ..

Write-Host "`n✅ All containers built successfully`n" -ForegroundColor Green

# Create network
Write-Host "Creating network..." -ForegroundColor Cyan
podman network create app-network 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Network already exists (this is OK)" -ForegroundColor Gray
}

# Stop and remove existing containers
Write-Host "Cleaning up existing containers..." -ForegroundColor Cyan
podman stop fonoster-server google-intelligent-backend google-intelligent-frontend 2>$null
podman rm fonoster-server google-intelligent-backend google-intelligent-frontend 2>$null

# Start containers
Write-Host "`n🚀 Starting containers...`n" -ForegroundColor Yellow

# Start Fonoster Server
Write-Host "Starting fonoster-server..." -ForegroundColor White
podman run -d `
  --name fonoster-server `
  --network app-network `
  -p 3001:3001 `
  -e PORT=3001 `
  -e FONOSTER_ACCESS_KEY_ID="$env:FONOSTER_ACCESS_KEY_ID" `
  -e FONOSTER_API_KEY="$env:FONOSTER_API_KEY" `
  -e FONOSTER_API_SECRET="$env:FONOSTER_API_SECRET" `
  -e FONOSTER_ENDPOINT="$env:FONOSTER_ENDPOINT" `
  -e FONOSTER_FROM_NUMBER="$env:FONOSTER_FROM_NUMBER" `
  fonoster-server:latest

Start-Sleep -Seconds 3

# Start Backend
Write-Host "Starting backend..." -ForegroundColor White
podman run -d `
  --name google-intelligent-backend `
  --network app-network `
  -p 8000:8000 `
  -e GEMINI_API_KEY="$env:GEMINI_API_KEY" `
  -e GOOGLE_MAPS_API_KEY="$env:GOOGLE_MAPS_API_KEY" `
  -e FONOSTER_SERVER_URL="http://fonoster-server:3001" `
  -e BACKEND_HOST=0.0.0.0 `
  -e BACKEND_PORT=8000 `
  -e PYTHONUNBUFFERED=1 `
  google-intelligent-backend:latest

Start-Sleep -Seconds 3

# Start Frontend
Write-Host "Starting frontend..." -ForegroundColor White
$frontendApiUrl = if ($Mode -eq "remote" -and $RemoteHost) { "http://$RemoteHost:8000" } else { "http://localhost:8000" }
podman run -d `
  --name google-intelligent-frontend `
  --network app-network `
  -p 3000:3000 `
  -e NEXT_PUBLIC_API_URL=$frontendApiUrl `
  -e NODE_ENV=production `
  -e NEXT_TELEMETRY_DISABLED=1 `
  google-intelligent-frontend:latest

Start-Sleep -Seconds 5

# Check container status
Write-Host "`n📊 Container Status:" -ForegroundColor Green
podman ps --filter "name=google-intelligent|fonoster-server" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

Write-Host "`n✅ All containers started!`n" -ForegroundColor Green
Write-Host "🌐 Access the application:" -ForegroundColor Cyan
if ($Mode -eq "remote" -and $RemoteHost) {
    Write-Host "   Frontend: http://$RemoteHost:3000" -ForegroundColor White
    Write-Host "   Backend:  http://$RemoteHost:8000" -ForegroundColor White
    Write-Host "   Fonoster: http://$RemoteHost:3001" -ForegroundColor White
} else {
    Write-Host "   Frontend: http://localhost:3000" -ForegroundColor White
    Write-Host "   Backend:  http://localhost:8000" -ForegroundColor White
    Write-Host "   Fonoster: http://localhost:3001" -ForegroundColor White
}

Write-Host "`n📝 Useful commands:" -ForegroundColor Cyan
Write-Host "   View logs:    podman logs <container-name>" -ForegroundColor White
Write-Host "   Stop all:     podman stop fonoster-server google-intelligent-backend google-intelligent-frontend" -ForegroundColor White
Write-Host "   Remove all:   podman rm fonoster-server google-intelligent-backend google-intelligent-frontend" -ForegroundColor White
Write-Host ""

