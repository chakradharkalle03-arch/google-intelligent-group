# Remote Access Guide for Podman on Windows

## Problem
Podman Desktop on Windows only forwards ports to `localhost`, not to all network interfaces. This prevents remote access via the Windows host IP (192.168.0.101).

## Solutions

### Solution 1: SSH Tunneling (Recommended for Quick Setup)

#### Step 1: Enable SSH Server on Windows

Run as Administrator:
```powershell
.\enable-ssh-server.ps1
```

Or manually:
```powershell
# Install OpenSSH Server
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# Start SSH Server
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'

# Configure Firewall
New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
```

#### Step 2: Connect from Remote Device

From your remote device (phone, tablet, another computer):

```bash
# SSH with port forwarding
ssh -L 3000:localhost:3000 -L 8000:localhost:8000 -L 3001:localhost:3001 user@192.168.0.101
```

Replace `user` with your Windows username.

#### Step 3: Access Services

After SSH connection is established, access:
- **Frontend:** http://localhost:3000
- **Backend:** http://localhost:8000
- **Fonoster:** http://localhost:3001

**Note:** Keep the SSH connection open while using the services.

---

### Solution 2: Deploy to Remote Linux Server (Best for Production)

Deploy directly to a remote Linux server to avoid Windows networking issues:

```powershell
.\deploy-podman-remote.ps1 -ServerIP "your-remote-server-ip"
```

This will:
- Build containers on the remote server
- Configure proper networking
- Enable direct remote access without SSH tunneling

**Advantages:**
- No SSH tunneling needed
- Better performance
- More reliable networking
- Production-ready

---

### Solution 3: Use ngrok or Similar Tunnel Service

Use a tunnel service to expose localhost:

1. **Install ngrok:** https://ngrok.com/
2. **Run tunnel:**
   ```bash
   ngrok http 3000
   ```
3. **Use the provided public URL**

**Note:** Free tier has limitations. Consider paid plans for production.

---

### Solution 4: Use Windows Remote Desktop + Localhost

1. Enable Remote Desktop on Windows
2. Connect via RDP
3. Access services via localhost in the RDP session

---

## Quick Start

### For SSH Tunneling:

1. **On Windows (as Administrator):**
   ```powershell
   .\enable-ssh-server.ps1
   ```

2. **From remote device:**
   ```bash
   ssh -L 3000:localhost:3000 -L 8000:localhost:8000 -L 3001:localhost:3001 your-username@192.168.0.101
   ```

3. **Access services:**
   - Frontend: http://localhost:3000
   - Backend: http://localhost:8000

### For Remote Server Deployment:

```powershell
.\deploy-podman-remote.ps1 -ServerIP "your-remote-server-ip"
```

---

## Troubleshooting

### SSH Connection Issues

1. **Check SSH Server is running:**
   ```powershell
   Get-Service sshd
   ```

2. **Check Firewall:**
   ```powershell
   Get-NetFirewallRule -Name sshd
   ```

3. **Test SSH locally:**
   ```powershell
   ssh localhost
   ```

### Port Forwarding Not Working

1. **Verify containers are running:**
   ```powershell
   podman ps
   ```

2. **Test localhost access:**
   ```powershell
   Invoke-WebRequest -Uri "http://localhost:3000"
   ```

3. **Check SSH tunnel:**
   - Ensure SSH connection is active
   - Verify port forwarding syntax

---

## Security Considerations

1. **SSH Keys:** Use SSH keys instead of passwords
2. **Firewall:** Only allow SSH from trusted networks
3. **VPN:** Consider using VPN for additional security
4. **HTTPS:** Use reverse proxy with SSL for production

---

## Summary

| Solution | Setup Complexity | Performance | Best For |
|----------|------------------|-------------|----------|
| SSH Tunneling | Low | Good | Quick testing, development |
| Remote Server | Medium | Excellent | Production, team access |
| ngrok | Very Low | Variable | Demos, temporary access |
| RDP | Low | Good | Single user, GUI access |

**Recommendation:** Use SSH tunneling for quick setup, deploy to remote server for production.

