# ⚡ Quick API Keys Setup

## 🚀 Fastest Way to Get Your Keys

### 1. Gemini API Key (2 minutes)
👉 **Click here:** https://aistudio.google.com/apikey
- Sign in → Click "Get API Key" → Copy key
- **Free tier available!**

### 2. Google Maps API Key (5 minutes)
👉 **Click here:** https://console.cloud.google.com/google/maps-apis
- Create project → Enable "Places API" → Create API Key → Copy key
- **$200 free credit/month!**

---

## 📝 Add to backend/.env

After getting your keys, edit `backend/.env`:

```env
GEMINI_API_KEY=AIzaSyYourKeyHere
GOOGLE_MAPS_API_KEY=AIzaSyYourKeyHere
```

---

## ✅ Or Use the Helper Script

Run:
```powershell
.\get_api_keys.ps1
```

This will:
- Open the API key pages in your browser
- Guide you through the process
- Automatically add keys to .env file

---

## 🎯 That's It!

Once keys are added, you're ready to run the backend!

