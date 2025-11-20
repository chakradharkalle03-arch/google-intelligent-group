# Free Deployment Guide
## Google Intelligent Group Multi-Agent System

**Date:** November 2025

This guide covers deploying the entire application stack using **100% free hosting services**.

---

## 🎯 Free Hosting Options

### Frontend (Next.js)
- **Vercel** ⭐ (Recommended - Best for Next.js)
  - Free tier: Unlimited projects, 100GB bandwidth/month
  - Automatic deployments from GitHub
  - Built-in CDN and edge functions

### Backend (Quart/Python)
- **Render** ⭐ (Recommended - Easy setup)
  - Free tier: 750 hours/month, sleeps after 15min inactivity
  - Automatic deployments from GitHub
  - Free SSL certificates

- **Railway** (Alternative)
  - Free tier: $5 credit/month (enough for small apps)
  - No sleep, always-on
  - Easy GitHub integration

- **Fly.io** (Alternative)
  - Free tier: 3 shared VMs, 160GB outbound data/month
  - Global edge deployment
  - Good for production

### Fonoster Server (Node.js)
- **Render** (Recommended)
  - Free tier: 750 hours/month
  - Can run alongside backend

- **Railway** (Alternative)
  - Same free tier as backend

---

## 📋 Deployment Architecture

```
┌─────────────────┐
│   Vercel        │  Frontend (Next.js)
│   (Free)        │  https://your-app.vercel.app
└────────┬────────┘
         │
         │ API Calls
         │
┌────────▼────────┐
│   Render        │  Backend (Quart/Python)
│   (Free)        │  https://your-backend.onrender.com
└────────┬────────┘
         │
         │ HTTP Requests
         │
┌────────▼────────┐
│   Render        │  Fonoster Server (Node.js)
│   (Free)        │  https://your-fonoster.onrender.com
└─────────────────┘
```

---

## 🚀 Step-by-Step Deployment

### Part 1: Deploy Frontend to Vercel

#### Step 1.1: Prepare Frontend

1. **Ensure frontend is ready:**
   ```bash
   cd frontend
   npm install
   npm run build  # Test build locally
   ```

2. **Update `next.config.js` for production:**
   ```javascript
   env: {
     NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL || 'https://your-backend.onrender.com',
   },
   ```

#### Step 1.2: Deploy to Vercel

1. **Sign up for Vercel:**
   - Go to: https://vercel.com/signup
   - Sign up with GitHub (recommended)

2. **Import your GitHub repository:**
   - Click "Add New Project"
   - Select your repository
   - **Root Directory:** Set to `frontend`
   - **Framework Preset:** Next.js (auto-detected)
   - **Build Command:** `npm run build` (default)
   - **Output Directory:** `.next` (default)

3. **Environment Variables:**
   - Go to Project Settings → Environment Variables
   - Add:
     ```
     NEXT_PUBLIC_API_URL=https://your-backend.onrender.com
     ```
   - Replace with your actual backend URL after deploying backend

4. **Deploy:**
   - Click "Deploy"
   - Wait 2-3 minutes
   - Your frontend will be live at: `https://your-app.vercel.app`

---

### Part 2: Deploy Backend to Render

#### Step 2.1: Prepare Backend

1. **Create `render.yaml` (optional but recommended):**
   ```yaml
   services:
     - type: web
       name: google-intelligent-backend
       env: python
       buildCommand: pip install -r requirements.txt
       startCommand: hypercorn main:app --bind 0.0.0.0:$PORT
       envVars:
         - key: GEMINI_API_KEY
           sync: false
         - key: GOOGLE_MAPS_API_KEY
           sync: false
         - key: FONOSTER_SERVER_URL
           sync: false
         - key: PORT
           value: 8000
   ```

2. **Create `Procfile` for Render:**
   ```
   web: hypercorn main:app --bind 0.0.0.0:$PORT
   ```

3. **Update `main.py` to use PORT from environment:**
   ```python
   import os
   PORT = int(os.environ.get("PORT", 8000))
   ```

#### Step 2.2: Deploy to Render

1. **Sign up for Render:**
   - Go to: https://render.com/signup
   - Sign up with GitHub

2. **Create New Web Service:**
   - Click "New +" → "Web Service"
   - Connect your GitHub repository
   - **Name:** `google-intelligent-backend`
   - **Root Directory:** `backend`
   - **Environment:** Python 3
   - **Build Command:** `pip install -r requirements.txt`
   - **Start Command:** `hypercorn main:app --bind 0.0.0.0:$PORT`

3. **Environment Variables:**
   - Add the following:
     ```
     GEMINI_API_KEY=your_gemini_api_key
     GOOGLE_MAPS_API_KEY=your_google_maps_api_key
     FONOSTER_SERVER_URL=https://your-fonoster.onrender.com
     PORT=8000
     PYTHONUNBUFFERED=1
     ```

4. **Deploy:**
   - Click "Create Web Service"
   - Wait 5-10 minutes for first deployment
   - Your backend will be live at: `https://your-backend.onrender.com`

**Note:** Free tier services sleep after 15 minutes of inactivity. First request after sleep takes ~30 seconds.

---

### Part 3: Deploy Fonoster Server to Render

#### Step 3.1: Prepare Fonoster Server

1. **Create `Procfile` for Render:**
   ```
   web: node server.js
   ```

2. **Ensure `server.js` uses PORT from environment:**
   ```javascript
   const PORT = process.env.PORT || 3001;
   ```

#### Step 3.2: Deploy to Render

1. **Create New Web Service:**
   - Click "New +" → "Web Service"
   - Connect your GitHub repository
   - **Name:** `google-intelligent-fonoster`
   - **Root Directory:** `fonoster-server`
   - **Environment:** Node
   - **Build Command:** `npm install`
   - **Start Command:** `node server.js`

2. **Environment Variables:**
   - Add the following:
     ```
     PORT=3001
     FONOSTER_ACCESS_KEY_ID=your_access_key_id
     FONOSTER_API_KEY=your_api_key
     FONOSTER_API_SECRET=your_api_secret
     FONOSTER_ENDPOINT=https://api.fonoster.com
     FONOSTER_FROM_NUMBER=+1234567890
     NODE_ENV=production
     ```

3. **Deploy:**
   - Click "Create Web Service"
   - Wait 5-10 minutes
   - Your Fonoster server will be live at: `https://your-fonoster.onrender.com`

4. **Update Backend Environment Variable:**
   - Go back to your backend service on Render
   - Update `FONOSTER_SERVER_URL` to: `https://your-fonoster.onrender.com`

---

### Part 4: Update Frontend with Backend URL

1. **Go to Vercel Dashboard:**
   - Select your frontend project
   - Go to Settings → Environment Variables
   - Update `NEXT_PUBLIC_API_URL` to: `https://your-backend.onrender.com`
   - Click "Redeploy" to apply changes

---

## 🔧 Configuration Files

### Frontend: `vercel.json` (Optional)

```json
{
  "buildCommand": "cd frontend && npm run build",
  "outputDirectory": "frontend/.next",
  "framework": "nextjs",
  "rewrites": [
    {
      "source": "/api/:path*",
      "destination": "https://your-backend.onrender.com/:path*"
    }
  ]
}
```

### Backend: `Procfile`

```
web: hypercorn main:app --bind 0.0.0.0:$PORT
```

### Backend: `runtime.txt` (Optional - specify Python version)

```
python-3.11.0
```

---

## 🌐 Final URLs

After deployment, you'll have:

- **Frontend:** `https://your-app.vercel.app`
- **Backend:** `https://your-backend.onrender.com`
- **Fonoster:** `https://your-fonoster.onrender.com`

---

## ⚠️ Important Notes

### Free Tier Limitations

1. **Render Free Tier:**
   - Services sleep after 15 minutes of inactivity
   - First request after sleep takes ~30 seconds (cold start)
   - 750 hours/month (enough for 24/7 single service)
   - 100GB bandwidth/month

2. **Vercel Free Tier:**
   - Unlimited projects
   - 100GB bandwidth/month
   - No sleep (always-on)

3. **Workarounds:**
   - Use a free uptime monitor (e.g., UptimeRobot) to ping your backend every 5 minutes to prevent sleep
   - Or upgrade to paid tier for always-on service

### CORS Configuration

Make sure your backend allows requests from your Vercel domain:

```python
# In backend/main.py
app = cors(app, allow_origin=[
    "https://your-app.vercel.app",
    "http://localhost:3000"  # For local development
])
```

---

## 🧪 Testing Deployment

1. **Test Frontend:**
   - Visit: `https://your-app.vercel.app`
   - Check browser console for errors

2. **Test Backend:**
   - Visit: `https://your-backend.onrender.com/health`
   - Should return: `{"status":"healthy"}`

3. **Test Fonoster:**
   - Visit: `https://your-fonoster.onrender.com/health`
   - Should return health status

4. **Test Full Flow:**
   - Submit a query from frontend
   - Check backend logs on Render dashboard
   - Verify streaming responses work

---

## 📊 Monitoring

### Render Dashboard
- View logs in real-time
- Monitor resource usage
- Check deployment status

### Vercel Dashboard
- View analytics
- Check build logs
- Monitor performance

---

## 🔄 Continuous Deployment

Both Vercel and Render automatically deploy when you push to GitHub:

1. **Make changes locally**
2. **Commit and push:**
   ```bash
   git add .
   git commit -m "Update feature"
   git push origin main
   ```
3. **Automatic deployment starts**
4. **Check deployment status in dashboards**

---

## 🆘 Troubleshooting

### Backend not responding
- Check Render logs for errors
- Verify environment variables are set
- Check if service is sleeping (first request after sleep is slow)

### Frontend can't connect to backend
- Verify `NEXT_PUBLIC_API_URL` is set correctly
- Check CORS settings in backend
- Check browser console for CORS errors

### Build failures
- Check build logs in dashboard
- Verify all dependencies are in `requirements.txt` or `package.json`
- Check Python/Node version compatibility

---

## 📚 Additional Resources

- **Vercel Docs:** https://vercel.com/docs
- **Render Docs:** https://render.com/docs
- **Railway Docs:** https://docs.railway.app
- **Fly.io Docs:** https://fly.io/docs

---

## ✅ Deployment Checklist

- [ ] Frontend deployed to Vercel
- [ ] Backend deployed to Render
- [ ] Fonoster server deployed to Render
- [ ] Environment variables configured
- [ ] Frontend URL updated with backend URL
- [ ] Backend URL updated with Fonoster URL
- [ ] CORS configured correctly
- [ ] All services tested and working
- [ ] Health endpoints responding
- [ ] Full query flow tested

---

**Last Updated:** November 2025

