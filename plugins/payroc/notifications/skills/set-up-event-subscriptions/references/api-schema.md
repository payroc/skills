# Event Subscriptions — API Schema Reference

> **Local snapshot — authoritative for this skill.** Source: `https://docs.payroc.com/openapi.yml`
> and `https://docs.payroc.com/api/schema/notifications/event-subscriptions/` (per-operation docs).
> Last synced: 2026-09-16. This is the offline source of truth this skill emits from — read enum
> values and required-field sets from here, not from memory.

---

## Endpoints

| Operation | Method | Path |
| --- | --- | --- |
| Create event subscription | `POST` | `/v1/event-subscriptions` |
| List event subscriptions | `GET` | `/v1/event-subscriptions` |
| Retrieve event subscription | `GET` | `/v1/event-subscriptions/{subscriptionId}` |
| Update event subscription (full) | `PUT` | `/v1/event-subscriptions/{subscriptionId}` |
| Partially update event subscription | `PATCH` | `/v1/event-subscriptions/{subscriptionId}` |
| Delete event subscription | `DELETE` | `/v1/event-subscriptions/{subscriptionId}` |

UAT host: `https://api.uat.payroc.com`
Production host: `https://api.payroc.com`

---

## Enums

### eventTypes[] — available event type identifiers

Read these verbatim; do not guess or invent event type names.

| Event type string | Description |
| --- | --- |
| `processingAccount.status.changed` | Payroc changed the status of a processing account |
| `processingAccount.riskStatus.changed` | Payroc changed the risk status of a processing account (funding held/released) |
| `processingAccount.signature.signed` | An owner or authorized signatory signed the Merchant Processing Agreement |
| `terminalOrder.status.changed` | Payroc changed the status of a terminal order |

> **Note:** This is the complete list of documented event types as of 2026-09-16. Do not emit any event type string not listed here.

### status — event subscription status (read-only; returned by API)

| Value | Description |
| --- | --- |
| `registered` | Active subscription — ready to receive event notifications |
| `suspended` | Subscription deactivated — notifications are disabled |
| `failed` | Delivery failed repeatedly — support team was notified |

> `status` is returned by the API; do not send it in the create request body. It may be used as an optional query parameter when listing subscriptions (`GET /v1/event-subscriptions?status=…`), and it may be sent in a PUT body (full update) but is optional there.

### notification.type — notification delivery method

| Value | Description |
| --- | --- |
| `webhook` | HTTP POST to the URI you supply |

> `webhook` is the only documented value. Do not emit any other string for this field.

---

## Schemas

### Create request body

**Endpoint:** `POST /v1/event-subscriptions`

**Required headers:**
```
Authorization:   Bearer <access_token>
Idempotency-Key: <uuid-v4>
Content-Type:    application/json
```

**Required fields:**
- `enabled` (boolean) — controls whether notifications are sent when events fire
- `eventTypes` (array of strings) — at least one event type from the enum above
- `notifications` (array of notification objects) — at least one entry

**Optional fields:**
- `metadata` (object) — key/value pairs you supply; echoed back in responses

**Notification object** (all fields required when the object is present):

| Field | Type | Description |
| --- | --- | --- |
| `type` | string enum | Must be `"webhook"` |
| `uri` | string | Your public endpoint URL; must be reachable from the internet |
| `secret` | string | Validation token — Payroc sends this in the `Payroc-Secret` header with every webhook so you can verify authenticity |
| `supportEmailAddress` | string | Email address Payroc contacts if webhook delivery fails after retries |

**Example request:**
```json
{
  "enabled": true,
  "eventTypes": ["processingAccount.status.changed"],
  "notifications": [
    {
      "type": "webhook",
      "uri": "https://my-server.example.com/webhooks/payroc",
      "secret": "aBcD1234eFgH5678iJkL9012mNoP3456",
      "supportEmailAddress": "ops@example.com"
    }
  ],
  "metadata": { "internalRef": "sub-001" }
}
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
      "secret": "**********oP3456",
      "supportEmailAddress": "ops@example.com"
    }
  ],
  "metadata": { "internalRef": "sub-001" }
}
```

> **Secret masking in responses:** The `secret` is masked — the first 10 characters are replaced with `*` and only the last 6 characters are shown. Store the original secret securely before creating the subscription; the full value cannot be retrieved later.

> **ID is an integer:** The `id` field returned is an integer (int64), not a string or UUID. Use it verbatim in path parameters for subsequent operations.

---

### List response (GET /v1/event-subscriptions)

Query parameters:
- `status` (optional) — filter by subscription status: `registered` | `suspended` | `failed`
- `event` (optional) — filter by event type string

Response (200):
```json
{
  "limit": 10,
  "count": 2,
  "hasMore": false,
  "links": [],
  "data": [
    { /* eventSubscription object */ }
  ]
}
```

Pagination is cursor-based via `limit`, `after`, `before` query parameters; `hasMore` indicates additional pages exist.

---

### Retrieve response (GET /v1/event-subscriptions/{subscriptionId})

Path parameter: `subscriptionId` (integer — the `id` from create/list)

Response (200): single `eventSubscription` object (same shape as the create response).

---

### Update request body (PUT /v1/event-subscriptions/{subscriptionId})

Full replacement. Required fields same as create: `enabled`, `eventTypes`, `notifications`.
Optional: `id`, `status`, `metadata`.

**Response: 204 No Content** (empty body on success).

---

### Partial update request body (PATCH /v1/event-subscriptions/{subscriptionId})

RFC 6902 JSON Patch array. Required headers include `Idempotency-Key`.

Patchable paths: `/eventTypes`, `/notifications`, `/enabled`.

**Op values:** `add` | `remove` | `replace` | `move` | `copy` | `test`

**Example:**
```json
[
  { "op": "replace", "path": "/enabled", "value": false }
]
```

**Response: 200** with the full updated `eventSubscription` object.

---

### Delete (DELETE /v1/event-subscriptions/{subscriptionId})

No request body. Authorization header required. No Idempotency-Key required.

**Response: 204 No Content** on success.

---

## Webhook payload — CloudEvents 1.0 format

All Payroc event notifications follow the [CloudEvents 1.0](https://cloudevents.io/) specification.

```json
{
  "specversion": "1.0",
  "type": "<event type string>",
  "version": "1.0.0",
  "source": "payroc",
  "id": "<uuid — unique identifier of the event>",
  "time": "<ISO 8601 timestamp>",
  "datacontenttype": "application/json",
  "data": { /* event-specific data */ }
}
```

> **Note on `version`:** The `version` field (`"1.0.0"`) is a Payroc-specific extension attribute — it is not part of the CloudEvents 1.0 standard attributes (`specversion`, `id`, `source`, `type`, `datacontenttype`, `time`, `data`). Expect it in every Payroc webhook payload. If you write strict CloudEvents schema validation, treat `version` as an allowed extension attribute.

### data object — processingAccount.status.changed

| Field | Type | Description |
| --- | --- | --- |
| `processingAccountId` | string | ID of the processing account whose status changed |
| `status` | enum | New status value |

Processing account status enum values:

| Value | Description |
| --- | --- |
| `entered` | Account info received, not yet reviewed |
| `pending` | Info reviewed, not yet approved |
| `approved` | Account approved for processing and funding |
| `subjectTo` | Approved with required supporting documents outstanding |
| `dormant` | Account temporarily closed |
| `nonProcessing` | Approved but no transactions initiated |
| `rejected` | Application rejected |
| `terminated` | Account permanently closed |
| `cancelled` | Merchant withdrew the application |

**Example:**
```json
{
  "specversion": "1.0",
  "type": "processingAccount.status.changed",
  "version": "1.0.0",
  "source": "payroc",
  "id": "123e4567-e89b-12d3-a456-426614174000",
  "time": "2024-07-02T15:30:00.000Z",
  "datacontenttype": "application/json",
  "data": {
    "processingAccountId": "38765",
    "status": "approved"
  }
}
```

### data object — processingAccount.riskStatus.changed

| Field | Type | Description |
| --- | --- | --- |
| `processingAccountId` | string | ID of the processing account whose risk status changed |
| `riskStatus` | enum | New risk status value |

Risk status enum values:

| Value | Description |
| --- | --- |
| `fullSuspense` | Funding suspended — all settlements held until Payroc completes its review |
| `nonFullSuspense` | Processing account cleared for normal funding |

**Example:**
```json
{
  "specversion": "1.0",
  "type": "processingAccount.riskStatus.changed",
  "version": "1.0.0",
  "source": "payroc",
  "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "time": "2024-09-15T10:45:00.000Z",
  "datacontenttype": "application/json",
  "data": {
    "processingAccountId": "38765",
    "riskStatus": "fullSuspense"
  }
}
```

### data object — processingAccount.signature.signed

| Field | Type | Description |
| --- | --- | --- |
| `processingAccountId` | string | ID of the processing account whose Merchant Processing Agreement was signed |
| `signed` | string | Always `"true"` — Payroc only sends this event once the agreement is signed |

**Example:**
```json
{
  "specversion": "1.0",
  "type": "processingAccount.signature.signed",
  "version": "1.0.0",
  "source": "payroc",
  "id": "123e4567-e89b-12d3-a456-426614174000",
  "time": "2026-05-21T11:30:00.000Z",
  "datacontenttype": "application/json",
  "data": {
    "processingAccountId": "38765",
    "signed": "true"
  }
}
```

### data object — terminalOrder.status.changed

| Field | Type | Description |
| --- | --- | --- |
| `terminalOrderId` | string | ID of the terminal order whose status changed |
| `processingAccountId` | string | ID of the associated processing account |
| `status` | enum | New status value |
| `reason` | string | Explanation — present when status is `cancelled` or `held` |

Terminal order status enum values:

| Value | Description |
| --- | --- |
| `open` | Order is being processed |
| `dispatched` | Items have been shipped |
| `fulfilled` | Order complete |
| `cancelled` | Order was cancelled (reason field populated) |
| `held` | Order placed on hold (reason field populated) |

**Example:**
```json
{
  "specversion": "1.0",
  "type": "terminalOrder.status.changed",
  "version": "1.0.0",
  "source": "payroc",
  "id": "c24a7423-9bed-403d-93eb-004dfadcc19b",
  "time": "2024-11-01T16:00:00.000Z",
  "datacontenttype": "application/json",
  "data": {
    "terminalOrderId": "1436",
    "processingAccountId": "12345678",
    "status": "held",
    "reason": "Pending MID Approval"
  }
}
```

---

## Webhook delivery behaviour

- Payroc sends the `Payroc-Secret` header with every webhook POST. Verify its value matches your subscription's `secret` to confirm authenticity.
- Your endpoint **must return HTTP 200** to acknowledge receipt. Any other response code is treated as a delivery failure.
- On failure, Payroc **retries up to 5 times**. If all retries fail, Payroc contacts `supportEmailAddress` and the subscription transitions to `failed` status.
- Idempotency: the CloudEvents `id` field is the unique identifier of the event — use it to detect and discard duplicate deliveries.

---

## Errors

Errors use the **RFC 7807 problem-details envelope** (`type`, `title`, `status`, `detail`, `instance`) extended with a Payroc `errors[]` array. See `references/error-response-format.md` for the envelope shape and the canonical error `type` catalog; read `errors[].parameter` to map each failure to your request body.

Status codes these endpoints return: `400` (validation), `401` (auth/expired token), `403` (permissions), `404` (unknown `subscriptionId`, or one belonging to a different account), `406` (content negotiation — unsupported request format), `409` (conflict — a subscription with conflicting configuration already exists), `500` (server — retry with backoff).
