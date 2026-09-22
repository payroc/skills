---
name: order-a-terminal
description: >
  Guides developers through ordering a physical payment terminal (a card reader / PIN pad / POS
  device) for an EXISTING Payroc processing account via the Boarding API
  (POST /processing-accounts/{processingAccountId}/terminal-orders), and through reading the order
  back. Use this skill whenever the user wants to order a terminal or device, ship a card reader or
  PIN pad to a merchant, provision hardware for a MID, configure a terminal's gateway/device/app
  settings (batch closure, tips, taxes, receipts, tokenization) at order time, build the request
  body for POST .../terminal-orders, check the status of a terminal order, list a processing
  account's terminal orders (GET /processing-accounts/{id}/terminal-orders), retrieve one order
  (GET /terminal-orders/{id}), specify who pays for the terminal and how (paymentIntent — merchant
  or sales partner, hosted payment page / account on file / residual offset), retrieve a payment
  intent (GET /payment-intents/{id}), or read the provisioned processing terminal and its
  host-processor configuration — even if they don't say "skill", "terminal order", or "boarding
  API" explicitly.
  This is distinct from add-processing-account (creating the MID itself) — reach for this skill once
  the processing account exists and you have its processingAccountId and want to send it hardware.
metadata:
  version: "0.2.0"
  category: boarding
  status: draft
---

# Order a Terminal

## Version check (run this first)

Before announcing anything or starting the flow, confirm this skill is current:

1. Read this skill's version from the `metadata.version` field in the frontmatter above.
2. Fetch the published copy and read its `metadata.version`:
   `https://raw.githubusercontent.com/payroc/skills/main/plugins/payroc/boarding/skills/order-a-terminal/SKILL.md`
3. Compare the two as semantic versions:
   - **This version >= published** → continue silently, no message. (A developer running an unreleased newer version is expected and fine.)
   - **This version < published** → tell the developer:
     > ⚠️ A newer version of this skill (v\<published\>) has been published — you're running v\<current\>. Upgrading is recommended for the best results.

     Then ask whether they'd like to continue with the current version or stop and upgrade first, and honour their answer.
   - **Couldn't fetch** (offline, network error, 404) → note briefly that the version couldn't be verified and continue.

---

## What this skill covers

Once a merchant has a processing account (a MID), you order the hardware they'll take payments on —
a terminal/card reader — and configure how it behaves. This skill creates that order against an
**existing** processing account, reads it back, and (optionally, with a caveat) reads the terminal
once it's provisioned.

```
POST  /v1/processing-accounts/{processingAccountId}/terminal-orders   → place an order
GET   /v1/processing-accounts/{processingAccountId}/terminal-orders   → list a PA's orders (status/date filters)
GET   /v1/terminal-orders/{terminalOrderId}                           → retrieve one order
GET   /v1/processing-accounts/{processingAccountId}/processing-terminals   → list provisioned terminals  *(see caveat)*
GET   /v1/processing-terminals/{processingTerminalId}                      → retrieve one terminal       *(see caveat)*
GET   /v1/processing-terminals/{processingTerminalId}/host-configurations  → host-processor config       *(see caveat)*
```

**Related skills** — mention these when relevant:
- **add-processing-account** — adds the processing account (MID) you order a terminal *for*. Use it
  first if you don't yet have a `processingAccountId`.
- **create-merchant-platform** — board a brand-new merchant if nothing exists yet.

For every field, enum, and nested object, read `references/api-schema.md`. Emit values from that
file, not from memory — the `orderItems` array and its `solutionSetup` are deep and the device/enum
values are easy to misremember.

---

## Quick reference

```
POST  https://api.payroc.com/v1/processing-accounts/{processingAccountId}/terminal-orders
Authorization:   Bearer <token>
Idempotency-Key: <uuid-v4>
Content-Type:    application/json
```

Test/UAT base URL: `https://api.uat.payroc.com`. Identity: `https://identity.uat.payroc.com`
(test) / `https://identity.payroc.com` (production).

---

## How to work (core principles)

- **Read before you emit.** Only two fields are strictly required (`orderItems` with each item's
  `type` + `solutionTemplateId`), but the optional `solutionSetup` is large and enum-heavy. Open
  `references/api-schema.md` and copy the device template, timezone, and `communicationType` values
  from there rather than reconstructing them.
- **Gather before you build.** Confirm the `processingAccountId`, which device(s) and how many, and
  where it ships before assembling the body — so you don't produce a half-specified order.
- **Request and response differ.** What you send (`createTerminalOrder`) comes back as a
  `terminalOrder` with a `status`, `createdDate`/`lastModifiedDate`, and per-item `links`. Read them
  as two shapes.
- **Default to the simplest valid order.** A complete order can be as small as one `orderItems`
  entry with a `type` and `solutionTemplateId`. Don't invent `solutionSetup` the merchant didn't
  ask for; add configuration only when they specify it.

---

## Intake — gather these before building

1. **`processingAccountId`** of the existing account the terminal is for. If the developer doesn't
   have it, point them to **add-processing-account** (to create it) or List Processing Accounts (to
   find it).
2. **Device(s)** — which `solutionTemplateId` and `solutionQuantity` (1–50 per item; up to 20 items),
   and `deviceCondition` (`new`/`refurbished`) if it matters.
3. **Shipping** — ship to the processing account's DBA address (the default — omit `shipping`), or a
   specific address? Note the method (`nextDay`/`ground`) and Saturday delivery if relevant.
4. **Training** — `trainingProvider` `partner` (default) or `payroc`.
5. **Terminal configuration (optional)** — only if the merchant specified it: timezone, industry
   template, batch closure, tips, taxes, receipt notifications, tokenization, gateway/device settings.
6. **Who pays for the terminal (optional)** — omit `paymentIntent` unless the developer asks about
   billing for the order. If they do: is it the merchant or the sales partner, and how (hosted
   payment page / account on file / residual offset)? See
   `references/api-schema.md#paymentintent-object-optional`.

---

## Prerequisites

- A bearer token (see Step 1).
- An existing `processingAccountId`.
- The environment-specific base URLs (test vs production).

---

## Step 1 — Get a bearer token

> Read `references/identity-call.md` before emitting any auth code. Do not guess the endpoint URL, header name, or response shape — use only what the reference documents.

Tokens expire in ~1 hour. Exchange your API key before each session (or refresh proactively).

```bash
# Test / sandbox
curl -X POST https://identity.uat.payroc.com/authorize -H "x-api-key: YOUR_API_KEY"

# Production
curl -X POST https://identity.payroc.com/authorize -H "x-api-key: YOUR_API_KEY"
```

Response contains `access_token`; use `Authorization: Bearer <access_token>` on every request.
The Payroc SDKs (TypeScript, Python, C#, PHP, Go, Java, Ruby) handle token exchange automatically —
see https://docs.payroc.com/api/payroc-sd-ks-beta.

**Checkpoint:** you have a token and the target `processingAccountId`.

---

## Step 2 — Build the terminal-order body

The body is a `createTerminalOrder` object: a required `orderItems` array (1–20 items) plus optional
`trainingProvider` and `shipping`. Each order item needs only `type: "solution"` and a
`solutionTemplateId`; the rest is optional configuration.

Read `references/api-schema.md` for the full field list, enums, and the annotated example. The
points worth stating up front, because they're the common mistakes:

- **`orderItems` is required** — at least one item, each with `type: "solution"` and a valid
  `solutionTemplateId`. `solutionQuantity` defaults to 1 (max 50).
- **`solutionTemplateId` is an enum, not free text.** Send one of the documented templates (e.g.
  `Payroc A920Pro`, `Roc Services_DX8000`). **For test/UAT, send `VAR_Only_TSYS`** — it's the
  template reliably accepted there; the others are environment-gated.
- **Shipping defaults to the DBA address.** Omit `shipping` entirely to ship to the processing
  account's Doing Business As address. Only send `shipping.address` to ship elsewhere — and when you
  do, `recipientName`, `addressLine1`, `city`, `state`, `postalCode`, and `email` are all required.
- **`batchClosure` is discriminated** on `batchCloseType`: `automatic` needs a `batchCloseTime`
  (`HH:MM`); `manual` takes no time.
- **Don't over-build `solutionSetup`.** It's entirely optional. Include only what the merchant
  specified (timezone, tips, taxes, etc.); a bare `{ type, solutionTemplateId }` item is valid.

**Checkpoint:** show the developer the assembled payload and confirm the device, quantity, and
shipping are right before submitting.

---

## Step 3 — Send the request

Generate a fresh UUID v4 for `Idempotency-Key`. The key is bound to the request body, so reuse the
same key *only* to retry a byte-for-byte identical order — the API then returns the original result
instead of creating a duplicate. A `400` validation error creates nothing, but when you fix the
payload the body has changed, so resubmit with a **fresh** UUID; reusing the old key with the
corrected body returns `409 idempotentKeyInUse`. Generate a new UUID for a genuinely separate order
too. If a resubmit does come back `409 idempotentKeyInUse`, the platform already has an order on file
under that key — mint a fresh UUID for the corrected attempt rather than forcing the old one.

```bash
curl -X POST https://api.payroc.com/v1/processing-accounts/287019/terminal-orders \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Idempotency-Key: $(uuidgen | tr '[:upper:]' '[:lower:]')" \
  -H "Content-Type: application/json" \
  -d @terminal-order.json
```

---

## Step 4 — Handle the response

**201 Created** — the order was accepted:

```json
{
  "terminalOrderId": "12345",
  "status": "open",
  "orderItems": [ { "type": "solution", "solutionTemplateId": "Payroc A920Pro", "links": [ ... ] } ],
  "createdDate": "2024-07-02T12:00:00.000Z",
  "lastModifiedDate": "2024-07-02T12:00:00.000Z"
}
```

Persist `terminalOrderId` — you need it to retrieve the order. Orders start `"open"` and move
through `held`/`dispatched`/`fulfilled`/`cancelled`; subscribe to `terminalOrder.status.changed` (or
poll the retrieve endpoint) to track fulfilment rather than relying on the create-response value.

**Checkpoint:** the `terminalOrderId` is saved.

---

## Step 5 — Read the order back

- **Retrieve one:** `GET /v1/terminal-orders/{terminalOrderId}` → full `terminalOrder`.
- **List a PA's orders:** `GET /v1/processing-accounts/{processingAccountId}/terminal-orders`.
  Filter with `status` (`open`/`held`/`dispatched`/`fulfilled`/`cancelled`), `fromDateTime`, and
  `toDateTime` (ISO-8601). This returns a **plain JSON array** of orders — there are no
  `limit`/`after`/`before` cursors on this endpoint.

```bash
curl "https://api.payroc.com/v1/processing-accounts/287019/terminal-orders?status=open" \
  -H "Authorization: Bearer $ACCESS_TOKEN"
```

---

## Step 6 — Read the provisioned terminal (optional)

Once an order is fulfilled, each `orderItems[].links` entry carries the `processingTerminalId` of the
terminal it provisioned. You can read that terminal and its host-processor configuration:

```
GET /v1/processing-accounts/{processingAccountId}/processing-terminals   → list provisioned terminals (paginated)
GET /v1/processing-terminals/{processingTerminalId}                      → one terminal's config
GET /v1/processing-terminals/{processingTerminalId}/host-configurations  → host-processor (e.g. TSYS) config
```

> ⚠️ **Warn the developer before generating this, and let them choose.** These reads are
> **unverified, and the retrieve currently has a known defect**: a UAT order doesn't return a
> `processingTerminalId` (the test environment uses a non-physical device), so there's nothing to
> chase there — and even when a known `processingTerminalId` is supplied, retrieving the processing
> terminal can fail because the terminal's batch-close configuration is incomplete (the terminal-side
> schema requires a `batchCloseTime` the gateway doesn't always return). The host-processor
> configuration likewise isn't available in the test environment. So the endpoints and shapes are real
> and documented (see `references/api-schema.md`), but treat this as a production path that still needs
> verifying before you rely on it — not a tested happy path. Ask whether to include these calls or
> skip them; don't emit them silently.

---

## Errors

Errors use the **RFC 7807 problem-details format as the envelope** (`type`, `title`, `status`,
`detail`, `instance`), **extended** with a Payroc `errors[]` array (the array is Payroc's own, not
defined by RFC 7807). Each `errors[]` item carries `parameter` (the JSON path of the failing field —
the most useful one), `detail` (a short reason, **distinct** from the top-level RFC `detail`), and
`message` (the human-readable explanation). Use `parameter` to map each issue back to your request
body, fix it, then resubmit with a **fresh** idempotency key (a `400` created nothing, but the
corrected body no longer matches the old key — reusing it returns `409`). See
`references/error-response-format.md` for the envelope shape and the canonical error `type`
catalog, and the error table in `references/api-schema.md`.

| Status | Scenario | Action |
|--------|----------|--------|
| 400 validation | Bad `solutionTemplateId`, `solutionQuantity` > 50, malformed `batchCloseTime`, missing shipping field | Fix each `errors[].parameter`; resubmit with a fresh idempotency key (the corrected body needs a new key) |
| 400 `idempotencyKeyMissing` | Missing header | Add `Idempotency-Key: <uuid-v4>` |
| 401 | Token expired/invalid | Re-authenticate for a fresh bearer token |
| 403 | Insufficient permissions | Check API key scope |
| 404 | Unknown `processingAccountId` / `terminalOrderId` | Verify the id via the list endpoints |
| 406 | Unsupported `Accept` | Request `application/json` |
| 409 `idempotentKeyInUse` | An order already exists under this idempotency key | Mint a fresh UUID for the new/corrected order (see Step 3) |
| 500 | Server error | Retry with exponential backoff |

---

## Common pitfalls

- **Treating `solutionTemplateId` as free text** — it's an enum of specific device templates. Sending
  a made-up name (or `VAR_Only_TSYS` in production) gets rejected.
- **Sending a partial `shipping.address`** — if you include an address at all, `recipientName`,
  `addressLine1`, `city`, `state`, `postalCode`, and `email` are all required. Omit `shipping`
  entirely to default to the DBA address.
- **`automatic` batch closure without `batchCloseTime`** (or `manual` with one).
- **Over-building `solutionSetup`** — inventing config the merchant didn't ask for. A bare
  `{ type, solutionTemplateId }` item is valid.
- **Expecting cursor pagination on List Terminal Orders** — it returns a plain array filtered by
  `status`/`fromDateTime`/`toDateTime`, not a `paginated…` envelope.
- **Assuming a `processingTerminalId` comes back in test** — it doesn't in UAT; the terminal reads
  are a production-only follow-on.
- **Reusing an idempotency key for a different order** — generate a fresh UUID per distinct order.

---

## Validation checklist (before submitting)

- [ ] `processingAccountId` is correct and the account exists
- [ ] `orderItems` has at least one item, each with `type: "solution"` and a valid `solutionTemplateId`
- [ ] For test/UAT, `solutionTemplateId` is `VAR_Only_TSYS`
- [ ] `solutionQuantity` (if set) is 1–50; no more than 20 order items
- [ ] `shipping` is omitted (ships to DBA) **or** `shipping.address` has all required fields
- [ ] `batchClosure` matches its `batchCloseType` (`automatic` + `batchCloseTime`, or `manual`)
- [ ] Only the `solutionSetup` the merchant actually specified is included
- [ ] `Authorization` and `Idempotency-Key` headers set

---

## Full field reference

Read `references/api-schema.md` for all endpoints, enum values, nested object schemas
(`orderItem`, `solutionSetup`, `shipping`, `batchClosure`, `processingTerminal`, `hostConfiguration`),
the list filters, the error shape, and a complete annotated example request.
