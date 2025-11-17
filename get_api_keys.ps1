# Helper script to guide users through getting API keys

Write-Host "🔑 API Keys Setup Helper" -ForegroundColor Cyan
Write-Host "=======================`n" -ForegroundColor Cyan

Write-Host "This script will help you get your API keys and add them to .env file`n" -ForegroundColor Yellow

# Check if .env exists
$envPath = "backend\.env"
if (-not (Test-Path $envPath)) {
    Write-Host "⚠️  .env file not found. Creating from template..." -ForegroundColor Yellow
    Copy-Item "backend\env.example" $envPath
    Write-Host "✅ Created backend/.env file`n" -ForegroundColor Green
}

# Function to open URL in browser
function Open-URL {
    param($URL, $Description)
    Write-Host "`n📌 $Description" -ForegroundColor Cyan
    Write-Host "   URL: $URL" -ForegroundColor White
    $response = Read-Host "   Open in browser? (Y/n)"
    if ($response -eq "" -or $response -eq "Y" -or $response -eq "y") {
        Start-Process $URL
        Write-Host "   ✅ Opened in browser`n" -ForegroundColor Green
    }
}

# Gemini API Key
Write-Host "🤖 Step 1: Get Google Gemini API Key" -ForegroundColor Yellow
Write-Host "=====================================" -ForegroundColor Yellow
Open-URL -URL "https://aistudio.google.com/apikey" -Description "Google AI Studio - Get Gemini API Key"

Write-Host "Instructions:" -ForegroundColor White
Write-Host "1. Sign in with your Google account" -ForegroundColor Gray
Write-Host "2. Click 'Create API Key' or 'Get API Key'" -ForegroundColor Gray
Write-Host "3. Select or create a Google Cloud project" -ForegroundColor Gray
Write-Host "4. Copy the API key (starts with AIza...)" -ForegroundColor Gray
Write-Host ""

$geminiKey = Read-Host "Paste your Gemini API Key here (or press Enter to skip)"
if ($geminiKey -and $geminiKey -ne "") {
    # Update .env file
    $content = Get-Content $envPath -Raw
    if ($content -match "GEMINI_API_KEY=.*") {
        $content = $content -replace "GEMINI_API_KEY=.*", "GEMINI_API_KEY=$geminiKey"
    } else {
        $content += "`nGEMINI_API_KEY=$geminiKey"
    }
    Set-Content -Path $envPath -Value $content -NoNewline
    Write-Host "✅ Gemini API Key added to backend/.env`n" -ForegroundColor Green
} else {
    Write-Host "⏭️  Skipped Gemini API Key (you can add it manually later)`n" -ForegroundColor Yellow
}

# Google Maps API Key
Write-Host "🗺️  Step 2: Get Google Maps API Key" -ForegroundColor Yellow
Write-Host "====================================" -ForegroundColor Yellow
Open-URL -URL "https://console.cloud.google.com/google/maps-apis" -Description "Google Cloud Console - Maps APIs"

Write-Host "Instructions:" -ForegroundColor White
Write-Host "1. Sign in with your Google account" -ForegroundColor Gray
Write-Host "2. Create a new project (or select existing)" -ForegroundColor Gray
Write-Host "3. Enable 'Places API' (REQUIRED for GoogleMap Agent)" -ForegroundColor Gray
Write-Host "4. Enable 'Maps JavaScript API' (optional)" -ForegroundColor Gray
Write-Host "5. Go to 'Credentials' → 'Create Credentials' → 'API Key'" -ForegroundColor Gray
Write-Host "6. Copy the API key" -ForegroundColor Gray
Write-Host ""

$mapsKey = Read-Host "Paste your Google Maps API Key here (or press Enter to skip)"
if ($mapsKey -and $mapsKey -ne "") {
    # Update .env file
    $content = Get-Content $envPath -Raw
    if ($content -match "GOOGLE_MAPS_API_KEY=.*") {
        $content = $content -replace "GOOGLE_MAPS_API_KEY=.*", "GOOGLE_MAPS_API_KEY=$mapsKey"
    } else {
        $content += "`nGOOGLE_MAPS_API_KEY=$mapsKey"
    }
    Set-Content -Path $envPath -Value $content -NoNewline
    Write-Host "✅ Google Maps API Key added to backend/.env`n" -ForegroundColor Green
} else {
    Write-Host "⏭️  Skipped Google Maps API Key (you can add it manually later)`n" -ForegroundColor Yellow
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "📊 Setup Summary" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Check what's in .env
$envContent = Get-Content $envPath -Raw
if ($envContent -match "GEMINI_API_KEY=(.+)") {
    $key = $matches[1].Trim()
    if ($key -and $key -ne "your_gemini_api_key_here") {
        Write-Host "✅ Gemini API Key: Set" -ForegroundColor Green
    } else {
        Write-Host "❌ Gemini API Key: Not set" -ForegroundColor Red
    }
} else {
    Write-Host "❌ Gemini API Key: Not found in .env" -ForegroundColor Red
}

if ($envContent -match "GOOGLE_MAPS_API_KEY=(.+)") {
    $key = $matches[1].Trim()
    if ($key -and $key -ne "your_google_maps_api_key_here") {
        Write-Host "✅ Google Maps API Key: Set" -ForegroundColor Green
    } else {
        Write-Host "❌ Google Maps API Key: Not set" -ForegroundColor Red
    }
} else {
    Write-Host "❌ Google Maps API Key: Not found in .env" -ForegroundColor Red
}

Write-Host "`n📝 Next Steps:" -ForegroundColor Cyan
Write-Host "1. If keys are missing, edit backend/.env manually" -ForegroundColor White
Write-Host "2. See GET_API_KEYS.md for detailed instructions" -ForegroundColor White
Write-Host "3. Run: cd backend && venv\Scripts\activate && python main.py" -ForegroundColor White

Write-Host "`n✅ Setup helper completed!`n" -ForegroundColor Green

