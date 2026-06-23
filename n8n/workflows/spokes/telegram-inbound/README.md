# Spoke: `telegram-inbound` (both INPUT + OUTPUT)

Receives Telegram messages (DMs, groups, channels), maps to the `inbound-event`
contract, calls the AI Hub, and replies back to Telegram.

```
[Telegram Trigger: message/command/callback]
        │
        ▼
[Function: map Telegram update → inbound-event]  ← source:"telegram", extract text/from/chat
        │
        ▼
[Execute Workflow: hub/ai-hub]                    ← wait mode
        │
        ▼
[Switch on ai-output.path]
        ├── alpha/gamma → [Telegram: sendMessage with reply markup]
        ├── beta        → [Telegram: ack message]
        └── deny        → [Telegram: explain refusal]
```

**Credentials needed:** `TELEGRAM_BOT_TOKEN`

## Setup

### 1. Create a Telegram bot
1. Open Telegram, chat with [@BotFather](https://t.me/BotFather)
2. Send `/newbot` and follow the prompts
3. Copy the **bot token** (e.g. `123456:ABC-DEF1234ghikl-zyx57W2v1u123ew11`)

### 2. Configure webhook
n8n's Telegram Trigger node auto-sets the webhook via `setWebhook` on activation.
No manual webhook setup needed. Just:
- Add the bot token in n8n Telegram credentials
- Activate the workflow — n8n registers the webhook URL with Telegram

### 3. Environment variables
```
TELEGRAM_BOT_TOKEN=
```

### 4. n8n credentials
Add **Telegram API** credentials in n8n with your bot token.

## Advanced: group/channel support
- The bot works in DMs out of the box
- For groups: add bot to group, give it "read messages" permission
- For channels: add bot as admin with "read messages" right
- Use `/command` syntax in groups to avoid processing every message

## Trading co-pilot usage
- Get portfolio alerts pushed to your Telegram
- Query your AI assistant: `/exposure`, `/pnl`, `/positions`
- Receive the daily debrief digest in your Telegram channel
