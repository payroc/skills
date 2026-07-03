---
name: create-single-use-token
description: >
  Guides developers through creating a Payroc single-use token for one-time payment use
  (POST /v1/processing-terminals/{processingTerminalId}/single-use-tokens). Use this skill
  when the user wants to: create a single-use token; tokenize card, ACH, or PAD details for
  immediate one-time use; capture payment details client-side without transmitting raw card
  data to the server; generate a short-lived (30-minute) token for a single payment; work
  with the /single-use-tokens endpoint; ask how to avoid handling raw card numbers
  server-side; pass payment details securely from client to server for a single transaction;
  or understand how single-use tokens differ from secure/reusable tokens. Do NOT use this
  skill when the user wants to save a payment method for future or recurring use, create a
  reusable/secure token, or set up recurring billing — those require the
  save-a-payment-method skill.
metadata:
  version: "0.1.0"
  category: transaction
  status: draft
---

# Create Single-Use Token

## Version check (run this first)

Before announcing anything or starting the flow, confirm this skill is current:

1. Read this skill's version from the `metadata.version` field in the frontmatter above.
2. Fetch the published copy and read its `metadata.version`:
   `https://raw.githubusercontent.com/payroc/skills/main/plugins/payroc/transaction/skills/create-single-use-token/SKILL.md`
3. Compare the two as semantic versions:
   - **This version >= published** → continue silently, no message. (A developer running an unreleased newer version is expected and fine.)
   - **This version < published** → tell the developer:
     > ⚠️ A newer version of this skill (v\<published\>) has been published — you're running v\<current\>. Upgrading is recommended for the best results.

     Then ask whether they'd like to continue with the current version or stop and upgrade first, and honour their answer.
   - **Couldn't fetch** (offline, network error, 404) → note briefly that the version couldn't be verified and continue.

---

On first invocation, announce to the developer:

> **Payroc Single-Use Token — Integration Guide**
> I'll guide you through creating a single-use token that represents a customer's payment details.
>
> **What a single-use token does:**
> - Captures card or bank account data and stores it securely in the Payroc vault
> - Returns a short-lived token string (expires in **30 minutes**, usable **exactly once**)
> - Lets you pass the token to a payment request without transmitting raw card data server-side
>
> **Single-use vs secure tokens:**
> - **Single-use** — one-time, 30-minute expiry, no merchant-initiated agreement needed. This skill.
> - **Secure tokens** — permanent, reusable, require an MIT agreement (recurring/installment/unscheduled). Different skill.

*[If an MCP connection-check tool is available, run it here and surface the result before continuing.]*

---

## Quick reference

```text
POST  https://api.uat.payroc.com/v1/processing-terminals/{processingTerminalId}/single-use-tokens
Authorization:   Bearer <token>
Idempotency-Key: <uuid-v4>
Content-Type:    application/json
```

---

## References

All enum values and schemas live in the local `references/` files below — this skill emits from them, not
from live lookups and not from memory.

| Source | Local file | Use for |
| --- | --- | --- |
| Identity service reference | `references/identity-call.md` | Auth endpoint URL, request header name, response fields — read before writing any auth code |
| API schema reference | `references/api-schema.md` | All enum values (`channel`, `source.type`, entry methods, ACH/PAD fields), required fields, request/response schema |
| Tokenization overview | `references/tokenization-overview.md` | Conceptual guidance on when to use single-use vs secure tokens |
| Error response format | `references/error-response-format.md` | Error envelope (RFC 7807) + Payroc errors[] + canonical error type catalog |

These are local snapshots, authoritative for this skill. Their source URLs and last-synced dates are
recorded in [`references/_sources.md`](references/_sources.md).

---

## Core principles

1. **Inspect before asking** — read the codebase before asking anything; use what you find to skip obvious questions and ask targeted ones.
2. **Ask before coding** — gather unknowns through intake before writing implementation code.
3. **Read the schema reference before emitting any enum value.** Every field that accepts a fixed set of strings — `channel`, `source.type`, `entryMethod`, `dataFormat`, `accountType`, `secCode` — is documented in `references/api-schema.md`. Read it before you emit the value. Do not use training-data guesses.
4. **Idempotency-Key on every POST.** The header value must be a UUID v4. This is required — omitting it causes a `400`. Generate a fresh UUID for each distinct request (do not reuse the same key across retries of a *different* submission; reuse it only when retrying the *same* failed request).
5. **Never hardcode credentials.** API keys and terminal IDs must come from environment variables or a secrets manager.
6. **Bearer token expiry.** Tokens from the identity service expire after 3,600 seconds (1 hour). For scripts that run longer than an hour, implement token refresh logic.
7. **Validate before advancing** — don't proceed to the next step until the current step's checkpoint passes in UAT.

---

## Intake

**First, scan the codebase.** Look for:
- Server-side language and framework
- Existing payment processing or API client code
- How environment variables are managed
- Whether a Payroc SDK is already in use

Use what you find to pre-fill obvious answers. Then ask:

1. **Payment method type** — Card, ACH (US bank transfer), or PAD (Canadian pre-authorized debit)?
2. **Channel** — How are the payment details being collected?
   - `pos` — physical device / point-of-sale
   - `web` — online / e-commerce form
   - `moto` — mail order or telephone order
3. **Card entry method** (if card) — How will card data arrive in the request?
   - `keyed` — manually typed (most common for web/MOTO)
   - `swiped` — magnetic stripe reader
   - `icc` — EMV chip reader
   - `raw` — unencrypted device data
4. **What happens after tokenization?** — Is the token passed to a payment request immediately, or stored temporarily for multi-step checkout?

> **Read `references/api-schema.md` before confirming the correct enum values** for `channel` and `source.type`. Do not emit these values from memory.

Use the answers to determine which source variant to implement and which fields are required.

---

## Prerequisites

These are needed to **run and test** the integration in UAT:

1. **API key** — used to generate Bearer tokens from the Payroc identity service. Provisioned by the Payroc Integrations team.
2. **Processing terminal ID** — the `processingTerminalId` used in the endpoint path. Provided by the Payroc Integrations team with UAT access.
3. **UAT environment** — Payroc's test environment; terminals are provisioned manually.

**If anything is missing — warn, don't block.** Scan the codebase for an existing env-var convention. Otherwise propose `PAYROC_API_KEY` and `PAYROC_TERMINAL_ID`. Write code to read from those variables, then tell the developer:

> ⚠️ I've wired this to read your API key and terminal ID from `<VAR names>`. You'll need a Payroc UAT terminal and API key to actually test this — contact the Payroc Integrations team. I can keep building in the meantime.

### Checkpoint

Either credentials are confirmed, or the developer knows what's outstanding and has chosen to proceed.

---

## Step 1 — Authenticate

> Read `references/identity-call.md` before emitting any auth code. Do not guess the endpoint URL, header name, or response shape — use only what the reference documents.

Endpoints:
- UAT/test: `POST https://identity.uat.payroc.com/authorize`
- Production: `POST https://identity.payroc.com/authorize`

Header: `x-api-key: <api-key>`

The response contains `access_token`, `expires_in` (3600), `token_type` ("Bearer"), and `scope` (space-separated list of service identifiers — not used in subsequent calls). All subsequent API requests use `Authorization: Bearer <access_token>`.

Implement a token-generation helper in the developer's language. Store the API key in an environment variable (e.g. `PAYROC_API_KEY`). Never inline it.

### Checkpoint

Can the helper generate a Bearer token without error? If not, check the `x-api-key` header and confirm the API key is correct for the UAT environment.

---

## Step 2 — Build the request body

> **Read `references/api-schema.md` before writing the request body.** The values for `channel`, `source.type`, `entryMethod`, `dataFormat`, `accountType`, and `secCode` are all defined there. Do not emit any of these from training data — the reference is the contract.

The request body has two required fields: `channel` and `source`. The optional `operator` field identifies who initiated the request.

### For a card source

```json
{
  "channel": "<pos|web|moto>",
  "source": {
    "type": "card",
    "cardDetails": {
      "entryMethod": "<raw|icc|keyed|swiped>",
      "keyedData": {
        "dataFormat": "<plainText|partiallyEncrypted|fullyEncrypted>",
        "cardNumber": "4539858876047062",
        "cvv": "234",
        "expiryDate": "1230"
      },
      "cardholderName": "Sarah Hazel Hopper"
    }
  },
  "operator": "Jane"
}
```

> **Do not guess `entryMethod` or `dataFormat` values.** Read `references/api-schema.md` for the exact enum values before writing these strings. A plausible-sounding value that is not in the documented enum will cause a `400`.

Key field notes:
- `expiryDate` is in `MMYY` format (4 digits) — e.g., `1230` means December 2030.
- `cardDetails` structure varies by `entryMethod`. **Important:** `references/api-schema.md` only documents the `keyedData` nested structure (for `entryMethod: "keyed"`). For `swiped`, `icc`, and `raw` entry methods, the nested field names (e.g. track data, EMV tag data) are **not documented in this skill's references**. Do not guess the nested field structure for these entry methods. Tell the developer: the reference only covers keyed data; for card-present (chip/swipe) flows, consult the Payroc Integrations team or the live API documentation at `https://docs.payroc.com` for the correct nested field schema.

### For an ACH source (US bank transfer)

> **Read `references/api-schema.md` for ACH enum values** (`accountType`, `secCode`) before writing.

Required fields: `accountType`, `secCode`, `nameOnAccount`, `accountNumber`, `routingNumber`. The optional `operator` field (identifying who initiated the request) applies to all source types including ACH.

```json
{
  "channel": "<web|moto>",
  "source": {
    "type": "ach",
    "accountType": "<checking|savings>",
    "secCode": "<web|tel|ccd|ppd>",
    "nameOnAccount": "Sarah Hazel Hopper",
    "accountNumber": "123456789",
    "routingNumber": "021000021"
  }
}
```

### For a PAD source (Canadian pre-authorized debit)

Required fields: `accountType`, `nameOnAccount`, `accountNumber`, `transitNumber`, `institutionNumber`. The optional `operator` field (identifying who initiated the request) applies to all source types including PAD.

```json
{
  "channel": "<web|moto>",
  "source": {
    "type": "pad",
    "accountType": "<checking|savings>",
    "nameOnAccount": "Sarah Hazel Hopper",
    "accountNumber": "123456789",
    "transitNumber": "12345",
    "institutionNumber": "001"
  }
}
```

---

## Step 3 — Send the request

Generate a fresh UUID v4 for `Idempotency-Key`. On retry of the *same* submission (e.g. a network timeout where you did not receive a response), reuse the same key — the API returns the original response. On a genuinely new submission — including a corrected retry after a `400` validation error — generate a new UUID; a changed request body constitutes a different submission.

```bash
curl -X POST \
  "https://api.uat.payroc.com/v1/processing-terminals/${PAYROC_TERMINAL_ID}/single-use-tokens" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Idempotency-Key: $(uuidgen | tr '[:upper:]' '[:lower:]')" \
  -H "Content-Type: application/json" \
  -d @token-request.json
```

### Checkpoint

Does the API return HTTP 201 with a `token` string and `expiresAt` timestamp? If not, work through the error taxonomy before proceeding.

---

## Step 4 — Handle the response

**201 Created** — token created successfully:

```json
{
  "processingTerminalId": "1234001",
  "token": "fa2e9e51bc5265a33a5ca41449524d53...",
  "expiresAt": "2024-08-05T19:50:05.723+02:00",
  "source": {
    "type": "card",
    "cardNumber": "453985******7062",
    "cardholderName": "Sarah Hazel Hopper",
    "cardType": "Visa Credit",
    "currency": "USD",
    "debit": false,
    "expiryDate": "1230"
  }
}
```

**Capture the `token` string immediately.** It is valid for 30 minutes and usable exactly once. Pass it to the consuming payment endpoint before it expires.

**Masking in responses:** Card numbers are masked — first 6 and last 4 digits are visible, middle replaced with `******`. ACH/PAD account numbers show only the last 4 digits.

**Using the token in a payment request:** Pass `"type": "singleUseToken"` with the `token` value as the `source` in a payment creation request. The exact field names depend on the payment endpoint — read that endpoint's schema before coding.

---

## Error taxonomy

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| 401 on any request | Token missing, expired, or API key wrong | Re-generate Bearer token; verify `x-api-key` header value is the correct UAT API key |
| 400 — validation error mentioning `channel` or `source.type` | Enum value not from the reference | Read `references/api-schema.md` and use the documented value |
| 400 — validation error on `entryMethod` or `dataFormat` | Enum value guessed, not read from reference | Read `references/api-schema.md` for exact card entry method enum values |
| 400 — missing `Idempotency-Key` | Header absent | Add `Idempotency-Key: <UUID v4>` to the POST; it is required |
| 400 — missing required fields (ACH/PAD) | `secCode`, `routingNumber`, `transitNumber`, or `institutionNumber` absent | Read `references/api-schema.md` for the full required-field set for each source type |
| 400 — `expiryDate` format error | Expiry sent as `MM/YY` or `YYYY-MM` instead of `MMYY` | Use 4-digit `MMYY` format (e.g. `1230` for December 2030) |
| 403 — Forbidden | API key lacks permission for this operation | Contact the Payroc Integrations team to confirm the API key's assigned permissions; ensure you're using the UAT key against the UAT host |
| 406 — Not Acceptable | `Accept` header set to an unsupported media type | Remove the `Accept` header or set it to `application/json` |
| 409 — Idempotency-Key conflict | Same UUID reused across different (non-retry) requests | Generate a fresh UUID for each distinct tokenization request |
| 415 — Unsupported Media Type | `Content-Type` is missing or not `application/json` | Add `Content-Type: application/json` to the POST request headers |
| Token rejected at payment step | Token already used or expired (>30 min) | Create a fresh single-use token and retry the payment immediately |
| 500 | Server-side error | Retry with exponential back-off; surface `errors[]` if present |

**Error response shape:** errors follow the RFC 7807 problem-details format — `type`, `title`, `status`, `detail`, `instance` (RFC standard envelope) plus Payroc's `errors[]` extension. Each `errors[]` item has `parameter` (JSON path of the failing field), `detail` (short reason), and `message` (human-readable explanation). Read `errors[].parameter` to identify which field failed. See [`references/error-response-format.md`](references/error-response-format.md) for the cross-skill standard.

---

## Common pitfalls

- **Token expiry during multi-step checkout:** If the payment step takes more than 30 minutes after tokenization (e.g., user abandons and returns), the token is expired. Implement a fresh tokenization step if the token age exceeds the session window.
- **Attempting to reuse a single-use token:** After one use, the token is invalid. Each checkout session needs a fresh token.
- **Wrong `expiryDate` format:** The API expects `MMYY` (4 digits). Common mistakes: `MM/YY`, `YYYY-MM`, `MM-YY`.
- **Missing `Idempotency-Key`:** All POSTs require this header. Omitting it returns a `400`.
- **Guessing enum values:** `channel`, `source.type`, `entryMethod`, `dataFormat`, `accountType`, `secCode` must all come from `references/api-schema.md` — do not infer them from naming patterns.
- **Hardcoding credentials:** API keys and terminal IDs must always come from environment variables.

---

## Next steps

After a successful tokenization:

- **Run a card sale:** Pass the `token` value as `source.type: "singleUseToken"` in a payment request — see the `run-a-card-sale` skill.
- **Save for future use:** Convert to a secure token by calling `POST /v1/processing-terminals/{processingTerminalId}/secure-tokens` with `source.type: "singleUseToken"` and the token value — see the `save-a-payment-method` skill.
- **3-D Secure:** For 3DS flows, the token can be used as the payment source in a 3DS-enabled payment request — see the `run-a-sale-with-3ds` skill.

---

## Full field reference

Read `references/api-schema.md` for:
- All enum values for `channel`, `source.type`, `entryMethod`, `dataFormat`, `accountType`, `secCode`
- Complete nested schemas for each source type (card, ACH, PAD)
- Full request/response field definitions
- HTTP status codes and error shapes
