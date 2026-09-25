---
name: look-up-card-details
description: >-
  Guide a developer through calling the Payroc BIN lookup API (POST /v1/cards/bin-lookup) to
  retrieve card metadata — card brand (Visa, Mastercard, Amex), country of issue, debit/credit
  indicator, healthcare/FSA/HSA flag, and surcharging eligibility — before or without processing
  a transaction. Use this skill when a developer asks about looking up card details via the
  Payroc API, identifying a card network or brand from a BIN or card number, checking whether a
  card is debit or credit, checking surcharge eligibility for a specific card via API lookup,
  doing a BIN lookup, checking card issuer country via the BIN lookup endpoint, or checking if a
  card is FSA/HSA-linked. Also use when the developer has a card number (or first 6–8 digits) and
  wants to know what kind of card it is, whether surcharging applies to that card, or whether
  healthcare spending applies — even if they don't use the term "BIN lookup". Do NOT use for card
  number format validation (Luhn check), processing a card payment, pre-authorization, refunds,
  configuring surcharging on a terminal, or general surcharging setup — those are separate skills.
metadata:
  version: "0.3.0"
  category: transaction
  status: draft
---

# Look Up Card Details

## Version check (run this first)

Before announcing anything or starting the flow, confirm this skill is current:

1. Read this skill's version from the `metadata.version` field in the frontmatter above.
2. Fetch the published copy and read its `metadata.version`:
   `https://raw.githubusercontent.com/payroc/skills/main/plugins/payroc/transaction/skills/look-up-card-details/SKILL.md`
3. Compare the two as semantic versions:
   - **This version >= published** → continue silently, no message. (A developer running an unreleased newer version is expected and fine.)
   - **This version < published** → tell the developer:
     > ⚠️ A newer version of this skill (v\<published\>) has been published — you're running v\<current\>. Upgrading is recommended for the best results.

     Then ask whether they'd like to continue with the current version or stop and upgrade first, and honour their answer.
   - **Couldn't fetch** (offline, network error, 404) → note briefly that the version couldn't be verified and continue.

---

On first invocation, announce to the developer:

> **Payroc Card Details Lookup**
> I'll guide you through calling the Payroc BIN lookup API — you can retrieve card brand, country, debit/credit status, healthcare flag, and surcharging eligibility from a BIN (first 6–8 digits) or full card data.
>
> **What this API returns:**
> - Card brand (e.g. Visa, Mastercard, Amex)
> - Issuer country (ISO 3166-1)
> - Whether the card is debit or credit
> - Whether the card is FSA/HSA-linked (healthcare)
> - Surcharging eligibility and calculated surcharge amount (if your terminal is configured for surcharging)
> - Service fee details and disclosure text (if the merchant applies a service fee)
>
> **Input options:**
> - **BIN only** — just the first 6–8 digits of the card number (no full PAN required)
> - **Full card entry** — keyed, swiped, chip, or raw device data
> - **Secure token** — a gateway-issued token for a previously saved card
> - **Digital wallet** — Apple Pay or Google Pay encrypted data

*[If an MCP connection-check tool is available, run it here and surface the result before continuing.]*

---

## Quick reference

```text
POST  https://api.uat.payroc.com/v1/cards/bin-lookup
Authorization: Bearer <token>
Content-Type:  application/json
```

> **No `Idempotency-Key` required.** This is a read-only lookup — no resource is created or modified, so no idempotency header is needed.

---

## References

All enum values and schemas live in the local `references/` files below — this skill emits from them, not from live lookups and not from memory.

| Source | Local file | Use for |
| --- | --- | --- |
| API schema reference | `references/api-schema.md` | **All** enum values, request variants (`cardBin`, `card`, `secureToken`, `digitalWallet`), response shape, surcharging and service fee objects, error codes |
| Identity call reference | `references/identity-call.md` | Bearer token exchange — endpoint URL, request header, response fields |
| Error response format | `references/error-response-format.md` | Error envelope (RFC 7807) + Payroc errors[] + canonical error type catalog |

These are local snapshots, authoritative for this skill. Their source URLs and last-synced dates are recorded in [`references/_sources.md`](references/_sources.md).

---

## Core Principles

1. **Read the schema reference before emitting any enum value.** Every field with a fixed set of values — `card.type`, `card.cardDetails.entryMethod`, `card.serviceProvider`, `card.accountType`, `card.secCode` — is documented in `references/api-schema.md`. Read it before emitting any value. Do not use training-data guesses. A plausible-sounding string that isn't in the documented enum will produce a 400. The same rule applies when **reviewing** developer-supplied code — consult `references/api-schema.md` before issuing a verdict.
2. **Read `references/identity-call.md` before emitting any auth code.** Do not guess the endpoint URL, header name, or response shape — use only what the reference documents.
3. **Never hardcode credentials.** API keys and terminal IDs must come from environment variables or a secrets manager, never source code or configuration files checked into version control.
4. **Bearer token expiry.** Tokens from the identity service expire after 3,600 seconds (1 hour). For short scripts this is fine; for long-running services, implement token refresh logic.
5. **No `Idempotency-Key` on this endpoint.** Unlike most Payroc POST endpoints, BIN lookup does not require an idempotency header — it is a read-only operation. Do not add one unnecessarily.
6. **Surcharging requires a terminal ID.** The `surcharging` object is only present in the response if `processingTerminalId` is supplied. If the developer wants surcharge information, they must include their terminal ID.
7. **BIN is the preferred input.** If the developer only needs card-type information and does not have a full card entry flow, the `cardBin` variant is the simplest — just the first 6–8 digits.
8. **Diagnose before proceeding** — if a step fails, pause and work through the error taxonomy before continuing.

---

## Intake

**First, scan the codebase.** Look for:
- Server-side language and framework
- Any existing card input or payment form code
- Existing HTTP client setup or credential configuration
- How environment variables are managed

Use what you find to pre-fill obvious answers and ask targeted questions. Then ask:

1. **What card data do you have available?** Choose the variant:
   - BIN only (first 6–8 digits) — `cardBin` type (simplest)
   - Full card entry from a terminal or form — `card` type
   - A gateway-issued secure token for a saved card — `secureToken` type
   - Apple Pay or Google Pay encrypted wallet data — `digitalWallet` type

2. **Do you need surcharging information?** If yes, you'll need to include your `processingTerminalId`. If the developer doesn't know their terminal ID, note it as outstanding and continue.

3. **Do you have an amount to calculate surcharge against?** If surcharging is relevant, including `amount` (integer, lowest denomination) and `currency` (ISO 4217 code) returns the surcharge calculated on that specific amount. The same applies to a percentage-based service fee: its `amount` comes back only if the request includes `amount`.

4. **Does the merchant apply a service fee?** If so, the response carries a `serviceFee` object alongside (or instead of) `surcharging`. Handle both in Step 4.

---

## Prerequisites

These are needed to **run and test** the integration in UAT — not to write the code. If the developer already has them, great. If not, don't stop: wire the code to read from environment variables and keep building.

1. **API key** — exchanged for a Bearer token from the Payroc identity service. Provisioned by the Payroc Integrations team.
2. **Processing terminal ID** (optional) — only required if surcharge information is needed. The developer should know this from their UAT setup.
3. **UAT environment** — Payroc's test environment. UAT terminals are provisioned manually by the Payroc Integrations team.

**If anything is missing — warn, don't block.** Scan the codebase for an existing env-var convention and match it; otherwise propose `PAYROC_API_KEY` and (if needed) `PAYROC_TERMINAL_ID`. Tell the developer plainly:

> ⚠️ I've wired this to read your API key from `PAYROC_API_KEY`. You'll need a Payroc UAT API key to run or test this — contact the Payroc Integrations team to get one, and set the variable before testing. I can keep building in the meantime.

### Checkpoint

Either the credentials are confirmed, or the developer knows what's outstanding and which environment variables the code reads from — and has chosen to proceed.

---

## Step 1 — Authenticate

> **Read `references/identity-call.md` now, before writing any auth code.** The endpoint URLs, request header name, and response field names are documented there. Do not rely on values stated elsewhere in this skill — the reference is the single source of truth and must be consulted at this step to avoid drift.

Using the values from `references/identity-call.md`:
- Obtain a Bearer token by calling the identity service endpoint for the target environment (UAT or production).
- Pass the API key using the header documented in the reference.
- From the response, extract the `access_token` (and `expires_in` for expiry tracking). All subsequent API requests use `Authorization: Bearer <access_token>`.

Implement a token-generation helper in the developer's language. For production code, include expiry tracking and refresh logic — tokens that expire mid-operation cause 401s on otherwise valid requests.

Store the API key in an environment variable (e.g. `PAYROC_API_KEY`). Never inline it.

### Checkpoint

Can the helper generate a Bearer token without error? If not, check the `x-api-key` header and confirm the API key is correct for the UAT environment.

---

## Step 2 — Build the request body

> **Read `references/api-schema.md` before writing the request body.** The `card.type` discriminator and all nested enum values are documented there. Do not emit any value from training data — the reference is the contract.

The request body has one required field (`card`) and three optional context fields (`processingTerminalId`, `amount`, `currency`).

### Variant A — BIN only (simplest)

Use this when the developer has the first 6–8 digits of a card number:

```json
{
  "processingTerminalId": "YOUR_TERMINAL_ID",
  "amount": 5000,
  "currency": "USD",
  "card": {
    "type": "cardBin",
    "bin": "411111"
  }
}
```

- `processingTerminalId`, `amount`, and `currency` are optional but required for surcharge information.
- `bin` is the only required field in the `card` object for this variant.
- Confirm the exact enum value for `type` from `references/api-schema.md` before emitting.

### Variant B — Full card entry (`card` type)

Use this when the developer has full card data (e.g. from a terminal or form):

```json
{
  "processingTerminalId": "YOUR_TERMINAL_ID",
  "card": {
    "type": "card",
    "accountType": "checking",
    "cardDetails": {
      "entryMethod": "keyed",
      "cardNumber": "4111111111111111",
      "expiryDate": "1226",
      "cvv": "123"
    }
  }
}
```

- `entryMethod` values: `keyed` | `swiped` | `icc` | `raw` — read from `references/api-schema.md`.
- **Entry-method-specific fields inside `cardDetails`:** The fields required alongside `entryMethod` depend on how the card data was captured:
  - `keyed` — include `cardNumber` (full PAN), `expiryDate` (MMYY), and optionally `cvv`
  - `swiped` — include the magnetic stripe track data (e.g. `track1Data` and/or `track2Data`)
  - `icc` — include the chip data blob from the terminal (e.g. `iccData`)
  - `raw` — include the raw device data payload from the reader
  - If you are unsure which fields your terminal or card reader supplies, consult your terminal SDK documentation for the card data it exposes after a read.
- `accountType` values: `checking` | `savings` — read from `references/api-schema.md`. Include only when the card is a debit/ACH card and the account type is known (e.g. from the cardholder or terminal); omit for credit cards or when unknown.

### Variant C — Secure token

Use this when the developer has a gateway-issued token for a previously saved card:

```json
{
  "processingTerminalId": "YOUR_TERMINAL_ID",
  "card": {
    "type": "secureToken",
    "token": "GATEWAY_TOKEN",
    "accountType": "checking",
    "secCode": "web"
  }
}
```

- `secCode` values: `web` | `tel` | `ccd` | `ppd` — read from `references/api-schema.md`.

### Variant D — Digital wallet

Use this when the developer has Apple Pay or Google Pay encrypted wallet data:

```json
{
  "processingTerminalId": "YOUR_TERMINAL_ID",
  "card": {
    "type": "digitalWallet",
    "serviceProvider": "apple",
    "encryptedData": "BASE64_ENCRYPTED_WALLET_DATA",
    "cardholderName": "Jane Smith"
  }
}
```

- `serviceProvider` values: `apple` | `google` — read from `references/api-schema.md`.

---

## Step 3 — Send the request

No `Idempotency-Key` is needed — this is a read-only lookup.

```bash
curl -X POST https://api.uat.payroc.com/v1/cards/bin-lookup \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "processingTerminalId": "'"$PAYROC_TERMINAL_ID"'",
    "amount": 5000,
    "currency": "USD",
    "card": {
      "type": "cardBin",
      "bin": "411111"
    }
  }'
```

### Checkpoint

Does the API return HTTP 200 with a `cardInfo` object? If not, work through the error taxonomy.

---

## Step 4 — Handle the response

**200 OK** — lookup successful:

```json
{
  "type": "VISA",
  "cardNumber": "411111######1111",
  "country": "US",
  "currency": "USD",
  "debit": false,
  "healthcare": false,
  "surcharging": {
    "allowed": true,
    "amount": 150,
    "percentage": 3.0,
    "disclosure": "A surcharge of 3.00% will be applied to this transaction."
  }
}
```

Key fields to capture and use:

| Field | Type | Meaning |
| --- | --- | --- |
| `type` | string | Card brand — e.g. `"VISA"`, `"MASTERCARD"`, `"AMEX"` |
| `cardNumber` | string | Masked card number — first 6 and last 4 digits visible |
| `country` | string | ISO 3166-1 alpha-2 — country of card issuer |
| `currency` | string | ISO 4217 — default currency for the issuing bank |
| `debit` | boolean | `true` = debit card; `false` = credit card |
| `healthcare` | boolean | `true` = FSA/HSA-linked card |
| `surcharging.allowed` | boolean | Whether surcharging is permitted for this card on this terminal |
| `surcharging.amount` | integer | Surcharge amount in lowest denomination (e.g. cents) |
| `surcharging.percentage` | number | Surcharge rate as a percentage |
| `surcharging.disclosure` | string | Disclosure text to show to the customer |
| `serviceFee.applicable` | boolean | Whether a service fee applies to this card. Always present when `serviceFee` is |
| `serviceFee.amount` | integer | Fee in lowest denomination. A percentage fee is returned only if the request included `amount` |
| `serviceFee.percentage` | number | Fee rate. Not returned when `basis` is `debitAmount` |
| `serviceFee.basis` | string | `creditPercentage` \| `debitPercentage` \| `debitAmount` |
| `serviceFee.disclosure` | string | Disclosure text to show to the customer. Only returned when `applicable` is `true` |

**Surcharging notes:**
- The `surcharging` object is only present if `processingTerminalId` was included in the request and the terminal is configured for surcharging.
- Even if `surcharging` is present, always check `surcharging.allowed` — `false` means this card is exempt (e.g. debit cards are often exempt from surcharging).
- If you included `amount` in the request, `surcharging.amount` reflects the calculated surcharge on that specific amount.
- Show `surcharging.disclosure` to the customer before they complete payment if `surcharging.allowed` is `true`.

**Service fee notes:**

> **Read the `serviceFee` notes in `references/api-schema.md` before writing service fee handling.** The `basis` enum and the rules for when each field is returned are documented there.

- The `serviceFee` object is only present if the merchant applies a service fee. It is also absent if the gateway can't determine which currency to calculate the fee in.
- Check `serviceFee.applicable` before adding a fee. It is `false` when the card is exempt from the program or is an EBT card.
- Branch on `basis`, not on `debit`. The gateway reads card type from the BIN file, and a credit card that doesn't accept service fees comes back as `debitAmount` or `debitPercentage`.
- Show `serviceFee.disclosure` to the customer before they complete payment if `serviceFee.applicable` is `true`.

---

## Step 5 — Handle errors

Errors use the **RFC 7807 problem-details format as the envelope**: top-level `type`, `title`, `status`, `detail`, and `instance` are the standard RFC members. Payroc **extends** the envelope with an `errors` array (the array and its contents are Payroc's own, not defined by RFC 7807). Each `errors[]` item carries `parameter` (the JSON path of the failing field), `detail` (a short reason — distinct from the top-level `detail`), and `message` (the human-readable explanation). Use `parameter` to map each error back to your request body.

| Status | Scenario | Action |
| --- | --- | --- |
| 400 | Validation failure — missing `card`, wrong `type` value, malformed BIN | Fix fields identified in `errors[].parameter`; re-read `references/api-schema.md` for correct enum values |
| 401 | Token expired or invalid | Re-authenticate and get a fresh Bearer token |
| 403 | API key lacks permission | Check API key scope; contact Payroc support |
| 404 | Token not found (for `secureToken` variant) | Verify the token value; check if the saved card still exists |
| 406 | `Accept` header rejects `application/json` | Remove the `Accept` header or set it to `application/json` |
| 409 | Conflict — duplicate idempotency key (unlikely on this read-only endpoint) | Do not add an `Idempotency-Key` header; if one is present, remove it |
| 415 | `Content-Type` is not `application/json` | Add `Content-Type: application/json` to the request |
| 500 | Server error | Retry with exponential backoff |

**Common 400 causes and fixes:**

| Error | Cause | Fix |
| --- | --- | --- |
| `card` required | `card` object missing | Add `card` with the appropriate `type` and required fields |
| Invalid `type` | `card.type` value is wrong — e.g. `"bin"` instead of `"cardBin"` | Read `references/api-schema.md` and use the exact enum value |
| Missing `bin` | `cardBin` variant used but `bin` not provided | Add `bin` field with the first 6–8 digits |
| Missing `token` | `secureToken` variant used but `token` not provided | Add `token` field |
| Missing `encryptedData` or `serviceProvider` | `digitalWallet` variant incomplete | Add both required fields |

---

## Error taxonomy

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| 401 on any request | Token missing, expired, or API key wrong | Re-generate token; verify `x-api-key` header value is the correct UAT API key |
| 400 — invalid `type` value | `card.type` enum value not from the reference | Read `references/api-schema.md` and use the documented value |
| 400 — missing `card` | Request body sent without the required `card` object | Add `card` with the appropriate variant |
| 400 — missing `bin` | `cardBin` type sent without `bin` field | Add the `bin` field |
| No `surcharging` in response | Terminal ID not provided, or terminal not configured for surcharging | Include `processingTerminalId` in the request; check terminal setup with Payroc support |
| `surcharging.allowed: false` | Card is exempt from surcharging (e.g. debit or regulated card) | Do not add a surcharge for this card; use `debit` field to detect debit cards |
| No `serviceFee` in response | Merchant doesn't apply a service fee, or the gateway couldn't determine the currency | If the merchant has a service fee, send `currency` and `processingTerminalId`. The fee is calculated in the request currency on multi-currency accounts, otherwise in the terminal's currency |
| `serviceFee` present but no `amount` | Percentage-based fee and no `amount` in the request | Include `amount` (and `currency`) to get the calculated fee |
| 404 — token not found | Secure token is invalid or the saved card was deleted | Verify the token; prompt the customer to re-enter card details |
| 403 — permission denied | API key scope doesn't cover this endpoint | Contact Payroc support to check API key permissions |

---

## Common pitfalls

- **Wrong `card.type` enum value**: Use exactly `cardBin`, `card`, `secureToken`, or `digitalWallet` — values like `"bin"`, `"card_bin"`, or `"secure_token"` will return 400. Read from `references/api-schema.md`.
- **Adding `Idempotency-Key` unnecessarily**: This endpoint does not require an idempotency key — it is a read-only operation that creates no resource. If you see an `Idempotency-Key` header on a BIN lookup request, remove it; it should not be there.
- **Omitting `processingTerminalId` when surcharging info is needed**: The `surcharging` object is absent from the response without a terminal ID. Always include it if the caller needs to know whether to apply a surcharge.
- **Not checking `surcharging.allowed`**: A `surcharging` object being present does not mean surcharging applies — always check `surcharging.allowed` before applying or disclosing a surcharge.
- **Using `amount` in major units**: `amount` is in the lowest currency denomination (e.g. cents for USD). `5000` means $50.00, not $5000.00.
- **Showing disclosure text**: If `surcharging.allowed` is `true`, show `surcharging.disclosure` to the customer **before** they confirm payment. This is a legal/compliance requirement in many jurisdictions. The same goes for `serviceFee.disclosure` when `serviceFee.applicable` is `true`.
- **Treating `serviceFee` as present means it applies**: Check `serviceFee.applicable`. A present object with `applicable: false` means no fee for this card.

---

## Full field reference

Read `references/api-schema.md` for:
- All enum values (`card.type`, `entryMethod`, `serviceProvider`, `accountType`, `secCode`)
- Complete request variants for each `card.type`
- Response field descriptions and the surcharging and service fee object shapes
- Full error status code table
