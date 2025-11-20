# Windows Firewall Configuration Script
# Run as Administrator to allow Podman container ports

Write-Host "`n🔥 Configuring Windows Firewall for Podman..." -ForegroundColor Green
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "❌ This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "   Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Running as Administrator" -ForegroundColor Green
Write-Host ""

# Remove existing rules (if any)
Write-Host "Cleaning up existing rules..." -ForegroundColor Cyan
Remove-NetFirewallRule -DisplayName "Podman Frontend" -ErrorAction SilentlyContinue
Remove-NetFirewallRule -DisplayName "Podman Backend" -ErrorAction SilentlyContinue
Remove-NetFirewallRule -DisplayName "Podman Fonoster" -ErrorAction SilentlyContinue

# Create new firewall rules
Write-Host "Creating firewall rules..." -ForegroundColor Cyan

try {
    # Frontend (Port 3000)
    New-NetFirewallRule -DisplayName "Podman Frontend" `
        -Direction Inbound `
        -LocalPort 3000 `
        -Protocol TCP `
        -Action Allow `
        -Description "Allow inbound connections to Podman Frontend container" | Out-Null
    Write-Host "   ✅ Port 3000 (Frontend) - Allowed" -ForegroundColor Green

    # Backend (Port 8000)
    New-NetFirewallRule -DisplayName "Podman Backend" `
        -Direction Inbound `
        -LocalPort 8000 `
        -Protocol TCP `
        -Action Allow `
        -Description "Allow inbound connections to Podman Backend container" | Out-Null
    Write-Host "   ✅ Port 8000 (Backend) - Allowed" -ForegroundColor Green

    # Fonoster (Port 3001)
    New-NetFirewallRule -DisplayName "Podman Fonoster" `
        -Direction Inbound `
        -LocalPort 3001 `
        -Protocol TCP `
        -Action Allow `
        -Description "Allow inbound connections to Podman Fonoster container" | Out-Null
    Write-Host "   ✅ Port 3001 (Fonoster) - Allowed" -ForegroundColor Green

    Write-Host "`n✅ Firewall configuration complete!" -ForegroundColor Green
    Write-Host "`n🌐 Your containers are now accessible from remote devices!" -ForegroundColor Cyan
    Write-Host "`n📝 To verify:" -ForegroundColor Yellow
    Write-Host "   Get-NetFirewallRule | Where-Object { `$_.DisplayName -like '*Podman*' }" -ForegroundColor Gray

} catch {
    Write-Host "`n❌ Error configuring firewall: $_" -ForegroundColor Red
    exit 1
}

