# Spoke: `gmail-inbound` (both INPUT + OUTPUT)

Polls your Gmail inbox for new unread emails, maps each to the `inbound-event`
contract, calls the AI Hub, and delivers the response by replying to the email.

```
[Schedule Trigger: every 5 min]
        │
        ▼
[Gmail: search unread, unprocessed emails]    ← query: "is:unread -label:DC_Processed"
        │
        ▼
[Function: map Gmail message → inbound-event] ← source:"gmail", extract body/sender/thread
        │
        ▼
[Execute Workflow: hub/ai-hub]                ← wait mode; runs sequentially per email
        │
        ▼
[Switch on ai-output.path]
        ├── alpha/gamma → [Gmail: Reply + label DC_Processed + mark read]
        ├── beta        → [Gmail: label DC_Beta + DC_Processed + mark read]
        └── deny        → [Gmail: label DC_Denied + DC_Processed + mark read]
```

## Setup

### 1. Google Cloud OAuth credentials

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a project (or use existing)
3. Enable the **Gmail API** under APIs & Services
4. Set up OAuth consent screen (External, add your email as test user)
5. Create an **OAuth 2.0 Client ID** (Desktop/Web application)
6. In n8n → Credentials → Add Gmail OAuth2 → enter Client ID + Secret
7. Complete the OAuth consent flow from n8n

### 2. Create Gmail labels (one-time)

In Gmail or via the n8n Gmail node, create these labels:
- `DC_Processed` — applied after any processing
- `DC_Beta` — task/follow-up was logged
- `DC_Denied` — AI refused / guardrail triggered

### 3. Environment variables

Add to your `.env`:
```
GMAIL_OAUTH_CLIENT_ID=
GMAIL_OAUTH_CLIENT_SECRET=
```

## How auto-reply works

1. Email arrives → AI analyzes with full context (system prompt guards apply)
2. If the AI determines it can answer (path `alpha`):
   - Drafts a reply in your tone
   - Sends it via Gmail (threaded to original conversation)
   - Labels the original as `DC_Processed`, marks read
3. If it needs to log a follow-up (path `beta`):
   - No reply sent
   - Labels as `DC_Beta` for your review
4. If the request is denied (e.g., asking to send money):
   - Labels as `DC_Denied`
   - Optionally replies explaining the limitation

## Security

- The AI Hub's guardrails remain in effect: read-only, no financial transactions
- Gmail OAuth tokens stored in n8n's encrypted credential store
- Only labels, reads, and replies — never deletes, never modifies folders
