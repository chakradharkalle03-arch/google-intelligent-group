# Enable SSH Server on Windows
# Run as Administrator

Write-Host "`n🔧 Enabling SSH Server on Windows..." -ForegroundColor Green
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "❌ This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "   Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Running as Administrator" -ForegroundColor Green

# Check if SSH Server is already installed
Write-Host "`n🔍 Checking SSH Server status..." -ForegroundColor Cyan
$sshStatus = Get-Service -Name sshd -ErrorAction SilentlyContinue

if ($sshStatus) {
    if ($sshStatus.Status -eq "Running") {
        Write-Host "   ✅ SSH Server is already running" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  SSH Server is installed but not running" -ForegroundColor Yellow
        Write-Host "   Starting SSH Server..." -ForegroundColor Cyan
        Start-Service sshd
        Set-Service -Name sshd -StartupType 'Automatic'
        Write-Host "   ✅ SSH Server started and set to auto-start" -ForegroundColor Green
    }
} else {
    Write-Host "   📦 Installing SSH Server..." -ForegroundColor Cyan
    
    # Install OpenSSH Server
    $capability = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'
    
    if ($capability) {
        Add-WindowsCapability -Online -Name $capability.Name
        Write-Host "   ✅ SSH Server installed" -ForegroundColor Green
        
        # Start SSH Server
        Start-Service sshd
        Set-Service -Name sshd -StartupType 'Automatic'
        Write-Host "   ✅ SSH Server started and set to auto-start" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Could not find OpenSSH Server capability" -ForegroundColor Red
        Write-Host "   Please install manually from Settings → Apps → Optional Features" -ForegroundColor Yellow
        exit 1
    }
}

# Configure Firewall
Write-Host "`n🔥 Configuring Windows Firewall..." -ForegroundColor Cyan
$firewallRule = Get-NetFirewallRule -Name sshd -ErrorAction SilentlyContinue

if (-not $firewallRule) {
    New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
    Write-Host "   ✅ Firewall rule created for SSH (port 22)" -ForegroundColor Green
} else {
    Write-Host "   ✅ Firewall rule already exists" -ForegroundColor Green
}

# Get Windows host IP
$hostIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { 
    $_.IPAddress -notlike "127.*" -and 
    $_.IPAddress -notlike "169.254.*" -and
    $_.IPAddress -notlike "172.*"
} | Select-Object -First 1).IPAddress

Write-Host "`n✅ SSH Server is ready!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Connection Information:" -ForegroundColor Cyan
Write-Host "   Windows Host IP: $hostIP" -ForegroundColor White
Write-Host "   SSH Port: 22" -ForegroundColor White
Write-Host ""
Write-Host "🔗 From remote device, connect using:" -ForegroundColor Yellow
Write-Host "   ssh $hostIP" -ForegroundColor Cyan
Write-Host ""
Write-Host "📝 For port forwarding (from remote device):" -ForegroundColor Yellow
Write-Host "   ssh -L 3000:localhost:3000 -L 8000:localhost:8000 -L 3001:localhost:3001 $hostIP" -ForegroundColor Cyan
Write-Host ""

