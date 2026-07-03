---
name: save-a-payment-method
description: >
  Guides developers through saving and tokenizing customer payment details via the Payroc Secure
  Tokens API (POST /v1/processing-terminals/{processingTerminalId}/secure-tokens). Use this skill
  when the user wants to: save a card or bank account for future use without charging it now;
  tokenize card details into a reusable vault token; store a payment method; implement card-on-file
  or bank-account-on-file storage; vault a card or ACH/PAD bank account for later use;
  create a reusable secure-token (secureTokenId) via the /secure-tokens endpoint; save payment
  details to enable future merchant-initiated charges (recurring, installment, or unscheduled);
  manage stored tokens (retrieve, list, delete, or update account details); or replace a customer's
  saved card with a new one. Do NOT use this skill when the user wants to create a single-use token
  for a one-time transaction (use create-single-use-token), set up or configure recurring billing
  schedules or payment plans (use set-up-a-payment-plan or manage-subscriptions), charge a customer
  using a saved token (use run-a-card-sale), or take a bank transfer/ACH payment right now (use
  take-an-ach-payment).
metadata:
  version: "0.1.0"
  category: transaction
  status: draft
---

# Save a Payment Method

## Version check (run this first)

Before announcing anything or starting the flow, confirm this skill is current:

1. Read this skill's version from the `metadata.version` field in the frontmatter above.
2. Fetch the published copy and read its `metadata.version`:
   `https://raw.githubusercontent.com/payroc/skills/main/plugins/payroc/transaction/skills/save-a-payment-method/SKILL.md`
3. Compare the two as semantic versions:
   - **This version >= published** → continue silently, no message. (A developer running an unreleased newer version is expected and fine.)
   - **This version < published** → tell the developer:
     > ⚠️ A newer version of this skill (v\<published\>) has been published — you're running v\<current\>. Upgrading is recommended for the best results.

     Then ask whether they'd like to continue with the current version or stop and upgrade first, and honour their answer.
   - **Couldn't fetch** (offline, network error, 404) → note briefly that the version couldn't be verified and continue.

---

On first invocation, announce to the developer:

> **Payroc Save a Payment Method**
> I'll guide you through tokenizing customer payment details using the Payroc Secure Tokens API — storing cards or bank accounts in Payroc's vault so you can reuse them in future transactions without handling raw payment data again.
>
> **Two tokenization paths:**
> 1. **Tokenize without a sale** (this skill) — store payment details now; charge later. No transaction is processed.
> 2. **Tokenize during a sale** — charge and vault simultaneously in a single payment API call. See the `run-a-card-sale` skill.

*[If an MCP connection-check tool is available, run it here and surface the result before continuing.]*

---

## Quick reference

```text
POST https://api.uat.payroc.com/v1/processing-terminals/{processingTerminalId}/secure-tokens
Authorization:   Bearer <token>
Idempotency-Key: <uuid-v4>
Content-Type:    application/json
```

---

## References

All enum values and schemas live in the local `references/` files below — this skill emits from them,
not from live lookups and not from memory.

| Source | Local file | Use for |
| --- | --- | --- |
| API schema reference | `references/api-schema.md` | **All** enum values, required fields, source variants, request/response schemas |
| Error format reference | `references/error-response-format.md` | Error envelope (RFC 7807) + Payroc errors[] + canonical error type catalog |
| Integration guide | `references/save-payment-details-guide.md` | Step-by-step narrative, token format, MitAgreement guidance, update-account flow |
| Auth reference | `references/identity-call.md` | Identity endpoint URL, request/response shape, token lifetime |

These are local snapshots, authoritative for this skill. Their source URLs and last-synced dates are
recorded in [`references/_sources.md`](references/_sources.md).

---

## Core Principles

1. **Inspect before asking** — scan the codebase before asking anything; use what you find to skip obvious questions.
2. **Ask before coding** — gather unknowns through intake before writing implementation code.
3. **Read the schema reference before emitting or reviewing any enum value — including in walkthroughs.** Every `source.type`, `mitAgreement`, `entryMethod`, `dataFormat`, `accountType`, `secCode`, and `status` value is documented in `references/api-schema.md`. Read the file before you emit the value, before you review code that contains these values, and before you describe these values in a walkthrough or explanation. Do not use training-data memory, do not rely on examples embedded in this skill file — the reference file is the contract. A plausible-sounding string that isn't in the documented enum will produce a 400 error.
4. **Idempotency-Key on every POST.** The header must be a UUID v4. Omitting it causes a 400. Generate a fresh UUID for each distinct create or update-account request.
5. **Never hardcode credentials.** API keys and terminal IDs must come from environment variables or a secrets manager.
6. **Bearer token expiry.** Tokens expire after 3,600 seconds (1 hour). For long-running services, implement token refresh logic.
7. **Validate before advancing** — don't move to the next step until the current step's checkpoint passes in UAT.
8. **Diagnose before proceeding** — if a step fails, pause and work through the error taxonomy before continuing.

---

## Intake

**First, scan the codebase.** Look for:
- Server-side language and framework
- Any existing payment, billing, or subscription-related code
- Existing HTTP client setup or credential configuration
- How environment variables are managed

Then ask the developer:

1. **What type of payment method?** Card / ACH bank account / PAD bank account / single-use token from Hosted Fields
2. **How are the payment details collected?** In a form (keyed entry) / Hosted Fields (single-use token) / card reader
3. **Is this for future merchant-initiated transactions?** If yes, what type: recurring, installment, or unscheduled?
4. **Do you need lifecycle operations?** Retrieve, list, delete, or replace the stored token?

Use the answers to skip sections that don't apply.

---

## Prerequisites

These are needed to run and test in UAT — not to write the code. If the developer already has them, great.
If not, wire the code to read each value from an environment variable and keep building.

1. **API key** — used to generate Bearer tokens. Provisioned by the Payroc Integrations team with UAT access.
2. **Processing terminal ID** — the `processingTerminalId` used in the endpoint path. Should be known from UAT setup.
3. **UAT environment** — no self-serve signup; UAT terminals are provisioned by the Payroc Integrations team.

**If anything is missing — warn, don't block.** Scan the codebase for an existing env-var convention and match it.
Otherwise propose `PAYROC_API_KEY` and `PAYROC_TERMINAL_ID`. Then tell the developer:

> ⚠️ I've wired this to read your API key and terminal ID from `<VAR names>`. You'll need Payroc UAT credentials to actually test this — contact the Payroc Integrations team. I can keep building in the meantime.

### Checkpoint

Credentials are confirmed or the developer knows what's outstanding and has chosen to proceed.

---

## Step 1 — Authenticate

> **Before describing or emitting any authentication code or endpoint URLs — including in walkthroughs — read `references/identity-call.md` now.** Do not guess the endpoint URL, header name, or response shape. Do not use values from memory or from examples in this skill file. The reference is the only authoritative source.

Implement a token-generation helper in the developer's language using the endpoint URL, request shape, and response fields documented in `references/identity-call.md`. For production code, include expiry tracking and proactive refresh — tokens that expire mid-operation cause `401` errors.

Store the API key in an environment variable (e.g. `PAYROC_API_KEY`). Never inline it.

### Checkpoint

Can the helper generate a Bearer token without error? If not, check the `x-api-key` header value and confirm the API key is correct for the UAT environment.

---

## Step 2 — Build the tokenization request

Endpoint: `POST https://api.uat.payroc.com/v1/processing-terminals/{processingTerminalId}/secure-tokens`

Required headers:
```
Authorization:   Bearer <token>
Content-Type:    application/json
Idempotency-Key: <UUID v4>
```

> **Before writing the request body — including in walkthroughs — read `references/api-schema.md` now.** The `source.type` discriminator, `entryMethod`, `dataFormat`, `mitAgreement`, `accountType`, `secCode`, and all other enum values are documented there. Do not emit any of these from training data or from examples visible in this skill file — the reference file is the only authoritative contract. Reading it is mandatory, not optional.

### Required field: source

The `source` object is required and polymorphic — its shape depends on `source.type`. Read the full schema for each variant from `references/api-schema.md` before writing. The short-form examples below are for orientation only — confirm every field name and enum value against the reference.

**Card (keyed entry — most common for card-not-present):**
```json
{
  "source": {
    "type": "card",
    "cardDetails": {
      "entryMethod": "keyed",
      "keyedData": {
        "dataFormat": "plainText",
        "cardNumber": "4539858876047062",
        "expiryDate": "1230",
        "cvv": "234"
      },
      "cardholderName": "Sarah Hopper"
    }
  }
}
```

**Single-use token (from Hosted Fields):**
```json
{
  "source": {
    "type": "singleUseToken",
    "token": "<single-use-token-from-hosted-fields>"
  }
}
```

> **Read `references/api-schema.md` for the ACH and PAD source shapes** — they have different required fields (`routingNumber` for ACH; `transitNumber` and `institutionNumber` for PAD). Do not infer these from naming convention.

### Optional but commonly needed fields

| Field | When to include |
| --- | --- |
| `secureTokenId` | Provide your own identifier (e.g. your internal customer ID); gateway assigns one if omitted |
| `operator` | Name of the agent who captured the payment details |
| `mitAgreement` | Required when the token will be used for merchant-initiated transactions — read values from `references/api-schema.md` |
| `customer` | Include for address verification, notification emails, and customer-level metadata |
| `customFields` | Custom key-value pairs that Payroc echoes back in all responses for this token |

### Idempotency guidance

- Generate a fresh UUID v4 for `Idempotency-Key` on each distinct tokenization request.
- On retry of the *same* failed request, reuse the same key — the API returns the original response without creating a duplicate token.
- A genuinely new tokenization always gets a new UUID.

### Checkpoint

Is the request body valid JSON with at minimum a `source` object containing a `type` value from `references/api-schema.md`?

---

## Step 3 — Send the request and capture the response

```bash
curl -X POST https://api.uat.payroc.com/v1/processing-terminals/$PAYROC_TERMINAL_ID/secure-tokens \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Idempotency-Key: $(uuidgen | tr '[:upper:]' '[:lower:]')" \
  -H "Content-Type: application/json" \
  -d @tokenize-payload.json
```

**201 Created** — success:
```json
{
  "secureTokenId": "MREF_abc1de23-f4a5-6789-bcd0-12e345678901fa",
  "processingTerminalId": "1234001",
  "source": {
    "type": "card",
    "cardNumber": "453985******7062",
    "cardholderName": "Sarah Hopper",
    "expiryDate": "1230"
  },
  "token": "296753123456",
  "status": "notValidated",
  "mitAgreement": "unscheduled"
}
```

**Persist `secureTokenId` and `token` immediately.** Both are needed for future operations.

**IDs are opaque.** The `MREF_...` form shown above is illustrative only. In UAT, IDs may come back as plain integers. Treat every ID as an opaque string — do not validate against a format pattern.

**Token format note.** The `token` field always starts with `296753` and is up to 12 digits (Luhn-verified). This is a reusable vault token — different from a single-use token issued by Hosted Fields.

### Checkpoint

Does the API return HTTP 201 with both a `secureTokenId` and a `token`? If not, work through the error taxonomy.

---

## Step 4 — Token lifecycle (implement what was selected during intake)

### Retrieve a token

`GET https://api.uat.payroc.com/v1/processing-terminals/{processingTerminalId}/secure-tokens/{secureTokenId}`

Headers: `Authorization: Bearer <token>`

Returns the full token record including current `status`, masked `source`, and `customer`. Useful for confirming a token exists before initiating a payment.

---

### List tokens for a terminal

`GET https://api.uat.payroc.com/v1/processing-terminals/{processingTerminalId}/secure-tokens`

Headers: `Authorization: Bearer <token>`

Supports query filters:

> **Read `references/api-schema.md` for the complete filter parameter list** before writing query-building code. Filters include `secureTokenId`, `customerName`, `phone`, `email`, `token`, `first6`, and `last4`.

Pagination: cursor-based via `limit`, `after`, `before`. Use `before` or `after` — not both. The response `hasMore` field indicates whether additional pages exist.

---

### Delete a token

`DELETE https://api.uat.payroc.com/v1/processing-terminals/{processingTerminalId}/secure-tokens/{secureTokenId}`

Headers: `Authorization: Bearer <token>`

**Before writing deletion code:** warn the developer that this is **permanent and irreversible**:
- Once deleted, the token cannot be recovered.
- The `secureTokenId` cannot be reused for a new token.
- Any future payments that reference this token will fail.

Ask whether they have considered archiving the token reference on their side instead. Only proceed after explicit confirmation.

Response: `204 No Content` — empty body.

---

### Update account details

*(When the customer's card has expired or they want to replace their saved payment method)*

`POST https://api.uat.payroc.com/v1/processing-terminals/{processingTerminalId}/secure-tokens/{secureTokenId}/update-account`

Required headers: `Authorization: Bearer <token>`, `Idempotency-Key: <UUID v4>`, `Content-Type: application/json`

> **Read `references/api-schema.md` for the update-account request shape** before writing this code.

> **IMPORTANT — the update-account body is flat, not nested.** Unlike the create request (which wraps everything inside a `source` object), the update-account body has `type` and `token` directly at the root level. Do not wrap them in a `source` object.

```json
{
  "type": "singleUseToken",
  "token": "<single-use-token-representing-the-new-payment-details>"
}
```

`type` is required and the only accepted value is `"singleUseToken"`. `token` is required and must be a single-use token representing the replacement payment details.

This replaces the payment source on the existing token while preserving `mitAgreement`, `customer`, and `customFields`. The response is the updated full token object.

---

## Error taxonomy

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| 401 on any request | Token missing, expired, or API key wrong | Re-generate Bearer token; verify `x-api-key` value is the correct UAT API key |
| 400 — validation error on `source.type` or any enum field | Enum value not from the reference | Read `references/api-schema.md` and use the documented value exactly |
| 400 — missing `Idempotency-Key` | Header absent or not a UUID v4 | Add `Idempotency-Key: <UUID v4>` to every POST |
| 400 — missing required field in `source` | Source variant is missing a required field | Read the full source schema for the `source.type` in `references/api-schema.md` |
| 409 — `secureTokenId` already exists | Provided `secureTokenId` is already in use for a different payment method | Use a different `secureTokenId`, or omit it and let the gateway generate one |
| 409 — idempotency key reused | Same Idempotency-Key sent with different payload | Generate a fresh UUID for each distinct request |
| 404 — token not found | `secureTokenId` or `processingTerminalId` wrong | Verify both IDs from the create response; use the list endpoint to confirm the token exists |
| 403 — insufficient permissions | API key lacks access to this terminal or operation | Check with the Payroc Integrations team for terminal-level permissions |
| 406 — not acceptable | Request format rejected by the gateway | Check that `Accept` header (if set) is compatible with `application/json` |
| 413 — payload too large | Request body exceeds the gateway size limit | Reduce payload size; check for unexpectedly large field values |
| 415 — unsupported media type | `Content-Type` is not `application/json` | Set `Content-Type: application/json` on all POST requests |
| 500 — server error | Gateway error | Retry with exponential back-off; if persistent, contact Payroc support |

**Reading validation errors:** Payroc errors use RFC 7807 problem-details as the envelope (`type`, `title`, `status`, `detail`, `instance`). Payroc extends it with an `errors` array (not part of RFC 7807) — each item has `parameter` (JSON path of the failing field), `detail` (short reason), and `message` (human-readable). Use `parameter` to pinpoint and fix each failing field. See [`references/error-response-format.md`](references/error-response-format.md) for the envelope shape and the canonical error `type` catalog.

---

## Validation checklist

- [ ] API key sourced from environment variable — never hardcoded
- [ ] Bearer token generated from identity service — never hardcoded
- [ ] `Idempotency-Key` header present on every POST, set to a fresh UUID v4
- [ ] `source.type` value read from `references/api-schema.md` — not from training data
- [ ] All nested enum values (`entryMethod`, `dataFormat`, `mitAgreement`, `accountType`, `secCode`) read from `references/api-schema.md`
- [ ] ACH source: `routingNumber`, `accountNumber`, `nameOnAccount`, `accountType`, and `secCode` all present
- [ ] PAD source: `transitNumber`, `institutionNumber`, `accountNumber`, `nameOnAccount`, and `accountType` all present (PAD does not use `routingNumber`)
- [ ] `secureTokenId` and `token` captured from create response and stored
- [ ] Delete operation: developer explicitly confirmed irreversibility before code was written
- [ ] UAT endpoints used (`api.uat.payroc.com`) during testing — not production endpoints
- [ ] Before going live: swap `api.uat.payroc.com` → `api.payroc.com` and `identity.uat.payroc.com` → `identity.payroc.com`; use production terminal ID and API key

---

## Completion

Once all checklist items pass:

> **Integration complete.** Here's what you've built:
>
> - **Authentication** — Bearer token generation from the Payroc identity service; credentials in env vars.
> - **Tokenization** — [summarise: source type, mitAgreement if set]
> - **Lifecycle** (list what was built) — retrieve, list, delete, update-account
> - **Validated in UAT** — token created successfully and secureTokenId confirmed.
>
> **Before going live:** swap `api.uat.payroc.com` for `api.payroc.com` and `identity.uat.payroc.com` for `identity.payroc.com`. Point credentials to the production terminal and API key.

Offer next steps:
- **Run a card sale using a saved token** — see the `run-a-card-sale` skill for using `secureTokenId` in a payment request
- **Set up a payment plan** — see the `set-up-a-payment-plan` skill for recurring billing using a saved token
- **Create a single-use token** — see the `create-single-use-token` skill for Hosted Fields integration
