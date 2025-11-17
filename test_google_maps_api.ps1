# Test Google Maps API Key
Write-Host "`n🔍 Testing Google Maps API Key...`n" -ForegroundColor Cyan

# Read API key from .env file
$envPath = Join-Path $PSScriptRoot "backend\.env"
if (-not (Test-Path $envPath)) {
    Write-Host "❌ .env file not found!" -ForegroundColor Red
    exit 1
}

$envContent = Get-Content $envPath
$apiKey = ($envContent | Select-String -Pattern "GOOGLE_MAPS_API_KEY=(.+)" | ForEach-Object { $_.Matches.Groups[1].Value }).Trim()

if (-not $apiKey -or $apiKey -eq "your_google_maps_api_key_here") {
    Write-Host "❌ Google Maps API Key not found or not set in .env file!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Found API Key: $($apiKey.Substring(0, 20))..." -ForegroundColor Green
Write-Host "`nTesting Geocoding API..." -ForegroundColor Yellow

# Test 1: Geocoding API
$geocodeUrl = "https://maps.googleapis.com/maps/api/geocode/json?address=Taipei+101&key=$apiKey"
try {
    $response = Invoke-WebRequest -Uri $geocodeUrl -Method GET -TimeoutSec 10 -ErrorAction Stop
    $data = $response.Content | ConvertFrom-Json
    
    if ($data.status -eq "OK") {
        Write-Host "✅ Geocoding API: Working!" -ForegroundColor Green
        $location = $data.results[0].geometry.location
        Write-Host "   Taipei 101 coordinates: $($location.lat), $($location.lng)" -ForegroundColor White
    } elseif ($data.status -eq "REQUEST_DENIED") {
        Write-Host "❌ Geocoding API: REQUEST_DENIED" -ForegroundColor Red
        Write-Host "   Error: $($data.error_message)" -ForegroundColor Yellow
        Write-Host "`n💡 Solutions:" -ForegroundColor Cyan
        Write-Host "   1. Enable Geocoding API in Google Cloud Console" -ForegroundColor White
        Write-Host "   2. Check API key restrictions" -ForegroundColor White
        Write-Host "   3. Ensure billing is enabled" -ForegroundColor White
    } else {
        Write-Host "⚠️  Geocoding API: $($data.status)" -ForegroundColor Yellow
        Write-Host "   Message: $($data.error_message)" -ForegroundColor Gray
    }
} catch {
    Write-Host "❌ Geocoding API: Connection failed" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "`nTesting Places API (Text Search)..." -ForegroundColor Yellow

# Test 2: Places API Text Search
$placesUrl = "https://maps.googleapis.com/maps/api/place/textsearch/json?query=Indian+restaurant+near+Taipei+101&key=$apiKey"
try {
    $response = Invoke-WebRequest -Uri $placesUrl -Method GET -TimeoutSec 10 -ErrorAction Stop
    $data = $response.Content | ConvertFrom-Json
    
    if ($data.status -eq "OK") {
        Write-Host "✅ Places API: Working!" -ForegroundColor Green
        Write-Host "   Found $($data.results.Count) results" -ForegroundColor White
        if ($data.results.Count -gt 0) {
            Write-Host "   First result: $($data.results[0].name)" -ForegroundColor White
        }
    } elseif ($data.status -eq "REQUEST_DENIED") {
        Write-Host "❌ Places API: REQUEST_DENIED" -ForegroundColor Red
        Write-Host "   Error: $($data.error_message)" -ForegroundColor Yellow
        Write-Host "`n💡 Solutions:" -ForegroundColor Cyan
        Write-Host "   1. Enable Places API in Google Cloud Console" -ForegroundColor White
        Write-Host "      URL: https://console.cloud.google.com/apis/library/places-backend.googleapis.com" -ForegroundColor Gray
        Write-Host "   2. Check API key restrictions" -ForegroundColor White
        Write-Host "   3. Ensure billing is enabled" -ForegroundColor White
    } else {
        Write-Host "⚠️  Places API: $($data.status)" -ForegroundColor Yellow
        Write-Host "   Message: $($data.error_message)" -ForegroundColor Gray
    }
} catch {
    Write-Host "❌ Places API: Connection failed" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "`n📋 Summary:" -ForegroundColor Cyan
Write-Host "   If you see REQUEST_DENIED errors, please:" -ForegroundColor White
Write-Host "   1. Go to: https://console.cloud.google.com/apis/library" -ForegroundColor Gray
Write-Host "   2. Enable: Geocoding API and Places API" -ForegroundColor Gray
Write-Host "   3. Go to: https://console.cloud.google.com/apis/credentials" -ForegroundColor Gray
Write-Host "   4. Click your API key and check restrictions" -ForegroundColor Gray
Write-Host "   5. Ensure billing is enabled: https://console.cloud.google.com/billing`n" -ForegroundColor Gray

