# Run Docker Containers Script for Windows PowerShell
# Alternative to Podman if Podman networking is not working

Write-Host "🚀 Starting Docker containers..." -ForegroundColor Cyan
Write-Host ""

# Check if Docker is installed
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Docker is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

# Check if containers are already running
$backendRunning = docker ps --filter "name=readlife-backend" --format "{{.Names}}" 2>$null
$frontendRunning = docker ps --filter "name=readlife-frontend" --format "{{.Names}}" 2>$null

# Stop and remove existing containers if they exist
if ($backendRunning) {
    Write-Host "🛑 Stopping existing backend container..." -ForegroundColor Yellow
    docker stop readlife-backend 2>$null
    docker rm readlife-backend 2>$null
}

if ($frontendRunning) {
    Write-Host "🛑 Stopping existing frontend container..." -ForegroundColor Yellow
    docker stop readlife-frontend 2>$null
    docker rm readlife-frontend 2>$null
}

# Check if images exist
$backendImage = docker images --format "{{.Repository}}:{{.Tag}}" | Select-String "readlife-backend:latest"
$frontendImage = docker images --format "{{.Repository}}:{{.Tag}}" | Select-String "readlife-frontend:latest"

if (-not $backendImage) {
    Write-Host "❌ Backend image not found. Please run .\build-docker.ps1 first" -ForegroundColor Red
    exit 1
}

if (-not $frontendImage) {
    Write-Host "❌ Frontend image not found. Please run .\build-docker.ps1 first" -ForegroundColor Red
    exit 1
}

# Check if .env file exists for backend
if (-not (Test-Path "backend\.env")) {
    Write-Host "⚠️  Warning: backend\.env not found" -ForegroundColor Yellow
    Write-Host "   Creating from env.example..." -ForegroundColor Yellow
    if (Test-Path "backend\env.example") {
        Copy-Item "backend\env.example" "backend\.env"
        Write-Host "   Please edit backend\.env and add your GEMINI_API_KEY" -ForegroundColor Yellow
    } else {
        Write-Host "   Please create backend\.env with required environment variables" -ForegroundColor Yellow
    }
}

# Create network if it doesn't exist
$networkExists = docker network ls --format "{{.Name}}" | Select-String "readlife-network"
if (-not $networkExists) {
    Write-Host "🌐 Creating Docker network..." -ForegroundColor Yellow
    docker network create readlife-network
}

Write-Host ""

# Start Backend Container
Write-Host "🔵 Starting backend container..." -ForegroundColor Yellow
$backendArgs = @(
    "run", "-d",
    "--name", "readlife-backend",
    "--network", "readlife-network",
    "-p", "8080:8080"
)

# Add env file if it exists
if (Test-Path "backend\.env") {
    $backendArgs += "--env-file", "backend\.env"
}

$backendArgs += "-e", "PORT=8080", "-e", "HOST=0.0.0.0", "readlife-backend:latest"

docker @backendArgs
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to start backend container!" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Backend container started" -ForegroundColor Green

# Wait a moment for backend to start
Start-Sleep -Seconds 2

# Start Frontend Container
Write-Host "🟢 Starting frontend container..." -ForegroundColor Yellow
$frontendArgs = @(
    "run", "-d",
    "--name", "readlife-frontend",
    "--network", "readlife-network",
    "-p", "3000:3000",
    "--env", "NEXT_PUBLIC_API_URL=http://readlife-backend:8080",
    "readlife-frontend:latest"
)

docker @frontendArgs
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to start frontend container!" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Frontend container started" -ForegroundColor Green

Write-Host ""
Write-Host "⏳ Waiting for containers to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Check container status
Write-Host ""
Write-Host "📊 Container Status:" -ForegroundColor Cyan
docker ps --filter "name=readlife-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

Write-Host ""
Write-Host "🔍 Health Checks:" -ForegroundColor Cyan

# Check backend health
try {
    $backendHealth = Invoke-WebRequest -Uri "http://localhost:8080/health" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
    Write-Host "   ✅ Backend (port 8080): Healthy - Status $($backendHealth.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "   ⚠️  Backend (port 8080): Not responding yet" -ForegroundColor Yellow
}

# Check frontend
try {
    $frontendHealth = Invoke-WebRequest -Uri "http://localhost:3000" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
    Write-Host "   ✅ Frontend (port 3000): Running - Status $($frontendHealth.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "   ⚠️  Frontend (port 3000): Not responding yet" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🌐 Access URLs:" -ForegroundColor Cyan
Write-Host "   Frontend:    http://localhost:3000" -ForegroundColor White
Write-Host "   Backend API: http://localhost:8080" -ForegroundColor White
Write-Host "   Health:      http://localhost:8080/health" -ForegroundColor White

Write-Host ""
Write-Host "📝 Useful commands:" -ForegroundColor Cyan
Write-Host "   View logs:    docker logs -f readlife-backend" -ForegroundColor Gray
Write-Host "   Stop:         docker stop readlife-backend readlife-frontend" -ForegroundColor Gray
Write-Host "   Remove:       docker rm readlife-backend readlife-frontend" -ForegroundColor Gray

