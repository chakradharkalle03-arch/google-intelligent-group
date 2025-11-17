# Fonoster SDK Integration Guide

## Current Status

The Fonoster server is currently using a **simulated call system** that mimics the behavior of the Fonoster SDK. This allows the system to work immediately while you set up your Fonoster credentials.

## Integration Steps

### 1. Install Fonoster SDK

```bash
cd fonoster-server
npm install @fonoster/sdk
```

### 2. Configure Environment Variables

Create a `.env` file in `fonoster-server/` directory:

```env
# Fonoster Configuration
FONOSTER_API_KEY=your_fonoster_api_key_here
FONOSTER_API_SECRET=your_fonoster_api_secret_here
FONOSTER_ENDPOINT=https://api.fonoster.com

# Your Fonoster phone number (for outbound calls)
FONOSTER_FROM_NUMBER=+1234567890

# Server Configuration
PORT=3001
NODE_ENV=production
```

### 3. Update server.js

Replace the simulated call code in `server.js` with actual Fonoster SDK calls:

```javascript
const fonoster = require('@fonoster/sdk');

// In the /api/call/make endpoint:
const client = new fonoster.Client({
  accessKeyId: process.env.FONOSTER_API_KEY,
  accessKeySecret: process.env.FONOSTER_API_SECRET,
  endpoint: process.env.FONOSTER_ENDPOINT
});

const call = await client.calls.create({
  from: process.env.FONOSTER_FROM_NUMBER,
  to: normalizedPhone,
  media: message || 'Call from Telephone Agent'
});

const callResult = {
  success: true,
  callId: call.callId,
  phoneNumber: normalizedPhone,
  status: call.status,
  message: message || 'Call initiated',
  timestamp: new Date().toISOString()
};
```

### 4. Get Fonoster Credentials

1. Sign up at [Fonoster](https://fonoster.com)
2. Create a project
3. Get your API credentials from the dashboard
4. Set up a phone number for outbound calls

## Current Implementation

The current implementation:
- ✅ Validates phone numbers
- ✅ Normalizes phone number format
- ✅ Returns realistic call responses
- ✅ Provides call IDs for tracking
- ✅ Logs all call attempts
- ⏳ Ready for SDK integration (just uncomment and configure)

## Testing

Test the current implementation:

```bash
curl -X POST http://localhost:3001/api/call/make \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber": "+886912345678", "message": "Test call"}'
```

## Notes

- The simulated system works perfectly for development and testing
- For production, integrate the actual Fonoster SDK using the steps above
- All phone numbers are validated and normalized before processing
- Call status can be checked using the `/api/call/status/:callId` endpoint

