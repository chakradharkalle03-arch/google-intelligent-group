# Podman Setup Instructions
## Quick Start Guide

## ⚠️ Important: Podman Desktop Setup

Podman Desktop is installed, but the `podman` command needs to be accessible from PowerShell.

---

## 🔧 Setup Steps

### Step 1: Start Podman Desktop

1. **Open Podman Desktop**
   - Click Start Menu → Search "Podman Desktop"
   - Or double-click the shortcut

2. **Wait for Podman Machine to Start**
   - Look for "Podman machine is running" status
   - This may take 1-2 minutes on first start

3. **Verify Status**
   - Status bar should show green/ready indicator
   - No error messages should appear

---

### Step 2: Add Podman to PATH (If Needed)

If `podman` command still doesn't work after starting Podman Desktop:

#### Option A: Restart PowerShell
```powershell
# Close and reopen PowerShell
# Podman Desktop may have updated PATH
```

#### Option B: Find Podman Executable
```powershell
# Check common locations
Get-ChildItem "C:\Program Files" -Recurse -Filter "podman.exe" -ErrorAction SilentlyContinue
Get-ChildItem "$env:LOCALAPPDATA\Programs" -Recurse -Filter "podman.exe" -ErrorAction SilentlyContinue
```

#### Option C: Use Full Path
If you find podman.exe, use the full path:
```powershell
& "C:\Path\To\podman.exe" --version
```

---

### Step 3: Verify Podman Works

```powershell
# Check version
podman --version

# Check system info
podman info

# Test with hello-world
podman run hello-world
```

---

### Step 4: Run the Project

Once Podman is working:

```powershell
cd C:\Users\user\Downloads\readlife
.\run-podman.ps1
```

---

## 🐛 Troubleshooting

### Issue: "podman: command not found"

**Solution:**
1. Ensure Podman Desktop is running
2. Restart PowerShell
3. Check if podman.exe exists in PATH:
   ```powershell
   $env:PATH -split ';' | Select-String -Pattern "podman"
   ```

### Issue: "Podman machine not running"

**Solution:**
1. Open Podman Desktop
2. Click "Start" or "Restart" on the machine
3. Wait for it to fully start

### Issue: "Cannot connect to Podman"

**Solution:**
1. Check Podman Desktop status
2. Restart Podman Desktop
3. Restart Podman machine from Desktop UI

---

## ✅ Success Indicators

You'll know Podman is working when:

- ✅ `podman --version` returns a version number
- ✅ `podman info` shows system information
- ✅ Podman Desktop shows "Running" status
- ✅ No error messages in Podman Desktop

---

## 📝 Alternative: Use Docker Desktop

If Podman continues to have issues, you can use Docker Desktop instead:

1. Install Docker Desktop: https://www.docker.com/products/docker-desktop
2. Replace `podman` with `docker` in all commands
3. Containerfiles are compatible with Docker

---

**Last Updated:** November 2025

