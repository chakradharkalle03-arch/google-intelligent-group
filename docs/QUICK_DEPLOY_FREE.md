# Quick Free Deployment Guide
## Google Intelligent Group - 5 Minute Setup

**Deploy your entire application stack for FREE using Vercel + Render**

---

## 🚀 Quick Start (5 Minutes)

### Prerequisites
- GitHub account
- API keys ready:
  - Gemini API Key
  - Google Maps API Key
  - (Optional) Fonoster credentials

---

## Step 1: Deploy Backend to Render (2 minutes)

1. **Go to:** https://render.com/signup
2. **Sign up with GitHub**
3. **Click:** "New +" → "Web Service"
4. **Connect your repository**
5. **Configure:**
   - **Name:** `google-intelligent-backend`
   - **Root Directory:** `backend`
   - **Environment:** `Python 3`
   - **Build Command:** `pip install -r requirements.txt`
   - **Start Command:** `hypercorn main:app --bind 0.0.0.0:$PORT`
6. **Add Environment Variables:**
   ```
   GEMINI_API_KEY=your_key_here
   GOOGLE_MAPS_API_KEY=your_key_here
   PORT=8000
   PYTHONUNBUFFERED=1
   ```
7. **Click:** "Create Web Service"
8. **Wait 5-10 minutes** for deployment
9. **Copy your backend URL:** `https://your-backend.onrender.com`

---

## Step 2: Deploy Fonoster Server to Render (2 minutes)

1. **Click:** "New +" → "Web Service"
2. **Connect same repository**
3. **Configure:**
   - **Name:** `google-intelligent-fonoster`
   - **Root Directory:** `fonoster-server`
   - **Environment:** `Node`
   - **Build Command:** `npm install`
   - **Start Command:** `node server.js`
4. **Add Environment Variables:**
   ```
   PORT=3001
   NODE_ENV=production
   FONOSTER_ENDPOINT=https://api.fonoster.com
   ```
   (Add Fonoster credentials if you have them)
5. **Click:** "Create Web Service"
6. **Wait 5-10 minutes**
7. **Copy your Fonoster URL:** `https://your-fonoster.onrender.com`

---

## Step 3: Update Backend with Fonoster URL (1 minute)

1. **Go to your backend service on Render**
2. **Environment tab**
3. **Add/Update:**
   ```
   FONOSTER_SERVER_URL=https://your-fonoster.onrender.com
   ```
4. **Save changes** (auto-redeploys)

---

## Step 4: Deploy Frontend to Vercel (2 minutes)

1. **Go to:** https://vercel.com/signup
2. **Sign up with GitHub**
3. **Click:** "Add New Project"
4. **Import your repository**
5. **Configure:**
   - **Root Directory:** `frontend`
   - **Framework Preset:** Next.js (auto-detected)
6. **Add Environment Variable:**
   ```
   NEXT_PUBLIC_API_URL=https://your-backend.onrender.com
   ```
   (Replace with your actual backend URL from Step 1)
7. **Click:** "Deploy"
8. **Wait 2-3 minutes**
9. **Your app is live!** 🎉

---

## ✅ Done!

Your application is now live at:
- **Frontend:** `https://your-app.vercel.app`
- **Backend:** `https://your-backend.onrender.com`
- **Fonoster:** `https://your-fonoster.onrender.com`

---

## 🧪 Test It

1. Visit your Vercel frontend URL
2. Submit a test query:
   ```
   Find a good Italian restaurant near me
   ```
3. Check that agents respond correctly

---

## ⚠️ Important Notes

### Free Tier Limitations

**Render:**
- Services sleep after 15 minutes of inactivity
- First request after sleep takes ~30 seconds
- Use UptimeRobot (free) to ping every 5 minutes to prevent sleep

**Vercel:**
- Always-on (no sleep)
- 100GB bandwidth/month (plenty for most apps)

### Prevent Render Sleep

1. **Sign up for UptimeRobot:** https://uptimerobot.com (free)
2. **Add monitor:**
   - URL: `https://your-backend.onrender.com/health`
   - Interval: 5 minutes
3. **This keeps your backend awake!**

---

## 🔄 Auto-Deployments

Both platforms auto-deploy when you push to GitHub:

```bash
git add .
git commit -m "Update feature"
git push origin main
```

Deployments start automatically! 🚀

---

## 📚 Full Documentation

For detailed instructions, see:
- `docs/FREE_DEPLOYMENT_GUIDE.md` - Complete deployment guide
- `docs/DEPLOYMENT_GUIDE_ACTUAL.md` - Podman deployment guide

---

**Last Updated:** November 2025

