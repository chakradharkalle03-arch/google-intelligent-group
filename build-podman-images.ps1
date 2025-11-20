# Build Podman Images Script
# Builds all container images for local deployment

Write-Host "`n=== BUILDING PODMAN IMAGES ===" -ForegroundColor Green
Write-Host ""

# Check Podman
Write-Host "Step 1: Checking Podman..." -ForegroundColor Yellow
if (-not (Get-Command podman -ErrorAction SilentlyContinue)) {
    Write-Host "  ERROR: Podman not found" -ForegroundColor Red
    Write-Host "  Please install Podman Desktop" -ForegroundColor Yellow
    exit 1
}

$podmanVersion = podman --version
Write-Host "  Podman found: $podmanVersion" -ForegroundColor Green

# Check Podman machine
Write-Host "`nStep 2: Checking Podman machine..." -ForegroundColor Yellow
$machineCheck = podman info --format "{{.Host.OS}}" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "  WARNING: Podman machine not running" -ForegroundColor Yellow
    Write-Host "  Attempting to start..." -ForegroundColor Yellow
    podman machine start 2>&1 | Out-Null
    Start-Sleep -Seconds 5
}

$machineCheck = podman info --format "{{.Host.OS}}" 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "  Podman machine is ready" -ForegroundColor Green
} else {
    Write-Host "  ERROR: Cannot connect to Podman machine" -ForegroundColor Red
    Write-Host "  Please start Podman Desktop" -ForegroundColor Yellow
    exit 1
}

# Build fonoster-server
Write-Host "`nStep 3: Building fonoster-server..." -ForegroundColor Yellow
Write-Host "  This may take several minutes..." -ForegroundColor Gray
Set-Location fonoster-server
podman build -t fonoster-server:latest -f Containerfile .
if ($LASTEXITCODE -eq 0) {
    Write-Host "  Fonoster server built successfully" -ForegroundColor Green
} else {
    Write-Host "  ERROR: Failed to build fonoster-server" -ForegroundColor Red
    Set-Location ..
    exit 1
}
Set-Location ..

# Build backend
Write-Host "`nStep 4: Building backend..." -ForegroundColor Yellow
Write-Host "  This may take several minutes..." -ForegroundColor Gray
Set-Location backend
podman build -t google-intelligent-backend:latest -f Containerfile .
if ($LASTEXITCODE -eq 0) {
    Write-Host "  Backend built successfully" -ForegroundColor Green
} else {
    Write-Host "  ERROR: Failed to build backend" -ForegroundColor Red
    Set-Location ..
    exit 1
}
Set-Location ..

# Build frontend
Write-Host "`nStep 5: Building frontend..." -ForegroundColor Yellow
Write-Host "  This may take several minutes..." -ForegroundColor Gray
Set-Location frontend
podman build -t google-intelligent-frontend:latest -f Containerfile .
if ($LASTEXITCODE -eq 0) {
    Write-Host "  Frontend built successfully" -ForegroundColor Green
} else {
    Write-Host "  ERROR: Failed to build frontend" -ForegroundColor Red
    Set-Location ..
    exit 1
}
Set-Location ..

# List images
Write-Host "`nStep 6: Verifying images..." -ForegroundColor Yellow
podman images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | Select-String "fonoster-server|google-intelligent"

Write-Host "`n=== BUILD COMPLETE ===" -ForegroundColor Green
Write-Host ""
Write-Host "All images built successfully!" -ForegroundColor Green
Write-Host "Next step: Run .\start-podman.ps1 to start containers" -ForegroundColor Cyan
Write-Host ""

