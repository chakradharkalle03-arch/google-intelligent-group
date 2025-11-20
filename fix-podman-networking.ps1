# Fix Podman Networking Script for Windows
# Attempts to resolve Podman machine networking issues

Write-Host "🔧 Fixing Podman Networking..." -ForegroundColor Cyan
Write-Host ""

# Check if Podman is installed
if (-not (Get-Command podman -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Podman is not installed" -ForegroundColor Red
    exit 1
}

Write-Host "Current Podman machine status:" -ForegroundColor Yellow
podman machine list
Write-Host ""

# Ask user if they want to recreate the machine
$response = Read-Host "This will recreate your Podman machine. Continue? (y/N)"
if ($response -ne "y" -and $response -ne "Y") {
    Write-Host "Cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host "`n🛑 Stopping existing Podman machine..." -ForegroundColor Yellow
podman machine stop podman-machine-default 2>$null
Start-Sleep -Seconds 2

Write-Host "🗑️  Removing existing Podman machine..." -ForegroundColor Yellow
podman machine rm podman-machine-default -f 2>$null
Start-Sleep -Seconds 2

Write-Host "🆕 Creating new Podman machine..." -ForegroundColor Yellow
podman machine init podman-machine-default
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to create Podman machine" -ForegroundColor Red
    exit 1
}

Write-Host "🚀 Starting Podman machine..." -ForegroundColor Yellow
podman machine start podman-machine-default
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to start Podman machine" -ForegroundColor Red
    exit 1
}

Start-Sleep -Seconds 5

Write-Host "`n🧪 Testing connectivity..." -ForegroundColor Yellow
$testPull = podman pull alpine:latest 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Networking is working! Podman can now pull images." -ForegroundColor Green
    Write-Host "`nYou can now run: .\build-podman.ps1" -ForegroundColor Cyan
} else {
    Write-Host "❌ Networking issue persists." -ForegroundColor Red
    Write-Host "`nTroubleshooting steps:" -ForegroundColor Yellow
    Write-Host "1. Check your internet connection" -ForegroundColor Gray
    Write-Host "2. Check Windows Firewall settings" -ForegroundColor Gray
    Write-Host "3. Try restarting WSL2: wsl --shutdown" -ForegroundColor Gray
    Write-Host "4. Consider using Docker Desktop instead" -ForegroundColor Gray
    Write-Host "`nSee PODMAN_WINDOWS_TROUBLESHOOTING.md for more help" -ForegroundColor Cyan
}

