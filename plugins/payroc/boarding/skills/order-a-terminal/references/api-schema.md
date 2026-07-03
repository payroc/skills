# Order a Terminal — Full API Schema Reference

Snapshot of the Payroc Boarding API surface for ordering a terminal against an **existing**
processing account, reading the order back, and (optionally) reading the provisioned processing
terminal. Sourced from `https://docs.payroc.com/openapi.yml` (see `_sources.md`). Emit field names
and enum values from this file — not from memory. The `orderItems` array and its nested
`solutionSetup` are deep and enum-heavy.

---

## Contents

- [Endpoints](#endpoints)
- [Headers](#headers)
- [Enums](#enums)
- [Request body — `createTerminalOrder`](#request-body--createterminalorder)
- [Response — `terminalOrder`](#response--terminalorder-201-on-create-200-on-retrieve)
- [List — `GET /processing-accounts/{id}/terminal-orders`](#list--get-processing-accountsidterminal-orders)
- [Optional follow-on — read the provisioned terminal](#optional-follow-on--read-the-provisioned-terminal)
- [Errors](#errors)
- [Complete annotated example](#complete-annotated-example--order-one-terminal-for-an-existing-processing-account)

---

## Endpoints

| Operation | Method & path | Request | Response |
|-----------|---------------|---------|----------|
| Create a terminal order | `POST /v1/processing-accounts/{processingAccountId}/terminal-orders` | `createTerminalOrder` | `201` → `terminalOrder` |
| List a processing account's orders | `GET /v1/processing-accounts/{processingAccountId}/terminal-orders` | — (query params) | `200` → array of `terminalOrder` |
| Retrieve one order | `GET /v1/terminal-orders/{terminalOrderId}` | — | `200` → `terminalOrder` |
| List a PA's processing terminals *(follow-on)* | `GET /v1/processing-accounts/{processingAccountId}/processing-terminals` | — | `200` → `paginatedProcessingTerminals` |
| Retrieve one processing terminal *(follow-on)* | `GET /v1/processing-terminals/{processingTerminalId}` | — | `200` → `processingTerminal` |
| Retrieve a terminal's host configuration *(follow-on)* | `GET /v1/processing-terminals/{processingTerminalId}/host-configurations` | — | `200` → `hostConfiguration` |

UAT host: `https://api.uat.payroc.com`  ·  Production host: `https://api.payroc.com`

> **Two different path roots.** You *create* and *list* orders under the **processing account**
> (`/processing-accounts/{processingAccountId}/terminal-orders`), but once an order exists you
> retrieve it directly by its own id under **`/terminal-orders/{terminalOrderId}`**. The provisioned
> *processing terminal* (a separate resource) is addressed under `/processing-terminals/{id}`.

> **The three follow-on reads are unverified in UAT** — a UAT order does not surface a
> `processingTerminalId` (the test rig uses a non-physical device), so the processing-terminal and
> host-configuration reads can't be validated end-to-end. The shapes below are from the spec. Warn
> the developer before emitting these calls and let them choose to include or skip them; see
> `_sources.md`.

---

## Headers

| Header | Required on | Notes |
|--------|-------------|-------|
| `Authorization` | all | `Bearer <access_token>` |
| `Idempotency-Key` | `POST` (create order) | UUID v4; reuse on retry of the same order |
| `Content-Type` | `POST` | `application/json` |

---

## Enums

### terminalOrder status (response only)
`open` | `held` | `dispatched` | `fulfilled` | `cancelled`

Subscribe to the `terminalOrder.status.changed` event to be notified of status changes instead of
polling.

### trainingProvider
`partner` | `payroc` (default `partner`) — who trains the merchant on the solution.

### orderItem type
`solution` (the only value).

### solutionTemplateId
Identifies the device/solution to order. Spec values:
`Roc Services_DX8000` | `Roc Services_DX4000` | `Roc Services_Web` | `Roc Services_Mobile` |
`Payroc DX8000` | `Payroc DX4000` | `Payroc RX7000_Cloud` | `Payroc DX8000_Cloud` |
`Payroc DX4000_Cloud` | `Payroc A920Pro` | `Payroc A80` | `Payroc A920Pro_Cloud` |
`Payroc A80_Cloud` | `Roc Terminal Plus_N950` | `Roc Terminal Plus_N950-S` |
`Roc Terminal Plus_X800` | `Gateway_Payroc` | `VAR_Only_TSYS` | `ROC Services Chipper3X` |
`BBPOS Chipper 3X` | `Augusta EMV` | `Ingenico - AXIUM Full Functional Base` |
`Pax A920 Charging Base` | `Pax A920 Comms Base` | `A920 Pro Ethernet` | `Axium Bundle`

> **UAT note:** most of these templates are environment/config-gated. The one reliably accepted by
> UAT is **`VAR_Only_TSYS`**. Use it for test/UAT calls; for production, send the template the
> merchant actually ordered. This is a testing
> aid, not a production constraint.

### deviceCondition
`new` | `refurbished`

### shipping preferences method
`nextDay` | `ground` (default `nextDay`)

### industryTemplateId
`Retail` | `Restaurant` | `Moto` | `Ecommerce`

### timezone
`Pacific/Midway` | `Pacific/Honolulu` | `America/Anchorage` | `America/Los_Angeles` |
`America/Denver` | `America/Phoenix` | `America/Chicago` | `America/Indiana/Indianapolis` |
`America/New_York` (default: the processing account's timezone)

### deviceSettings communicationType
`bluetooth` | `cellular` | `ethernet` | `wifi`

### batchClosure batchCloseType (discriminated)
`automatic` (add `batchCloseTime`, `HH:MM`) | `manual`

---

## Request body — `createTerminalOrder`

Required: `orderItems` (array, **1–20** items). Optional top-level: `trainingProvider`
(default `partner`), `shipping` (**omit to ship to the processing account's DBA address**).

```json
{
  "trainingProvider": "payroc",               // optional, enum, default "partner"
  "shipping": { ... },                         // optional — omit to use the DBA address
  "orderItems": [ ... ]                        // required, 1–20 orderItem objects
}
```

### shipping object (optional)

```json
{
  "preferences": {
    "method": "nextDay",                       // nextDay | ground (default nextDay)
    "saturdayDelivery": true                   // boolean, default false
  },
  "address": {                                 // if you send address, the fields below are required
    "recipientName": "Recipient Name",         // required, max 100
    "addressLine1": "1 Example Ave.",           // required, max 100
    "city": "Chicago",                          // required, max 50
    "state": "Illinois",                        // required, max 30
    "postalCode": "60056",                      // required, max 9
    "email": "example@mail.com",                // required, email, max 100
    "businessName": "Company Ltd",              // optional, max 100
    "addressLine2": "Example Address Line 2",  // optional, max 100
    "phone": "2025550164"                       // optional, max 15
  }
}
```

> **Shipping defaults to the DBA address.** If you omit `shipping` (or `shipping.address`), Payroc
> ships to the Doing Business As address on the processing account. Only send an address to ship
> somewhere else. When you *do* send an `address`, `recipientName`, `addressLine1`, `city`, `state`,
> `postalCode`, and `email` are all required.

### orderItems[] (`orderItem`)

Required per item: `type` (`solution`) and `solutionTemplateId`. Everything else is optional.

```json
{
  "type": "solution",                          // required, enum (only "solution")
  "solutionTemplateId": "Payroc A920Pro",      // required — see solutionTemplateId enum
  "solutionQuantity": 1,                        // optional integer, default 1, max 50
  "deviceCondition": "new",                     // optional, new | refurbished
  "solutionSetup": { ... }                      // optional — device/gateway/app configuration
}
```

### solutionSetup object (optional)

All fields optional. Configures the terminal at provisioning time.

```json
{
  "timezone": "America/Chicago",               // enum; defaults to the processing account's timezone
  "industryTemplateId": "Retail",              // Retail | Restaurant | Moto | Ecommerce

  "gatewaySettings": {                          // identifiers of pre-built gateway templates
    "merchantPortfolioId": "Company Ltd",
    "merchantTemplateId": "Company Ltd Merchant Template",
    "userTemplateId": "Company Ltd User Template",
    "terminalTemplateId": "Company Ltd Terminal Template"
  },

  "applicationSettings": {
    "clerkPrompt": false,                       // boolean
    "security": {                               // prompt for a password on these actions
      "refundPassword": true,
      "keyedSalePassword": false,
      "reversalPassword": true
    }
  },

  "deviceSettings": {
    "numberOfMobileUsers": 2,                   // integer — for mobile solutions
    "communicationType": "wifi"                 // bluetooth | cellular | ethernet | wifi
  },

  "batchClosure": {                             // discriminated on batchCloseType
    "batchCloseType": "automatic",              // automatic (+ batchCloseTime) | manual
    "batchCloseTime": "23:40"                   // HH:MM — only with "automatic"
  },

  "receiptNotifications": {
    "emailReceipt": true,
    "smsReceipt": false
  },

  "taxes": [                                    // array, 0–3 items
    { "taxRate": 6, "taxLabel": "Sales Tax" }   // taxRate 0–99.999, taxLabel max 10 — both required
  ],

  "tips": { "enabled": false },                 // boolean
  "tokenization": true                          // boolean — terminal can tokenize card details
}
```

> **`batchClosure` is discriminated on `batchCloseType`.** Use `{ "batchCloseType": "automatic",
> "batchCloseTime": "23:40" }` for a daily auto-close, or `{ "batchCloseType": "manual" }` (no
> `batchCloseTime`) when the merchant closes the batch themselves.

---

## Response — `terminalOrder` (201 on create, 200 on retrieve)

```json
{
  "terminalOrderId": "12345",                  // persist this — needed to retrieve the order
  "status": "open",                            // open | held | dispatched | fulfilled | cancelled
  "trainingProvider": "payroc",
  "shipping": { ... },                          // echoes what you sent (or the resolved DBA address)
  "orderItems": [
    {
      "type": "solution",
      "solutionTemplateId": "Payroc A920Pro",
      "solutionQuantity": 1,
      "deviceCondition": "new",
      "solutionSetup": { ... },
      "links": [                                // per-item — the provisioned processing terminal(s)
        {
          "processingTerminalId": "1234001",
          "link": { "rel": "processingTerminal", "method": "get", "href": "https://.../processing-terminals/1234001" }
        }
      ]
    }
  ],
  "createdDate": "2024-07-02T12:00:00.000Z",   // ISO-8601, read-only
  "lastModifiedDate": "2024-07-02T12:00:00.000Z"
}
```

Persist `terminalOrderId` immediately — it's how you retrieve the order later. The order starts in
`"open"`; subscribe to `terminalOrder.status.changed` (or poll the retrieve endpoint) to track it to
`dispatched`/`fulfilled` rather than relying on the create-response value.

> **`orderItems[].links` carries the provisioned `processingTerminalId`** — the handle you'd use for
> the follow-on processing-terminal reads. **In UAT this `links`/`processingTerminalId` is not
> populated** (non-physical device), so don't assume it's present when testing. See the follow-on
> section and `_sources.md`.

**IDs are opaque.** The `12345` / `1234001` forms here are for readability only. Treat every ID as
an opaque string whose format is not guaranteed and varies by environment — in UAT they come back
as plain integers. Don't validate or parse them against a `PREFIX-XXXX` pattern.

---

## List — `GET /processing-accounts/{id}/terminal-orders`

Returns a **plain JSON array** of `terminalOrder` objects (not a paginated envelope — unlike List
Processing Accounts). Query parameters, all optional, filter the list:

| Param | Type | Notes |
|-------|------|-------|
| `status` | string | One of `open`/`held`/`dispatched`/`fulfilled`/`cancelled`. |
| `fromDateTime` | string (ISO-8601) | Orders created **after** this instant, e.g. `2024-09-08T12:00:00.000Z`. |
| `toDateTime` | string (ISO-8601) | Orders created **before** this instant. |

```bash
GET /v1/processing-accounts/{processingAccountId}/terminal-orders?status=open&fromDateTime=2024-09-08T12:00:00.000Z
```

```json
[
  { "terminalOrderId": "12345", "status": "open", "orderItems": [ ... ], "createdDate": "...", "lastModifiedDate": "..." }
]
```

---

## Optional follow-on — read the provisioned terminal

> ⚠️ **Unverified in UAT, and the retrieve has a known defect.** A UAT terminal order doesn't return
> a `processingTerminalId` (the test environment uses a non-physical device), so these reads can't be
> exercised against UAT. Separately, even with a valid `processingTerminalId`, retrieving the
> processing terminal currently fails to deserialize `batchClosure` — the terminal-side
> `automaticBatchClose` requires a `batchCloseTime` that isn't always returned (see below). The host
> processor configuration is likewise not available in the test environment. The shapes are from the
> spec. Tell the developer this before emitting the code and let them include or skip it.

### List a PA's processing terminals
`GET /v1/processing-accounts/{processingAccountId}/processing-terminals` → `paginatedProcessingTerminals`
(a `{ limit, count, hasMore, links, data: [ processingTerminal ] }` envelope — paginate via the
`next`/`prev` links).

### Retrieve one processing terminal
`GET /v1/processing-terminals/{processingTerminalId}` → `processingTerminal`. Key fields:
`processingTerminalId`, `status` (`active` | `inactive`), `timezone`, `program`, `gateway`
(`{ gateway: "payroc", terminalTemplateId }`), `batchClosure`, `applicationSettings`, `features`
(tips/EBT/`enhancedProcessing`/`pinDebitCashback`/`recurringPayments`/`paymentLinks`/
`preAuthorizations`/`offlinePayments`), `taxes`, `security`
(`{ tokenization, avsPrompt, avsLevel, cvvPrompt }`), `receiptNotifications`, `devices[]`
(`manufacturer`, `model`, `serialNumber`, `communicationType`).

### Retrieve a terminal's host (processor) configuration
`GET /v1/processing-terminals/{processingTerminalId}/host-configurations` → `hostConfiguration`:
`{ processingTerminalId, processingAccountId, configuration }`, where `configuration` is
discriminated on `processor` (`tsys`) and carries `merchant` (`posMid`, `chainNumber`, `binNumber`,
…) and `terminal` (`terminalId`, `terminalNumber`, …) blocks.

(`POST /processing-terminals/{id}/close-batch` and the device-configuration reads also exist but are
out of scope for this skill.)

---

## Errors

Errors use the **RFC 7807 problem-details envelope** (`type`, `title`, `status`, `detail`, `instance`) extended with a Payroc `errors[]` array. See `references/error-response-format.md` for the envelope shape and the canonical error `type` catalog; read `errors[].parameter` to map each failure to your request body.

Status codes these endpoints return: `400` (validation, incl. `idempotencyKeyMissing`), `401`
(auth/expired token), `403` (permissions), `404` (unknown `processingAccountId`/`terminalOrderId`),
`406` (content negotiation), `409` (`idempotentKeyInUse` — an order already exists under this key),
`500` (server — retry with backoff). Example `400` from posting an order with no `orderItems`:

```json
{
  "type": "https://docs.payroc.com/api/errors#bad-request",
  "title": "Bad request",
  "status": 400,
  "detail": "One or more validation errors occurred, see error section for more info",
  "instance": "https://api.uat.payroc.com/v1/processing-accounts/287019/terminal-orders",
  "errors": [
    { "parameter": "createTerminalOrder.orderItems", "detail": "Required field not populated", "message": "'orderItems' must not be empty." }
  ]
}
```

| Status | Scenario | Action |
|--------|----------|--------|
| 400 validation | Field issues (bad `solutionTemplateId`, `solutionQuantity` > 50, malformed `batchCloseTime`, missing shipping field) | Fix each `errors[].parameter` path; resubmit with a fresh idempotency key (the corrected body needs a new key) |
| 400 `idempotencyKeyMissing` | Missing header | Add `Idempotency-Key: <uuid-v4>` |
| 401 | Token expired/invalid | Re-authenticate for a fresh bearer token |
| 403 | Insufficient permissions | Check the API key's scope |
| 404 | Unknown `processingAccountId` / `terminalOrderId` | Verify the id; list the PA's orders to find it |
| 406 | Unsupported `Accept` | Request `application/json` |
| 409 `idempotentKeyInUse` | An order already exists under this idempotency key | Mint a fresh UUID for the new/corrected order |
| 500 | Server error | Retry with exponential backoff; surface `errors` if present |

(The published OpenAPI `ErrorsItems` schema lists only `message`; the live API also returns
`parameter` + `detail` + a top-level `instance` — consistent with the sibling boarding skills.)

---

## Complete annotated example — order one terminal for an existing processing account

`POST https://api.payroc.com/v1/processing-accounts/287019/terminal-orders`

```json
{
  "trainingProvider": "payroc",
  "shipping": {
    "preferences": { "method": "nextDay", "saturdayDelivery": true },
    "address": {
      "recipientName": "Maria Rossi",
      "businessName": "Thread & Needle - Lakeview",
      "addressLine1": "920 W Belmont Ave",
      "city": "Chicago",
      "state": "Illinois",
      "postalCode": "60657",
      "email": "lakeview@threadandneedle.com",
      "phone": "2025550164"
    }
  },
  "orderItems": [
    {
      "type": "solution",
      "solutionTemplateId": "Payroc A920Pro",   // for UAT, send "VAR_Only_TSYS" (the reliably-accepted template)
      "solutionQuantity": 1,
      "deviceCondition": "new",
      "solutionSetup": {
        "timezone": "America/Chicago",
        "industryTemplateId": "Retail",
        "applicationSettings": {
          "clerkPrompt": false,
          "security": { "refundPassword": true, "keyedSalePassword": false, "reversalPassword": true }
        },
        "deviceSettings": { "communicationType": "wifi" },
        "batchClosure": { "batchCloseType": "automatic", "batchCloseTime": "23:40" },
        "receiptNotifications": { "emailReceipt": true, "smsReceipt": false },
        "taxes": [ { "taxRate": 6, "taxLabel": "Sales Tax" } ],
        "tips": { "enabled": false },
        "tokenization": true
      }
    }
  ]
}
```

Headers: `Authorization: Bearer <token>`, `Idempotency-Key: <uuid-v4>`,
`Content-Type: application/json`. Omit the `shipping` block entirely to ship to the processing
account's DBA address.
