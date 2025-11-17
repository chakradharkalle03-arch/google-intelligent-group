# Start Fonoster Server Script

Write-Host "`n☎️  Starting Fonoster Server...`n" -ForegroundColor Green

# Change to fonoster-server directory
Set-Location -Path "$PSScriptRoot\fonoster-server"

# Check if node_modules exists
if (-not (Test-Path "node_modules")) {
    Write-Host "Installing dependencies...`n" -ForegroundColor Yellow
    npm install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to install dependencies!" -ForegroundColor Red
        exit 1
    }
}

# Check for existing server on port 3001
Write-Host "Checking for existing server on port 3001...`n" -ForegroundColor Cyan
$existing = Get-NetTCPConnection -LocalPort 3001 -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "Stopping existing server...`n" -ForegroundColor Yellow
    $existing | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }
    Start-Sleep -Seconds 2
}

Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host "✅ Starting Fonoster Server" -ForegroundColor Green
Write-Host "═══════════════════════════════════════`n" -ForegroundColor Cyan
Write-Host "🌐 Server will be available at:" -ForegroundColor Yellow
Write-Host "   📡 API: http://localhost:3001" -ForegroundColor White
Write-Host "   ❤️  Health: http://localhost:3001/health`n" -ForegroundColor White
Write-Host "Press Ctrl+C to stop the server`n" -ForegroundColor Gray
Write-Host "═══════════════════════════════════════`n" -ForegroundColor Cyan

# Run the server
npm start

