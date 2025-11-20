# Build Docker Containers Script for Windows PowerShell
# Alternative to Podman if Podman networking is not working

Write-Host "🔨 Building Docker containers..." -ForegroundColor Cyan
Write-Host ""

# Check if Docker is installed
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Docker is not installed or not in PATH" -ForegroundColor Red
    Write-Host "   Please install Docker Desktop from https://www.docker.com/products/docker-desktop/" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Docker found: $(docker --version)" -ForegroundColor Green
Write-Host ""

# Build Backend Container
Write-Host "📦 Building backend container..." -ForegroundColor Yellow
Set-Location backend
$backendBuild = docker build -t readlife-backend:latest -f Containerfile .
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Backend build failed!" -ForegroundColor Red
    Set-Location ..
    exit 1
}
Write-Host "✅ Backend container built successfully" -ForegroundColor Green
Set-Location ..

Write-Host ""

# Build Frontend Container
Write-Host "📦 Building frontend container..." -ForegroundColor Yellow
Set-Location frontend

# Get the API URL from environment or use default
$apiUrl = $env:NEXT_PUBLIC_API_URL
if (-not $apiUrl) {
    $apiUrl = "http://localhost:8080"
    Write-Host "   Using default API URL: $apiUrl" -ForegroundColor Gray
} else {
    Write-Host "   Using API URL from environment: $apiUrl" -ForegroundColor Gray
}

$frontendBuild = docker build --build-arg NEXT_PUBLIC_API_URL=$apiUrl -t readlife-frontend:latest -f Containerfile .
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Frontend build failed!" -ForegroundColor Red
    Set-Location ..
    exit 1
}
Write-Host "✅ Frontend container built successfully" -ForegroundColor Green
Set-Location ..

Write-Host ""
Write-Host "🎉 All containers built successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Run containers: .\run-docker.ps1" -ForegroundColor White
Write-Host "  2. Or manually: docker run -d --name readlife-backend -p 8080:8080 --env-file backend/.env readlife-backend:latest" -ForegroundColor Gray

