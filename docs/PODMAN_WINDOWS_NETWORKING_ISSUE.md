# Podman Windows Networking Issue - ERR_EMPTY_RESPONSE

## Problem
- **Error:** `ERR_EMPTY_RESPONSE` when accessing `http://192.168.0.101:3000`
- **Symptom:** Many TIME_WAIT connections to `172.22.48.1:3000`
- **Status:** Port forwarding configured, but connections fail

## Root Cause
Podman Desktop on Windows uses WSL2, and the networking model has limitations:
1. Containers run inside WSL2 VM
2. Port forwarding from Windows host to WSL2 can be unreliable
3. `netsh interface portproxy` may not work correctly with Podman Desktop's networking

## Solutions

### Solution 1: Use Podman Desktop Port Forwarding (Recommended)
Podman Desktop should handle port forwarding automatically. Check:

1. **Podman Desktop Settings:**
   - Open Podman Desktop
   - Go to Settings → Resources → Port Forwarding
   - Ensure ports 3000, 8000, 3001 are forwarded

2. **Restart Podman Desktop:**
   - Close Podman Desktop completely
   - Restart Podman Desktop
   - Restart containers

### Solution 2: Access via WSL IP Directly
If port forwarding doesn't work, access containers directly via WSL IP:

- **Frontend:** http://172.22.48.1:3000
- **Backend:** http://172.22.48.1:8000
- **Fonoster:** http://172.22.48.1:3001

**Note:** This only works from the Windows host machine, not from remote devices.

### Solution 3: Use SSH Tunnel (For Remote Access)
If you need remote access and port forwarding doesn't work:

```powershell
# On Windows host, create SSH tunnel
ssh -L 3000:localhost:3000 user@windows-host
ssh -L 8000:localhost:8000 user@windows-host
ssh -L 3001:localhost:3001 user@windows-host
```

### Solution 4: Deploy on Remote Server (Best for Production)
For production use, deploy directly on a remote Linux server:

```powershell
.\deploy-podman-remote.ps1 -ServerIP "your-remote-server-ip"
```

This avoids Windows/WSL networking issues entirely.

### Solution 5: Use Docker Desktop Instead
If Podman Desktop networking continues to cause issues, consider using Docker Desktop, which has better Windows networking support.

## Troubleshooting Steps

1. **Check if containers are accessible via localhost:**
   ```powershell
   Invoke-WebRequest -Uri "http://localhost:3000"
   ```

2. **Check if containers are accessible via WSL IP:**
   ```powershell
   Invoke-WebRequest -Uri "http://172.22.48.1:3000"
   ```

3. **Check port forwarding rules:**
   ```powershell
   netsh interface portproxy show all
   ```

4. **Check Podman Desktop port forwarding:**
   - Open Podman Desktop
   - Check Settings → Resources → Port Forwarding

5. **Restart Podman Desktop:**
   - Close completely
   - Restart
   - Restart containers

## Current Status
- ✅ Containers running
- ✅ Port forwarding configured via `netsh`
- ❌ Connections failing (ERR_EMPTY_RESPONSE)
- ⚠️  Podman Desktop networking may need restart

## Recommended Action
1. Restart Podman Desktop completely
2. Restart containers
3. Test localhost access first
4. If localhost works but remote doesn't, use Solution 4 (deploy on remote server)

