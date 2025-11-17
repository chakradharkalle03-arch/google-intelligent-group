# 🤖 Automated Installation Guide

## ✅ All Project Files Are Ready!

The automated setup script has been created and will run automatically once prerequisites are installed.

---

## 🚀 Quick Auto-Setup

### Step 1: Install Prerequisites (One-Time)

**Node.js:**
1. Download: https://nodejs.org/en/download/
2. Run installer → Accept defaults → Install
3. Restart PowerShell/terminal

**Python:**
1. Download: https://www.python.org/downloads/
2. Run installer → **CHECK "Add Python to PATH"** → Install
3. Restart PowerShell/terminal

### Step 2: Run Auto-Setup

After installing prerequisites, simply run:

```powershell
.\auto_setup.ps1
```

This will automatically:
- ✅ Detect Node.js and Python
- ✅ Install all frontend dependencies
- ✅ Create Python virtual environment
- ✅ Install all backend dependencies
- ✅ Set up Fonoster server
- ✅ Create .env files from templates

---

## 📋 What the Auto-Setup Does

The `auto_setup.ps1` script automatically:

1. **Checks Prerequisites**
   - Verifies Node.js installation
   - Verifies Python installation
   - Checks for npm and pip

2. **Sets Up Frontend**
   - Runs `npm install` in frontend directory
   - Installs all Next.js dependencies

3. **Sets Up Backend**
   - Creates Python virtual environment
   - Activates venv
   - Installs all Python packages from requirements.txt
   - Creates .env file from template

4. **Sets Up Fonoster Server**
   - Runs `npm install` in fonoster-server directory
   - Creates .env file from template

5. **Provides Summary**
   - Shows what's ready
   - Shows what's missing
   - Provides next steps

---

## 🎯 After Auto-Setup Completes

### 1. Add API Keys

Edit these files:

**`backend/.env`:**
```env
GEMINI_API_KEY=your_key_here
GOOGLE_MAPS_API_KEY=your_key_here
FONOSTER_SERVER_URL=http://localhost:3001
```

**`fonoster-server/.env`:**
```env
FONOSTER_API_KEY=your_key_here
FONOSTER_API_SECRET=your_secret_here
PORT=3001
```

### 2. Start All Services

**Terminal 1 - Frontend:**
```powershell
cd frontend
npm run dev
```
→ Opens at http://localhost:3000

**Terminal 2 - Backend:**
```powershell
cd backend
venv\Scripts\activate
python main.py
```
→ Opens at http://localhost:8000

**Terminal 3 - Fonoster:**
```powershell
cd fonoster-server
npm start
```
→ Opens at http://localhost:3001

---

## 🔄 Re-running Setup

If you need to re-run setup (e.g., after installing prerequisites):

```powershell
.\auto_setup.ps1
```

The script is idempotent - it's safe to run multiple times.

---

## ✅ Verification

After setup, verify everything works:

1. **Frontend:** http://localhost:3000 → Should show UI
2. **Backend:** http://localhost:8000/docs → Should show API docs
3. **Fonoster:** http://localhost:3001/health → Should return `{"status":"healthy"}`

---

## 🆘 Troubleshooting

**"Node.js not found" after installation:**
- Restart PowerShell/terminal
- Verify: `node --version`
- Check PATH environment variable

**"Python not found" after installation:**
- Reinstall Python with "Add to PATH" checked
- Restart PowerShell/terminal
- Verify: `python --version`

**Setup script errors:**
- Make sure you're in the project root directory
- Check that all folders (frontend, backend, fonoster-server) exist
- Try running PowerShell as Administrator

---

## 📊 Current Status

**Project Files:** ✅ 100% Complete  
**Setup Script:** ✅ Ready  
**Waiting For:** Node.js & Python installation

---

**🎯 Once prerequisites are installed, just run `.\auto_setup.ps1` and everything will be set up automatically!**

