---
name: set-up-event-subscriptions
description: >
  Guides developers through Payroc's event subscription API — registering webhook endpoints to
  receive real-time CloudEvents notifications when Payroc resources change. Use this skill when
  the user wants to set up webhooks with Payroc, receive webhook notifications from Payroc,
  subscribe to Payroc resource-change events, listen for processingAccount.status.changed events,
  listen for terminalOrder.status.changed events, implement event-driven integrations with Payroc,
  register a webhook endpoint with Payroc, create or manage Payroc event subscriptions (create,
  list, retrieve, update, disable, delete), handle Payroc webhook payloads, verify Payroc webhook
  signatures, or avoid polling the Payroc API for status updates. Also use when a developer asks
  how to know when a merchant's boarding status changes or when a terminal order ships — without
  polling. NOT for managing recurring billing subscriptions or payment plans.
metadata:
  version: "0.2.0"
  category: notifications
  status: draft
---

# Set Up Event Subscriptions

## Version check (run this first)

Before announcing anything or starting the flow, confirm this skill is current:

1. Read this skill's version from the `metadata.version` field in the frontmatter above.
2. Fetch the published copy and read its `metadata.version`:
   `https://raw.githubusercontent.com/payroc/skills/main/plugins/payroc/notifications/skills/set-up-event-subscriptions/SKILL.md`
3. Compare the two as semantic versions:
   - **This version >= published** → continue silently, no message. (A developer running an unreleased newer version is expected and fine.)
   - **This version < published** → tell the developer:
     > ⚠️ A newer version of this skill (v\<published\>) has been published — you're running v\<current\>. Upgrading is recommended for the best results.

     Then ask whether they'd like to continue with the current version or stop and upgrade first, and honour their answer.
   - **Couldn't fetch** (offline, network error, 404) → note briefly that the version couldn't be verified and continue.

---

> **UAT access is key-scoped.** `POST /v1/event-subscriptions` requires a key with event access enabled — if you get an access error, you're most likely using a key that isn't event-scoped (e.g. a general-purpose key) rather than hitting a platform-wide limitation. Contact the Payroc Integrations team to get an event-enabled key. In the meantime, you can test your webhook endpoint independently using a synthetic CloudEvents 1.0 payload.

---

On first invocation, announce to the developer:

> **Payroc Event Subscriptions**
> I'll guide you through registering a webhook endpoint with Payroc so you receive real-time notifications when resources change — no more polling.
>
> **How it works:**
> 1. You create an event subscription specifying which events to monitor and your webhook URL
> 2. Payroc returns a subscription ID
> 3. When a subscribed event fires, Payroc POSTs a CloudEvents 1.0 payload to your endpoint
> 4. Your endpoint returns HTTP 200 to acknowledge; Payroc retries up to 5 times on failure

---

## Quick reference

```text
POST   https://api.uat.payroc.com/v1/event-subscriptions     (create)
GET    https://api.uat.payroc.com/v1/event-subscriptions     (list)
GET    https://api.uat.payroc.com/v1/event-subscriptions/{subscriptionId}   (retrieve)
PUT    https://api.uat.payroc.com/v1/event-subscriptions/{subscriptionId}   (full update)
PATCH  https://api.uat.payroc.com/v1/event-subscriptions/{subscriptionId}   (partial update)
DELETE https://api.uat.payroc.com/v1/event-subscriptions/{subscriptionId}   (delete)

Authorization:   Bearer <token>
Idempotency-Key: <uuid-v4>   (required on POST and PATCH)
Content-Type:    application/json   (required on POST, PUT, PATCH)
```

---

## References

All event type values, field schemas, and webhook payload shapes live in the local `references/` files below. This skill emits from them — not from memory and not from live lookups.

| Source | Local file | Use for |
| --- | --- | --- |
| Auth / identity service | `references/identity-call.md` | Bearer token exchange — endpoint URL, header name, response fields |
| API schema reference | `references/api-schema.md` | **All** enum values, required fields, request/response schemas, webhook payload format |
| Integration narrative | `references/event-subscriptions-guide.md` | Step-by-step context, webhook endpoint setup, CloudEvents overview, delivery behaviour |
| Error response format | `references/error-response-format.md` | Error envelope (RFC 7807) + Payroc errors[] + canonical error type catalog |

These are local snapshots. Source URLs and last-synced dates are in [`references/_sources.md`](references/_sources.md).

---

## Core principles

1. **Inspect before asking** — scan the codebase for existing HTTP client setup, credential configuration, and env var conventions before asking questions. Use what you find.
2. **Read the schema reference before emitting any enum value.** The `eventTypes[]` string values and `notification.type` are documented in `references/api-schema.md`. Do not guess event type names from training data — a plausible-sounding string that isn't in the documented enum will silently fail to trigger notifications.
3. **Idempotency-Key on every POST and PATCH.** The header value must be a UUID v4. Omitting it on POST causes a 400.
4. **Never hardcode credentials.** API keys must come from environment variables or a secrets manager.
5. **Secret is write-only.** The `secret` you set in the subscription is masked in all responses (first 10 characters replaced with `*`) — store it securely before creating the subscription. If the secret is lost, you cannot retrieve it from the API; you must update the subscription (via PUT or PATCH) to set a new known secret value, then update your webhook endpoint's env var to match.
6. **Return 200 from your webhook immediately.** Acknowledge receipt synchronously; process the payload asynchronously. Non-200 responses are treated as delivery failures.

---

## Intake

**First, scan the codebase.** Look for:
- Server-side language and framework
- Existing HTTP client setup or credential configuration
- Any existing webhook handling (e.g. other payment provider webhooks)
- How environment variables are managed

Then ask the developer:

**What operations do you need?**
- [ ] Create a new event subscription (required for any new integration)
- [ ] List existing subscriptions (discover what's already registered)
- [ ] Retrieve a specific subscription (by ID)
- [ ] Update subscription configuration (change events, URL, enable/disable)
- [ ] Delete a subscription permanently

**Which events do you want to subscribe to?** (Select all that apply)
- `processingAccount.status.changed` — notified when Payroc changes a processing account status (boarding workflow)
- `processingAccount.riskStatus.changed` — notified when Payroc holds or releases funding for a processing account
- `processingAccount.signature.signed` — notified when an owner or authorized signatory signs the Merchant Processing Agreement
- `terminalOrder.status.changed` — notified when Payroc changes a terminal order status (hardware shipping)

> **Read `references/api-schema.md` before presenting, emitting, or reviewing any event type values, notification type values, status values, or Idempotency-Key requirements** — use only the documented strings. Do not suggest or accept values not listed there. This directive applies both to code generation and to code review tasks.

**Is your webhook endpoint ready?**
- If yes: confirm the URL and that it returns HTTP 200.
- If no: help them build it first — the endpoint must exist and be publicly reachable before Payroc can deliver notifications to it.

---

## Prerequisites

1. **API key** — exchanged for a Bearer token. Provisioned by the Payroc Integrations team.
2. **Publicly reachable HTTPS endpoint** — your webhook receiver must be accessible from the internet. For local development, use ngrok or a similar tool.
3. **Webhook secret** — you choose a secret string to set in the subscription; Payroc echoes it in the `Payroc-Secret` header on every notification so you can verify authenticity.

If the webhook endpoint isn't built yet, help the developer implement it (Step 2) before creating the subscription (Step 3). Getting the endpoint right first avoids repeated subscription recreations.

---

## Step 1 — Authenticate

> Read `references/identity-call.md` before emitting any auth code. Do not guess the endpoint URL, header name, or response shape — use only what the reference documents.

Endpoints (from `references/identity-call.md`):
- UAT/test: `POST https://identity.uat.payroc.com/authorize`
- Production: `POST https://identity.payroc.com/authorize`

Header: `x-api-key: <api-key>`

The response contains `access_token`, `expires_in` (3600), and `token_type` ("Bearer"). Use `Authorization: Bearer <access_token>` on all subsequent API requests.

Store the API key in an environment variable (e.g. `PAYROC_API_KEY`). Never inline it.

### Checkpoint

Can the helper generate a Bearer token without error? If not, check the `x-api-key` header and confirm the API key is correct for the environment.

---

## Step 2 — Build the webhook endpoint

Before registering the subscription, the webhook receiver must be ready. Implement an HTTP handler that:

1. **Verifies the `Payroc-Secret` header** — compare against the secret you'll set in the subscription. Reject with 401 if it doesn't match.
2. **Returns HTTP 200 immediately** — do not wait for event processing to complete before responding. Payroc treats any non-200 as a delivery failure.
3. **Processes the payload asynchronously** — parse the CloudEvents 1.0 payload and handle it outside the HTTP response cycle.
4. **Handles duplicate deliveries** — use the `id` field in the CloudEvents envelope (the unique identifier of the event) to detect and skip duplicates. Store each processed CloudEvents `id` in a database or cache (e.g. a Redis set with a TTL, or a deduplication table) and skip processing for any `id` already seen.

> **Read `references/api-schema.md` for the CloudEvents 1.0 payload shape and the `data` object schema for each event type** before writing event-parsing code. Do not guess field names — the webhook payload structure is documented there verbatim.

**Webhook payload structure** (CloudEvents 1.0 — from `references/api-schema.md`):
```json
{
  "specversion": "1.0",
  "type": "<event type string>",
  "version": "1.0.0",
  "source": "payroc",
  "id": "<uuid>",
  "time": "<ISO 8601 timestamp>",
  "datacontenttype": "application/json",
  "data": { /* event-specific fields — read api-schema.md */ }
}
```

> `version` (`"1.0.0"`) is a Payroc-specific extension attribute — it is not a standard CloudEvents 1.0 field. Expect it in every Payroc webhook; treat it as an allowed extension if you validate against the CloudEvents schema.

**`data` schema by event type:**

*processingAccount.status.changed:*
- `processingAccountId` (string) — the account that changed
- `status` (enum) — the new status; valid values in `references/api-schema.md`

*processingAccount.riskStatus.changed:*
- `processingAccountId` (string) — the account whose risk status changed
- `riskStatus` (enum) — `fullSuspense` | `nonFullSuspense`; see `references/api-schema.md`

*processingAccount.signature.signed:*
- `processingAccountId` (string) — the account whose agreement was signed
- `signed` (string) — always `"true"`

*terminalOrder.status.changed:*
- `terminalOrderId` (string)
- `processingAccountId` (string)
- `status` (enum) — valid values in `references/api-schema.md`
- `reason` (string) — present when status is `cancelled` or `held`

> **Do not hardcode expected status values.** Read all status enum values from `references/api-schema.md` before writing any switch/case or if-else branching on status. A value not in the documented enum will silently fall through.

Store the webhook secret in an environment variable (e.g. `PAYROC_WEBHOOK_SECRET`) — never hardcode it.

**Example endpoint skeleton (Node.js/Express):**
```javascript
const crypto = require('crypto');

app.post('/webhooks/payroc', express.json(), (req, res) => {
  const receivedSecret = req.headers['payroc-secret'] ?? '';
  const expectedSecret = process.env.PAYROC_WEBHOOK_SECRET ?? '';
  // Use a constant-time comparison to avoid timing-attack exposure of the secret.
  const secretsMatch =
    receivedSecret.length === expectedSecret.length &&
    crypto.timingSafeEqual(Buffer.from(receivedSecret), Buffer.from(expectedSecret));
  if (!secretsMatch) {
    return res.status(401).send('Unauthorized');
  }
  // Acknowledge immediately
  res.status(200).send('OK');
  // Process asynchronously
  setImmediate(() => handleEvent(req.body));
});
```

> **Why `timingSafeEqual`?** A naive `!==` string comparison leaks information through response timing — an attacker can measure how many characters match before the comparison short-circuits. Use a constant-time comparison (Node.js: `crypto.timingSafeEqual`; Python: `hmac.compare_digest`; C#: `CryptographicOperations.FixedTimeEquals`) whenever comparing secrets.

### Checkpoint

Is the endpoint returning 200 for a test POST? Use a tool like curl or Postman to send a synthetic CloudEvents payload (matching the schema in `references/api-schema.md`) and verify the response. Don't proceed to subscription creation until this works — Payroc won't retry successfully until the endpoint is healthy.

---

## Step 3 — Create the event subscription

**Endpoint:** `POST https://api.uat.payroc.com/v1/event-subscriptions`

**Required headers:**
```
Authorization:   Bearer <access_token>
Idempotency-Key: <uuid-v4>
Content-Type:    application/json
```

> **Read `references/api-schema.md` before writing the request body.** The `eventTypes[]` string values and `notification.type` enum value are defined there. Do not emit any event type not listed in the reference — an unrecognised string will silently register a subscription that never fires.

**Required fields:**
- `enabled` (boolean) — set `true` to receive notifications immediately
- `eventTypes` (array) — one or more event type strings from the reference
- `notifications` (array) — at least one notification object

**Notification object** (all fields required):
- `type` — must be `"webhook"` (only documented value)
- `uri` — your publicly reachable HTTPS endpoint
- `secret` — the string Payroc will echo in `Payroc-Secret` header on every delivery
- `supportEmailAddress` — Payroc contacts this address if delivery fails after all retries

**Optional fields:**
- `metadata` — key/value pairs echoed back in responses; useful for your own tracking

Generate a fresh UUID v4 for `Idempotency-Key`. On retry of the *same* submission, reuse the same key — the API returns the original response instead of creating a duplicate. On a genuinely new submission, generate a new UUID.

**Example request:**
```bash
curl -X POST https://api.uat.payroc.com/v1/event-subscriptions \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Idempotency-Key: $(uuidgen | tr '[:upper:]' '[:lower:]')" \
  -H "Content-Type: application/json" \
  -d '{
    "enabled": true,
    "eventTypes": ["processingAccount.status.changed"],
    "notifications": [
      {
        "type": "webhook",
        "uri": "https://my-server.example.com/webhooks/payroc",
        "secret": "my-webhook-secret-value",
        "supportEmailAddress": "ops@example.com"
      }
    ]
  }'
```

**Response (201 Created):**
```json
{
  "id": 2565435189324,
  "enabled": true,
  "status": "registered",
  "eventTypes": ["processingAccount.status.changed"],
  "notifications": [
    {
      "type": "webhook",
      "uri": "https://my-server.example.com/webhooks/payroc",
      "secret": "**********-value",
      "supportEmailAddress": "ops@example.com"
    }
  ]
}
```

**Persist the `id` immediately** — it's required for all subsequent operations (retrieve, update, delete). The `secret` is masked in the response; you cannot retrieve the full value later.

> **IDs are integers.** The `id` field is an int64 integer, not a string or UUID. Use it verbatim in path parameters.

### Checkpoint

Did the API return HTTP 201 with an `id` and `status: "registered"`? If not, work through the error taxonomy below.

---

## Step 4 — Verify delivery

Once the subscription is created, trigger a test event if possible (e.g. update a processing account or terminal order via the boarding API) and confirm your webhook endpoint receives the notification.

If you cannot trigger the event directly, verify the subscription was created correctly:

1. `GET /v1/event-subscriptions/{id}` — confirm status is `registered` and `enabled: true`
2. Send a synthetic CloudEvents 1.0 POST directly to your endpoint to test your parsing and acknowledgement logic
3. Check `supportEmailAddress` is reachable — if the real event eventually fires and delivery fails, Payroc will email it

### Checkpoint

Is the subscription listed as `registered` and `enabled: true`? Is your webhook handler returning 200 for synthetic test payloads?

---

## Step 5 — Manage existing subscriptions

*(Implement only the sections the developer selected during intake)*

### List subscriptions

`GET https://api.uat.payroc.com/v1/event-subscriptions`

Headers: `Authorization: Bearer <token>`

Optional query parameters:
- `status` — filter by `registered`, `suspended`, or `failed`
- `event` — filter by event type string

> **Read `references/api-schema.md` for the valid `status` enum values** before writing filter logic.

Returns a paginated response: `{ limit, count, hasMore, links, data[] }`.

---

### Retrieve a subscription

`GET https://api.uat.payroc.com/v1/event-subscriptions/{subscriptionId}`

Headers: `Authorization: Bearer <token>`

Returns the full subscription object. `subscriptionId` is the integer `id` from the create/list response.

---

### Update a subscription (full replacement)

`PUT https://api.uat.payroc.com/v1/event-subscriptions/{subscriptionId}`

Required headers: `Authorization: Bearer <token>`, `Content-Type: application/json`

> No `Idempotency-Key` required on PUT — unlike POST and PATCH.

The body replaces the entire subscription configuration. Required fields: `enabled`, `eventTypes`, `notifications`. Optional: `id`, `status`, `metadata`.

Returns **204 No Content** on success (no body).

---

### Partially update a subscription

`PATCH https://api.uat.payroc.com/v1/event-subscriptions/{subscriptionId}`

Required headers: `Authorization: Bearer <token>`, `Idempotency-Key: <uuid-v4>`, `Content-Type: application/json`

Body is an **RFC 6902 JSON Patch array** — not a flat object:
```json
[
  { "op": "replace", "path": "/enabled", "value": false }
]
```

> **Read `references/api-schema.md` for the valid `op` values** before writing patch operations.

Patchable paths: `/enabled`, `/eventTypes`, `/notifications`.

Returns 200 with the full updated subscription object.

**Disabling vs deleting:** `{ "op": "replace", "path": "/enabled", "value": false }` disables notifications but keeps the subscription record. Use DELETE for permanent removal.

---

### Delete a subscription

`DELETE https://api.uat.payroc.com/v1/event-subscriptions/{subscriptionId}`

Headers: `Authorization: Bearer <token>`

**No request body, no Idempotency-Key required.**

Returns **204 No Content** on success.

**Before writing deletion code:** confirm with the developer that this is permanent. A deleted subscription cannot be recovered — any future events for those event types will not trigger notifications. If the intent is to temporarily stop notifications, use PATCH to set `enabled: false` instead.

---

## Error taxonomy

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| 400 — validation error on `eventTypes` | Event type string not in documented enum | Read `references/api-schema.md` and use only the documented event type strings |
| 400 — validation error on `notification.type` | Value other than `"webhook"` used | Use `"webhook"` exactly — the only documented value |
| 400 — missing or malformed `Idempotency-Key` | Header absent or not a UUID v4 | Add `Idempotency-Key: <UUID v4>` to every POST and PATCH |
| 400 — validation errors on notification fields | Missing `uri`, `secret`, or `supportEmailAddress` | All four notification fields are required: `type`, `uri`, `secret`, `supportEmailAddress` |
| 401 — authentication failed | Token expired or API key wrong | Re-exchange the API key for a fresh Bearer token |
| 406 — not acceptable | Request format rejected (e.g. unsupported `Accept` header) | Omit the `Accept` header or set it to `application/json` |
| 404 — subscription not found | Wrong `subscriptionId` or subscription was deleted | Verify the ID from the create/list response |
| 409 — conflict | Duplicate subscription | List existing subscriptions to check whether one already covers these event types |
| 500 — server error | Transient error | Retry with exponential backoff |
| Notifications not received | Subscription status `failed` | Check `supportEmailAddress` for a Payroc notification; fix your endpoint; update the subscription to re-enable |
| Notifications not received | `enabled: false` | PATCH the subscription to `{ "op": "replace", "path": "/enabled", "value": true }` |
| Unexpected/duplicate notification | Payroc delivered the same event twice | Use the CloudEvents `id` field to detect and skip duplicates |
| `Payroc-Secret` header mismatch | Secret in subscription doesn't match what endpoint expects | Verify the secret stored in your env var matches what you set in the subscription |

**Reading validation errors:** Errors follow the RFC 7807 problem-details envelope (`type`, `title`, `status`, `detail`, `instance`); Payroc extends it with an `errors` array. Each `errors[]` item has `parameter` (JSON path of the failing field), `detail` (short reason), and `message` (human-readable explanation). See [`references/error-response-format.md`](references/error-response-format.md) for the envelope shape and the canonical error `type` catalog.

---

## Validation checklist

- [ ] API key sourced from environment variable — never hardcoded
- [ ] Bearer token generated from identity service — never hardcoded
- [ ] `Idempotency-Key` header present on every POST and PATCH — UUID v4 format
- [ ] `eventTypes[]` values read from `references/api-schema.md` — not from memory
- [ ] `notification.type` is `"webhook"` (only documented value)
- [ ] `uri`, `secret`, and `supportEmailAddress` all provided in each notification object
- [ ] Webhook secret stored in an environment variable — never hardcoded
- [ ] Webhook endpoint returns HTTP 200 immediately on receipt
- [ ] Webhook endpoint verifies `Payroc-Secret` header against expected secret
- [ ] `data` field parsing uses event-type-specific field names from `references/api-schema.md`
- [ ] Status enum values read from `references/api-schema.md` — not inferred from names
- [ ] Subscription `id` (integer) persisted after creation
- [ ] Duplicate delivery handling implemented: CloudEvents `id` checked against a persistent store (DB table or cache) before processing
- [ ] UAT endpoints used (`api.uat.payroc.com`) during testing

---

## Completion

Once all checklist items pass:

> **Event subscription set up.** Here's what you've built:
>
> - **Webhook endpoint** — receives and verifies Payroc notifications; returns 200 immediately; processes asynchronously.
> - **Subscription registered** — ID: `<id>`, monitoring: `<event types>`.
> - **Secret verification** — `Payroc-Secret` header checked against env var.
> - **Duplicate handling** — CloudEvents `id` used to detect and discard duplicate deliveries.
>
> **Before going live:** swap `api.uat.payroc.com` for `api.payroc.com` and `identity.uat.payroc.com` for `identity.payroc.com`. Ensure your webhook endpoint is deployed and reachable in production.

Offer next steps:
- **Boarding integration** — use `processingAccount.status.changed` events to drive merchant onboarding status in your platform
- **Funding risk tracking** — use `processingAccount.riskStatus.changed` to detect when funding is held or released
- **Signature tracking** — use `processingAccount.signature.signed` to know when a merchant has signed their agreement without polling
- **Terminal hardware tracking** — use `terminalOrder.status.changed` to show merchants the shipping status of their terminals
- **Payment webhooks** — for transaction-level notifications, check the Payroc docs for payment event types as they become available
