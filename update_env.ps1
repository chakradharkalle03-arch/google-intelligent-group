# Update .env file with API keys
# This script helps update the backend .env file

Write-Host "`n🔧 Updating Backend .env File...`n" -ForegroundColor Cyan

$envPath = Join-Path $PSScriptRoot "backend\.env"

if (-not (Test-Path $envPath)) {
    Write-Host "❌ .env file not found at: $envPath" -ForegroundColor Red
    Write-Host "Creating from env.example..." -ForegroundColor Yellow
    
    $examplePath = Join-Path $PSScriptRoot "backend\env.example"
    if (Test-Path $examplePath) {
        Copy-Item $examplePath $envPath
        Write-Host "✅ Created .env file from example" -ForegroundColor Green
    } else {
        Write-Host "❌ env.example not found!" -ForegroundColor Red
        exit 1
    }
}

Write-Host "Current .env file location: $envPath`n" -ForegroundColor White

# Read current content
$content = Get-Content $envPath -Raw

Write-Host "Please update the following in your .env file:" -ForegroundColor Yellow
Write-Host "1. GEMINI_API_KEY=AIzaSyCePb8_afE2fvq1tWCRITYGNHp-MIezk44" -ForegroundColor White
Write-Host "2. GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here`n" -ForegroundColor White

Write-Host "To edit the file, run:" -ForegroundColor Cyan
Write-Host "   notepad $envPath`n" -ForegroundColor White

$open = Read-Host "Open .env file in Notepad now? (Y/N)"
if ($open -eq "Y" -or $open -eq "y") {
    notepad $envPath
    Write-Host "`n✅ Please save the file and restart the backend server.`n" -ForegroundColor Green
} else {
    Write-Host "`n📝 Remember to update the .env file manually!`n" -ForegroundColor Yellow
}

Write-Host "After updating, restart the backend server:" -ForegroundColor Cyan
Write-Host "   .\start_backend_only.ps1" -ForegroundColor White
Write-Host "   or" -ForegroundColor White
Write-Host "   .\run_web.ps1`n" -ForegroundColor White

