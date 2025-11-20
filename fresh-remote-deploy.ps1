# Fresh Remote Deployment Script
# Kills all Podman processes and deploys fresh with remote IP

param(
    [string]$RemoteIP = "192.168.0.101"  # Remote IP address
)

Write-Host "`n🔄 Fresh Remote Deployment" -ForegroundColor Green
Write-Host "   Remote IP: $RemoteIP" -ForegroundColor Cyan
Write-Host ""

# Step 1: Stop and remove all containers
Write-Host "🧹 Step 1: Stopping and removing all containers..." -ForegroundColor Yellow
$containers = podman ps -a --format "{{.Names}}" 2>&1
if ($containers -and $containers -notmatch "error|Error") {
    foreach ($container in $containers) {
        Write-Host "   Stopping: $container" -ForegroundColor Gray
        podman stop $container 2>&1 | Out-Null
        Write-Host "   Removing: $container" -ForegroundColor Gray
        podman rm $container 2>&1 | Out-Null
    }
    Write-Host "   ✅ All containers stopped and removed" -ForegroundColor Green
} else {
    Write-Host "   ℹ️  No containers to remove" -ForegroundColor Gray
}

# Step 2: Remove all images (optional, but for fresh start)
Write-Host "`n🧹 Step 2: Removing container images..." -ForegroundColor Yellow
$images = podman images --format "{{.Repository}}:{{.Tag}}" | Select-String "google-intelligent|fonoster"
if ($images) {
    foreach ($image in $images) {
        Write-Host "   Removing: $image" -ForegroundColor Gray
        podman rmi $image 2>&1 | Out-Null
    }
    Write-Host "   ✅ Images removed" -ForegroundColor Green
} else {
    Write-Host "   ℹ️  No images to remove" -ForegroundColor Gray
}

# Step 3: Clean up Podman system
Write-Host "`n🧹 Step 3: Cleaning up Podman system..." -ForegroundColor Yellow
podman system prune -af 2>&1 | Out-Null
Write-Host "   ✅ System cleaned" -ForegroundColor Green

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

# Check required environment variables
if ([string]::IsNullOrEmpty($env:GEMINI_API_KEY)) {
    Write-Host "   ❌ GEMINI_API_KEY is not set" -ForegroundColor Red
    exit 1
}

if ([string]::IsNullOrEmpty($env:GOOGLE_MAPS_API_KEY)) {
    Write-Host "   ❌ GOOGLE_MAPS_API_KEY is not set" -ForegroundColor Red
    exit 1
}

# Step 5: Build containers with remote IP
Write-Host "`n📦 Step 5: Building containers for remote access..." -ForegroundColor Yellow

# Build backend
Write-Host "`n   Building backend..." -ForegroundColor Cyan
Set-Location backend
podman build -t google-intelligent-backend:latest -f Containerfile .
if ($LASTEXITCODE -ne 0) {
    Write-Host "   ❌ Failed to build backend" -ForegroundColor Red
    Set-Location ..
    exit 1
}
Write-Host "   ✅ Backend built" -ForegroundColor Green
Set-Location ..

# Build frontend with remote API URL
Write-Host "`n   Building frontend with remote API URL..." -ForegroundColor Cyan
Set-Location frontend
$apiUrl = "http://$RemoteIP:8000"
Write-Host "   API URL: $apiUrl" -ForegroundColor Gray
podman build --build-arg NEXT_PUBLIC_API_URL=$apiUrl -t google-intelligent-frontend:latest -f Containerfile .
if ($LASTEXITCODE -ne 0) {
    Write-Host "   ❌ Failed to build frontend" -ForegroundColor Red
    Set-Location ..
    exit 1
}
Write-Host "   ✅ Frontend built with remote API URL" -ForegroundColor Green
Set-Location ..

# Build fonoster server
Write-Host "`n   Building fonoster server..." -ForegroundColor Cyan
Set-Location fonoster-server
podman build -t fonoster-server:latest -f Containerfile .
if ($LASTEXITCODE -ne 0) {
    Write-Host "   ❌ Failed to build fonoster server" -ForegroundColor Red
    Set-Location ..
    exit 1
}
Write-Host "   ✅ Fonoster server built" -ForegroundColor Green
Set-Location ..

# Step 6: Create network
Write-Host "`n🌐 Step 6: Creating network..." -ForegroundColor Yellow
podman network exists app-network 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    podman network create app-network 2>&1 | Out-Null
    Write-Host "   ✅ Network created" -ForegroundColor Green
} else {
    Write-Host "   ℹ️  Network already exists" -ForegroundColor Gray
}

# Step 7: Start containers
Write-Host "`n🚀 Step 7: Starting containers..." -ForegroundColor Yellow

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

# Step 8: Verify containers
Write-Host "`n✅ Step 8: Verifying containers..." -ForegroundColor Yellow
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

