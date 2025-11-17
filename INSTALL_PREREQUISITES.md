# 📥 Install Prerequisites Guide

## Quick Installation Links

### 1. Node.js Installation
**Download:** https://nodejs.org/en/download/

**Steps:**
1. Download the Windows Installer (.msi) for Node.js LTS version
2. Run the installer
3. Follow the installation wizard (accept defaults)
4. Restart your terminal/PowerShell

**Verify:**
```powershell
node --version
npm --version
```

### 2. Python Installation
**Download:** https://www.python.org/downloads/

**Steps:**
1. Download Python 3.10 or higher for Windows
2. Run the installer
3. **IMPORTANT:** Check "Add Python to PATH" during installation
4. Complete the installation
5. Restart your terminal/PowerShell

**Verify:**
```powershell
python --version
pip --version
```

---

## After Installation

Once both are installed, come back and run:
```powershell
.\setup.ps1
```

This will automatically:
- Install all frontend dependencies
- Create Python virtual environment
- Install all backend dependencies
- Set up Fonoster server
- Create .env files from templates

---

## Troubleshooting

**"node is not recognized"**
- Restart PowerShell/terminal after installing Node.js
- Verify Node.js is added to PATH

**"python is not recognized"**
- Reinstall Python and make sure "Add to PATH" is checked
- Restart PowerShell/terminal

**"npm is not recognized"**
- npm comes with Node.js, reinstall Node.js if needed

