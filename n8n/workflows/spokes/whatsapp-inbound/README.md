# Spoke: `whatsapp-inbound` (both INPUT + OUTPUT)

Receives WhatsApp messages via Twilio webhook, maps them to the `inbound-event`
contract, calls the AI Hub, and delivers the response back to WhatsApp.

```
[Webhook Trigger: Twilio WhatsApp POST]
        │
        ▼
[Function: map Twilio → inbound-event]         ← source:"whatsapp", extract Body/From
        │
        ▼
[Execute Workflow: hub/ai-hub]                 ← wait mode
        │
        ▼
[Switch on ai-output.path]
        ├── alpha/gamma → [Twilio: send WhatsApp reply]
        ├── beta        → [Twilio: ack message]
        └── deny        → [Twilio: explain refusal]
```

**Credentials needed:** `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_PHONE_NUMBER`

## Setup

### 1. Twilio sandbox / WhatsApp Business
1. Go to [Twilio Console](https://console.twilio.com/)
2. Get your **Account SID** and **Auth Token**
3. Go to Messaging > Try it out > Send a WhatsApp message
4. Follow the sandbox setup: send a join code from your WhatsApp to the Twilio number
5. Note the Twilio WhatsApp number (e.g. `+14155238886`)

### 2. Configure webhook
In Twilio Console > Messaging > Sandbox Settings:
- **When a message comes in**: `POST` → `https://your-n8n-host/webhook/whatsapp`
- Or use the n8n-generated webhook URL from this workflow

### 3. Environment variables
```
TWILIO_ACCOUNT_SID=
TWILIO_AUTH_TOKEN=
TWILIO_PHONE_NUMBER=+14155238886
```

### 4. n8n credentials
Add **Twilio** credentials in n8n with your Account SID + Auth Token.

## How it flows in the trading co-pilot
1. Kite-data spoke detects a P&L threshold breach → Hub
2. Hub generates alert → this spoke delivers it to WhatsApp
3. You reply on WhatsApp: "What's my exposure?" → this spoke → Hub → Reply
