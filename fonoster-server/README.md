# Fonoster Server

Node.js server for handling Fonoster telephony operations.

## Setup Instructions

1. Install dependencies:
```bash
npm install
```

2. Set up environment variables:
```bash
# Copy .env.example to .env
cp .env.example .env

# Edit .env and add your Fonoster credentials
```

3. Run the server:
```bash
npm start
# Or for development with auto-reload:
npm run dev
```

4. Server will be available at [http://localhost:3001](http://localhost:3001)

## API Endpoints

- `GET /health` - Health check
- `POST /api/call/make` - Make an outbound call
  - Body: `{ "phoneNumber": "+886912345678", "message": "Optional message" }`
- `GET /api/call/status/:callId` - Get call status

## Fonoster Integration

This server will integrate with Fonoster SDK to:
- Make outbound calls
- Handle call status updates
- Process call recordings
- Integrate with Gemini LLM for call dialogue simulation

## Next Steps

- Install and configure Fonoster SDK
- Set up SIP accounts
- Implement actual call flow
- Integrate with Gemini for dialogue simulation

