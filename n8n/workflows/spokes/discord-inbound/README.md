# Spoke: `discord-inbound` (both INPUT + OUTPUT)

Receives Discord interaction events (slash commands, buttons), maps to the
`inbound-event` contract, calls the AI Hub, and responds via Discord's
interaction webhook.

```
[Webhook: Discord Interactions Endpoint POST]
        │
        ▼
[Function: verify signature + map → inbound-event]  ← source:"discord", handles PING
        │
        ├── PING (type 1) → immediate { type: 1 } response
        │
        └── Command (type 2) → routed to Hub
              │
              ▼
        [Execute Workflow: hub/ai-hub]
              │
              ▼
        [Switch on ai-output.path]
              ├── alpha/gamma → [HTTP: POST interaction callback, type 4 + content]
              ├── beta        → [HTTP: ack callback]
              └── deny        → [HTTP: denial callback]
```

**Credentials needed:** `DISCORD_BOT_TOKEN`, `DISCORD_APPLICATION_ID`, `DISCORD_PUBLIC_KEY`

## Setup

### 1. Create a Discord application + bot
1. Go to [Discord Developer Portal](https://discord.com/developers/applications)
2. Create a **New Application**
3. Go to **Bot** → Add Bot → copy the **token**
4. Under **Privileged Gateway Intents**, enable what you need
5. Go to **OAuth2 > URL Generator**:
   - Scopes: `bot`, `applications.commands`
   - Bot Permissions: `Send Messages`, `Read Messages/View Channels`, `Use Slash Commands`
   - Open the generated URL to invite the bot to your server

### 2. Set up Interactions Endpoint
1. Go to your app → **General Information** → copy **Public Key**
2. Under **Interactions Endpoint URL**, paste your n8n webhook URL:
   ```
   https://your-n8n-host/webhook/discord
   ```
3. Discord will send a validation request — your workflow must respond to PING (type 1)
4. Save — Discord only accepts if PING validation succeeds

### 3. Register slash commands
Use Discord's API or a tool to register commands:
```bash
curl -X POST https://discord.com/api/v10/applications/$APP_ID/commands \
  -H "Authorization: Bot $DISCORD_BOT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"ask","description":"Ask the AI anything","options":[{"name":"question","description":"Your question","type":3,"required":true}]}'
```

### 4. Environment variables
```
DISCORD_BOT_TOKEN=
DISCORD_APPLICATION_ID=
DISCORD_PUBLIC_KEY=
```

> Note: This spoke handles **Interactions** (slash commands, buttons, modals).
> For full message-read capability in Discord servers, you need a WebSocket gateway
> connection, which n8n doesn't natively support. Use OpenClaw (included in this
> stack) for full Discord message support.

## Limitations
- Handles slash commands and component interactions only (not raw messages)
- Ed25519 signature verification is documented but n8n's JS sandbox lacks SHA-512
  — use a reverse proxy (nginx) or OpenClaw for production-grade verification
