# 🔧 Correct URL to Use

## ❌ Problem

You tried to access: **http://0.0.0.0:8000/**

**Error:** `ERR_ADDRESS_INVALID`

**Why:** `0.0.0.0` is a special address used by servers to bind to all network interfaces. You **cannot** connect to it from a browser.

---

## ✅ Solution

Use **localhost** or **127.0.0.1** instead:

### Correct URLs:

1. **API Documentation (Recommended):**
   ```
   http://localhost:8000/docs
   ```

2. **API Root:**
   ```
   http://localhost:8000
   ```

3. **Health Check:**
   ```
   http://localhost:8000/health
   ```

4. **Alternative (same as localhost):**
   ```
   http://127.0.0.1:8000/docs
   ```

---

## 🌐 How to Access

### Option 1: API Documentation (Easiest)
1. Open your browser
2. Go to: **http://localhost:8000/docs**
3. You'll see interactive API documentation
4. Click `POST /query` to test queries

### Option 2: Direct API
1. Open your browser
2. Go to: **http://localhost:8000**
3. You'll see API information

### Option 3: Health Check
1. Open your browser
2. Go to: **http://localhost:8000/health**
3. Should show: `{"status":"healthy"}`

---

## 🔍 If Server Not Responding

If you get connection errors:

1. **Check if server is running:**
   - Look for a PowerShell window running the backend
   - You should see: `Uvicorn running on http://0.0.0.0:8000`

2. **Wait a few seconds:**
   - Server may still be starting
   - Give it 10-15 seconds after startup

3. **Restart server if needed:**
   ```powershell
   cd backend
   venv\Scripts\activate
   python main.py
   ```

---

## 📝 Summary

- ❌ **Don't use:** http://0.0.0.0:8000
- ✅ **Use instead:** http://localhost:8000/docs
- ✅ **Or use:** http://127.0.0.1:8000/docs

**The server binds to 0.0.0.0, but you connect to localhost!**

---

**🎯 Try now: http://localhost:8000/docs**

