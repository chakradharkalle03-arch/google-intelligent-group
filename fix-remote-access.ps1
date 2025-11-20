# 修復遠端存取腳本
# 設定 WSL 到 Windows 的連接埠轉送
# 必須以管理員身份執行

Write-Host "`n🔧 修復遠端存取設定..." -ForegroundColor Green
Write-Host ""

# 檢查管理員權限
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "❌ 此腳本必須以管理員身份執行！" -ForegroundColor Red
    Write-Host "`n請執行以下步驟：" -ForegroundColor Yellow
    Write-Host "1. 右鍵點擊 PowerShell" -ForegroundColor White
    Write-Host "2. 選擇「以系統管理員身分執行」" -ForegroundColor White
    Write-Host "3. 執行: cd C:\Users\user\Downloads\readlife" -ForegroundColor White
    Write-Host "4. 執行: .\fix-remote-access.ps1" -ForegroundColor White
    exit 1
}

Write-Host "✅ 已以管理員身份執行" -ForegroundColor Green

# 取得 WSL IP
Write-Host "`n🔍 尋找 WSL IP 位址..." -ForegroundColor Cyan
$wslIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { 
    $_.IPAddress -like "172.22.*" -or $_.IPAddress -like "172.17.*"
} | Select-Object -First 1).IPAddress

if (-not $wslIP) {
    Write-Host "⚠️  無法自動找到 WSL IP，嘗試其他方法..." -ForegroundColor Yellow
    try {
        $wslOutput = wsl hostname -I 2>$null
        if ($wslOutput) {
            $wslIP = $wslOutput.Trim().Split()[0]
        }
    } catch {
        Write-Host "❌ 無法取得 WSL IP 位址" -ForegroundColor Red
        Write-Host "   請確認 Podman Desktop 正在執行" -ForegroundColor Yellow
        exit 1
    }
}

if (-not $wslIP) {
    Write-Host "❌ 無法確定 WSL IP 位址" -ForegroundColor Red
    Write-Host "   請檢查 Podman Desktop 是否正在執行" -ForegroundColor Yellow
    exit 1
}

Write-Host "   找到 WSL IP: $wslIP" -ForegroundColor Green

# 清除現有的連接埠轉送規則
Write-Host "`n🧹 清除現有的連接埠轉送規則..." -ForegroundColor Cyan
netsh interface portproxy delete v4tov4 listenport=3000 listenaddress=0.0.0.0 2>$null
netsh interface portproxy delete v4tov4 listenport=8000 listenaddress=0.0.0.0 2>$null
netsh interface portproxy delete v4tov4 listenport=3001 listenaddress=0.0.0.0 2>$null
Start-Sleep -Seconds 1

# 新增連接埠轉送規則
Write-Host "`n📝 新增連接埠轉送規則..." -ForegroundColor Cyan

try {
    # 連接埠 3000 (Frontend)
    netsh interface portproxy add v4tov4 listenport=3000 listenaddress=0.0.0.0 connectport=3000 connectaddress=$wslIP 2>&1 | Out-Null
    Write-Host "   ✅ 連接埠 3000 → $wslIP:3000" -ForegroundColor Green

    # 連接埠 8000 (Backend)
    netsh interface portproxy add v4tov4 listenport=8000 listenaddress=0.0.0.0 connectport=8000 connectaddress=$wslIP 2>&1 | Out-Null
    Write-Host "   ✅ 連接埠 8000 → $wslIP:8000" -ForegroundColor Green

    # 連接埠 3001 (Fonoster)
    netsh interface portproxy add v4tov4 listenport=3001 listenaddress=0.0.0.0 connectport=3001 connectaddress=$wslIP 2>&1 | Out-Null
    Write-Host "   ✅ 連接埠 3001 → $wslIP:3001" -ForegroundColor Green

    Write-Host "`n✅ 連接埠轉送設定完成！" -ForegroundColor Green

    # 顯示目前的規則
    Write-Host "`n📋 目前的連接埠轉送規則：" -ForegroundColor Cyan
    netsh interface portproxy show all

    # 取得 Windows 主機 IP
    $hostIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { 
        $_.IPAddress -notlike "127.*" -and 
        $_.IPAddress -notlike "169.254.*" -and
        $_.IPAddress -notlike "172.*"
    } | Select-Object -First 1).IPAddress

    if ($hostIP) {
        Write-Host "`n🌐 遠端存取網址：" -ForegroundColor Yellow
        Write-Host "   前端: http://$hostIP:3000" -ForegroundColor White
        Write-Host "   後端: http://$hostIP:8000" -ForegroundColor White
        Write-Host "   Fonoster: http://$hostIP:3001" -ForegroundColor White
        
        Write-Host "`n🧪 測試連線..." -ForegroundColor Cyan
        Start-Sleep -Seconds 2
        
        try {
            $test = Invoke-WebRequest -Uri "http://$hostIP:8000/health" -UseBasicParsing -TimeoutSec 5
            Write-Host "   ✅ 後端可透過 $hostIP:8000 存取" -ForegroundColor Green
        } catch {
            Write-Host "   ⚠️  後端測試失敗，可能需要幾秒鐘才能生效" -ForegroundColor Yellow
        }
    }

    Write-Host "`n⚠️  注意：連接埠轉送規則在重新開機後會消失。" -ForegroundColor Yellow
    Write-Host "   如需永久設定，請建立開機時執行的排程工作。" -ForegroundColor White

} catch {
    Write-Host "`n❌ 設定連接埠轉送時發生錯誤: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

