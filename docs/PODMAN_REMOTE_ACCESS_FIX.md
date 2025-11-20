# Podman Remote Access Fix
## Windows + WSL Port Forwarding Issue

**Issue:** Containers running in Podman (WSL) are not accessible via Windows host IP.

---

## 🔍 Problem Identified

Your setup:
- **Windows Host IP:** `192.168.0.101` (Wi-Fi adapter)
- **Podman Machine IP:** `172.22.48.1` (WSL virtual adapter)
- **Containers:** Running inside Podman machine (WSL)

**Issue:** Podman Desktop on Windows runs containers inside a WSL VM. While ports are bound to `0.0.0.0` inside the VM, they need proper port forwarding to be accessible from the Windows network.

---

## ✅ Solution: Use Correct IP Address

### For Remote Access, Use:

**Windows Host IP:** `192.168.0.101` (NOT 172.22.48.1)

- **Frontend:** http://192.168.0.101:3000
- **Backend:** http://192.168.0.101:8000
- **Fonoster:** http://192.168.0.101:3001

---

## 🔧 Podman Desktop Port Forwarding

Podman Desktop should automatically forward ports from WSL to Windows host. If remote access doesn't work:

### Option 1: Verify Podman Desktop Settings

1. Open **Podman Desktop**
2. Go to **Settings** → **Resources** → **Port Forwarding**
3. Ensure ports 3000, 8000, 3001 are forwarded
4. Restart Podman Desktop if needed

### Option 2: Manual Port Forwarding (If Needed)

If automatic forwarding doesn't work, you may need to configure WSL port forwarding:

```powershell
# Run as Administrator
# Forward port 3000
netsh interface portproxy add v4tov4 listenport=3000 listenaddress=0.0.0.0 connectport=3000 connectaddress=172.22.48.1

# Forward port 8000
netsh interface portproxy add v4tov4 listenport=8000 listenaddress=0.0.0.0 connectport=8000 connectaddress=172.22.48.1

# Forward port 3001
netsh interface portproxy add v4tov4 listenport=3001 listenaddress=0.0.0.0 connectport=3001 connectaddress=172.22.48.1
```

### Option 3: Use Localhost (For Testing)

If remote access still doesn't work, you can:
1. Access from the same machine: http://localhost:3000
2. Use SSH tunnel for remote access
3. Deploy directly on remote server (not via Podman Desktop)

---

## 🧪 Testing Remote Access

### From Windows Host (Same Machine)

```powershell
# Test with Windows host IP
Invoke-WebRequest -Uri "http://192.168.0.101:8000/health"
Invoke-WebRequest -Uri "http://192.168.0.101:3000"
```

### From Another Device (Same Network)

```bash
# Replace 192.168.0.101 with your actual Windows IP
curl http://192.168.0.101:8000/health
curl http://192.168.0.101:3000
```

---

## 📋 Troubleshooting Checklist

- [ ] Using correct Windows host IP (192.168.0.101, not 172.22.48.1)
- [ ] Firewall rules configured (ports 3000, 8000, 3001)
- [ ] Podman Desktop port forwarding enabled
- [ ] Containers running and bound to 0.0.0.0
- [ ] Testing from same network
- [ ] No VPN or network restrictions blocking access

---

## 🚀 Alternative: Deploy on Remote Server

If Podman Desktop port forwarding is problematic, consider:

1. **Deploy directly on remote server:**
   ```powershell
   .\deploy-podman-remote.ps1 -ServerIP "your-remote-server-ip"
   ```

2. **Use SSH tunnel:**
   ```bash
   ssh -L 3000:localhost:3000 user@windows-host
   ```

3. **Use reverse proxy (nginx/traefik)** on Windows host

---

## ✅ Quick Fix Summary

1. **Use Windows Host IP:** `192.168.0.101` (not WSL IP)
2. **Verify Firewall:** Ports 3000, 8000, 3001 allowed
3. **Check Podman Desktop:** Port forwarding enabled
4. **Test from another device** on the same network

---

**Last Updated:** November 2025

