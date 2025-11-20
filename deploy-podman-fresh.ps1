# Fresh Podman Deployment Script with Remote IP Access
# This script builds and deploys all containers with remote access enabled

param(
    [string]$RemoteIP = ""
)

Write-Host "`n=== PODMAN FRESH DEPLOYMENT ===" -ForegroundColor Green
Write-Host "Building and deploying containers with remote access`n" -ForegroundColor Cyan

# Step 1: Load environment variables
Write-Host "[1/8] Loading environment variables..." -ForegroundColor Yellow
if (Test-Path .env) {
    Get-Content .env | ForEach-Object {
        if ($_ -match '^([^#][^=]+)=(.*)$') {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            Set-Item -Path "env:$name" -Value $value
        }
    }
    Write-Host "  ✅ Environment variables loaded" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  .env file not found" -ForegroundColor Yellow
}

# Check required variables
if ([string]::IsNullOrEmpty($env:GEMINI_API_KEY)) {
    Write-Host "  ❌ ERROR: GEMINI_API_KEY is not set" -ForegroundColor Red
    exit 1
}

# Get remote IP if not provided
if ([string]::IsNullOrEmpty($RemoteIP)) {
    $RemoteIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*" } | Select-Object -First 1).IPAddress
    Write-Host "  ℹ️  Detected IP: $RemoteIP" -ForegroundColor Gray
}

Write-Host "  📍 Remote IP: $RemoteIP" -ForegroundColor Cyan

# Step 2: Stop and remove existing containers
Write-Host "`n[2/8] Cleaning up existing containers..." -ForegroundColor Yellow
$containers = @("fonoster-server", "google-intelligent-backend", "google-intelligent-frontend")
foreach ($container in $containers) {
    podman stop $container 2>&1 | Out-Null
    podman rm $container 2>&1 | Out-Null
}
Write-Host "  ✅ Cleanup complete" -ForegroundColor Green

# Step 3: Remove existing images (optional - for fresh build)
Write-Host "`n[3/8] Removing old images..." -ForegroundColor Yellow
podman rmi fonoster-server:latest 2>&1 | Out-Null
podman rmi google-intelligent-backend:latest 2>&1 | Out-Null
podman rmi google-intelligent-frontend:latest 2>&1 | Out-Null
Write-Host "  ✅ Old images removed" -ForegroundColor Green

# Step 4: Create network
Write-Host "`n[4/8] Creating network..." -ForegroundColor Yellow
podman network create app-network 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✅ Network created" -ForegroundColor Green
} else {
    Write-Host "  ℹ️  Network already exists" -ForegroundColor Gray
}

# Step 5: Build images with retry
Write-Host "`n[5/8] Building images (this may take several minutes)..." -ForegroundColor Yellow

# Function to build with retry
function Build-ImageWithRetry {
    param(
        [string]$ImageName,
        [string]$Path,
        [string]$Containerfile,
        [string]$BuildArgs = ""
    )
    
    $maxRetries = 20
    $retryCount = 0
    
    while ($retryCount -lt $maxRetries) {
        $retryCount++
        Write-Host "  📦 Attempt ${retryCount}/${maxRetries}: Building ${ImageName}..." -ForegroundColor Cyan
        
        Set-Location $Path
        if ($BuildArgs) {
            $buildOutput = podman build $BuildArgs -t $ImageName -f $Containerfile . 2>&1
        } else {
            $buildOutput = podman build -t $ImageName -f $Containerfile . 2>&1
        }
        Set-Location ..
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✅ $ImageName built successfully!" -ForegroundColor Green
            return $true
        } else {
            if ($buildOutput -match "timeout|no route to host|connection refused|i/o timeout") {
                $waitTime = [math]::Min(30 + ($retryCount * 10), 120)
                Write-Host "  ⚠️  Network timeout. Waiting $waitTime seconds before retry..." -ForegroundColor Yellow
                Start-Sleep -Seconds $waitTime
            } else {
                Write-Host "  ❌ Build failed: $($buildOutput | Select-Object -Last 2)" -ForegroundColor Red
                $waitTime = 30
                Write-Host "  ⚠️  Waiting $waitTime seconds before retry..." -ForegroundColor Yellow
                Start-Sleep -Seconds $waitTime
            }
        }
    }
    
    Write-Host "  ❌ Failed to build $ImageName after $maxRetries attempts" -ForegroundColor Red
    return $false
}

# Build fonoster-server
if (-not (Build-ImageWithRetry "fonoster-server:latest" "fonoster-server" "Containerfile")) {
    Write-Host "`n❌ Deployment failed at fonoster-server build" -ForegroundColor Red
    exit 1
}

# Build backend
if (-not (Build-ImageWithRetry "google-intelligent-backend:latest" "backend" "Containerfile")) {
    Write-Host "`n❌ Deployment failed at backend build" -ForegroundColor Red
    exit 1
}

# Build frontend
if (-not (Build-ImageWithRetry "google-intelligent-frontend:latest" "frontend" "Containerfile" "--build-arg NEXT_PUBLIC_API_URL=`"http://$RemoteIP:8000`"")) {
    Write-Host "`n❌ Deployment failed at frontend build" -ForegroundColor Red
    exit 1
}

# Step 6: Start containers
Write-Host "`n[6/8] Starting containers..." -ForegroundColor Yellow

# Start fonoster-server
Write-Host "  🚀 Starting fonoster-server..." -ForegroundColor Cyan
podman run -d `
  --name fonoster-server `
  --network app-network `
  -p 0.0.0.0:3001:3001 `
  -e PORT=3001 `
  -e FONOSTER_ACCESS_KEY_ID=$env:FONOSTER_ACCESS_KEY_ID `
  -e FONOSTER_API_KEY=$env:FONOSTER_API_KEY `
  -e FONOSTER_API_SECRET=$env:FONOSTER_API_SECRET `
  -e FONOSTER_ENDPOINT=$env:FONOSTER_ENDPOINT `
  -e FONOSTER_FROM_NUMBER=$env:FONOSTER_FROM_NUMBER `
  --restart unless-stopped `
  localhost/fonoster-server:latest

if ($LASTEXITCODE -ne 0) {
    Write-Host "  ❌ Failed to start fonoster-server" -ForegroundColor Red
    exit 1
}
Write-Host "  ✅ Fonoster-server started" -ForegroundColor Green
Start-Sleep -Seconds 3

# Start backend
Write-Host "  🚀 Starting backend..." -ForegroundColor Cyan
podman run -d `
  --name google-intelligent-backend `
  --network app-network `
  -p 0.0.0.0:8000:8000 `
  -e GEMINI_API_KEY=$env:GEMINI_API_KEY `
  -e GOOGLE_MAPS_API_KEY=$env:GOOGLE_MAPS_API_KEY `
  -e FONOSTER_SERVER_URL=http://fonoster-server:3001 `
  -e BACKEND_HOST=0.0.0.0 `
  -e BACKEND_PORT=8000 `
  -e PYTHONUNBUFFERED=1 `
  --restart unless-stopped `
  localhost/google-intelligent-backend:latest

if ($LASTEXITCODE -ne 0) {
    Write-Host "  ❌ Failed to start backend" -ForegroundColor Red
    exit 1
}
Write-Host "  ✅ Backend started" -ForegroundColor Green
Start-Sleep -Seconds 3

# Start frontend
Write-Host "  🚀 Starting frontend..." -ForegroundColor Cyan
podman run -d `
  --name google-intelligent-frontend `
  --network app-network `
  -p 0.0.0.0:3000:3000 `
  -e NEXT_PUBLIC_API_URL="http://$RemoteIP:8000" `
  -e NODE_ENV=production `
  -e NEXT_TELEMETRY_DISABLED=1 `
  --restart unless-stopped `
  localhost/google-intelligent-frontend:latest

if ($LASTEXITCODE -ne 0) {
    Write-Host "  ❌ Failed to start frontend" -ForegroundColor Red
    exit 1
}
Write-Host "  ✅ Frontend started" -ForegroundColor Green
Start-Sleep -Seconds 5

# Step 7: Verify containers
Write-Host "`n[7/8] Verifying containers..." -ForegroundColor Yellow
podman ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Step 8: Test connectivity
Write-Host "`n[8/8] Testing connectivity..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Test backend
try {
    $backend = Invoke-WebRequest -Uri "http://localhost:8000/health" -UseBasicParsing -TimeoutSec 10
    Write-Host "  ✅ Backend: OK (Status: $($backend.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "  ⚠️  Backend: Not ready yet - $($_.Exception.Message)" -ForegroundColor Yellow
}

# Test frontend
try {
    $frontend = Invoke-WebRequest -Uri "http://localhost:3000" -UseBasicParsing -TimeoutSec 10
    Write-Host "  ✅ Frontend: OK (Status: $($frontend.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "  ⚠️  Frontend: Not ready yet - $($_.Exception.Message)" -ForegroundColor Yellow
}

# Test fonoster
try {
    $fonoster = Invoke-WebRequest -Uri "http://localhost:3001/health" -UseBasicParsing -TimeoutSec 10
    Write-Host "  ✅ Fonoster: OK (Status: $($fonoster.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "  ⚠️  Fonoster: Not ready yet - $($_.Exception.Message)" -ForegroundColor Yellow
}

# Final summary
Write-Host "`n=== ✅ DEPLOYMENT COMPLETE ===" -ForegroundColor Green
Write-Host ""
Write-Host "🌐 Access URLs:" -ForegroundColor Cyan
Write-Host "  Local:" -ForegroundColor Yellow
Write-Host "    Frontend: http://localhost:3000" -ForegroundColor White
Write-Host "    Backend:  http://localhost:8000" -ForegroundColor White
Write-Host "    Fonoster: http://localhost:3001" -ForegroundColor White
Write-Host ""
Write-Host "  Remote:" -ForegroundColor Yellow
Write-Host "    Frontend: http://$RemoteIP:3000" -ForegroundColor White
Write-Host "    Backend:  http://$RemoteIP:8000" -ForegroundColor White
Write-Host "    Fonoster: http://$RemoteIP:3001" -ForegroundColor White
Write-Host ""
Write-Host "📊 View containers: podman ps" -ForegroundColor Cyan
Write-Host "📋 View logs: podman logs <container-name>" -ForegroundColor Cyan
Write-Host ""

