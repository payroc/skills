---
name: verify-bank-account
description: >
  Guides developers through verifying a bank account via the Payroc API
  (POST /v1/bank-accounts/verify). Use this skill when the user wants to verify
  or pre-validate a bank account before a bank transfer, check whether a specific
  bank account is valid for ACH or PAD, validate ACH routing numbers or PAD
  transit/institution numbers, call or integrate the /v1/bank-accounts/verify
  endpoint, implement bank account verification in a payment integration, or debug
  errors returned by the bank account verify endpoint. Also use when the user asks
  what `verified: false` means, how idempotency applies to the verify call, or how
  to handle verification outcomes in application logic — even if they don't use the
  word "verify" explicitly. Do NOT use for general ACH or bank transfer payment
  processing that does not involve the verify endpoint.
metadata:
  version: "0.1.1"
  category: transaction
  status: draft
---

# Verify Bank Account

## Version check (run this first)

Before announcing anything or starting the flow, confirm this skill is current:

1. Read this skill's version from the `metadata.version` field in the frontmatter above.
2. Fetch the published copy and read its `metadata.version`:
   `https://raw.githubusercontent.com/payroc/skills/main/plugins/payroc/transaction/skills/verify-bank-account/SKILL.md`
3. Compare the two as semantic versions:
   - **This version >= published** → continue silently, no message. (A developer running an unreleased newer version is expected and fine.)
   - **This version < published** → tell the developer:
     > ⚠️ A newer version of this skill (v\<published\>) has been published — you're running v\<current\>. Upgrading is recommended for the best results.

     Then ask whether they'd like to continue with the current version or stop and upgrade first, and honour their answer.
   - **Couldn't fetch** (offline, network error, 404) → note briefly that the version couldn't be verified and continue.

---

> **This requires a bank-transfer-capable terminal.** Bank account verification needs a terminal
> provisioned for bank transfers — this applies in both UAT and production. Built from spec review of
> `https://docs.payroc.com/openapi.yml` and
> `https://docs.payroc.com/api/schema/payment-features/bank/verify.md`.

---

## Quick reference

```text
POST  https://api.uat.payroc.com/v1/bank-accounts/verify
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
| Identity service (auth) | `references/identity-call.md` | Endpoint URL, headers, and response shape for Bearer token exchange — read before any auth code |
| API schema reference | `references/api-schema.md` | All enum values (`type`, `accountType`, `secCode`), required field sets, request/response schemas, and worked examples |
| Error format reference | `references/error-response-format.md` | Error envelope (RFC 7807) + Payroc errors[] + canonical error type catalog |

These are local snapshots, authoritative for this skill. Their source URLs and last-synced dates are
recorded in [`references/_sources.md`](references/_sources.md).

---

## Core Principles

1. **Inspect before asking** — scan the codebase before asking anything; use what you find to pre-fill obvious answers and ask targeted questions.
2. **Ask before coding** — gather unknowns through intake before writing implementation code.
3. **Read the schema reference before emitting any enum value or describing the response schema.** Every field that accepts a fixed set of strings — `type` (bank account type), `accountType`, `secCode` — is documented in `references/api-schema.md`. Read it before you emit any value. Do not use training-data guesses. When reviewing developer code, consult `references/api-schema.md` before issuing a verdict — never validate enum values from memory. When answering questions about what the endpoint returns (e.g. which fields are in the response, whether balance is returned, what the response shape is), read `references/api-schema.md` to confirm the response schema before answering — do not describe response fields from memory or from this skill file alone.
4. **Idempotency-Key on every POST.** The header value must be a UUID v4. Omitting it causes a 400. Generate a fresh UUID for each distinct operation; reuse the same key only when retrying the exact same failed request.
5. **Never hardcode credentials.** API keys and terminal IDs must come from environment variables or a secrets manager.
6. **Bearer token expiry.** Tokens expire after 3,600 seconds (1 hour). For long-running services, implement refresh logic.
7. **`verified: false` is not an error.** An HTTP 200 with `"verified": false` means the verification operation succeeded but the account details did not pass — it is a valid, expected outcome, not a failure condition. Handle it in application logic rather than as an exception.
8. **Diagnose before proceeding** — if a step fails, work through the error taxonomy before continuing.

---

## Intake

**First, scan the codebase.** Look for:
- Server-side language and framework
- Existing payment or bank transfer code
- Any existing HTTP client setup or credential configuration
- How environment variables are managed

Use what you find to pre-fill obvious answers, then confirm the following:

- **Bank account type:** ACH (U.S.) or PAD (Canadian)?
- **Purpose of verification:** Pre-validating before a bank transfer payment? Or standalone account validation?
- **Do they have a processing terminal ID** provisioned for bank transfers (ACH or PAD)?

Use the answers to tailor the implementation. If the type is ambiguous, ask one targeted clarifying question.

---

## Prerequisites

These are needed to **run and test** the integration — not to write the code. If the developer already has them, proceed. If not, wire the code to read from environment variables and keep building.

1. **API key** — used to generate Bearer tokens from the Payroc identity service. Provisioned by the Payroc Integrations team.
2. **Processing terminal ID** — the `processingTerminalId` in the request body. Must be provisioned for bank transfers (ACH or PAD).
3. **UAT environment** — Payroc's test environment. UAT terminals must be provisioned manually by the Payroc Integrations team; there is no self-serve signup.

**If anything is missing — warn, don't block.** Scan the codebase for an existing env-var convention and match it; otherwise propose `PAYROC_API_KEY` and `PAYROC_TERMINAL_ID`. Then:

> ⚠️ I've wired this to read your API key and terminal ID from `<VAR names>`. You'll need a Payroc UAT terminal provisioned for bank transfers (ACH or PAD) to actually test this — contact the Payroc Integrations team. I can keep building in the meantime.

### Checkpoint

Either the credentials are confirmed, or the developer knows what's outstanding, how to obtain it, and which environment variables the code reads from — and has chosen to proceed.

---

## Step 1 — Authenticate

> Read `references/identity-call.md` before emitting any auth code. Do not guess the endpoint URL, header name, or response shape — use only what the reference documents.

Endpoints:
- UAT/test: `POST https://identity.uat.payroc.com/authorize`
- Production: `POST https://identity.payroc.com/authorize`

Header: `x-api-key: <api-key>`

The response contains `access_token`, `expires_in` (3600), `scope`, and `token_type` ("Bearer"). All subsequent API requests use `Authorization: Bearer <access_token>`. The `Bearer` prefix is a literal string — do not substitute the `token_type` value from the response; always write `Authorization: Bearer <access_token>` verbatim.

Implement a token-generation helper in the developer's language. For production code, include expiry tracking and refresh logic.

Store the API key in an environment variable (e.g. `PAYROC_API_KEY`). Never inline it.

### Checkpoint

Can the helper generate a Bearer token without error? If not, check the `x-api-key` header and confirm the API key is correct for the UAT environment.

---

## Step 2 — Build the verification request

Endpoint: `POST https://api.uat.payroc.com/v1/bank-accounts/verify`

Required headers:
```
Authorization:   Bearer <token>
Idempotency-Key: <UUID v4 — lowercase, hyphenated>
Content-Type:    application/json
```

> **`Idempotency-Key` format:** the value must be a UUID v4, lowercase, hyphenated (e.g.
> `550e8400-e29b-41d4-a716-446655440000`). Always use lowercase — uppercase UUIDs are not guaranteed to
> be accepted. Use a fresh UUID for each distinct request; reuse the same key only when retrying the
> exact same failed request.

> **Read `references/api-schema.md` before writing the request body.** The `type` discriminator,
> `accountType` values, and `secCode` values are all defined there. Do not emit any enum value from
> training data — the reference is the contract.

> **`processingTerminalId` is a string, not a number.** Always send it as a quoted JSON string —
> `"1234001"` not `1234001`. If your config stores the terminal ID as an integer, convert to string
> before serializing the request body.

### ACH request body

```json
{
  "processingTerminalId": "YOUR_TERMINAL_ID",
  "bankAccount": {
    "type": "ach",
    "accountNumber": "11101010",
    "nameOnAccount": "Sarah Hazel Hopper",
    "routingNumber": "053200983",
    "accountType": "checking",
    "secCode": "web"
  }
}
```

Required ACH fields: `type`, `accountNumber`, `nameOnAccount`, `routingNumber`.
Optional ACH fields: `accountType` (`"checking"` | `"savings"`), `secCode` (`"web"` | `"tel"` | `"ccd"` | `"ppd"`).

> **`secCode` — treat it as required in practice, even though the spec marks it optional.** ACH payment
> processing requires `secCode`; the verification response does not return it. If you plan to follow
> this call with a bank transfer payment using the same account data, you must include `secCode` now —
> the payment endpoint expects it. A developer who omits `secCode` at verification time will hit a
> failed payment call later. **Include `secCode` in every ACH verification request unless you have a
> confirmed reason to omit it.** The JSON example above includes it; match it.

> **`accountType` — include it explicitly.** `accountType` is optional in the spec, but the server
> default when it is absent is not documented. Always include `"checking"` or `"savings"` to avoid
> unpredictable behaviour.

### PAD request body

```json
{
  "processingTerminalId": "YOUR_TERMINAL_ID",
  "bankAccount": {
    "type": "pad",
    "accountNumber": "11101010",
    "nameOnAccount": "Sarah Hazel Hopper",
    "transitNumber": "12345",
    "institutionNumber": "003",
    "accountType": "checking"
  }
}
```

Required PAD fields: `type`, `accountNumber`, `nameOnAccount`, `transitNumber`, `institutionNumber`.
Optional PAD fields: `accountType` (`"checking"` | `"savings"`).

> **`accountType` — include it explicitly.** `accountType` is optional in the spec, but the server
> default when it is absent is not documented. Always include `"checking"` or `"savings"` to avoid
> unpredictable behaviour.

> **`institutionNumber` and `transitNumber` — exact character count with zero-padding.** The spec
> requires `institutionNumber` to be exactly 3 characters and `transitNumber` to be exactly 5
> characters. These must be zero-padded strings, not plain integers. Send `"003"` not `"3"`;
> send `"00123"` not `"123"`; send `"01234"` not `"1234"`. A value with the right number of
> significant digits but fewer total characters will produce a 400 validation error. The example
> above uses `"12345"` for `transitNumber` — a convenient 5-digit value that needs no padding.
> Real transit numbers are often shorter (e.g. `"123"` → `"00123"`) and must be zero-padded.

> **Confirm all enum values against `references/api-schema.md` before writing code.** The `type`
> discriminator must be exactly `"ach"` or `"pad"` — not `"ACH"`, `"Ach"`, or any other casing.
> The `accountType` values are exactly `"checking"` and `"savings"`. The `secCode` values are exactly
> `"web"`, `"tel"`, `"ccd"`, and `"ppd"`.

### Checkpoint

Is the request body constructed with all required fields for the account type? Confirm all enum values against `references/api-schema.md`.

---

## Step 3 — Send the request and handle the response

Always generate a fresh UUID v4 for `Idempotency-Key`. On retry of the *same* request (e.g. a network timeout where you don't know if the request arrived), reuse the same key — the API returns the original response instead of creating a duplicate.

> **Do not reuse the key after `verified: false`.** `verified: false` is a completed, successful API
> call — it is not a transient error. If the developer corrects the account details and tries again,
> that is a new distinct request and requires a fresh UUID. Reusing the old key with a different
> payload will cause a 409 conflict.

```bash
curl -X POST https://api.uat.payroc.com/v1/bank-accounts/verify \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Idempotency-Key: $(uuidgen | tr '[:upper:]' '[:lower:]')" \
  -H "Content-Type: application/json" \
  -d '{
    "processingTerminalId": "'"$PAYROC_TERMINAL_ID"'",
    "bankAccount": {
      "type": "ach",
      "accountNumber": "11101010",
      "nameOnAccount": "Sarah Hazel Hopper",
      "routingNumber": "053200983",
      "accountType": "checking",
      "secCode": "web"
    }
  }'
```

### Successful response (HTTP 200)

```json
{
  "processingTerminalId": "1234001",
  "verified": true
}
```

| Field | Type | Description |
| --- | --- | --- |
| `processingTerminalId` | string | Echo of the terminal ID from the request |
| `verified` | boolean | `true` = account verified; `false` = account did not pass verification |

> **`verified: false` is not an error condition.** HTTP 200 means the verification operation completed
> successfully. `verified: false` means the account details did not pass the check — treat this in
> application logic (e.g. prompt the customer to re-enter their account details) rather than as an
> exception or API failure.

### Application logic based on result

```python
result = response.json()
if result["verified"]:
    # Account is valid — proceed with payment setup
    proceed_with_payment(result["processingTerminalId"])
else:
    # Account did NOT pass verification — do not proceed
    # Prompt the customer to check their account details
    ask_customer_to_reenter_details()
```

### Checkpoint

Does the API return HTTP 200? Is the `verified` field present in the response? If not, work through the error taxonomy below.

---

## Error taxonomy

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| 401 on any request | Token missing, expired, or API key wrong | Re-generate token; verify `x-api-key` header value is the correct UAT API key |
| 400 — `Idempotency-Key` header absent | `Idempotency-Key` header missing from the POST | Add `Idempotency-Key: <UUID v4, lowercase, hyphenated>` to the POST request |
| 400 — `Idempotency-Key` value is not a valid UUID | `Idempotency-Key` header present but value is not a valid UUID v4 | Ensure the value is a UUID v4, lowercase, hyphenated (e.g. `550e8400-e29b-41d4-a716-446655440000`) |
| 400 — validation error on `type` | Wrong or misspelled `bankAccount.type` value | Read `references/api-schema.md`; `type` must be exactly `"ach"` or `"pad"` |
| 400 — validation error on `accountType` | Wrong casing or value for `accountType` | Read `references/api-schema.md`; valid values are `"checking"` and `"savings"` |
| 400 — validation error on `secCode` | Invalid SEC code value | Read `references/api-schema.md`; valid values are `"web"`, `"tel"`, `"ccd"`, `"ppd"` |
| 400 — validation on `routingNumber` | Routing number fails format validation | ACH routing numbers must be exactly 9 digits (the spec value is a "9-digit ABA routing number"). Correct the digit count first; if the number still fails, verify it is a valid ABA routing number |
| 400 — validation on `transitNumber` | Transit number is not 5 characters | PAD transit numbers must be exactly 5 characters, zero-padded (e.g. `"00123"`, not `"123"`) |
| 400 — validation on `institutionNumber` | Institution number is not 3 characters | PAD institution numbers must be exactly 3 characters, zero-padded (e.g. `"003"`, not `"3"`) |
| 400 — missing required field | A required field is absent from the body | Read `references/api-schema.md` for the complete required-field list for the relevant `type` |
| 403 | Terminal not authorized for bank account verification | Check the terminal ID; confirm it is provisioned for bank transfers (ACH/PAD) with the Payroc Integrations team |
| 404 | Terminal not found | Verify the `processingTerminalId` is correct for the UAT environment |
| 406 | `Accept` header mismatch | Remove any explicit `Accept` header or set it to `application/json` |
| 409 — duplicate `Idempotency-Key` | Same key reused with a different payload | Generate a fresh UUID for a new distinct request. Note: after `verified: false`, corrected account data is a new distinct request — do not reuse the previous key |
| 415 | `Content-Type` header is not `application/json` | Set `Content-Type: application/json` on the request |
| 500 | Server error | Retry with exponential backoff |
| HTTP 200 but `verified: false` | Account details did not pass verification | Not an error — handle in application logic; prompt customer to check their account number and routing/transit number |

**Reading validation errors** — the response uses the **RFC 7807 problem-details envelope** (`type`,
`title`, `status`, `detail`, `instance`); Payroc **extends** it with an `errors` array. Each `errors[]`
item has a `parameter` (the JSON path of the failing field), `detail` (a short reason), and `message`
(human-readable explanation). Use `parameter` to map each error directly back to the request body field
that failed.

---

## Common pitfalls

- **Wrong `type` casing** — `"ACH"`, `"Ach"`, or `"bank_transfer"` are all wrong; the value must be exactly `"ach"` or `"pad"` (lowercase)
- **Wrong `accountType` casing** — `"Checking"` or `"SAVINGS"` are wrong; values are `"checking"` and `"savings"`
- **Wrong `secCode` casing** — `"WEB"` or `"Web"` are wrong; values are `"web"`, `"tel"`, `"ccd"`, `"ppd"` (all lowercase)
- **Omitting `secCode` from ACH verification when payments will follow** — `secCode` is optional for verification but required for ACH payments; omitting it now means the payment call will fail later when it tries to reuse the same account data
- **Omitting `accountType`** — the server default is undocumented; always include `"checking"` or `"savings"` explicitly
- **Wrong `institutionNumber` or `transitNumber` format** — these must be zero-padded strings of exactly the right character count (`"003"` not `"3"`, `"00123"` not `"123"`, `"01234"` not `"1234"`)
- **`processingTerminalId` sent as a JSON number** — the field is typed as `string`; always serialize it as `"1234001"` (quoted), never as `1234001` (bare integer)
- **Missing `Idempotency-Key`** — all POST requests require this header; omitting it causes a 400
- **Uppercase UUID in `Idempotency-Key`** — the value must be lowercase and hyphenated; always use lowercase (e.g. from `uuid.uuid4()` in Python, `uuidgen | tr '[:upper:]' '[:lower:]'` in bash, or `Guid.NewGuid().ToString()` in C# which produces lowercase by default)
- **Treating `verified: false` as an error** — HTTP 200 with `verified: false` is a normal outcome; do not throw an exception or retry the same request
- **Reusing the same `Idempotency-Key` after `verified: false` with corrected data** — `verified: false` is a completed call, not a transient error; corrected account details are a new distinct request requiring a fresh UUID (reuse causes a 409)
- **Using a card terminal for bank verification** — the terminal must be provisioned for bank transfers; verify this with the Payroc Integrations team if you receive a 403

---

## Full field reference

Read `references/api-schema.md` for:
- All enum values (`type`, `accountType`, `secCode`)
- Complete required field sets per bank account type (ACH vs PAD)
- Example request bodies for both ACH and PAD
- Full error response shape
- The complete response schema (the endpoint returns only `processingTerminalId` and `verified` — no balance, no account details, no additional fields)

> When answering any question about what fields the endpoint accepts or returns, always read `references/api-schema.md` first. Do not describe the API surface from memory.
