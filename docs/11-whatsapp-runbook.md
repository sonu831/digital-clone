# 11 · WhatsApp Spoke — Issues, Fixes & n8n 2.26 Gotchas

A field log from getting the WhatsApp (Twilio) spoke working end-to-end on
**n8n 2.26.8**. Most of these apply to *any* spoke on n8n 2.x, not just WhatsApp.
Read this before debugging a webhook spoke — it will save you hours.

> TL;DR of the worst trap: **production runs a *separate published snapshot*, not
> the workflow you're editing.** See [§A](#a-the-big-one--n8n-2x-draftpublished-model).

---

## A. THE BIG ONE — n8n 2.x draft/published model

n8n 2.x split every workflow into a **draft** and a **published snapshot**:

| | Draft | Published snapshot |
| --- | --- | --- |
| Stored in | `workflow_entity.nodes` | `workflow_history.nodes` (row where `versionId = workflow_entity.activeVersionId`) |
| Edited by | the UI canvas / `import:workflow` | the **Publish** button only |
| Runs in production | ❌ no | ✅ **yes** — this is what `/webhook/...` executes |

**Consequences that wasted hours:**

- Editing the draft (in the UI **or** by patching `workflow_entity` in the DB) has
  **zero effect on production** until you **Publish**.
- The CLI `n8n publish:workflow --id=...` sets `active=true` but does **not**
  reliably create the published snapshot — webhooks flap on restart.
- Patching `workflow_entity` directly gets **clobbered** the next time the UI saves.
- The reliable fixes are: **(1)** Publish from the UI (after a hard refresh so the
  browser holds the correct draft), or **(2)** patch the *active snapshot* directly:

```bash
# Find the active version, then patch workflow_history for THAT versionId:
AVID=$(psql ... -At -c "SELECT \"activeVersionId\" FROM workflow_entity WHERE id='whatsapp-inbound';")
# ...edit the nodes JSON for that versionId in workflow_history, then restart n8n.
```

> Rule of thumb: after **any** change, **Publish** — and if you patch the DB,
> patch `workflow_history` for the `activeVersionId`, then `docker compose restart n8n`.

---

## B. Webhook registration (the 404s)

| Symptom | Cause | Fix |
| --- | --- | --- |
| `Received request for unknown webhook "whatsapp"` / `404` on `/webhook/whatsapp` | Workflow not **Published** (active flag alone is not enough on 2.x) | Publish the workflow. Confirm a row exists: `SELECT * FROM webhook_entity;` |
| Test URL works, production doesn't | `/webhook-test/...` only listens **once**, right after clicking **"Listen for test event"**. `/webhook/...` is permanent but needs Publish | Put the **production** URL (`/webhook/whatsapp`, no `-test`) in Twilio; Publish the workflow |
| Webhook 404s right after a restart | Registration flaps on restart in this version | Re-Publish, or restart again; verify `webhook_entity` |

There is **no separate "production mode"** to run n8n in — one process serves both
test and production webhooks. Production just needs Publish + the prod URL in Twilio.

---

## C. Importing workflows

| Symptom | Cause | Fix |
| --- | --- | --- |
| `make import-workflows` imports **0** | n8n's `--separate --input=<dir>` does **not** recurse into `spokes/*/` | Loop per file: `for f in $(find /workflows -name '*.json'); do n8n import:workflow --input="$f"; done` |
| `null value in column "id"` on single-file import | Workflow JSON had no top-level `"id"` | Add a stable `"id"` to every workflow JSON; single-file import preserves it |
| Spokes' **Call Hub** breaks after import | `--separate` regenerates random IDs, so `executeWorkflow.workflowId: "ai-hub"` no longer resolves | Give the Hub a stable `"id": "ai-hub"`, import single-file (preserves IDs), and reference it via a resource locator |
| Path errors like `C:/Program Files/Git/workflows/...` | Git Bash (MSYS) rewrites POSIX paths in args | Run the command inside `sh -c '...'` so the path isn't mangled |

---

## D. Node-specific gotchas

### `Execute Workflow` → renamed **`Execute Sub-workflow`**
Same node (`n8n-nodes-base.executeWorkflow`). Search "Execute Sub-workflow".

- Valid `mode` values are **`once`** / `each` — **not** `wait`. Waiting is controlled
  by `options.waitForSubWorkflow: true`.
- The **Workflow** field must be *selected from the dropdown* (resource locator). A
  manually-typed value can show **"Parameter Workflow is required"**. Correct shape:
  ```json
  "workflowId": { "__rl": true, "value": "ai-hub", "mode": "list", "cachedResultName": "ai-hub" }
  ```
- The referenced sub-workflow must itself be **Published** to be callable.

### Code node — `crypto is not defined`
n8n 2.26's Code-node sandbox does **not** expose `crypto`. Replace
`crypto.randomUUID()` with a `Math.random` helper:
```js
const uuid = () => 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, c => {
  const r = Math.random() * 16 | 0; return (c === 'x' ? r : (r & 3 | 8)).toString(16);
});
```

### Webhook payload — fields are nested under `body`
A form-urlencoded POST (Twilio) is parsed to `item.json.body.<Field>`, **not**
`item.json.<Field>`. Reading the top level returns the whole `body` object, which
breaks things like `body.startsWith is not a function`.
```js
const tw = item.json.body || item.json;   // always normalize first
```

### HTTP Request node drops upstream fields
`Call Ollama` (HTTP Request) **replaces** the item with the HTTP response, so
`_from` / `_to` set earlier are lost. Recover them from the earlier node:
```js
const src = $('Build Prompt').all()[i].json;   // not item.json
```

---

## E. Twilio gotchas

### Credential mismatch
Imported JSON referenced a placeholder credential id (e.g. `dc-twilio-cred`) that
doesn't exist. Open the node → select your real **Twilio account** credential.
Find the real id: `SELECT id, name, type FROM credentials_entity;`

### Error 21211 "To number ... is not a valid phone number" — the `To Whatsapp` toggle
The n8n Twilio node's **"To Whatsapp"** toggle **prepends `whatsapp:`** to From and To.
So you must pick **one** of these — never both:

| `To Whatsapp` | From / To values | Result |
| --- | --- | --- |
| **OFF** | `whatsapp:+14155238886` / `={{ $json._from }}` (already prefixed) | ✅ correct |
| **ON**  | `+14155238886` / `={{ $json._from.replace('whatsapp:','') }}` (raw) | ✅ correct |
| ON | `whatsapp:+...` (already prefixed) | ❌ `whatsapp:whatsapp:+...` → **21211** |

Twilio echoes the error with a single prefix because it consumes the first
`whatsapp:` as the channel — making it look correct when it isn't.

### Sandbox + verifying delivery
- The recipient must have **joined the sandbox** (sent the `join <code>` message) and
  there must be an open 24h session (they messaged you recently).
- Sanity-check the credentials/format with a direct API call:
  ```bash
  curl -X POST "https://api.twilio.com/2010-04-01/Accounts/$SID/Messages.json" \
    -u "$SID:$TOKEN" \
    --data-urlencode "From=whatsapp:+14155238886" \
    --data-urlencode "To=whatsapp:+919XXXXXXXXX" \
    --data-urlencode "Body=test"
  # status: queued  → format + sandbox are fine; the bug is in the n8n node config
  ```

---

## F. Tunnel (cloudflared / ngrok)

- The `trycloudflare.com` URL is **ephemeral** — it changes every time you restart
  the tunnel, and dies when you close the terminal. Update the Twilio webhook URL
  **and** `WEBHOOK_URL` in `.env` whenever it changes.
- `ERR Unable to reach the origin service ... EOF` on `/rest/ph/flags` etc. is just
  the **n8n UI failing during an n8n restart** — harmless and transient.

---

## G. Reading execution errors from the database

The UI Executions tab is easiest (red run → red node → error). To pull it from the DB,
note that `execution_data.data` is a **flatted** array (values are string indices):

```python
import json
arr = json.load(open('data.json'))
def val(v):
    return arr[int(v)] if isinstance(v, str) and v.lstrip('-').isdigit() else v
for el in arr:
    if isinstance(el, dict) and 'message' in el and ('name' in el or 'stack' in el):
        print(val(el['message']), '|', val(el.get('description')))
```

---

## H. Open issue — the AI hallucinates data ⚠️

The simplified WhatsApp flow forwards the message straight to llama3 with a generic
prompt. Asked "check all my trades", it **invented** trades and P&L figures. It has
**no data access and no grounding guardrail.**

Two fixes:
1. **Prompt hardening** (quick): instruct the model it has *no* access to live
   accounts/trades/tools and must never invent numbers — see the guardrails in
   [04 · Workflow Design](04-workflow-design.md).
2. **Real data** (the goal): feed actual trades via the `kite-data` spoke / broker
   API so summaries are factual. This is why the Hub-and-Spoke + contracts exist.

---

## I. The working WhatsApp flow (reference)

```
Webhook (POST /whatsapp, Respond: Immediately)
  → Build Prompt        (tw = item.json.body || item.json; uuid helper; builds _prompt/_from/_to)
  → Skip Empty
  → Call Ollama         (HTTP POST http://ollama:11434/api/generate, model llama3:8b)
  → Parse Reply         (recovers _from/_to via $('Build Prompt'))
  → Reply WhatsApp      (Twilio: To Whatsapp OFF, From whatsapp:+14155238886, To {{ $json._from }})
```
Publish it, point Twilio's "When a message comes in" at the **production** URL, done.
