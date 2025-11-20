# Podman Quick Start Script (PowerShell)
# Google Intelligent Group Multi-Agent System

Write-Host "`n🚀 Starting Google Intelligent Group with Podman...`n" -ForegroundColor Green

# Check if Podman is installed
if (-not (Get-Command podman -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Podman is not installed. Please install Podman first." -ForegroundColor Red
    exit 1
}

Write-Host "✅ Podman found: $(podman --version)" -ForegroundColor Green
Write-Host ""

# Check if Podman machine is running
Write-Host "🔍 Checking Podman machine status..." -ForegroundColor Cyan
$machineCheck = podman info --format "{{.Host.OS}}" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  Podman machine is not running or not initialized." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Attempting to start Podman machine..." -ForegroundColor Yellow
    podman machine start 2>&1 | Out-Null
    Start-Sleep -Seconds 5
    
    # Check again
    $machineCheck = podman info --format "{{.Host.OS}}" 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Cannot connect to Podman machine." -ForegroundColor Red
        Write-Host ""
        Write-Host "Please do one of the following:" -ForegroundColor Yellow
        Write-Host "1. Start Podman Desktop and wait for machine to initialize" -ForegroundColor White
        Write-Host "2. Initialize Podman machine: podman machine init" -ForegroundColor White
        Write-Host "3. If on Windows, install WSL: wsl --install (as Administrator)" -ForegroundColor White
        Write-Host ""
        Write-Host "See docs/PODMAN_DEPLOYMENT_GUIDE.md for detailed instructions." -ForegroundColor Cyan
        exit 1
    }
}
Write-Host "✅ Podman machine is ready" -ForegroundColor Green
Write-Host ""

# Check if .env file exists
if (-not (Test-Path .env)) {
    Write-Host "⚠️  .env file not found. Creating template...`n" -ForegroundColor Yellow
    @"
# Backend API Keys (Required)
GEMINI_API_KEY=your_gemini_api_key_here
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here

# Fonoster Configuration (Optional - for real phone calls)
FONOSTER_ACCESS_KEY_ID=
FONOSTER_API_KEY=
FONOSTER_API_SECRET=
FONOSTER_ENDPOINT=https://api.fonoster.com
FONOSTER_FROM_NUMBER=
"@ | Out-File -FilePath .env -Encoding utf8
    
    Write-Host "⚠️  Please edit .env file and add your API keys before continuing." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to continue after editing .env file"
}

# Load environment variables
Get-Content .env | ForEach-Object {
    if ($_ -match '^([^#][^=]+)=(.*)$') {
        $name = $matches[1].Trim()
        $value = $matches[2].Trim()
        Set-Item -Path "env:$name" -Value $value
    }
}

# Check required environment variables
if ([string]::IsNullOrEmpty($env:GEMINI_API_KEY) -or $env:GEMINI_API_KEY -eq "your_gemini_api_key_here") {
    Write-Host "❌ GEMINI_API_KEY is not set in .env file" -ForegroundColor Red
    exit 1
}

if ([string]::IsNullOrEmpty($env:GOOGLE_MAPS_API_KEY) -or $env:GOOGLE_MAPS_API_KEY -eq "your_google_maps_api_key_here") {
    Write-Host "❌ GOOGLE_MAPS_API_KEY is not set in .env file" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Environment variables loaded`n" -ForegroundColor Green

# Build containers
Write-Host "📦 Building containers...`n" -ForegroundColor Yellow

Write-Host "Building backend..."
Set-Location backend
podman build -t google-intelligent-backend:latest -f Containerfile .
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to build backend container" -ForegroundColor Red
    exit 1
}
Set-Location ..

Write-Host "Building frontend..."
Set-Location frontend
podman build -t google-intelligent-frontend:latest -f Containerfile .
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to build frontend container" -ForegroundColor Red
    exit 1
}
Set-Location ..

Write-Host "Building fonoster-server..."
Set-Location fonoster-server
podman build -t fonoster-server:latest -f Containerfile .
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to build fonoster-server container" -ForegroundColor Red
    exit 1
}
Set-Location ..

Write-Host "`n✅ All containers built successfully`n" -ForegroundColor Green

# Create network
Write-Host "Creating network..."
podman network create app-network 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Network already exists (this is OK)" -ForegroundColor Gray
}
Write-Host ""

# Stop and remove existing containers
Write-Host "Cleaning up existing containers..."
podman stop fonoster-server google-intelligent-backend google-intelligent-frontend 2>$null
podman rm fonoster-server google-intelligent-backend google-intelligent-frontend 2>$null
Write-Host ""

# Start containers
Write-Host "🚀 Starting containers...`n" -ForegroundColor Yellow

# Start Fonoster Server
Write-Host "Starting fonoster-server..."
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
Write-Host "Starting backend..."
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
Write-Host "Starting frontend..."
podman run -d `
  --name google-intelligent-frontend `
  --network app-network `
  -p 3000:3000 `
  -e NEXT_PUBLIC_API_URL="http://localhost:8000" `
  -e NODE_ENV=production `
  -e NEXT_TELEMETRY_DISABLED=1 `
  google-intelligent-frontend:latest

Start-Sleep -Seconds 5

# Check container status
Write-Host "`n📊 Container Status:" -ForegroundColor Green
podman ps --filter "name=google-intelligent|fonoster-server" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

Write-Host "`n✅ All containers started!`n" -ForegroundColor Green
Write-Host "🌐 Access the application:" -ForegroundColor Cyan
Write-Host "   Frontend: http://localhost:3000" -ForegroundColor White
Write-Host "   Backend:  http://localhost:8000" -ForegroundColor White
Write-Host "   Fonoster: http://localhost:3001" -ForegroundColor White
Write-Host "`n📝 Useful commands:" -ForegroundColor Cyan
Write-Host "   View logs:    podman logs <container-name>" -ForegroundColor White
Write-Host "   Stop all:     podman stop fonoster-server google-intelligent-backend google-intelligent-frontend" -ForegroundColor White
Write-Host "   Remove all:   podman rm fonoster-server google-intelligent-backend google-intelligent-frontend" -ForegroundColor White
Write-Host ""

