---
name: integrate-payroc-cloud
description: >-
  Guides developers through running in-person, card-present sales and refunds through Payroc Cloud —
  the semi-integrated cloud-to-device API where a POS sends an instruction to the Payroc gateway and
  the gateway relays it to a physical payment device. Use this skill whenever the user mentions Payroc
  Cloud, "pay by cloud", semi-integrated card-present payments, sending a sale/refund/signature to a
  terminal or card reader via the API, payment-instructions / refund-instructions /
  signature-instructions, polling an instruction, or cloud device payments — even if they don't say
  "skill" explicitly. Covers the async submit -> poll -> follow-link -> retrieve flow, idempotency,
  cancelling an in-progress instruction, referenced vs unreferenced refunds, reversals, signature
  capture, closed-loop reads, and finding a device serialNumber via GET /devices. Do NOT use this
  skill for card-not-present / e-commerce flows, for Hosted Fields, Hosted Payment Pages, or Payment
  Links (browser-based — separate skills), or for physically configuring or pairing a payment device
  (that is hardware setup, out of scope). If the user wants to set up or pair a device, say that is
  out of scope and that this skill picks up once a device serial number exists.
metadata:
  version: "0.2.0"
  category: transaction
  status: draft
---

# Integrate Payroc Cloud

**Scope: card-present payments via Payroc Cloud — the *API bit* of the semi-integrated product.**
Submitting, polling, and retrieving the cloud *instructions* that drive a physical payment device:
sales, pre-auths, refunds (referenced + unreferenced), reversals, signature capture, and closed-loop
reads, plus read-only device lookup. **Physical device configuration/pairing is out of scope** — this
skill picks up once you have a device's `serialNumber`.

## Version check (run this first)

Before announcing anything or starting the flow, confirm this skill is current:

1. Read this skill's version from the `metadata.version` field in the frontmatter above.
2. Fetch the published copy and read its `metadata.version`:
   `https://raw.githubusercontent.com/payroc/skills/main/plugins/payroc/transaction/skills/integrate-payroc-cloud/SKILL.md`
3. Compare the two as semantic versions:
   - **This version >= published** → continue silently, no message. (A developer running an unreleased newer version is expected and fine.)
   - **This version < published** → tell the developer:
     > ⚠️ A newer version of this skill (v\<published\>) has been published — you're running v\<current\>. Upgrading is recommended for the best results.

     Then ask whether they'd like to continue with the current version or stop and upgrade first, and honour their answer.
   - **Couldn't fetch** (offline, network error, 404) → note briefly that the version couldn't be verified and continue.

---

## How Payroc Cloud works

In a semi-integrated model the POS **never talks to the payment device directly**. The POS sends an
*instruction* to the Payroc gateway over HTTPS; the gateway relays it to the device; the device runs
the card interaction (tap/insert/PIN/sign); the result flows back through the gateway, which the POS
retrieves.

```text
  POS / POS app  --HTTPS-->  Payroc gateway  -->  payment device (Payroc App)
       ^                          |                        |
       +-------- poll status <----+<--- result ------------+
```

Because everything routes through the gateway, your integration is **pure REST** — there is no device
SDK to embed and no card data on your servers. This skill covers that REST surface.

**What's in scope vs out:**

- **In scope (pure API):** build & submit instructions (payment / refund / signature); poll them;
  retrieve the resulting payment/refund/signature; cancel an in-progress instruction; read closed-loop
  payloads; referenced/unreferenced refunds and reversals; `GET /devices` to find a `serialNumber`.
- **Out of scope (hardware):** configuring or pairing the physical device (Android / Ingenico /
  ID TECH setup), the tap/insert/swipe/PIN/on-glass-signing interaction, binding a real serial number
  to a terminal. If the developer needs these, say so plainly — they're device setup, not API work.

This skill treats the **device + `serialNumber` as a given input**. If the developer doesn't have one,
`GET /devices` finds one (read-only, no hardware), and the Payroc Cloud Simulator
(`cloud.uat.payroc.com`) issues a mock serial number per browser tab for testing without hardware.

---

## References — read these, don't emit from memory

This skill emits from the local `references/` files below — not from live lookups and not from memory.
There are **two complementary kinds of source**, each owning a different kind of question; using the
wrong one is a known failure mode:

- **`references/api-schema.md` — what crosses the wire.** Field names, types, required flags, enum
  values, request/response shapes, the endpoint inventory, and the error envelope. Whenever you need
  *what a field is called* or *what values it accepts*, read it. **Emit every enum and field name from
  here, not from memory** — a plausible-sounding value (e.g. a status of `"approved"`, an
  `entryMethod` of `"chip"`) that isn't in the enum is the most common way this goes wrong.
- **`references/narrative-run-a-sale.md` and `references/narrative-extend.md` — how to sequence.**
  Which call comes first, how the poll-then-follow-link flow composes, how the follow-on flows
  (signature, referenced/unreferenced refund, reverse) build on the core pattern.

Source URLs and last-synced dates are in [`references/_sources.md`](references/_sources.md).

> **Honest limitation.** These references were curated from Payroc's published docs **without a
> Cloud-enabled account or hardware to validate against**. The contract (paths, fields, enums, the
> instruction lifecycle) comes straight from the docs and is reliable; the **error response shape for
> Cloud is assumed** to match the cross-skill standard and is *not* confirmed for Cloud. Flag this if a
> developer is building hard error-handling logic.

---

## Core principles

1. **Inspect before asking.** Read the developer's codebase first — language, HTTP client, how config
   and secrets are handled, any existing Payroc or POS integration — and frame questions in their
   terms instead of asking what you can infer.
2. **Read-then-emit, per value.** Before emitting any enum or field name (`currency`, `entryMethod`,
   instruction `status`, `mitAgreement`, `tip.type`, refund `responseCode`, `type` on a payment
   search, …), read it from `references/api-schema.md`. The skill's inline examples exist so you
   recognise the shape — they are not a substitute for reading the reference as you build each body.
3. **One pattern, learned once.** Sales, refunds, and signatures are all the same async instruction:
   **submit (202) → poll → follow the link → retrieve**. Internalise it once and the rest is variation.
4. **The instruction id is not the resource id.** Polling returns a `paymentInstructionId`; the
   completed instruction's `link.href` points at a *different* id — the `paymentId`. Follow the link;
   never synthesise the resource URL from the instruction id.
5. **202 ≠ approved.** A `202` means the gateway accepted the instruction and is relaying it to the
   device. The sale's actual outcome (bank approval/decline) lives on the **retrieved payment**, not
   on the instruction.
6. **Never hardcode credentials.** The API key and any terminal/serial values come from environment
   variables or a secrets manager — never source code.

---

## Quick reference

```text
Base URL (test):  https://api.uat.payroc.com/v1          Identity (test): https://identity.uat.payroc.com/authorize
Base URL (prod):  https://api.payroc.com/v1              Identity (prod): https://identity.payroc.com/authorize

# Instruction submit (runs on the device) — Idempotency-Key required
POST   /devices/{serialNumber}/payment-instructions      -> 202
POST   /devices/{serialNumber}/refund-instructions       -> 202   (unreferenced refund)
POST   /devices/{serialNumber}/signature-instructions    -> 202

# Poll an instruction (gateway long-holds ~60s) / cancel it
GET    /payment-instructions/{id}                         -> 200
DELETE /payment-instructions/{id}                         -> 204   (only while inProgress, else 409)
#   ...same GET/DELETE shape for refund-instructions and signature-instructions

# Retrieve the resulting resource (follow link.href from the completed instruction)
GET    /payments/{paymentId}        GET /refunds/{refundId}        GET /signatures/{signatureId}
GET    /closed-loop-reads/{closedLoopReadId}

# Referenced refund & reversal (standard payments API, NOT device instructions) — Idempotency-Key required
POST   /payments/{paymentId}/refunds                      -> 201
POST   /payments/{paymentId}/reverse                      -> 200
GET    /payments        GET /payments/{paymentId}         # find / retrieve a payment
GET    /devices                                           # find a serialNumber

Headers: Authorization: Bearer <token>   Content-Type: application/json   Idempotency-Key: <uuid-v4>
```

---

## Step 1 — Get a bearer token

Tokens expire in ~1 hour (`expires_in: 3600`). Exchange the API key before each session, refreshing
proactively before expiry.

```bash
# Test / sandbox (production: identity.payroc.com)
curl -X POST https://identity.uat.payroc.com/authorize \
  -H "x-api-key: $PAYROC_API_KEY"
```

Response carries `access_token`, `expires_in`, `token_type: "Bearer"`. Send
`Authorization: Bearer <access_token>` on every subsequent request. The Payroc SDKs handle token
exchange automatically — see https://docs.payroc.com/api/payroc-sd-ks-beta.

---

## Step 2 — The instruction pattern (submit → poll → follow link → retrieve)

Read `references/narrative-run-a-sale.md`. This is the heart of Payroc Cloud; every operation uses it.

1. **Submit** the instruction to the device with a fresh `Idempotency-Key`. You get **`202 Accepted`**
   with `{ status: "inProgress", <x>InstructionId, link }`. Persist the instruction id.
2. **Poll** `GET /<x>-instructions/{id}`. **The gateway holds the response for up to ~60 seconds**
   waiting for the status to change — so don't write a tight loop or your own sleep. Issue the GET,
   wait for it to return, and only re-issue if it's still `inProgress`. The statuses are `inProgress`,
   `completed`, `failure`, `canceled` — read them from `references/api-schema.md`, not memory.
3. On **`completed`**, the response's `link.href` points at the **real resource**. Follow it:
   `GET /payments/{paymentId}` (or `/refunds/{id}`, `/signatures/{id}`). Don't build this URL from the
   instruction id — they are different ids. The retrieved payment carries the bank outcome in
   `transactionResult` — branch on `transactionResult.status` reading the **full** approval set from
   `references/api-schema.md` (e.g. `ready` = authorized + queued for capture is an approval), not on a
   single remembered value like `complete`.
4. On **`failure`**, read `errorMessage`. On **`canceled`**, the instruction was cancelled first.

**Cancelling.** `DELETE /<x>-instructions/{id}` returns `204` — but only while the instruction is
`inProgress`. Once it has completed/failed/cancelled, the DELETE returns `409 Conflict`. If unsure of
the current state, GET the instruction and read `status` before cancelling.

### Checkpoint

Submit returns `202` with an instruction id and a `self` link; polling eventually yields `completed`
(or `failure` with an `errorMessage`); following the completed link retrieves the resource.

---

## Step 3 — Build a sale instruction

Read `references/api-schema.md` (the `paymentInstructionRequest` section) as you build the body.
Required: `processingTerminalId` and `order` (`orderId`, `amount`, `currency`).

```json
POST /v1/devices/{serialNumber}/payment-instructions
{
  "processingTerminalId": "1234001",
  "order": {
    "orderId": "OrderRef6543",
    "amount": 4999,
    "currency": "USD",
    "breakdown": {
      "subtotal": 4500,
      "tip": { "type": "fixedAmount", "mode": "prompted", "amount": 499 },
      "taxes": [ { "rate": 0.08, "name": "Sales Tax" } ]
    }
  },
  "customizationOptions": { "entryMethod": "deviceRead" },
  "autoCapture": true
}
```

Key choices (read the enum/field details from the reference):

- **`amount` is integer cents** in the order's `currency` (ISO 4217). `4999` = $49.99. Never send a
  decimal.
- **Sale vs pre-auth vs settle:** `autoCapture: true` (default) = sale; `autoCapture: false` =
  pre-authorization (capture later); `processAsSale: true` settles immediately and ignores
  `autoCapture`. Pick deliberately.
- **`entryMethod`** defaults to `deviceRead`; the other values are in the reference — don't invent one.
- **Tokenize on the sale** with `credentialOnFile.tokenize: true` (and `mitAgreement` for
  merchant-initiated follow-ons).

---

## Step 4 — Extend (signatures, refunds, reversals)

Read `references/narrative-extend.md` for sequencing, `references/api-schema.md` for shapes.

- **Capture a signature** — standalone, not tied to a payment. Submit `{ "processingTerminalId": "…" }`
  to `/signature-instructions`, poll, then follow the `signature` link to `GET /signatures/{id}` and
  decode the Base64 `signature` (its `contentType`, e.g. `image/png`).
- **Unreferenced refund** — a device instruction: `POST /devices/{serialNumber}/refund-instructions`.
  Note `order.description` is **required** on a refund order. Poll → follow link → `GET /refunds/{id}`.
- **Referenced refund** — **not** a device instruction; it uses the standard payments API and needs the
  original `paymentId`. Get it via `GET /payments/{paymentId}` or search `GET /payments` (`last4`,
  `cardholderName`, `orderId`, `dateFrom`/`dateTo`, …), then `POST /payments/{paymentId}/refunds` with
  `{ amount, currency }`.
- **Reverse a payment** — also the payments API, for a payment still in an **open batch**:
  `POST /payments/{paymentId}/reverse` (omit `amount` for full, supply it for partial). No funds move.
- **Reverse vs refund:** open batch, funds not yet taken → **reverse**; already settled → **refund**.
  Beware: a referenced refund against an *open-batch* payment **auto-reverses** it instead of creating
  a refund — so be deliberate about which you intend.
- **Closed-loop reads** — if you've issued a closed-loop instruction (e.g. a MiFare card read),
  retrieve the payload with `GET /closed-loop-reads/{id}`. Its `data` object is **unstructured** (shape
  varies by card); don't assume a fixed schema. See `references/api-schema.md`.

---

## Idempotency

Every instruction `POST` (and every refund/reverse `POST`) takes an `Idempotency-Key` header — a fresh
UUID v4 per **new** submission. To retry a submission that may not have landed (network blip, timeout),
resend the **byte-for-byte identical** body with the **same** key: the gateway returns the original
result instead of submitting a second instruction to the device. Changing the body while reusing the
key is a `409`. Polls (`GET`) and cancels (`DELETE`) don't take an idempotency key.

---

## Handle errors

Errors use the [RFC 7807](https://datatracker.ietf.org/doc/html/rfc7807) problem-details envelope
(standard members `type`, `title`, `status`, `detail`, `instance`) plus a Payroc **`errors[]`
extension** — the array is Payroc's own, not RFC-defined. Each item carries `parameter` (the JSON path
of the failing field — the fastest way to find what to fix), `detail` (a short reason, *distinct* from
the top-level `detail`), and `message`. See
[`_shared/error-response-format.md`](../../../_shared/error-response-format.md) for the cross-skill
standard and `references/api-schema.md` for the per-status table.

> **Cloud error shape is not yet verified.** We applied the standard Payroc envelope (confirmed on
> boarding endpoints) on the assumption Cloud is consistent, but could not confirm against a live
> Cloud account. Read `errorMessage` on a `failure` instruction and `errors[]` on a 4xx, but don't
> hard-code assumptions about Cloud-specific error text.

| Status | Scenario | Action |
|--------|----------|--------|
| 400 | Validation error on submit | Map each `errors[].parameter` to the field; fix and resubmit (reuse the same idempotency key for an identical retry). |
| 401 | Token expired/invalid | Re-authenticate for a fresh bearer token. |
| 403 | Insufficient permissions | Check the API key's scope. |
| 404 | Instruction or resource not found | Verify the id — and check you didn't confuse the instruction id with the resource id. |
| 409 | Conflict — cancelling an instruction no longer `inProgress`, or reusing an idempotency key with a changed body | GET the instruction's current `status` first; don't blindly retry. |
| 500 | Server error | Retry with backoff; surface `errors` if present. |

Plus the instruction-level outcomes: poll `status: "failure"` → read `errorMessage`; `status:
"canceled"` → cancelled before completing.

---

## Common pitfalls

- **Synthesising the resource URL from the instruction id.** The completed instruction gives you a
  `link.href` to a *different* id. Follow the link; don't build `/payments/{paymentInstructionId}`.
- **Treating `202` (or `200` on a poll) as success.** `202` = accepted for relay; a poll can return
  `200` with `status: "failure"`. The sale outcome is on the **retrieved payment**.
- **Tight polling loops / manual sleeps.** The gateway already long-holds the poll ~60s. Just await the
  GET and re-issue only if still `inProgress`.
- **Cancelling too late.** `DELETE` only works while `inProgress`; otherwise it's a `409`. Check
  `status` first.
- **Decimal amounts.** `amount` is integer **cents**, always.
- **Inventing enum values.** `entryMethod`, instruction `status`, `currency`, `mitAgreement`,
  `tip.type`, refund `responseCode`, payment-search `status`/`type` are all enums — read them from
  `references/api-schema.md`.
- **Forgetting `order.description` on a refund instruction** — it's required there (unlike on a
  payment).
- **Refund vs reverse on an open batch.** A referenced refund on an open-batch payment auto-reverses
  it. Use `POST /payments/{paymentId}/reverse` when you mean to cancel an unsettled payment.
- **Reusing or omitting the idempotency key.** Fresh UUID per new submit; same key only to retry an
  identical body; none on GET/DELETE.
- **Trying to "set up" the device.** Pairing/configuration is hardware, out of scope. The skill starts
  from a known `serialNumber` (find one with `GET /devices`).

---

## Full field reference

Read `references/api-schema.md` for: the endpoint inventory; the instruction object and its `status`
enum; `paymentInstructionRequest` / `refundInstructionRequest` / `signatureInstructionRequest`
schemas (with `order`, `breakdown`, `credentialOnFile`, `customizationOptions`); signature and
closed-loop retrieval; the referenced-refund and reverse endpoints; `GET /payments` and `GET /devices`
search; and the error envelope.
