# Event Subscriptions — Integration Guide

> **Local snapshot — narrative guide.** Source: `https://docs.payroc.com/guides/board-merchants/event-subscriptions/create-an-event-subscription.md`
> and `https://docs.payroc.com/guides/board-merchants/event-subscriptions.md`.
> Last synced: 2026-06-22. Use for step-by-step setup context; use `api-schema.md` for all field names, enum values, and schemas.

---

## What Are Event Subscriptions?

Event subscriptions let you receive real-time webhook notifications when Payroc resources change. Instead of polling the API to detect status changes, you register an HTTPS endpoint and Payroc posts a notification to it whenever a subscribed event fires.

**Current use case:** Event subscriptions are primarily associated with the boarding workflow — you subscribe to `processingAccount.status.changed` or `terminalOrder.status.changed` to receive real-time updates when Payroc reviews and approves merchant applications or ships terminal hardware.

---

## How It Works

```
Your integration                    Payroc
     |                                 |
     |  POST /v1/event-subscriptions   |
     |-------------------------------->|
     |  201 Created (subscriptionId)   |
     |<--------------------------------|
     |                                 |
     |     [Event occurs]              |
     |                                 |
     |  POST <your webhook uri>        |
     |<--------------------------------|  (CloudEvents 1.0 payload)
     |  200 OK                         |
     |-------------------------------->|
```

1. You create an event subscription, specifying which events to monitor and your webhook endpoint URL.
2. Payroc returns a subscription ID.
3. When a subscribed event fires (e.g. a processing account status changes), Payroc sends a POST to your webhook URI with a CloudEvents 1.0 payload.
4. Your endpoint returns HTTP 200 to acknowledge receipt.
5. If delivery fails (non-200 or timeout), Payroc retries up to 5 times; after all retries fail, the subscription transitions to `failed` and Payroc emails your `supportEmailAddress`.

---

## Prerequisites

- **API key** — to exchange for a Bearer token.
- **Processing terminal ID** — not needed for event subscriptions themselves (subscriptions are account-level, not terminal-level). However you need one if you also want to test payment flows.
- **Publicly reachable HTTPS endpoint** — your webhook receiver must be accessible from the internet. For development/testing, use a tool like [ngrok](https://ngrok.com/) or [Hookdeck](https://hookdeck.com/) to expose a local endpoint.

---

## Setting Up Your Webhook Endpoint

Before creating the subscription, your endpoint should:

1. **Accept `POST` requests** at the URI you'll register.
2. **Read the `Payroc-Secret` header** and verify it matches the `secret` you set in the subscription. Reject requests where it doesn't match.
3. **Return HTTP 200** to acknowledge receipt — even if you process the event asynchronously. Return the 200 immediately; process the payload afterwards.
4. **Handle duplicates** — use the CloudEvents `id` field (the unique identifier of the event) to detect and discard duplicate deliveries.

**Secret verification example (Node.js):**
```javascript
app.post('/webhooks/payroc', (req, res) => {
  const secret = req.headers['payroc-secret'];
  if (secret !== process.env.PAYROC_WEBHOOK_SECRET) {
    return res.status(401).send('Unauthorized');
  }
  // Acknowledge immediately; process body asynchronously
  res.status(200).send('OK');
  processEvent(req.body);
});
```

---

## Managing Subscriptions

### Updating a subscription

Use `PUT /v1/event-subscriptions/{subscriptionId}` to fully replace a subscription's configuration, or `PATCH` with RFC 6902 JSON Patch operations for partial updates (e.g. toggling `enabled` or adding an event type).

### Disabling vs. deleting

- **Disable** (set `enabled: false` via PUT or PATCH) — keeps the subscription record and its ID; no notifications are sent while disabled. Re-enable at any time.
- **Delete** (`DELETE /v1/event-subscriptions/{subscriptionId}`) — permanently removes the subscription. Any future events matching the event types will not trigger notifications.

### Recovering a failed subscription

If the subscription reaches `failed` status (all delivery retries exhausted), you need to:
1. Fix the delivery issue (check your endpoint is reachable, returns 200, etc.).
2. Update the subscription to re-enable it or change the URI.
3. The subscription returns to `registered` once re-enabled successfully.

---

## UAT Note

**Event access in UAT is key-scoped, not universally blocked.** `GET`/`POST /v1/event-subscriptions` work fine (200/201) against a key that has event access enabled. If you get a 401 at the identity step or an access error on the call itself, you're most likely using a key without event access enabled rather than hitting a platform-wide UAT limitation — switch to an event-enabled key before assuming the feature is unavailable.

Workaround if you don't have an event-enabled key yet: test your webhook endpoint independently by sending a synthetic CloudEvents 1.0 payload matching the schemas in `references/api-schema.md`, then integrate live once an event-enabled key is available.
