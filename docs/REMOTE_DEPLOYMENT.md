# Remote Deployment Guide
## Podman Remote Access Configuration

**Complete guide for deploying and accessing the Multi-Agent System remotely.**

---

## ✅ Current Status

Your containers are now configured for **remote access**:

- ✅ All containers bound to `0.0.0.0` (all network interfaces)
- ✅ Frontend configured with correct API URL
- ✅ Backend accessible from remote hosts
- ✅ Ports exposed: 3000, 8000, 3001

---

## 🚀 Quick Start

### Option 1: Auto-Detect IP (Recommended)

```powershell
.\deploy-podman-remote.ps1 -AutoDetectIP
```

This will:
- Auto-detect your local IP address
- Build frontend with correct API URL
- Start all containers with remote access

### Option 2: Specify Server IP

```powershell
.\deploy-podman-remote.ps1 -ServerIP "192.168.1.100"
```

Replace `192.168.1.100` with your actual server IP address.

---

## 🔥 Windows Firewall Configuration

**CRITICAL:** Windows Firewall blocks incoming connections by default. You must allow ports for remote access.

### Method 1: PowerShell (Run as Administrator)

```powershell
# Allow Frontend (Port 3000)
New-NetFirewallRule -DisplayName "Podman Frontend" -Direction Inbound -LocalPort 3000 -Protocol TCP -Action Allow

# Allow Backend (Port 8000)
New-NetFirewallRule -DisplayName "Podman Backend" -Direction Inbound -LocalPort 8000 -Protocol TCP -Action Allow

# Allow Fonoster (Port 3001)
New-NetFirewallRule -DisplayName "Podman Fonoster" -Direction Inbound -LocalPort 3001 -Protocol TCP -Action Allow
```

### Method 2: Windows Firewall GUI

1. Open **Windows Defender Firewall**
2. Click **Advanced Settings**
3. Click **Inbound Rules** → **New Rule**
4. Select **Port** → **Next**
5. Select **TCP** and enter port number (3000, 8000, or 3001)
6. Select **Allow the connection**
7. Apply to all profiles
8. Name it (e.g., "Podman Frontend")
9. Repeat for all three ports

---

## 🌐 Access URLs

After deployment and firewall configuration:

### Local Access
- **Frontend:** http://localhost:3000
- **Backend:** http://localhost:8000
- **Fonoster:** http://localhost:3001

### Remote Access
Replace `YOUR_SERVER_IP` with your actual IP:

- **Frontend:** http://YOUR_SERVER_IP:3000
- **Backend:** http://YOUR_SERVER_IP:8000
- **Fonoster:** http://YOUR_SERVER_IP:3001

### Find Your IP Address

**Windows:**
```powershell
Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*" }
```

**Or:**
```powershell
ipconfig
```
Look for "IPv4 Address" under your active network adapter.

---

## 🔍 Verification

### Test Local Access
```powershell
# Test backend
Invoke-WebRequest -Uri "http://localhost:8000/health"

# Test frontend
Invoke-WebRequest -Uri "http://localhost:3000"

# Test fonoster
Invoke-WebRequest -Uri "http://localhost:3001/health"
```

### Test Remote Access
From another device on the same network:

```bash
# Replace YOUR_SERVER_IP with actual IP
curl http://YOUR_SERVER_IP:8000/health
curl http://YOUR_SERVER_IP:3000
curl http://YOUR_SERVER_IP:3001/health
```

---

## 📋 Deployment Checklist

### Before Deployment
- [ ] Podman installed and running
- [ ] `.env` file configured with API keys
- [ ] Know your server IP address

### During Deployment
- [ ] Run `.\deploy-podman-remote.ps1 -AutoDetectIP`
- [ ] Verify all containers started successfully
- [ ] Check container status: `podman ps`

### After Deployment
- [ ] Configure Windows Firewall (ports 3000, 8000, 3001)
- [ ] Test local access
- [ ] Test remote access from another device
- [ ] Verify frontend can connect to backend

---

## 🔧 Troubleshooting

### Issue: Can't access from remote device

**Solutions:**
1. **Check Firewall:**
   ```powershell
   Get-NetFirewallRule | Where-Object { $_.DisplayName -like "*Podman*" }
   ```

2. **Verify Port Binding:**
   ```powershell
   netstat -ano | findstr ":3000"
   netstat -ano | findstr ":8000"
   netstat -ano | findstr ":3001"
   ```
   Should show `0.0.0.0:PORT` (not `127.0.0.1:PORT`)

3. **Check Container Logs:**
   ```powershell
   podman logs google-intelligent-backend
   podman logs google-intelligent-frontend
   ```

### Issue: Frontend can't connect to backend

**Solution:**
- Verify `NEXT_PUBLIC_API_URL` in frontend container:
  ```powershell
  podman inspect google-intelligent-frontend | Select-String "NEXT_PUBLIC_API_URL"
  ```
- Should match your server IP, not `localhost`

### Issue: Connection refused

**Solutions:**
1. Ensure containers are running: `podman ps`
2. Check firewall rules are active
3. Verify IP address is correct
4. Ensure devices are on same network (for local network access)

---

## 🌍 Internet Access (Production)

For internet access (not just local network):

1. **Use Public IP:**
   - Get your public IP: https://whatismyipaddress.com
   - Use this IP in deployment: `.\deploy-podman-remote.ps1 -ServerIP "YOUR_PUBLIC_IP"`

2. **Router Configuration:**
   - Port forward ports 3000, 8000, 3001 to your server
   - Configure in router admin panel

3. **Security Considerations:**
   - Use reverse proxy (nginx/traefik) with HTTPS
   - Implement authentication
   - Use firewall rules to restrict access
   - Consider VPN for secure access

---

## 📚 Additional Resources

- **Podman Documentation:** https://docs.podman.io
- **Windows Firewall:** https://docs.microsoft.com/windows/security/threat-protection/windows-firewall
- **Network Configuration:** See `docs/PODMAN_DEPLOYMENT_COMPLETE.md`

---

**Last Updated:** November 2025

