# Fix Remote Access Script
# Configure port forwarding from WSL to Windows host
# Must run as Administrator

Write-Host "`n🔧 Fixing Remote Access Configuration..." -ForegroundColor Green
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "❌ This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "`nPlease follow these steps:" -ForegroundColor Yellow
    Write-Host "1. Right-click PowerShell" -ForegroundColor White
    Write-Host "2. Select 'Run as Administrator'" -ForegroundColor White
    Write-Host "3. Run: cd C:\Users\user\Downloads\readlife" -ForegroundColor White
    Write-Host "4. Run: .\fix-remote-access.ps1" -ForegroundColor White
    exit 1
}

Write-Host "✅ Running as Administrator" -ForegroundColor Green

# Get WSL IP address
Write-Host "`n🔍 Finding WSL IP address..." -ForegroundColor Cyan
$wslIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { 
    $_.IPAddress -like "172.22.*" -or $_.IPAddress -like "172.17.*"
} | Select-Object -First 1).IPAddress

if (-not $wslIP) {
    Write-Host "⚠️  Could not auto-detect WSL IP, trying alternative method..." -ForegroundColor Yellow
    try {
        $wslOutput = wsl hostname -I 2>$null
        if ($wslOutput) {
            $wslIP = $wslOutput.Trim().Split()[0]
        }
    } catch {
        Write-Host "❌ Could not get WSL IP address" -ForegroundColor Red
        Write-Host "   Please ensure Podman Desktop is running" -ForegroundColor Yellow
        exit 1
    }
}

if (-not $wslIP) {
    Write-Host "❌ Could not determine WSL IP address" -ForegroundColor Red
    Write-Host "   Please check if Podman Desktop is running" -ForegroundColor Yellow
    exit 1
}

Write-Host "   Found WSL IP: $wslIP" -ForegroundColor Green

# Remove existing port forwarding rules
Write-Host "`n🧹 Cleaning up existing port forwarding rules..." -ForegroundColor Cyan
netsh interface portproxy delete v4tov4 listenport=3000 listenaddress=0.0.0.0 2>$null
netsh interface portproxy delete v4tov4 listenport=8000 listenaddress=0.0.0.0 2>$null
netsh interface portproxy delete v4tov4 listenport=3001 listenaddress=0.0.0.0 2>$null
Start-Sleep -Seconds 1

# Add port forwarding rules
Write-Host "`n📝 Adding port forwarding rules..." -ForegroundColor Cyan

try {
    # Port 3000 (Frontend)
    netsh interface portproxy add v4tov4 listenport=3000 listenaddress=0.0.0.0 connectport=3000 connectaddress=$wslIP 2>&1 | Out-Null
    Write-Host "   ✅ Port 3000 → $wslIP:3000" -ForegroundColor Green

    # Port 8000 (Backend)
    netsh interface portproxy add v4tov4 listenport=8000 listenaddress=0.0.0.0 connectport=8000 connectaddress=$wslIP 2>&1 | Out-Null
    Write-Host "   ✅ Port 8000 → $wslIP:8000" -ForegroundColor Green

    # Port 3001 (Fonoster)
    netsh interface portproxy add v4tov4 listenport=3001 listenaddress=0.0.0.0 connectport=3001 connectaddress=$wslIP 2>&1 | Out-Null
    Write-Host "   ✅ Port 3001 → $wslIP:3001" -ForegroundColor Green

    Write-Host "`n✅ Port forwarding configured successfully!" -ForegroundColor Green

    # Show current rules
    Write-Host "`n📋 Current Port Forwarding Rules:" -ForegroundColor Cyan
    netsh interface portproxy show all

    # Get Windows host IP
    $hostIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { 
        $_.IPAddress -notlike "127.*" -and 
        $_.IPAddress -notlike "169.254.*" -and
        $_.IPAddress -notlike "172.*"
    } | Select-Object -First 1).IPAddress

    if ($hostIP) {
        Write-Host "`n🌐 Remote Access URLs:" -ForegroundColor Yellow
        Write-Host "   Frontend: http://$hostIP:3000" -ForegroundColor White
        Write-Host "   Backend:  http://$hostIP:8000" -ForegroundColor White
        Write-Host "   Fonoster: http://$hostIP:3001" -ForegroundColor White
        
        Write-Host "`n🧪 Testing connection..." -ForegroundColor Cyan
        Start-Sleep -Seconds 2
        
        try {
            $test = Invoke-WebRequest -Uri "http://$hostIP:8000/health" -UseBasicParsing -TimeoutSec 5
            Write-Host "   ✅ Backend accessible via $hostIP:8000" -ForegroundColor Green
        } catch {
            Write-Host "   ⚠️  Backend test failed, may need a few seconds to take effect" -ForegroundColor Yellow
        }
    }

    Write-Host "`n⚠️  Note: Port forwarding rules are temporary and will be lost after reboot." -ForegroundColor Yellow
    Write-Host "   To make them persistent, create a scheduled task or startup script." -ForegroundColor White

} catch {
    Write-Host "`n❌ Error configuring port forwarding: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
