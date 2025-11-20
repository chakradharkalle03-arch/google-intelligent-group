# Test Remote Access Script
# Helps diagnose and test remote access to Podman containers

Write-Host "`n🔍 Testing Remote Access Configuration..." -ForegroundColor Green
Write-Host ""

# Get Windows host IPs
Write-Host "1. Finding Windows Host IP Addresses..." -ForegroundColor Cyan
$hostIPs = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { 
    $_.IPAddress -notlike "127.*" -and 
    $_.IPAddress -notlike "169.254.*" -and
    $_.IPAddress -notlike "172.22.*" -and
    $_.IPAddress -notlike "172.17.*"
} | Select-Object IPAddress, InterfaceAlias

if ($hostIPs) {
    Write-Host "   ✅ Found Windows host IPs:" -ForegroundColor Green
    $hostIPs | ForEach-Object {
        Write-Host "      - $($_.IPAddress) ($($_.InterfaceAlias))" -ForegroundColor White
    }
} else {
    Write-Host "   ⚠️  No suitable IP found. Showing all IPs:" -ForegroundColor Yellow
    Get-NetIPAddress -AddressFamily IPv4 | Format-Table IPAddress, InterfaceAlias -AutoSize
}

# Check container status
Write-Host "`n2. Checking Container Status..." -ForegroundColor Cyan
$containers = podman ps --format "{{.Names}}"
if ($containers) {
    Write-Host "   ✅ Containers running:" -ForegroundColor Green
    $containers | ForEach-Object { Write-Host "      - $_" -ForegroundColor White }
} else {
    Write-Host "   ❌ No containers running!" -ForegroundColor Red
    exit 1
}

# Check port bindings
Write-Host "`n3. Checking Port Bindings..." -ForegroundColor Cyan
$ports = podman ps --format "{{.Ports}}"
if ($ports -match "0\.0\.0\.0") {
    Write-Host "   ✅ Ports bound to 0.0.0.0 (all interfaces)" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  Ports may not be bound to all interfaces" -ForegroundColor Yellow
    Write-Host "   Current bindings: $ports" -ForegroundColor Gray
}

# Check firewall rules
Write-Host "`n4. Checking Firewall Rules..." -ForegroundColor Cyan
$firewallRules = Get-NetFirewallRule | Where-Object { $_.DisplayName -like "*Podman*" }
if ($firewallRules) {
    Write-Host "   ✅ Firewall rules found:" -ForegroundColor Green
    $firewallRules | ForEach-Object {
        $port = (Get-NetFirewallPortFilter -AssociatedNetFirewallRule $_).LocalPort
        Write-Host "      - $($_.DisplayName) (Port $port) - $($_.Enabled)" -ForegroundColor White
    }
} else {
    Write-Host "   ⚠️  No Podman firewall rules found!" -ForegroundColor Yellow
    Write-Host "   Run: .\configure-firewall.ps1 (as Administrator)" -ForegroundColor Gray
}

# Test localhost access
Write-Host "`n5. Testing Localhost Access..." -ForegroundColor Cyan
$tests = @(
    @{Name="Backend Health"; URL="http://localhost:8000/health"},
    @{Name="Frontend"; URL="http://localhost:3000"},
    @{Name="Fonoster Health"; URL="http://localhost:3001/health"}
)

foreach ($test in $tests) {
    try {
        $response = Invoke-WebRequest -Uri $test.URL -UseBasicParsing -TimeoutSec 3
        Write-Host "   ✅ $($test.Name): Working (Status: $($response.StatusCode))" -ForegroundColor Green
    } catch {
        Write-Host "   ❌ $($test.Name): Not accessible" -ForegroundColor Red
    }
}

# Test remote access if IP found
if ($hostIPs) {
    Write-Host "`n6. Testing Remote Access..." -ForegroundColor Cyan
    $testIP = $hostIPs[0].IPAddress
    
    Write-Host "   Testing with IP: $testIP" -ForegroundColor Yellow
    
    $remoteTests = @(
        @{Name="Backend Health"; URL="http://${testIP}:8000/health"},
        @{Name="Frontend"; URL="http://${testIP}:3000"},
        @{Name="Fonoster Health"; URL="http://${testIP}:3001/health"}
    )
    
    foreach ($test in $remoteTests) {
        try {
            $response = Invoke-WebRequest -Uri $test.URL -UseBasicParsing -TimeoutSec 3
            Write-Host "   ✅ $($test.Name): Working via $testIP" -ForegroundColor Green
        } catch {
            Write-Host "   ❌ $($test.Name): Not accessible via $testIP" -ForegroundColor Red
            Write-Host "      Error: $($_.Exception.Message)" -ForegroundColor Gray
        }
    }
}

# Summary and recommendations
Write-Host "`n📋 Summary & Recommendations:" -ForegroundColor Cyan
Write-Host ""

if ($hostIPs) {
    $recommendedIP = $hostIPs[0].IPAddress
    Write-Host "   ✅ Use this IP for remote access: $recommendedIP" -ForegroundColor Green
    Write-Host "`n   Access URLs:" -ForegroundColor Yellow
    Write-Host "      Frontend: http://$recommendedIP:3000" -ForegroundColor White
    Write-Host "      Backend:  http://$recommendedIP:8000" -ForegroundColor White
    Write-Host "      Fonoster: http://$recommendedIP:3001" -ForegroundColor White
} else {
    Write-Host "   ⚠️  Could not determine Windows host IP" -ForegroundColor Yellow
    Write-Host "   Run 'ipconfig' to find your IP address" -ForegroundColor White
}

Write-Host "`n   If remote access doesn't work:" -ForegroundColor Yellow
Write-Host "   1. Verify firewall rules are enabled" -ForegroundColor White
Write-Host "   2. Check Podman Desktop port forwarding settings" -ForegroundColor White
Write-Host "   3. Ensure devices are on the same network" -ForegroundColor White
Write-Host "   4. Try accessing from another device on the network" -ForegroundColor White
Write-Host ""

