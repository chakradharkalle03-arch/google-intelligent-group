/**
 * Fonoster Server
 * Handles telephony operations for the Telephone Agent
 */

const express = require('express');
const cors = require('cors');
require('dotenv').config();

// Import Fonoster SDK
const SDK = require('@fonoster/sdk');

const app = express();
const PORT = process.env.PORT || 3001;

// Initialize Fonoster client (if credentials are provided)
let fonosterClient = null;
let fonosterInitialized = false;

try {
  const accessKeyId = process.env.FONOSTER_ACCESS_KEY_ID;
  const apiKey = process.env.FONOSTER_API_KEY;
  const apiSecret = process.env.FONOSTER_API_SECRET;
  const endpoint = process.env.FONOSTER_ENDPOINT || 'https://api.fonoster.com';

  if (accessKeyId && apiKey && apiSecret) {
    fonosterClient = new SDK.Client({ 
      accessKeyId: accessKeyId,
      endpoint: endpoint
    });
    
    // Login with API key
    fonosterClient.loginWithApiKey(apiKey, apiSecret)
      .then(() => {
        fonosterInitialized = true;
        console.log('✅ Fonoster SDK initialized successfully');
      })
      .catch((error) => {
        console.warn('⚠️ Fonoster SDK initialization failed:', error.message);
        console.warn('   Continuing with simulation mode. Set FONOSTER_ACCESS_KEY_ID, FONOSTER_API_KEY, and FONOSTER_API_SECRET in .env to enable real calls.');
      });
  } else {
    console.log('ℹ️ Fonoster credentials not configured. Running in simulation mode.');
    console.log('   To enable real calls, set FONOSTER_ACCESS_KEY_ID, FONOSTER_API_KEY, and FONOSTER_API_SECRET in .env');
  }
} catch (error) {
  console.warn('⚠️ Fonoster SDK not available:', error.message);
  console.warn('   Continuing with simulation mode.');
}

// Middleware
app.use(cors());
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', service: 'fonoster-server' });
});

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'Fonoster Server',
    version: '1.0.0',
    endpoints: {
      health: '/health',
      makeCall: '/api/call/make'
    }
  });
});

// Make outbound call endpoint
app.post('/api/call/make', async (req, res) => {
  try {
    const { phoneNumber, message } = req.body;

    if (!phoneNumber) {
      return res.status(400).json({
        error: 'Phone number is required',
        message: 'Please provide a valid phone number'
      });
    }

    // Validate phone number format
    const phoneRegex = /^[\d\s\+\-\(\)]+$/;
    if (!phoneRegex.test(phoneNumber)) {
      return res.status(400).json({
        error: 'Invalid phone number format',
        message: 'Please provide a valid phone number'
      });
    }

    // Normalize phone number (remove spaces, dashes, parentheses)
    const normalizedPhone = phoneNumber.replace(/[\s\-\(\)]/g, '');
    
    console.log(`📞 Initiating call to: ${normalizedPhone}`);
    console.log(`💬 Message: ${message || 'No message provided'}`);

    // Try to use Fonoster SDK if initialized, otherwise use simulation
    if (fonosterInitialized && fonosterClient) {
      try {
        // Use Fonoster SDK to make call
        // Note: Fonoster SDK structure may vary - adjust based on actual API
        const CallManager = SDK.CallManager || SDK.Calls;
        
        if (CallManager) {
          const callManager = new CallManager(fonosterClient);
          const fromNumber = process.env.FONOSTER_FROM_NUMBER || process.env.FONOSTER_PHONE_NUMBER;
          
          if (!fromNumber) {
            throw new Error('FONOSTER_FROM_NUMBER or FONOSTER_PHONE_NUMBER not configured');
          }

          const callResult = await callManager.call({
            from: fromNumber,
            to: normalizedPhone,
            webhook: process.env.FONOSTER_WEBHOOK_URL || undefined,
            ignoreE164Validation: true
          });

          console.log(`✅ Call initiated via Fonoster SDK: ${callResult.callId || callResult.id}`);
          
          return res.json({
            success: true,
            callId: callResult.callId || callResult.id,
            phoneNumber: normalizedPhone,
            originalPhoneNumber: phoneNumber,
            status: callResult.status || 'initiated',
            message: message || 'Call initiated by Telephone Agent',
            timestamp: new Date().toISOString(),
            duration: null,
            note: 'Call initiated successfully via Fonoster SDK.'
          });
        } else {
          throw new Error('CallManager not available in SDK');
        }
      } catch (sdkError) {
        console.error('❌ Fonoster SDK call failed:', sdkError.message);
        console.log('   Falling back to simulation mode...');
        // Fall through to simulation mode
      }
    }

    // Simulation mode (when SDK not configured or failed)
    const callId = `call_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    const callResult = {
      success: true,
      callId: callId,
      phoneNumber: normalizedPhone,
      originalPhoneNumber: phoneNumber,
      status: 'initiated',
      message: message || 'Call initiated by Telephone Agent',
      timestamp: new Date().toISOString(),
      duration: null,
      note: fonosterInitialized 
        ? 'Call initiated (simulation mode - SDK call failed)' 
        : 'Call initiated (simulation mode - configure Fonoster credentials in .env to enable real calls)'
    };

    console.log(`✅ Call initiated (simulation): ${callId}`);
    
    res.json(callResult);
  } catch (error) {
    console.error('❌ Error making call:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to make call',
      message: error.message,
      note: 'Check Fonoster server configuration and credentials'
    });
  }
});

// Call status endpoint
app.get('/api/call/status/:callId', (req, res) => {
  try {
    const { callId } = req.params;
    
    // TODO: Replace with actual Fonoster SDK call status check:
    // const call = await client.calls.get(callId);
    // return call status from SDK
    
    // Simulated call status
    res.json({
      callId: callId,
      status: 'completed', // or 'ringing', 'answered', 'failed', 'completed'
      duration: 45, // seconds
      timestamp: new Date().toISOString(),
      message: 'Call status retrieved. For production, use Fonoster SDK to get real-time status.'
    });
  } catch (error) {
    console.error('Error getting call status:', error);
    res.status(500).json({
      error: 'Failed to get call status',
      message: error.message
    });
  }
});

app.listen(PORT, () => {
  console.log(`Fonoster Server running on port ${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/health`);
});

