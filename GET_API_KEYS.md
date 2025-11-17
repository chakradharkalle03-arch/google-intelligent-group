# 🔑 How to Get API Keys

## 📋 Required API Keys

You need two API keys for this project:
1. **Google Gemini API Key** - For AI/LLM functionality
2. **Google Maps API Key** - For GoogleMap Agent location searches

---

## 🤖 Step 1: Get Google Gemini API Key

### Quick Steps:
1. **Go to:** https://aistudio.google.com/apikey
2. **Sign in** with your Google account
3. **Click** "Create API Key" or "Get API Key"
4. **Select** a Google Cloud project (or create a new one)
5. **Copy** the API key that appears
6. **Add to** `backend/.env` as `GEMINI_API_KEY=your_key_here`

### Detailed Instructions:
- Visit Google AI Studio: https://aistudio.google.com/
- Click on "Get API Key" in the top right
- Sign in with your Google account
- Create a new project or select an existing one
- Copy the generated API key
- The key will look like: `AIzaSy...` (starts with AIza)

**Free Tier:** Google Gemini API has a generous free tier for development

---

## 🗺️ Step 2: Get Google Maps API Key

### Quick Steps:
1. **Go to:** https://console.cloud.google.com/google/maps-apis
2. **Sign in** with your Google account
3. **Create a new project** (or select existing)
4. **Enable** "Maps JavaScript API" and "Places API"
5. **Go to** "Credentials" → "Create Credentials" → "API Key"
6. **Copy** the API key
7. **Add to** `backend/.env` as `GOOGLE_MAPS_API_KEY=your_key_here`

### Detailed Instructions:

#### Enable Required APIs:
1. Go to Google Cloud Console: https://console.cloud.google.com/
2. Create a new project (or select existing)
3. Go to "APIs & Services" → "Library"
4. Search and enable:
   - **Maps JavaScript API** (for map display)
   - **Places API** (for location searches) - **REQUIRED for GoogleMap Agent**
   - **Geocoding API** (optional, for address conversion)

#### Create API Key:
1. Go to "APIs & Services" → "Credentials"
2. Click "Create Credentials" → "API Key"
3. Copy the API key
4. (Recommended) Click "Restrict Key" and:
   - Restrict to "Places API" and "Maps JavaScript API"
   - Add HTTP referrer restrictions for production

**Free Tier:** Google Maps API provides $200 free credit per month (enough for development)

---

## 📝 Step 3: Add Keys to .env File

Edit `backend/.env` file and add:

```env
# Gemini API Key
GEMINI_API_KEY=AIzaSyYourGeminiKeyHere

# Google Maps API Key  
GOOGLE_MAPS_API_KEY=AIzaSyYourMapsKeyHere

# Backend Configuration
BACKEND_HOST=0.0.0.0
BACKEND_PORT=8000

# Fonoster Server URL
FONOSTER_SERVER_URL=http://localhost:3001
```

---

## ✅ Verification

After adding keys, test them:

### Test Gemini API:
```powershell
cd backend
venv\Scripts\activate
python -c "import os; from dotenv import load_dotenv; load_dotenv(); print('Gemini Key:', os.getenv('GEMINI_API_KEY')[:20] + '...' if os.getenv('GEMINI_API_KEY') else 'NOT SET')"
```

### Test Google Maps API:
```powershell
python -c "import os; from dotenv import load_dotenv; load_dotenv(); print('Maps Key:', os.getenv('GOOGLE_MAPS_API_KEY')[:20] + '...' if os.getenv('GOOGLE_MAPS_API_KEY') else 'NOT SET')"
```

---

## 🆘 Troubleshooting

**"API key not valid"**
- Make sure you copied the entire key
- Check for extra spaces
- Verify the API is enabled in Google Cloud Console

**"Quota exceeded"**
- Check your usage in Google Cloud Console
- Free tier limits apply

**"API not enabled"**
- Go to Google Cloud Console → APIs & Services → Library
- Enable the required APIs

---

## 🔒 Security Notes

- **Never commit** `.env` files to Git (already in .gitignore)
- **Restrict** API keys in Google Cloud Console for production
- **Use different keys** for development and production
- **Monitor usage** in Google Cloud Console

---

## 📚 Quick Links

- **Gemini API:** https://aistudio.google.com/apikey
- **Google Maps API:** https://console.cloud.google.com/google/maps-apis
- **Google Cloud Console:** https://console.cloud.google.com/

---

**🎯 Once you have both keys, add them to `backend/.env` and you're ready to go!**

