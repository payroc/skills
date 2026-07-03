---
name: check-ebt-balance
description: >
  Guides developers through checking an EBT (Electronic Benefits Transfer) card balance via the
  Payroc API (POST /v1/cards/balance). Use this skill when the user wants to query an EBT card
  balance, implement an EBT balance inquiry, check SNAP balance or EBT Cash account funds, look up
  available benefits on a food stamp or EBT card, integrate EBT balance checking into a POS system,
  or work with the /v1/cards/balance endpoint. Also use when the user asks about foodStamp or EBT
  cash balances, benefit card balance lookup, or wants to check how much EBT credit is available on
  a card before a transaction — even if they don't use the phrase "balance check" or "EBT API"
  explicitly. Do NOT use for processing, charging, or refunding an EBT card; those operations
  require separate payment skills.
metadata:
  version: "0.1.3"
  category: transaction
  status: draft
---

# Check EBT Balance

## Version check (run this first)

Before announcing anything or starting the flow, confirm this skill is current:

1. Read this skill's version from the `metadata.version` field in the frontmatter above.
2. Fetch the published copy and read its `metadata.version`:
   `https://raw.githubusercontent.com/payroc/skills/main/plugins/payroc/transaction/skills/check-ebt-balance/SKILL.md`
3. Compare the two as semantic versions:
   - **This version >= published** → continue silently, no message. (A developer running an unreleased newer version is expected and fine.)
   - **This version < published** → tell the developer:
     > ⚠️ A newer version of this skill (v\<published\>) has been published — you're running v\<current\>. Upgrading is recommended for the best results.

     Then ask whether they'd like to continue with the current version or stop and upgrade first, and honour their answer.
   - **Couldn't fetch** (offline, network error, 404) → note briefly that the version couldn't be verified and continue.

---

## EBT terminal provisioning

> **This requires a terminal provisioned for EBT.** `POST /v1/cards/balance` returns `400 Bad Request` if the terminal isn't configured in an EBT sharing group — this is a terminal-provisioning requirement, not an API validation issue. If you have a Payroc terminal provisioned for EBT, these instructions work against UAT or production. The endpoint URL, request schema, response schema, required headers, and enum values documented here are all derived from the published Payroc OpenAPI spec and the endpoint reference at `https://docs.payroc.com/api/schema/payment-features/cards/view-ebt-balance.md`.
>
> **To unblock UAT testing:** Contact the Payroc Integrations team and request that your UAT terminal be added to an EBT sharing group.

---

## Quick reference

```text
POST  https://api.uat.payroc.com/v1/cards/balance
Authorization:   Bearer <token>
Idempotency-Key: <uuid-v4>
Content-Type:    application/json
```

---

## Scope of this skill

This skill covers **EBT balance inquiry only** — querying how much money is available on an EBT card. It does not process or debit the EBT account.

| What the developer wants | Endpoint | Skill |
| --- | --- | --- |
| Check available EBT balance (SNAP / cash) | `POST /v1/cards/balance` | **This skill** |
| Process an EBT purchase (debit the card) | `POST /v1/payments` | Process-payment skill |

**If the developer asks about processing an EBT payment** (i.e. actually charging the card at checkout), clarify that:
1. `POST /v1/cards/balance` is for balance inquiry only — it does not create a charge or debit the EBT account.
2. EBT payment processing uses `POST /v1/payments` — a separate API call. This is outside the scope of this skill.
3. Direct them to the Payroc API documentation at `https://docs.payroc.com` or to the standard payment processing skill for next steps.

---

## References

All enum values, field schemas, and response structures live in the local `references/` files — this skill emits from them, not from live lookups and not from memory.

| Source | Local file | Use for |
| --- | --- | --- |
| API schema reference | `references/api-schema.md` | **All** enum values, required/optional fields, request/response schemas, `cardBalance` shape, `responseCode` values |
| Identity call reference | `references/identity-call.md` | Bearer token exchange — endpoint URL, request header, response fields |
| Error response format | `references/error-response-format.md` | Error envelope (RFC 7807) + Payroc errors[] + canonical error type catalog |

These are local snapshots, authoritative for this skill. Their source URLs and last-synced dates are recorded in [`references/_sources.md`](references/_sources.md).

---

## Core principles

1. **Read the schema reference before emitting any enum value.** Every field that accepts a fixed set of strings — `card.type`, `cardDetails.entryMethod`, `ebtDetails.benefitCategory`, `responseCode` — is documented in `references/api-schema.md`. Read it before emitting any value. Do not use training-data guesses. In particular, `benefitCategory` has exactly two valid values: `"cash"` and `"foodStamp"`. Do not use `"snap"`, `"food"`, `"ebt"`, or any other variant.
2. **Idempotency-Key on every POST.** The header value must be a UUID v4 — omitting it causes a 400. Generate a fresh UUID for each distinct operation.
3. **Never hardcode credentials.** API keys and terminal IDs must come from environment variables or a secrets manager.
4. **Bearer token expiry.** Tokens expire after 3,600 seconds (1 hour). For long-running services, implement refresh logic.
5. **Diagnose before proceeding.** If a step fails, pause and work through the error taxonomy before continuing.
6. **EBT requires a sharing-group terminal.** The terminal used must be provisioned by Payroc into an EBT sharing group. A standard terminal will return 400. If the developer hits this, direct them to the Payroc Integrations team — it is a configuration requirement, not a code issue.

---

## Prerequisites

These are needed to run and test the integration — not to write the code. If the developer already has them, great. If not, wire the code to read from environment variables and keep building.

1. **API key** — used to generate Bearer tokens from the Payroc identity service. Provisioned by the Payroc Integrations team.
2. **EBT-enabled processing terminal ID** — the `processingTerminalId` sent in the request. Must be provisioned in an EBT sharing group by the Payroc Integrations team.
3. **UAT environment** — `api.uat.payroc.com`. EBT testing in UAT requires a terminal explicitly configured for EBT by Payroc.

**If anything is missing — warn, don't block.** Propose `PAYROC_API_KEY` and `PAYROC_TERMINAL_ID` as env var names if no convention exists. Tell the developer:

> ⚠️ I've wired this to read your API key from `PAYROC_API_KEY` and terminal ID from `PAYROC_TERMINAL_ID`. You'll need a Payroc EBT-enabled terminal to actually run this — contact the Payroc Integrations team to confirm your terminal is in an EBT sharing group. I can keep building in the meantime.

### Checkpoint

Either credentials are confirmed, or the developer knows what's outstanding and has chosen to proceed anyway.

---

## Step 1 — Authenticate

> Read `references/identity-call.md` before emitting any auth code. Do not guess the endpoint URL, header name, or response shape — use only what the reference documents.

Endpoints:
- UAT/test: `POST https://identity.uat.payroc.com/authorize`
- Production: `POST https://identity.payroc.com/authorize`

Header: `x-api-key: <api-key>`

The response contains `access_token`, `expires_in` (3600), and `token_type` ("Bearer"). All subsequent API requests use `Authorization: Bearer <access_token>`.

Implement a token-generation helper in the developer's language. For production code, include expiry tracking and refresh logic.

Store the API key in an environment variable (e.g. `PAYROC_API_KEY`). Never inline it.

### Checkpoint

Can the helper generate a Bearer token without error? If not, check the `x-api-key` header and confirm the API key is valid for the environment.

---

## Step 2 — Build the balance inquiry request

Endpoint: `POST https://api.uat.payroc.com/v1/cards/balance`

Required headers:
```
Authorization:   Bearer <token>
Content-Type:    application/json
Idempotency-Key: <UUID v4>
```

> **Read `references/api-schema.md` before writing the request body.** The values for `card.type`, `cardDetails.entryMethod`, and `ebtDetails.benefitCategory` are all enum-constrained and documented there. Do not emit any enum value from training data.

### Root-level request fields

| Field | Required | Notes |
| --- | --- | --- |
| `processingTerminalId` | **required** | Terminal ID (from env var) |
| `currency` | **required** | ISO 4217 code — e.g. `"USD"` |
| `card` | **required** | Polymorphic card object — see below |
| `operator` | optional | Operator identifier |
| `customer` | optional | Customer contact/address |

### `card` object — two variants

> **Confirm the exact `card.type` value from `references/api-schema.md` before writing.** The two valid values are `"card"` and `"singleUseToken"` — do not guess.

**Variant 1 — raw card details (`"card"`):**
```json
{
  "type": "card",
  "cardDetails": {
    "entryMethod": "icc",
    "device": { ... },
    "iccData": "9F1A0840..."
  },
  "ebtDetails": {
    "benefitCategory": "foodStamp"
  }
}
```

**Variant 2 — tokenized card (`"singleUseToken"`):**
```json
{
  "type": "singleUseToken",
  "token": "<gateway-token>",
  "ebtDetails": {
    "benefitCategory": "cash"
  }
}
```

### `ebtDetails.benefitCategory`

> **Read `references/api-schema.md` for the exact `benefitCategory` values before writing.** Only two values are valid:
> - `"cash"` — EBT Cash account (government cash assistance)
> - `"foodStamp"` — EBT SNAP account (Supplemental Nutrition Assistance Program)
>
> Do not use `"snap"`, `"food"`, `"stamp"`, `"ebtCash"`, `"ebtFoodStamp"`, or any other variant.

> **`ebtDetails` is optional in the API schema but required for an EBT balance inquiry.** Omitting it does not cause a 400 validation error, but the API will not know which EBT account to query and the response will not include meaningful EBT balance data. Always include `ebtDetails.benefitCategory` when performing EBT balance checks.

**Intake question:** Ask the developer which benefit type they need to check — cash or SNAP/food stamp — or whether they need to check both. A single request can query one benefit category; to check both, make two separate requests — each with its own distinct, freshly generated `Idempotency-Key` UUID.

### `cardDetails.entryMethod`

> **Read `references/api-schema.md` for the exact `entryMethod` values.** Valid values: `"icc"` (chip), `"swiped"` (magnetic stripe), `"keyed"` (manual), `"raw"` (unencrypted device).

Match the entry method to the POS hardware:
- Physical POS with chip reader → `"icc"` (EMV chip data via `iccData`)
- Swipe-only reader → `"swiped"` (track data)
- Manual/virtual → `"keyed"` (PAN + expiry in `MMYY` format — not `MM/YY`, `MMYYYY`, or `YYYY-MM`)
- Tokenized (prior Payroc session) → `"singleUseToken"` variant
- Unencrypted device reader → `"raw"` — sub-fields are device-specific; consult the device manufacturer's integration guide for the exact field names to pass alongside the `device` object

> **PIN for physical EBT terminals:** Real-world EBT transactions at a POS terminal typically require cardholder PIN entry — this is an EBT network rule, not an API schema constraint. Both card variants expose an optional `pinDetails` field in the schema. If you are integrating with physical POS hardware and the EBT network rejects requests without a PIN, capture the PIN via your terminal's PIN-entry device (PED) and include it in `pinDetails`. Consult the Payroc Integrations team and your terminal SDK documentation for the correct `pinDetails` structure for your device.

### Complete example request (chip card, food stamp balance)

```json
{
  "processingTerminalId": "TERM-001",
  "currency": "USD",
  "operator": "cashier1",
  "card": {
    "type": "card",
    "cardDetails": {
      "entryMethod": "icc",
      "device": {
        "model": "paxA920",
        "serialNumber": "12345678",
        "category": "attended"
      },
      "iccData": "9F1A0840..."
    },
    "ebtDetails": {
      "benefitCategory": "foodStamp"
    }
  }
}
```

### Checkpoint

Is the request body correct? Verify:
- `processingTerminalId` sourced from env var, not hardcoded
- `ebtDetails.benefitCategory` is exactly `"cash"` or `"foodStamp"` from the reference
- `cardDetails.entryMethod` matches the hardware in use
- `Idempotency-Key` is a freshly generated UUID v4

---

## Step 3 — Send the request

Always generate a fresh UUID v4 for `Idempotency-Key`.

```bash
curl -X POST https://api.uat.payroc.com/v1/cards/balance \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Idempotency-Key: $(uuidgen | tr '[:upper:]' '[:lower:]')" \
  -H "Content-Type: application/json" \
  -d @balance-request.json
```

---

## Step 4 — Handle the response

**HTTP 200** — successful balance inquiry:

```json
{
  "processingTerminalId": "TERM-001",
  "operator": "cashier1",
  "responseCode": "A",
  "responseMessage": "Approved",
  "card": {
    "type": "VISA",
    "entryMethod": "icc",
    "cardNumber": "412345******3456",
    "expiryDate": "1228",
    "balances": [
      {
        "benefitCategory": "foodStamp",
        "amount": 12500,
        "currency": "USD"
      }
    ]
  }
}
```

### Reading the response

> **Read `references/api-schema.md` for the `responseCode` enum values before writing response-handling logic.** Do not assume response codes from training data.

**`responseCode` handling:**

| Code | Meaning | Action |
| --- | --- | --- |
| `"A"` | Approved | Read `balances[]` for available funds |
| `"D"` | Declined | Card was declined — do not rely on `balances[]` |
| `"E"` | Pending | Retry or wait; processor is processing |
| `"P"` | Partial authorization | Partial — check `balances[]` |
| `"R"` | Declined — contact issuer | Advise cardholder to contact their issuer |
| `"C"` | Declined — retain card | Card is flagged lost/stolen |

> **`card.type` has different semantics in the request and response.** In the request body, `card.type` is the polymorphic discriminator (`"card"` or `"singleUseToken"`). In the response body, `card.type` is the card brand — for example `"VISA"`, `"MASTERCARD"`, `"AMEX"`. Do not assert `response.card.type === "card"` — that will always be false. Switch on the card brand strings when displaying network logos or brand names, not on the request discriminator values.

> **`entryMethod` path differs between request and response.** In the request, `entryMethod` is nested: `card.cardDetails.entryMethod`. In the response, it is flattened to `card.entryMethod`. Do not use the request path when reading response fields, and do not use the response path when building the request body.

> **`responseCode` may be absent.** The schema marks `responseCode` as optional. Always guard against a missing value before branching on it — for example, check `if (responseCode) { switch(responseCode) { ... } }` before processing the response code logic.

**`balances[]` array:** Each entry has `benefitCategory` (`"cash"` or `"foodStamp"`), `amount` (integer in lowest denomination — cents for USD), and `currency`. A single response may have one or two entries depending on the card.

> **`balances[]` may be absent even on a 200 response.** If a non-EBT card is used, or if the EBT network does not return balance data, the response may contain `responseCode: "A"` with no `balances` array (or an empty array). Always check that `balances` exists and is non-empty before reading `balances[0]`. If absent, confirm the correct EBT card is being used and check `responseCode`.

**Amount interpretation:** `"amount": 12500` with `"currency": "USD"` means $125.00. Amounts are in the currency's lowest denomination (cents for USD, pence for GBP, etc.).

**`cardNumber` masking:** The response returns a masked PAN — first 6 and last 4 digits, asterisks in between. Do not log or store the full PAN.

### Checkpoint

Is the response code `"A"` with a `balances[]` array containing EBT balance data? If not, work through the error taxonomy below.

---

## Step 5 — Handle errors

Errors follow [RFC 7807](https://datatracker.ietf.org/doc/html/rfc7807) and Payroc's `errors[]` extension. See `references/error-response-format.md` for the cross-skill standard.

| Status | Scenario | Action |
| --- | --- | --- |
| 400 validation | Field missing or invalid | Read `errors[].parameter` to identify the failing field; fix and resubmit. **Reuse the same `Idempotency-Key` only if the payload body is otherwise unchanged** (e.g. you only corrected a header). If you changed any body field (including `benefitCategory` or `entryMethod`) the payload is now different — generate a fresh UUID, or the next request will receive a 409. |
| 400 EBT sharing group | Terminal not configured for EBT | This is a configuration issue — contact Payroc Integrations to add the terminal to an EBT sharing group |
| 400 `idempotencyKeyMissing` | Missing `Idempotency-Key` header | Add `Idempotency-Key: <uuid-v4>` to the request |
| 401 | Token expired or invalid | Re-authenticate and get a fresh Bearer token |
| 403 | Insufficient permissions | Check API key scope; contact Payroc support |
| 404 | Terminal not found | Verify `processingTerminalId` is correct for the environment |
| 406 | Not acceptable content type | Ensure `Accept: application/json` is set (or omit the `Accept` header entirely to use the default) |
| 409 `idempotencyKeyInUse` | Key reused with a different payload | Generate a new UUID for the new request. **When making two requests to check both benefit categories, each request must use its own distinct UUID.** |
| 415 | Unsupported media type | Ensure `Content-Type: application/json` is set on the POST request |
| 500 | Server error | Retry with exponential backoff |

**Reading validation errors:**

The response envelope is RFC 7807 (`type`, `title`, `status`, `detail`, `instance`). Payroc extends it with an `errors` array (Payroc-specific, not defined by RFC 7807). Each `errors[]` item has:
- `parameter` — JSON path of the failing field (e.g. `"card.ebtDetails.benefitCategory"`)
- `detail` — short reason (e.g. `"Invalid value"`)
- `message` — human-readable explanation

Use `errors[].parameter` to map each error back to the request body field and fix it.

---

## Error taxonomy

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| 401 on any request | Token missing, expired, or API key wrong | Re-generate token; verify `x-api-key` header value is the correct API key |
| 400 — validation error mentioning `benefitCategory` | Enum value not from the reference | Read `references/api-schema.md` and use `"cash"` or `"foodStamp"` exactly |
| 400 — validation error mentioning `entryMethod` | Invalid entry method value | Read `references/api-schema.md` — valid values are `"icc"`, `"swiped"`, `"keyed"`, `"raw"` |
| 400 — missing or malformed `Idempotency-Key` | Header absent or not a UUID v4 | Add `Idempotency-Key: <UUID v4>` to the POST |
| 400 — EBT sharing group / terminal config | Terminal not in EBT sharing group | Contact Payroc Integrations team to configure the terminal for EBT |
| 404 — terminal not found | `processingTerminalId` wrong or typo | Verify the terminal ID from Payroc's provisioning documentation |
| `responseCode: "D"` | Card declined by network | Advise customer to contact their EBT issuer; do not retry blindly |
| `responseCode: "C"` | Card flagged lost/stolen | Follow your organization's lost/stolen card handling procedure |
| `balances[]` absent in response | Non-EBT card used, or network returned no balance | Confirm EBT card is being used; check `responseCode` |
| Amount looks wrong | Amounts are in lowest denomination | Divide by 100 for USD: `12500` = $125.00 |

---

## Common pitfalls

- **Wrong `benefitCategory` value:** The only valid values are `"cash"` and `"foodStamp"`. Using `"snap"`, `"food"`, `"stamp"`, or other variants will produce a 400.
- **Terminal not EBT-enabled:** A standard Payroc terminal will not work for EBT balance checks — the terminal must be in an EBT sharing group. This is the most likely cause of unexpected 400 errors in UAT.
- **Missing `Idempotency-Key`:** All POST requests require this header as a UUID v4.
- **Two accounts, two requests:** A single request queries one `benefitCategory`. To check both cash and food stamp balances, make two separate requests — **each with its own distinct UUID `Idempotency-Key`.** Do not reuse the same key for the second request; the payloads differ (different `benefitCategory`) and you will receive a 409.
- **UUID casing for `Idempotency-Key`:** Generate the UUID in lowercase. Some language UUID libraries (e.g. `Guid.NewGuid().ToString()` in C#, `UUID.randomUUID()` in Java) return uppercase by default — call `.toLowerCase()` / `.ToLower()` before sending.
- **Amount in lowest denomination:** `amount` in the response is in cents (for USD) — divide by 100 to display to the customer.
- **Masked PAN only:** The response returns a masked `cardNumber` — never log or store the full PAN.
- **Hardcoded terminal ID:** `processingTerminalId` must come from an environment variable, not be hardcoded.

---

## Full field reference

Read `references/api-schema.md` for:
- All enum values (`card.type`, `cardDetails.entryMethod`, `ebtDetails.benefitCategory`, `responseCode`)
- Complete request and response schema with all optional fields
- `cardDetails` variant schemas per `entryMethod`
- `cardBalance` object shape and `balances[]` array structure
- Error response schema
