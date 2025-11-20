# Remote Access Setup Script
# Configures remote access for Podman containers on Windows

Write-Host "`n🌐 Setting Up Remote Access for Podman Containers..." -ForegroundColor Green
Write-Host ""

# Get Windows host IP
Write-Host "🔍 Detecting Windows Host IP..." -ForegroundColor Cyan
$hostIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { 
    $_.IPAddress -notlike "127.*" -and 
    $_.IPAddress -notlike "169.254.*" -and
    $_.IPAddress -notlike "172.*"
} | Select-Object -First 1).IPAddress

if (-not $hostIP) {
    Write-Host "❌ Could not detect Windows host IP" -ForegroundColor Red
    exit 1
}

Write-Host "   Windows Host IP: $hostIP" -ForegroundColor Green

# Check if containers are running
Write-Host "`n🔍 Checking container status..." -ForegroundColor Cyan
$containers = podman ps --format "{{.Names}}"
if (-not $containers) {
    Write-Host "❌ No containers running!" -ForegroundColor Red
    Write-Host "   Please start containers first: podman start fonoster-server google-intelligent-backend google-intelligent-frontend" -ForegroundColor Yellow
    exit 1
}

Write-Host "   ✅ Containers running: $($containers -join ', ')" -ForegroundColor Green

# Check if localhost works
Write-Host "`n🧪 Testing localhost access..." -ForegroundColor Cyan
try {
    $test = Invoke-WebRequest -Uri "http://localhost:3000" -UseBasicParsing -TimeoutSec 3
    Write-Host "   ✅ localhost:3000 is accessible" -ForegroundColor Green
} catch {
    Write-Host "   ❌ localhost:3000 is not accessible" -ForegroundColor Red
    Write-Host "   Please ensure containers are running correctly" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n📋 Remote Access Solutions:" -ForegroundColor Cyan
Write-Host ""

Write-Host "⚠️  IMPORTANT: Podman Desktop on Windows has networking limitations." -ForegroundColor Yellow
Write-Host "   Ports are only forwarded to localhost, not to all interfaces." -ForegroundColor Yellow
Write-Host ""

Write-Host "Solution 1: SSH Tunneling (Recommended for Quick Setup)" -ForegroundColor Green
Write-Host "─────────────────────────────────────────────────────" -ForegroundColor Gray
Write-Host ""
Write-Host "On your remote device, run:" -ForegroundColor White
Write-Host "  ssh -L 3000:localhost:3000 -L 8000:localhost:8000 -L 3001:localhost:3001 $hostIP" -ForegroundColor Cyan
Write-Host ""
Write-Host "Then access:" -ForegroundColor White
Write-Host "  Frontend: http://localhost:3000" -ForegroundColor Gray
Write-Host "  Backend:  http://localhost:8000" -ForegroundColor Gray
Write-Host "  Fonoster: http://localhost:3001" -ForegroundColor Gray
Write-Host ""
Write-Host "Prerequisites:" -ForegroundColor Yellow
Write-Host "  1. Enable SSH Server on Windows (Settings → Apps → Optional Features → OpenSSH Server)" -ForegroundColor White
Write-Host "  2. Configure Windows Firewall to allow SSH (port 22)" -ForegroundColor White
Write-Host "  3. Ensure remote device can reach $hostIP" -ForegroundColor White
Write-Host ""

Write-Host "Solution 2: Deploy to Remote Linux Server (Best for Production)" -ForegroundColor Green
Write-Host "───────────────────────────────────────────────────────────────" -ForegroundColor Gray
Write-Host ""
Write-Host "Deploy directly to a remote Linux server to avoid Windows networking issues:" -ForegroundColor White
Write-Host "  .\deploy-podman-remote.ps1 -ServerIP 'your-remote-server-ip'" -ForegroundColor Cyan
Write-Host ""
Write-Host "This will:" -ForegroundColor White
Write-Host "  - Build containers on remote server" -ForegroundColor Gray
Write-Host "  - Configure proper networking" -ForegroundColor Gray
Write-Host "  - Enable remote access without SSH tunneling" -ForegroundColor Gray
Write-Host ""

Write-Host "Solution 3: Use ngrok or Similar Tunnel Service" -ForegroundColor Green
Write-Host "───────────────────────────────────────────────" -ForegroundColor Gray
Write-Host ""
Write-Host "Use a tunnel service to expose localhost:" -ForegroundColor White
Write-Host "  1. Install ngrok: https://ngrok.com/" -ForegroundColor Gray
Write-Host "  2. Run: ngrok http 3000" -ForegroundColor Cyan
Write-Host "  3. Use the provided public URL" -ForegroundColor Gray
Write-Host ""

Write-Host "📝 Quick Setup for SSH Tunneling:" -ForegroundColor Cyan
Write-Host "─────────────────────────────────" -ForegroundColor Gray
Write-Host ""
Write-Host "Step 1: Enable SSH Server on Windows" -ForegroundColor Yellow
Write-Host "  Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'" -ForegroundColor Cyan
Write-Host "  Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0" -ForegroundColor Cyan
Write-Host "  Start-Service sshd" -ForegroundColor Cyan
Write-Host "  Set-Service -Name sshd -StartupType 'Automatic'" -ForegroundColor Cyan
Write-Host ""
Write-Host "Step 2: Configure Firewall" -ForegroundColor Yellow
Write-Host "  New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22" -ForegroundColor Cyan
Write-Host ""
Write-Host "Step 3: Test SSH connection" -ForegroundColor Yellow
Write-Host "  From remote device: ssh $hostIP" -ForegroundColor Cyan
Write-Host ""

Write-Host "✅ Setup information displayed above!" -ForegroundColor Green
Write-Host ""

