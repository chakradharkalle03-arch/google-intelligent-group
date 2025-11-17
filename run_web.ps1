# Run Web Application Script
# Starts both backend and frontend servers and opens browser

Write-Host "`nStarting Web Application...`n" -ForegroundColor Green

# Store original location
$originalLocation = Get-Location
$scriptRoot = $PSScriptRoot

# Function to check if port is in use
function Test-Port {
    param([int]$Port)
    $connection = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue
    return $null -ne $connection
}

# Function to stop process on port
function Stop-PortProcess {
    param([int]$Port)
    $connections = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue
    if ($connections) {
        Write-Host "Stopping existing process on port $Port...`n" -ForegroundColor Yellow
        $connections | ForEach-Object { 
            Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue 
        }
        Start-Sleep -Seconds 2
    }
}

# Check and stop existing servers
Write-Host "Checking for existing servers...`n" -ForegroundColor Cyan
if (Test-Port -Port 8000) {
    Stop-PortProcess -Port 8000
}
if (Test-Port -Port 3000) {
    Stop-PortProcess -Port 3000
}

# Start Backend Server
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "Starting Backend Server..." -ForegroundColor Green
Write-Host "=======================================`n" -ForegroundColor Cyan

$backendDir = Join-Path $scriptRoot "backend"

# Check if virtual environment exists
if (-not (Test-Path (Join-Path $backendDir "venv\Scripts\activate.ps1"))) {
    Write-Host "Virtual environment not found!" -ForegroundColor Red
    Write-Host "Please run: python -m venv venv" -ForegroundColor Yellow
    exit 1
}

# Create backend startup script file
$backendScriptPath = Join-Path $env:TEMP "start_backend.ps1"
$backendScriptContent = @"
`$ErrorActionPreference = 'Stop'
Set-Location '$backendDir'
Write-Host 'Activating virtual environment...' -ForegroundColor Cyan
& '$backendDir\venv\Scripts\activate.ps1'
Write-Host 'Backend Server Starting...' -ForegroundColor Green
Write-Host 'API Docs: http://127.0.0.1:8000/docs' -ForegroundColor Cyan
Write-Host 'Press Ctrl+C to stop' -ForegroundColor Gray
Write-Host ''
python main.py
"@
$backendScriptContent | Out-File -FilePath $backendScriptPath -Encoding UTF8

Write-Host "Starting backend server in new window...`n" -ForegroundColor Green
Start-Process powershell -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-File", $backendScriptPath

# Wait for backend to start and verify
Write-Host "Waiting for backend to start..." -ForegroundColor Yellow
$maxAttempts = 10
$attempt = 0
$backendStarted = $false

while ($attempt -lt $maxAttempts) {
    Start-Sleep -Seconds 2
    $connection = Get-NetTCPConnection -LocalPort 8000 -ErrorAction SilentlyContinue
    if ($connection) {
        $backendStarted = $true
        Write-Host "✅ Backend server is running!`n" -ForegroundColor Green
        break
    }
    $attempt++
    Write-Host "  Attempt $attempt/$maxAttempts..." -ForegroundColor Gray
}

if (-not $backendStarted) {
    Write-Host "⚠️  Backend may not have started properly. Please check the backend window.`n" -ForegroundColor Yellow
}

# Start Frontend Server
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "Starting Frontend Server..." -ForegroundColor Green
Write-Host "=======================================`n" -ForegroundColor Cyan

$frontendDir = Join-Path $scriptRoot "frontend"

# Check if npm is available
$npmAvailable = $false
try {
    $null = Get-Command npm -ErrorAction Stop
    $npmAvailable = $true
} catch {
    Write-Host "npm not found in PATH. Skipping frontend startup." -ForegroundColor Yellow
    Write-Host "To install Node.js, visit: https://nodejs.org/`n" -ForegroundColor Gray
}

if ($npmAvailable) {
    # Check if node_modules exists
    if (-not (Test-Path (Join-Path $frontendDir "node_modules"))) {
        Write-Host "node_modules not found. Installing dependencies...`n" -ForegroundColor Yellow
        Set-Location -Path $frontendDir
        npm install
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Failed to install dependencies!" -ForegroundColor Red
            $npmAvailable = $false
        }
    }
    
    if ($npmAvailable) {
        # Create frontend startup script file
        $frontendScriptPath = Join-Path $env:TEMP "start_frontend.ps1"
        @"
Set-Location '$frontendDir'
Write-Host 'Frontend Server Starting...' -ForegroundColor Green
Write-Host 'App will be available at: http://localhost:3000' -ForegroundColor Cyan
Write-Host 'Press Ctrl+C to stop' -ForegroundColor Gray
npm run dev
"@ | Out-File -FilePath $frontendScriptPath -Encoding UTF8

        Start-Process powershell -ArgumentList "-NoExit", "-File", $frontendScriptPath

        Write-Host "Frontend server starting in new window...`n" -ForegroundColor Green
    }
}

# Wait for servers to start
Write-Host "Waiting for servers to start...`n" -ForegroundColor Yellow
if ($npmAvailable) {
    Start-Sleep -Seconds 8
} else {
    Start-Sleep -Seconds 5
}

# Open browser
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "Opening Browser...`n" -ForegroundColor Green
Write-Host "=======================================`n" -ForegroundColor Cyan

if ($npmAvailable) {
    Write-Host "Frontend: http://localhost:3000" -ForegroundColor White
}
Write-Host "Backend API Docs: http://127.0.0.1:8000/docs`n" -ForegroundColor White

# Try to open browser
try {
    if ($npmAvailable) {
        Start-Process "http://localhost:3000"
        Write-Host "Browser opened to frontend!`n" -ForegroundColor Green
    } else {
        Start-Process "http://127.0.0.1:8000/docs"
        Write-Host "Browser opened to backend API docs!`n" -ForegroundColor Green
    }
} catch {
    Write-Host "Could not open browser automatically. Please open:" -ForegroundColor Yellow
    if ($npmAvailable) {
        Write-Host "   Frontend: http://localhost:3000" -ForegroundColor White
    }
    Write-Host "   Backend API Docs: http://127.0.0.1:8000/docs" -ForegroundColor White
}

# Restore original location
Set-Location $originalLocation

Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "Application Started Successfully!" -ForegroundColor Green
Write-Host "=======================================`n" -ForegroundColor Cyan
Write-Host "Tips:" -ForegroundColor Yellow
if ($npmAvailable) {
    Write-Host "   - Frontend: http://localhost:3000" -ForegroundColor White
}
Write-Host "   - Backend API: http://127.0.0.1:8000" -ForegroundColor White
Write-Host "   - API Docs: http://127.0.0.1:8000/docs" -ForegroundColor White
Write-Host "   - Close the PowerShell windows to stop servers`n" -ForegroundColor Gray
