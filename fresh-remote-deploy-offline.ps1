# Fresh Remote Deployment Script (Offline Mode)
# Uses existing images or skips build if images exist

param(
    [string]$RemoteIP = "192.168.0.101",  # Remote IP address
    [switch]$SkipBuild  # Skip building if images exist
)

Write-Host "`n🔄 Fresh Remote Deployment (Offline Mode)" -ForegroundColor Green
Write-Host "   Remote IP: $RemoteIP" -ForegroundColor Cyan
Write-Host ""

# Step 1: Stop and remove all containers
Write-Host "🧹 Step 1: Stopping and removing all containers..." -ForegroundColor Yellow
$containers = podman ps -a --format "{{.Names}}" 2>&1
if ($containers -and $containers -notmatch "error|Error") {
    foreach ($container in $containers) {
        if ($container) {
            Write-Host "   Stopping: $container" -ForegroundColor Gray
            podman stop $container 2>&1 | Out-Null
            Write-Host "   Removing: $container" -ForegroundColor Gray
            podman rm $container 2>&1 | Out-Null
        }
    }
    Write-Host "   ✅ All containers stopped and removed" -ForegroundColor Green
} else {
    Write-Host "   ℹ️  No containers to remove" -ForegroundColor Gray
}

# Step 2: Check for existing images
Write-Host "`n🔍 Step 2: Checking for existing images..." -ForegroundColor Yellow
$backendImage = podman images --format "{{.Repository}}:{{.Tag}}" | Select-String "google-intelligent-backend"
$frontendImage = podman images --format "{{.Repository}}:{{.Tag}}" | Select-String "google-intelligent-frontend"
$fonosterImage = podman images --format "{{.Repository}}:{{.Tag}}" | Select-String "fonoster-server"

$needBuild = $false
if (-not $backendImage) {
    Write-Host "   ⚠️  Backend image not found" -ForegroundColor Yellow
    $needBuild = $true
} else {
    Write-Host "   ✅ Backend image found: $backendImage" -ForegroundColor Green
}

if (-not $frontendImage) {
    Write-Host "   ⚠️  Frontend image not found" -ForegroundColor Yellow
    $needBuild = $true
} else {
    Write-Host "   ✅ Frontend image found: $frontendImage" -ForegroundColor Green
}

if (-not $fonosterImage) {
    Write-Host "   ⚠️  Fonoster image not found" -ForegroundColor Yellow
    $needBuild = $true
} else {
    Write-Host "   ✅ Fonoster image found: $fonosterImage" -ForegroundColor Green
}

# Step 3: Build only if needed and not skipping
if ($needBuild -and -not $SkipBuild) {
    Write-Host "`n📦 Step 3: Building missing images..." -ForegroundColor Yellow
    
    # Load environment variables
    if (Test-Path .env) {
        Get-Content .env | ForEach-Object {
            if ($_ -match '^([^#][^=]+)=(.*)$') {
                $name = $matches[1].Trim()
                $value = $matches[2].Trim()
                Set-Item -Path "env:$name" -Value $value
            }
        }
    }
    
    # Build backend if needed
    if (-not $backendImage) {
        Write-Host "   Building backend..." -ForegroundColor Cyan
        Set-Location backend
        podman build -t google-intelligent-backend:latest -f Containerfile .
        if ($LASTEXITCODE -ne 0) {
            Write-Host "   ❌ Failed to build backend (network issue?)" -ForegroundColor Red
            Write-Host "   💡 Try: .\fresh-remote-deploy-offline.ps1 -SkipBuild" -ForegroundColor Yellow
            Set-Location ..
            exit 1
        }
        Set-Location ..
    }
    
    # Build frontend if needed
    if (-not $frontendImage) {
        Write-Host "   Building frontend with remote API URL..." -ForegroundColor Cyan
        Set-Location frontend
        $apiUrl = "http://$RemoteIP:8000"
        podman build --build-arg NEXT_PUBLIC_API_URL=$apiUrl -t google-intelligent-frontend:latest -f Containerfile .
        if ($LASTEXITCODE -ne 0) {
            Write-Host "   ❌ Failed to build frontend (network issue?)" -ForegroundColor Red
            Write-Host "   💡 Try: .\fresh-remote-deploy-offline.ps1 -SkipBuild" -ForegroundColor Yellow
            Set-Location ..
            exit 1
        }
        Set-Location ..
    }
    
    # Build fonoster if needed
    if (-not $fonosterImage) {
        Write-Host "   Building fonoster server..." -ForegroundColor Cyan
        Set-Location fonoster-server
        podman build -t fonoster-server:latest -f Containerfile .
        if ($LASTEXITCODE -ne 0) {
            Write-Host "   ❌ Failed to build fonoster (network issue?)" -ForegroundColor Red
            Write-Host "   💡 Try: .\fresh-remote-deploy-offline.ps1 -SkipBuild" -ForegroundColor Yellow
            Set-Location ..
            exit 1
        }
        Set-Location ..
    }
} elseif ($SkipBuild) {
    Write-Host "`n⏭️  Step 3: Skipping build (using existing images)" -ForegroundColor Yellow
} else {
    Write-Host "`n✅ Step 3: All images exist, skipping build" -ForegroundColor Green
}

# Step 4: Load environment variables
Write-Host "`n📋 Step 4: Loading environment variables..." -ForegroundColor Yellow
if (Test-Path .env) {
    Get-Content .env | ForEach-Object {
        if ($_ -match '^([^#][^=]+)=(.*)$') {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            Set-Item -Path "env:$name" -Value $value
        }
    }
    Write-Host "   ✅ Environment variables loaded" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  .env file not found" -ForegroundColor Yellow
}

# Step 5: Create network
Write-Host "`n🌐 Step 5: Creating network..." -ForegroundColor Yellow
podman network exists app-network 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    podman network create app-network 2>&1 | Out-Null
    Write-Host "   ✅ Network created" -ForegroundColor Green
} else {
    Write-Host "   ℹ️  Network already exists" -ForegroundColor Gray
}

# Step 6: Start containers
Write-Host "`n🚀 Step 6: Starting containers..." -ForegroundColor Yellow

# Start fonoster server
Write-Host "   Starting fonoster-server..." -ForegroundColor Cyan
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
    fonoster-server:latest

if ($LASTEXITCODE -ne 0) {
    Write-Host "   ❌ Failed to start fonoster-server" -ForegroundColor Red
    exit 1
}
Write-Host "   ✅ Fonoster server started" -ForegroundColor Green

# Wait for fonoster to be ready
Start-Sleep -Seconds 3

# Start backend
Write-Host "   Starting backend..." -ForegroundColor Cyan
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
    google-intelligent-backend:latest

if ($LASTEXITCODE -ne 0) {
    Write-Host "   ❌ Failed to start backend" -ForegroundColor Red
    exit 1
}
Write-Host "   ✅ Backend started" -ForegroundColor Green

# Wait for backend to be ready
Start-Sleep -Seconds 3

# Start frontend
Write-Host "   Starting frontend..." -ForegroundColor Cyan
podman run -d `
    --name google-intelligent-frontend `
    --network app-network `
    -p 0.0.0.0:3000:3000 `
    -e NEXT_PUBLIC_API_URL=http://$RemoteIP:8000 `
    -e NODE_ENV=production `
    -e NEXT_TELEMETRY_DISABLED=1 `
    --restart unless-stopped `
    google-intelligent-frontend:latest

if ($LASTEXITCODE -ne 0) {
    Write-Host "   ❌ Failed to start frontend" -ForegroundColor Red
    exit 1
}
Write-Host "   ✅ Frontend started" -ForegroundColor Green

# Step 7: Verify containers
Write-Host "`n✅ Step 7: Verifying containers..." -ForegroundColor Yellow
Start-Sleep -Seconds 5
podman ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

Write-Host "`n🎉 Fresh deployment complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Remote Access URLs:" -ForegroundColor Cyan
Write-Host "   Frontend: http://$RemoteIP:3000" -ForegroundColor White
Write-Host "   Backend:  http://$RemoteIP:8000" -ForegroundColor White
Write-Host "   Fonoster: http://$RemoteIP:3001" -ForegroundColor White
Write-Host ""
Write-Host "⚠️  Note: For remote access, you may need:" -ForegroundColor Yellow
Write-Host "   1. Configure Windows Firewall (ports 3000, 8000, 3001)" -ForegroundColor White
Write-Host "   2. Use SSH tunneling if direct access doesn't work" -ForegroundColor White
Write-Host "   3. Run: .\enable-ssh-server.ps1 for SSH tunneling setup" -ForegroundColor White
Write-Host ""

