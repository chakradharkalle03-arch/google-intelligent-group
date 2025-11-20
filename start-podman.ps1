# Podman Local Deployment Script
# Starts all containers using podman run

Write-Host "`n=== STARTING PODMAN CONTAINERS ===" -ForegroundColor Green
Write-Host ""

# Load environment variables
Write-Host "Step 1: Loading environment variables..." -ForegroundColor Yellow
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

# Check required environment variables
if ([string]::IsNullOrEmpty($env:GEMINI_API_KEY)) {
    Write-Host "  ERROR: GEMINI_API_KEY is not set" -ForegroundColor Red
    exit 1
}

if ([string]::IsNullOrEmpty($env:GOOGLE_MAPS_API_KEY)) {
    Write-Host "  ERROR: GOOGLE_MAPS_API_KEY is not set" -ForegroundColor Red
    exit 1
}

# Create network
Write-Host "`nStep 2: Creating network..." -ForegroundColor Yellow
podman network create app-network 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "  Network created" -ForegroundColor Green
} else {
    Write-Host "  Network already exists or created" -ForegroundColor Gray
}

# Stop and remove existing containers
Write-Host "`nStep 3: Cleaning up existing containers..." -ForegroundColor Yellow
podman stop fonoster-server google-intelligent-backend google-intelligent-frontend 2>&1 | Out-Null
podman rm fonoster-server google-intelligent-backend google-intelligent-frontend 2>&1 | Out-Null
Write-Host "  Cleanup complete" -ForegroundColor Green

# Start fonoster-server
Write-Host "`nStep 4: Starting fonoster-server..." -ForegroundColor Yellow
podman run -d `
  --name fonoster-server `
  --network app-network `
  -p 3001:3001 `
  -e PORT=3001 `
  -e FONOSTER_ACCESS_KEY_ID=$env:FONOSTER_ACCESS_KEY_ID `
  -e FONOSTER_API_KEY=$env:FONOSTER_API_KEY `
  -e FONOSTER_API_SECRET=$env:FONOSTER_API_SECRET `
  -e FONOSTER_ENDPOINT=$env:FONOSTER_ENDPOINT `
  -e FONOSTER_FROM_NUMBER=$env:FONOSTER_FROM_NUMBER `
  --restart unless-stopped `
  localhost/fonoster-server:latest

if ($LASTEXITCODE -eq 0) {
    Write-Host "  Fonoster server started" -ForegroundColor Green
    Start-Sleep -Seconds 3
} else {
    Write-Host "  ERROR: Failed to start fonoster-server" -ForegroundColor Red
    Write-Host "  Make sure image is built: podman build -t fonoster-server:latest ./fonoster-server" -ForegroundColor Yellow
    exit 1
}

# Start backend
Write-Host "`nStep 5: Starting backend..." -ForegroundColor Yellow
podman run -d `
  --name google-intelligent-backend `
  --network app-network `
  -p 8000:8000 `
  -e GEMINI_API_KEY=$env:GEMINI_API_KEY `
  -e GOOGLE_MAPS_API_KEY=$env:GOOGLE_MAPS_API_KEY `
  -e FONOSTER_SERVER_URL=http://fonoster-server:3001 `
  -e BACKEND_HOST=0.0.0.0 `
  -e BACKEND_PORT=8000 `
  -e PYTHONUNBUFFERED=1 `
  --restart unless-stopped `
  localhost/google-intelligent-backend:latest

if ($LASTEXITCODE -eq 0) {
    Write-Host "  Backend started" -ForegroundColor Green
    Start-Sleep -Seconds 3
} else {
    Write-Host "  ERROR: Failed to start backend" -ForegroundColor Red
    Write-Host "  Make sure image is built: podman build -t google-intelligent-backend:latest ./backend" -ForegroundColor Yellow
    exit 1
}

# Start frontend
Write-Host "`nStep 6: Starting frontend..." -ForegroundColor Yellow
podman run -d `
  --name google-intelligent-frontend `
  --network app-network `
  -p 3000:3000 `
  -e NEXT_PUBLIC_API_URL=http://localhost:8000 `
  -e NODE_ENV=production `
  -e NEXT_TELEMETRY_DISABLED=1 `
  --restart unless-stopped `
  localhost/google-intelligent-frontend:latest

if ($LASTEXITCODE -eq 0) {
    Write-Host "  Frontend started" -ForegroundColor Green
    Start-Sleep -Seconds 3
} else {
    Write-Host "  ERROR: Failed to start frontend" -ForegroundColor Red
    Write-Host "  Make sure image is built: podman build -t google-intelligent-frontend:latest ./frontend" -ForegroundColor Yellow
    exit 1
}

# Verify containers
Write-Host "`nStep 7: Verifying containers..." -ForegroundColor Yellow
Start-Sleep -Seconds 5
podman ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Test connectivity
Write-Host "`nStep 8: Testing connectivity..." -ForegroundColor Yellow
try {
    $backend = Invoke-WebRequest -Uri "http://localhost:8000/health" -UseBasicParsing -TimeoutSec 5
    Write-Host "  Backend: OK (Status: $($backend.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "  Backend: Not ready yet" -ForegroundColor Yellow
}

try {
    $frontend = Invoke-WebRequest -Uri "http://localhost:3000" -UseBasicParsing -TimeoutSec 5
    Write-Host "  Frontend: OK (Status: $($frontend.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "  Frontend: Not ready yet" -ForegroundColor Yellow
}

Write-Host "`n=== DEPLOYMENT COMPLETE ===" -ForegroundColor Green
Write-Host ""
Write-Host "Access URLs:" -ForegroundColor Cyan
Write-Host "  Frontend: http://localhost:3000" -ForegroundColor White
Write-Host "  Backend:  http://localhost:8000" -ForegroundColor White
Write-Host "  Fonoster: http://localhost:3001" -ForegroundColor White
Write-Host ""

