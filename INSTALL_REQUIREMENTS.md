# Installation Requirements

## Prerequisites Needed

To run this project, you need to install the following:

### 1. Node.js (v18 or higher)
**Download:** https://nodejs.org/

After installation, verify:
```powershell
node --version
npm --version
```

### 2. Python (v3.10 or higher)
**Download:** https://www.python.org/downloads/

After installation, verify:
```powershell
python --version
```

**Important:** During Python installation, check "Add Python to PATH"

### 3. Git (Optional, for version control)
**Download:** https://git-scm.com/downloads

---

## After Installing Prerequisites

Once Node.js and Python are installed, run:

```powershell
.\setup.ps1
```

Or manually:

### Frontend:
```powershell
cd frontend
npm install
```

### Backend:
```powershell
cd backend
python -m venv venv
.\venv\Scripts\activate
pip install -r requirements.txt
```

### Fonoster Server:
```powershell
cd fonoster-server
npm install
```

---

## Quick Verification

After installing prerequisites, verify everything works:

```powershell
# Check Node.js
node --version
npm --version

# Check Python
python --version

# Check pip
pip --version
```

---

## Current Status

✅ Project structure created
✅ Configuration files ready
✅ .env files created (update with your API keys)
⏳ Waiting for Node.js and Python installation

