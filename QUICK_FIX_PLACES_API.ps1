# Quick Fix Guide for Places API
Write-Host "`nPlaces API Quick Fix Guide`n" -ForegroundColor Cyan

Write-Host "Error Message:" -ForegroundColor Red
Write-Host "   You're calling a legacy API, which is not enabled for your project`n" -ForegroundColor Yellow

Write-Host "Solution Steps:`n" -ForegroundColor Green

Write-Host "Step 1: Open Google Cloud Console API Library:" -ForegroundColor Cyan
Write-Host "   https://console.cloud.google.com/apis/library`n" -ForegroundColor White

Write-Host "Step 2: Search and click 'Places API':" -ForegroundColor Cyan
Write-Host "   https://console.cloud.google.com/apis/library/places-backend.googleapis.com`n" -ForegroundColor White

Write-Host "Step 3: Click the blue 'ENABLE' button`n" -ForegroundColor Cyan

Write-Host "Step 4: Wait 1-2 minutes for API to activate`n" -ForegroundColor Cyan

Write-Host "Step 5: Test if API is working:" -ForegroundColor Cyan
Write-Host "   .\test_google_maps_api.ps1`n" -ForegroundColor White

Write-Host "Step 6: Restart backend server:" -ForegroundColor Cyan
Write-Host "   .\run_web.ps1`n" -ForegroundColor White

Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "Additional Notes:" -ForegroundColor Yellow
Write-Host "=======================================`n" -ForegroundColor Cyan

Write-Host "- Places API is a legacy API but still works" -ForegroundColor White
Write-Host "- It takes a few minutes to activate after enabling" -ForegroundColor White
Write-Host "- Make sure billing is enabled for your Google Cloud project" -ForegroundColor White
Write-Host "- Free tier: $200 monthly credit for Google Maps Platform`n" -ForegroundColor White

Write-Host "Tip: If you can't find Places API, make sure:" -ForegroundColor Yellow
Write-Host "   1. You selected the correct Google Cloud project" -ForegroundColor White
Write-Host "   2. You have admin permissions for the project" -ForegroundColor White
Write-Host "   3. Billing account is enabled`n" -ForegroundColor White

$open = Read-Host "Open Google Cloud Console API Library page? (Y/N)"
if ($open -eq "Y" -or $open -eq "y") {
    Start-Process "https://console.cloud.google.com/apis/library/places-backend.googleapis.com"
    Write-Host "`nBrowser opened. Please follow the steps above to enable Places API`n" -ForegroundColor Green
}

