# Update API Keys in .env file
Write-Host "`n🔧 Updating API Keys in .env file...`n" -ForegroundColor Cyan

$envPath = Join-Path $PSScriptRoot "backend\.env"

if (-not (Test-Path $envPath)) {
    Write-Host "❌ .env file not found!" -ForegroundColor Red
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

# Read current content
$content = Get-Content $envPath -Raw

# Update GEMINI_API_KEY (using the user's provided key)
$geminiKey = "AIzaSyCePb8_afE2fvq1tWCRITYGNHp-MIezk44"
$content = $content -replace "GEMINI_API_KEY=.*", "GEMINI_API_KEY=$geminiKey"

# Update GOOGLE_MAPS_API_KEY (using Places/Geocoding API key)
$googleMapsKey = "AIzaSyBNVPNZusl4oTEJCGpaYaBn-60fY3B3xmI"
$content = $content -replace "GOOGLE_MAPS_API_KEY=.*", "GOOGLE_MAPS_API_KEY=$googleMapsKey"

# Write updated content
$content | Set-Content $envPath -Encoding UTF8

Write-Host "✅ Updated API Keys:" -ForegroundColor Green
Write-Host "   GEMINI_API_KEY: $($geminiKey.Substring(0, 20))..." -ForegroundColor White
Write-Host "   GOOGLE_MAPS_API_KEY: $($googleMapsKey.Substring(0, 20))...`n" -ForegroundColor White

Write-Host "📋 Updated .env file location: $envPath`n" -ForegroundColor Cyan

Write-Host "⚠️  Important: Make sure your Google Maps API key has:" -ForegroundColor Yellow
Write-Host "   1. No HTTP referrer restrictions (or use IP restrictions)" -ForegroundColor White
Write-Host "   2. Places API enabled" -ForegroundColor White
Write-Host "   3. Geocoding API enabled" -ForegroundColor White
Write-Host "   4. Billing enabled`n" -ForegroundColor White

Write-Host "🧪 Test the API keys:" -ForegroundColor Cyan
Write-Host "   .\test_google_maps_api.ps1`n" -ForegroundColor White

Write-Host "🔄 Restart backend server:" -ForegroundColor Cyan
Write-Host "   .\run_web.ps1`n" -ForegroundColor White

