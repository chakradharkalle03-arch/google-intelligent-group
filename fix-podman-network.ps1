# Fix Podman Network Issues
# Troubleshoots and fixes Podman network connectivity

Write-Host "`n🔧 Fixing Podman Network Issues..." -ForegroundColor Green
Write-Host ""

# Test Docker registry connectivity
Write-Host "🔍 Step 1: Testing Docker registry connectivity..." -ForegroundColor Cyan
try {
    $test = Invoke-WebRequest -Uri "https://registry-1.docker.io/v2/" -UseBasicParsing -TimeoutSec 10
    Write-Host "   ✅ Can connect to Docker registry" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Cannot connect to Docker registry" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "💡 Solutions:" -ForegroundColor Cyan
    Write-Host "   1. Check internet connection" -ForegroundColor White
    Write-Host "   2. Check firewall settings" -ForegroundColor White
    Write-Host "   3. Configure proxy if needed" -ForegroundColor White
    Write-Host "   4. Try using a VPN" -ForegroundColor White
    Write-Host "   5. Use SSH tunneling instead (no build needed)" -ForegroundColor White
    Write-Host ""
    exit 1
}

# Check Podman configuration
Write-Host "`n🔍 Step 2: Checking Podman configuration..." -ForegroundColor Cyan
$podmanInfo = podman info 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ Podman is configured correctly" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  Podman configuration issue" -ForegroundColor Yellow
    Write-Host "   $podmanInfo" -ForegroundColor Gray
}

# Check DNS resolution
Write-Host "`n🔍 Step 3: Testing DNS resolution..." -ForegroundColor Cyan
try {
    $dns = Resolve-DnsName -Name "registry-1.docker.io" -ErrorAction Stop
    Write-Host "   ✅ DNS resolution working" -ForegroundColor Green
    Write-Host "   IP: $($dns[0].IPAddress)" -ForegroundColor Gray
} catch {
    Write-Host "   ❌ DNS resolution failed" -ForegroundColor Red
    Write-Host "   Try: nslookup registry-1.docker.io" -ForegroundColor Yellow
}

Write-Host "`n✅ Network diagnostics complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Cyan
Write-Host "   1. If network is working, try: .\fresh-remote-deploy.ps1 -RemoteIP 192.168.0.101" -ForegroundColor White
Write-Host "   2. If network is not working, use SSH tunneling: .\quick-remote-access.ps1" -ForegroundColor White
Write-Host ""

