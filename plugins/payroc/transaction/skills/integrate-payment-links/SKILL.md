---
name: integrate-payment-links
description: >-
  Guide a developer through integrating Payroc Payment Links — creating
  shareable payment URLs, distributing them by email, and managing their
  lifecycle (retrieve, list, update, deactivate, view sharing history). Use
  this skill whenever someone asks about Payroc payment links, generating a
  payment URL to send to a customer, sending a payment request by email,
  building an invoice payment flow, setting up a donation link, creating a
  hosted payment link, sharing or re-sharing a link, updating or expiring a
  payment link, or deactivating a link — even if they don't explicitly say
  "payment links". Also trigger when a developer has a Payroc API key and
  wants to charge customers without embedding a payment form in their site.
metadata:
  version: "0.1.0"
  category: integration
  status: draft
---

# Payroc Payment Links Integration

On first invocation, announce to the developer:

> **Payroc Payment Links Integration**
> I'll guide you from setup through a working integration — creating links, optionally sharing them by email, and managing their lifecycle.
>
> **How Payment Links works:**
> 1. You call Payroc's API to create a payment link — you get back a URL
> 2. You (or Payroc's email service) share that URL with your customer
> 3. The customer clicks the link and pays on Payroc's hosted payment page
> 4. The link transitions to `completed` (single-use) or stays `active` (multi-use)
>
> **Payment Links vs Hosted Pages vs Hosted Fields:**
> - **Payment Links** — you generate a URL, share it any way you like (email, SMS, invoice). No checkout form needed on your site. This skill.
> - **Hosted Pages (HPP)** — customer checks out on your site, gets redirected to Payroc's payment page mid-flow, then returns. Different skill.
> - **Hosted Fields** — Payroc card-input widgets are embedded directly in your own checkout form. No redirect. Different skill.

*[If an MCP connection-check tool is available, run it here and surface the result before continuing.]*

---

## Quick reference

```text
POST  https://api.uat.payroc.com/v1/processing-terminals/{processingTerminalId}/payment-links
Authorization:   Bearer <token>
Idempotency-Key: <uuid-v4>
Content-Type:    application/json
```

---

## References

All enum values and schemas live in the local `references/` files below — this skill emits from them, not
from live lookups and not from memory. Payment Links is a pure REST/JSON API; there is no form-POST surface.

| Source | Local file | Use for |
|--------|-----------|---------|
| API schema reference | `references/api-schema.md` | **All** enum values, required fields, request/response schemas, charge shape, JSON Patch ops |
| Create & share guide | `references/create-and-share-a-payment-link.md` | Step-by-step narrative for creation + sharing |
| Extended features guide | `references/extend-your-integration.md` | Retrieve, list, update, deactivate, sharing events |

These are local snapshots, authoritative for this skill. Their source URLs and last-synced dates are
recorded in [`references/_sources.md`](references/_sources.md) — regenerate from there if they look stale.

---

## Core Principles

1. **Inspect before asking** — read the codebase before asking anything; use what you find to skip obvious questions and ask targeted ones.
2. **Ask before coding** — gather unknowns through intake before writing implementation code; wrong assumptions waste the developer's time.
3. **Read the schema reference before emitting any enum value.** Every field that accepts a fixed set of strings — `type`, `authType`, `paymentMethods[]` values, `status`, `sharingMethod`, JSON Patch `op` values — is documented in `references/api-schema.md`, the authoritative copy for this skill. Read it before you emit the value. Do not use training-data guesses. A plausible-sounding string that isn't in the documented enum will produce a 400 or silent mismatch. The same rule applies when **reviewing** developer-supplied code: consult `references/api-schema.md` before issuing a verdict on whether enum values or field names are correct — never validate from memory.
4. **Idempotency-Key on every POST and PATCH.** The header value must be a UUID v4. This is a required header, not optional — omitting it causes a 400. Generate a fresh UUID for each distinct operation (do not reuse the same key across different requests).
5. **Never hardcode credentials.** API keys and terminal IDs must come from environment variables or a secrets manager, never source code or configuration files checked into version control.
6. **Bearer token expiry.** Tokens from the identity service expire after 3,600 seconds (1 hour). For short scripts this is fine; for long-running services, implement token refresh logic.
7. **Validate before advancing** — don't move to the next step until the current step's checkpoint passes in UAT.
8. **Diagnose before proceeding** — if a step fails, pause and work through the error taxonomy before continuing.

---

## Intake

**First, scan the codebase.** Look for:
- Server-side language and framework
- Existing invoice, order, or billing-related code
- Any existing HTTP client setup or credential configuration
- How environment variables are managed

Use what you find to pre-fill obvious answers and ask targeted questions. Then present the following checklist — the developer's answers determine which sections you implement:

---

**What does your integration need? Ask the developer to select all that apply:**

- **[Always included]** Create payment links (required core)
- Share links by email via Payroc's API
- Retrieve a specific link's details
- List / search all links for a terminal
- Update a link (change expiry date, labels, or amount)
- Deactivate a link permanently
- View sharing history (list sharing events)
- Tokenize / save payment details for future charges (`credentialOnFile`)

Also confirm:
- **Link type:** single-use (one successful payment, then `completed`) or multi-use (unlimited payments)?
- **Transaction type:** sale (charge immediately) or pre-authorization (hold funds, capture later)?
- **Payment methods:** card, bank transfer, or both?
- **Amount:** fixed (you set it) or customer-entered (prompt)?

Use the answers to skip sections that don't apply. If the developer's use case is ambiguous (e.g. "I want to send invoices") ask one targeted clarifying question before proceeding.

---

## Prerequisites

Before writing any code, confirm the developer has all three:

1. **API key** — used to generate Bearer tokens from the Payroc identity service. Provisioned by the Payroc Integrations team along with UAT access.
2. **Processing terminal ID** — the `processingTerminalId` used in the create-link endpoint path. The developer should know this from their UAT setup.
3. **UAT environment** — Payroc's test environment. There is no self-serve signup; UAT terminals are provisioned manually by the Payroc Integrations team.

If anything is missing, stop and help the developer resolve it before continuing.

### Checkpoint

API key, terminal ID, and UAT access all confirmed? If not, stay here.

---

## Step 1 — Authenticate

Endpoints:
- UAT/test: `POST https://identity.uat.payroc.com/authorize`
- Production: `POST https://identity.payroc.com/authorize`

Header: `x-api-key: <api-key>`

The response contains `access_token`, `expires_in` (3600), and `token_type` ("Bearer"). All subsequent API requests use `Authorization: Bearer <access_token>`.

Implement a token-generation helper in the developer's language. For production code, include expiry tracking and refresh logic — tokens that expire mid-operation will produce 401s on otherwise valid requests.

Store the API key in an environment variable (e.g. `PAYROC_API_KEY`). Never inline it.

### Checkpoint

Can the helper generate a Bearer token without error? If not, check the `x-api-key` header and confirm the API key is correct for the UAT environment.

---

## Step 2 — Create a payment link

Endpoint: `POST https://api.uat.payroc.com/v1/processing-terminals/{processingTerminalId}/payment-links`

Required headers:
```
Authorization: Bearer <token>
Content-Type: application/json
Idempotency-Key: <UUID v4>
```

> **Read `references/api-schema.md` before writing the request body.** The values for `type`, `authType`, `paymentMethods` array elements, and the charge object structure are all defined there. Do not emit any of these from training data — the reference is the contract.

Key decisions to implement, based on intake answers:

> **Confirm the full required-field set from the reference.** Don't rely on a remembered list of mandatory fields — read the create-link request schema in `references/api-schema.md` and check which root-level fields are required (e.g. `merchantReference`) and which are conditional on link type. When reviewing developer code, missing-required-field findings must come from the schema reference, not memory; a field that "looks optional" may be required.

**Link type**
- `singleUse` — one successful payment allowed. Per the schema, single-use links require additional fields (such as `orderId` inside the `order` object and `expiresOn` in `YYYY-MM-DD` format) — confirm the exact conditional requirements in `references/api-schema.md`. After payment: link transitions to `completed`.
- `multiUse` — accepts unlimited payments. The single-use-only fields are not required.

**Transaction type (`authType`)**
- `sale` — funds captured immediately
- `preAuthorization` — funds held; you must call the capture endpoint later using the payment's ID

**Payment methods**
- Array containing `card`, `bankTransfer`, or both — read the valid values from `references/api-schema.md` before writing
- Bank transfer + multi-use + pre-authorization is a valid combination but appears less often in worked examples — always check the reference rather than relying on patterns from card-only flows

**Charge** — `charge` is a **single flat object discriminated by a `type` field**. `preset` and `prompt` are the *values* `type` takes, not keys you nest under. The amount/currency fields sit **beside** `type` as siblings:

```jsonc
// preset — you set the amount
"charge": { "type": "preset", "amount": 10000, "currency": "GBP" }

// prompt — customer enters the amount at payment time (no amount field)
"charge": { "type": "prompt", "currency": "GBP" }
```

> **Common mistake — the nested-`preset` trap.** Writing `"charge": { "preset": { "amount": …, "currency": … } }` (or a nested `prompt` key) is wrong and the API rejects it with a 400. There is no `preset`/`prompt` *key* — `preset`/`prompt` is the *value* of `type`, and `amount`/`currency` are siblings of `type`. When reviewing developer code, name this explicitly: the nested `preset`/`prompt` wrapper must be removed, not just "add a `type` field". This snippet shows the *shape* only — confirm the exact charge schema and any additional fields by reading `references/api-schema.md`.

Capture the `paymentLinkId` and `assets.paymentUrl` from the response — these are needed for all subsequent operations.

### Checkpoint

Does the API return HTTP 201 with a `paymentLinkId` and `assets.paymentUrl`? If not, work through the error taxonomy.

---

## Step 3 — Share by email

*(Include this section if the developer selected "Share links by email")*

Endpoint: `POST https://api.uat.payroc.com/v1/payment-links/{paymentLinkId}/sharing-events`

Required headers:
```
Authorization: Bearer <token>
Content-Type: application/json
Idempotency-Key: <UUID v4>      ← generate a new UUID; do not reuse Step 2's key
```

Request body:
```json
{
  "sharingMethod": "email",
  "recipients": [
    { "name": "Customer Name", "email": "customer@example.com" }
  ],
  "message": "Optional message to include with the payment link",
  "merchantCopy": false
}
```

> **Read `references/api-schema.md` before writing the `sharingMethod` value** — use the documented enum value, not a guess.

The response (HTTP 201) includes a `sharingEventId` for tracking. Store it if sharing history is relevant to the application.

### Checkpoint

Does the API return HTTP 201 with a `sharingEventId`? If not, verify the `paymentLinkId` is correct and the Idempotency-Key is a fresh UUID.

---

## Step 4 — Extended features

*(Implement only the sub-sections the developer selected during intake)*

### Retrieve a link

`GET https://api.uat.payroc.com/v1/payment-links/{paymentLinkId}`

Headers: `Authorization: Bearer <token>`

Returns the full link object including current `status`. Useful for checking whether a single-use link has been completed.

---

### List links for a terminal

`GET https://api.uat.payroc.com/v1/processing-terminals/{processingTerminalId}/payment-links`

Headers: `Authorization: Bearer <token>`

Supports query filters: `merchantReference`, `linkType` (`singleUse`/`multiUse`), `chargeType`, `status` (`active`/`completed`/`deactivated`/`expired`), `recipientName`, `recipientEmail`, `createdOn`, `expiresOn`.

Pagination: cursor-based via `limit`, `after`, `before` query parameters. The response `hasMore` field indicates whether additional pages exist.

> **Read `references/api-schema.md` for the exact `linkType` and `status` enum values** before writing filter logic.

---

### Update a link (partial update)

`PATCH https://api.uat.payroc.com/v1/payment-links/{paymentLinkId}`

Required headers: `Authorization: Bearer <token>`, `Idempotency-Key: <UUID v4>`

The request body is an **RFC 6902 JSON Patch array** — not a PUT body:
```json
[
  { "op": "replace", "path": "/expiresOn", "value": "2026-12-31" }
]
```

Supported `op` values: `add`, `remove`, `replace`, `move`, `copy`, `test`. See `references/api-schema.md` for the patch operation set and per-type constraints.

**Important:** Updating a single-use link regenerates the `paymentUrl` and `paymentButton`. If you've already distributed the old URL, you must re-share the new one.

---

### Deactivate a link

`POST https://api.uat.payroc.com/v1/payment-links/{paymentLinkId}/deactivate`

Required headers: `Authorization: Bearer <token>`

**Before writing deactivation code:** confirm with the developer that they understand this is **permanent and irreversible**. A deactivated link:
- Cannot be reactivated
- Returns a `deactivated` status in all subsequent retrieval calls
- Any customer who tries to use the URL will not be able to pay

If the intent is to temporarily pause payments, ask whether updating the `expiresOn` to a past date (via PATCH) achieves the goal instead — that link can later be reactivated by extending `expiresOn`. Only proceed to deactivation code after the developer explicitly confirms they want permanent deactivation.

---

### List sharing events

`GET https://api.uat.payroc.com/v1/payment-links/{paymentLinkId}/sharing-events`

Headers: `Authorization: Bearer <token>`

Filters: `recipientName`, `recipientEmail`. Pagination: `limit`, `before`, `after` (cursor-based; use one, not both).

Returns a paginated list of sharing events with timestamps, recipient details, and optional message text.

---

## Error taxonomy

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| 401 on any request | Token missing, expired, or API key wrong | Re-generate token; verify `x-api-key` header value is the correct UAT API key |
| 400 — validation error mentioning `type`, `authType`, or `paymentMethods` | Enum value not from the reference | Read `references/api-schema.md` and use the documented value |
| 400 — missing or malformed `Idempotency-Key` | Header absent or not a UUID v4 | Add `Idempotency-Key: <UUID v4>` to every POST and PATCH; generate a new UUID per operation |
| 400 — single-use link missing required field | A field the schema marks required is absent | Read the create-link schema in `references/api-schema.md`; add every required field (single-use typically needs `orderId` inside `order` and `expiresOn`) |
| 400 — charge object rejected / malformed | `charge` wrapped in a nested `preset`/`prompt` key (`charge.preset.amount`) | Flatten it: `charge` is one object with `type` (`preset`/`prompt`) and `amount`/`currency` as **siblings** of `type` — no nested wrapper |
| 409 — duplicate Idempotency-Key | Same key reused across different operations | Generate a fresh UUID for every distinct operation |
| PATCH regenerates `paymentUrl` unexpectedly | Updating a single-use link is by design | Re-share the new URL from the updated response |
| Link `status: expired`, customer can't pay | `expiresOn` has passed | PATCH to extend `expiresOn` if you still want the link active |
| Link `status: deactivated`, customer can't pay | Link was permanently deactivated | Create a new link — deactivated links cannot be reactivated |
| 404 on payment link endpoint | `paymentLinkId` wrong or link doesn't exist | Verify the ID from the creation response; check list endpoint to confirm link exists |
| Pre-auth: funds held but never captured | Capture step not implemented or not called | Implement capture using the payment's ID from the Payments API; pre-auths expire after the issuer's hold period |

---

## Validation checklist

- [ ] API key sourced from environment variable — never hardcoded
- [ ] Bearer token generated from identity service — never hardcoded
- [ ] `Idempotency-Key` header present and set to a UUID v4 on every POST and PATCH
- [ ] `type`, `authType`, `paymentMethods[]` values, and all other enum values read from `references/api-schema.md` — not from training data
- [ ] `paymentLinkId` captured from creation response and stored for subsequent operations
- [ ] Single-use links: every required field present in the creation request (confirmed against `references/api-schema.md`, not memory)
- [ ] `charge` is a flat object — `type` (`preset`/`prompt`) with `amount`/`currency` as siblings; no nested `preset`/`prompt` wrapper key
- [ ] Deactivation: developer explicitly confirmed the operation is permanent before code was written
- [ ] PATCH operations: RFC 6902 JSON Patch array format (not a PUT/POST body)
- [ ] UAT endpoints used (`api.uat.payroc.com`) — not production endpoints during testing

---

## Completion

Once all checklist items pass:

> **Integration complete.** Here's what you've built:
>
> - **Authentication** — Bearer token generation from the Payroc identity service; credentials in env vars.
> - **Create payment link** — [summarise: type, authType, paymentMethods, charge type]
> - **Share by email** (if built) — sends the payment URL to recipients via Payroc's API; stores `sharingEventId`.
> - **Extended features** (list what was built) — retrieve, list, update, deactivate, sharing events.
> - **Validated in UAT** — end-to-end flow confirmed.
>
> **Before going live:** swap `api.uat.payroc.com` for `api.payroc.com` and `identity.uat.payroc.com` for `identity.payroc.com`. Point credentials to the production terminal and API key.

Offer next steps:
- **Tokenization / recurring billing** — save payment details with `credentialOnFile` for future merchant-initiated charges
- **Webhook notifications** — receive server-side payment events rather than polling the Payments API
- **Hosted Fields** — embed Payroc card-input widgets directly in your own checkout form (no redirect)
