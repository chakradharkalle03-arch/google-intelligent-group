# PowerShell script to build and run Podman containers
# Usage: .\start-podman.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ReadLife Podman Container Launcher" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Podman is installed
Write-Host "Checking Podman installation..." -ForegroundColor Yellow
try {
    $podmanVersion = podman --version
    Write-Host "✓ Podman found: $podmanVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Podman is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Podman first: https://podman.io/getting-started/installation" -ForegroundColor Red
    exit 1
}

# Check if backend .env exists
if (-not (Test-Path "backend\.env")) {
    Write-Host "⚠ Warning: backend\.env not found" -ForegroundColor Yellow
    Write-Host "Creating backend\.env from env.example..." -ForegroundColor Yellow
    if (Test-Path "backend\env.example") {
        Copy-Item "backend\env.example" "backend\.env"
        Write-Host "✓ Created backend\.env - Please edit it with your API keys!" -ForegroundColor Yellow
    } else {
        Write-Host "✗ backend\env.example not found!" -ForegroundColor Red
        exit 1
    }
}

# Function to check if container exists
function Test-Container {
    param([string]$Name)
    $result = podman ps -a --format "{{.Names}}" | Select-String -Pattern "^$Name$"
    return $result -ne $null
}

# Function to remove existing container
function Remove-ContainerIfExists {
    param([string]$Name)
    if (Test-Container -Name $Name) {
        Write-Host "Removing existing container: $Name" -ForegroundColor Yellow
        podman rm -f $Name | Out-Null
    }
}

# Build Backend
Write-Host ""
Write-Host "Building backend container..." -ForegroundColor Cyan
Set-Location backend
podman build -t readlife-backend:latest -f Containerfile .
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Backend build failed!" -ForegroundColor Red
    Set-Location ..
    exit 1
}
Write-Host "✓ Backend container built successfully" -ForegroundColor Green
Set-Location ..

# Build Frontend
Write-Host ""
Write-Host "Building frontend container..." -ForegroundColor Cyan
Set-Location frontend
$apiUrl = Read-Host "Enter backend API URL (default: http://127.0.0.1:8000)"
if ([string]::IsNullOrWhiteSpace($apiUrl)) {
    $apiUrl = "http://127.0.0.1:8000"
}
podman build -t readlife-frontend:latest -f Containerfile --build-arg NEXT_PUBLIC_API_URL=$apiUrl .
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Frontend build failed!" -ForegroundColor Red
    Set-Location ..
    exit 1
}
Write-Host "✓ Frontend container built successfully" -ForegroundColor Green
Set-Location ..

# Remove existing containers if they exist
Write-Host ""
Write-Host "Cleaning up existing containers..." -ForegroundColor Yellow
Remove-ContainerIfExists -Name "readlife-backend"
Remove-ContainerIfExists -Name "readlife-frontend"

# Run Backend
Write-Host ""
Write-Host "Starting backend container..." -ForegroundColor Cyan
podman run -d `
    --name readlife-backend `
    -p 8000:8000 `
    --env-file backend\.env `
    readlife-backend:latest

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Failed to start backend container!" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Backend container started" -ForegroundColor Green

# Wait for backend to be ready
Write-Host "Waiting for backend to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 3

# Check backend health
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8000/health" -TimeoutSec 5 -UseBasicParsing
    if ($response.StatusCode -eq 200) {
        Write-Host "✓ Backend is healthy" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠ Backend may not be ready yet, but container is running" -ForegroundColor Yellow
}

# Run Frontend
Write-Host ""
Write-Host "Starting frontend container..." -ForegroundColor Cyan
podman run -d `
    --name readlife-frontend `
    -p 3000:3000 `
    readlife-frontend:latest

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Failed to start frontend container!" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Frontend container started" -ForegroundColor Green

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Containers Started Successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Backend:  http://localhost:8000" -ForegroundColor White
Write-Host "Frontend: http://localhost:3000" -ForegroundColor White
Write-Host ""
Write-Host "Useful commands:" -ForegroundColor Yellow
Write-Host "  View logs:    podman logs -f readlife-backend" -ForegroundColor Gray
Write-Host "  View logs:    podman logs -f readlife-frontend" -ForegroundColor Gray
Write-Host "  Stop:         podman stop readlife-backend readlife-frontend" -ForegroundColor Gray
Write-Host "  Start:        podman start readlife-backend readlife-frontend" -ForegroundColor Gray
Write-Host "  Remove:       podman rm -f readlife-backend readlife-frontend" -ForegroundColor Gray
Write-Host ""

