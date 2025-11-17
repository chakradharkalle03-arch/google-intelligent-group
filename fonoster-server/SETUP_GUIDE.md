# Fonoster SDK Setup Guide

## ✅ SDK Installed

The `@fonoster/sdk` package has been installed and integrated into the server.

## Current Status

- ✅ SDK package installed (`@fonoster/sdk@0.15.21`)
- ✅ SDK integration code added
- ⏳ Waiting for Fonoster credentials to enable real calls

## To Enable Real Calls

### Step 1: Get Fonoster Credentials

1. Sign up at [Fonoster](https://fonoster.com) or log in to your account
2. Go to your Workspace dashboard
3. Create an API key:
   - Access Key ID (starts with `WO...`)
   - API Key
   - API Secret
4. Get your phone number for outbound calls

### Step 2: Configure Environment Variables

1. Copy the example file:
   ```bash
   cd fonoster-server
   cp env.example .env
   ```

2. Edit `.env` and add your credentials:
   ```env
   FONOSTER_ACCESS_KEY_ID=WO00000000000000000000000000000000
   FONOSTER_API_KEY=your_api_key_here
   FONOSTER_API_SECRET=your_api_secret_here
   FONOSTER_ENDPOINT=https://api.fonoster.com
   FONOSTER_FROM_NUMBER=+1234567890
   ```

### Step 3: Restart Server

```bash
npm start
```

You should see:
```
✅ Fonoster SDK initialized successfully
```

## How It Works

### With Credentials (Real Calls)
- Server initializes Fonoster SDK on startup
- Calls are made using the real SDK
- Note message: "Call initiated successfully via Fonoster SDK."

### Without Credentials (Simulation)
- Server runs in simulation mode
- Calls are simulated (for testing)
- Note message: "Call initiated (simulation mode - configure Fonoster credentials in .env to enable real calls)"

## Testing

Test the integration:

```bash
curl -X POST http://localhost:3001/api/call/make \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber": "+886912345678", "message": "Test call"}'
```

## Troubleshooting

### SDK Not Initializing
- Check that all three credentials are set: `FONOSTER_ACCESS_KEY_ID`, `FONOSTER_API_KEY`, `FONOSTER_API_SECRET`
- Verify credentials are correct
- Check server logs for error messages

### Calls Failing
- Ensure `FONOSTER_FROM_NUMBER` is set
- Verify phone number format (E.164 format: +1234567890)
- Check Fonoster dashboard for account status

## Documentation

- [Fonoster Official Docs](https://docs.fonoster.com)
- [Fonoster SDK on npm](https://www.npmjs.com/package/@fonoster/sdk)
- [Fonoster GitHub](https://github.com/fonoster/fonoster)

