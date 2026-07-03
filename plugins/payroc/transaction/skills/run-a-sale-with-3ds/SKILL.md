---
name: run-a-sale-with-3ds
description: >-
  Guide a developer through implementing a 3-D Secure (3DS) card sale using
  the Payroc API — sending a card token through the Payroc MPI service for
  cardholder authentication, then posting the payment with the resulting
  mpiReference. Use this skill when someone asks about 3-D Secure payments,
  3DS integration, 3DS2, SCA (Strong Customer Authentication), verifying
  cardholder identity for online card payments, running a card sale with 3DS,
  implementing Visa Secure, Mastercard Identity Check, or Verified by Visa.
  Also use when the developer wants to reduce fraud liability using
  3-D Secure, add 3DS cardholder authentication to a web checkout, use the
  Payroc MPI service or mpi endpoint, or include a threeDSecure object or
  mpiReference in a payment request — even if they don't say "3DS"
  explicitly. Do NOT use for card sales without 3DS authentication, refunds,
  ACH payments, or card tokenization alone.
metadata:
  version: "0.1.0"
  category: transaction
  status: draft
---

# Run a Sale with 3-D Secure

## Version check (run this first)

Before announcing anything or starting the flow, confirm this skill is current:

1. Read this skill's version from the `metadata.version` field in the frontmatter above.
2. Fetch the published copy and read its `metadata.version`:
   `https://raw.githubusercontent.com/payroc/skills/main/plugins/payroc/transaction/skills/run-a-sale-with-3ds/SKILL.md`
3. Compare the two as semantic versions:
   - **This version >= published** → continue silently, no message. (A developer running an unreleased newer version is expected and fine.)
   - **This version < published** → tell the developer:
     > ⚠️ A newer version of this skill (v\<published\>) has been published — you're running v\<current\>. Upgrading is recommended for the best results.

     Then ask whether they'd like to continue with the current version or stop and upgrade first, and honour their answer.
   - **Couldn't fetch** (offline, network error, 404) → note briefly that the version couldn't be verified and continue.

---

On first invocation, announce to the developer:

> **Payroc 3-D Secure Integration**
> I'll guide you through a five-step flow: (1) enrolment setup, (2) authentication (Bearer token), (3) card tokenization, (4) MPI authentication, and (5) posting the payment.
>
> **How 3-D Secure works with Payroc:**
> 1. You tokenize the card using Hosted Fields or the API tokenization feature.
> 2. You send the token to Payroc's MPI service — the bank assesses fraud risk and may challenge the cardholder.
> 3. The MPI result arrives asynchronously at your callback URL (delivered as a GET request — your handler must accept GET, not POST).
> 4. If the result is approved (`"A"`), you post the payment including the `mpiReference`.
>
> **Important:** 3-D Secure uses two different Payroc API hosts — `payments.payroc.com` for the MPI step and `api.payroc.com` for the payment step. Don't mix them up.

*[If an MCP connection-check tool is available, run it here and surface the result before continuing.]*

---

## Quick reference

```text
Step 4 (MPI):   GET  https://payments.uat.payroc.com/merchant/mpi?processingTerminalId=...&singleUseToken=...&...
                Authorization:   Bearer <token>
Step 5 (Pay):   POST https://api.uat.payroc.com/v1/payments
                Authorization:   Bearer <token>
                Idempotency-Key: <uuid-v4>
                Content-Type:    application/json
```

---

## References

All enum values and schemas live in the local `references/` files below — this skill emits from them, not
from live lookups and not from memory. Read the relevant reference file before writing code, reviewing
code, or answering questions about parameter names, enum values, or API shapes. Do not rely on
training data or memory for anything that has a reference file.

| Source | Local file | Use for |
| --- | --- | --- |
| API schema reference | `references/api-schema.md` | **All** enum values, required fields, MPI request parameters, MPI response schema, threeDSecure object variants, payment request/response shape |
| Error format reference | `references/error-response-format.md` | Error envelope (RFC 7807) + Payroc errors[] + canonical error type catalog |
| 3DS overview | `references/3ds-overview.md` | Flow narrative, cardholder challenge guidance, MPI result interpretation table |
| Identity service reference | `references/identity-call.md` | Bearer token exchange — endpoint URLs, request header, response shape |

These are local snapshots, authoritative for this skill. Source URLs and last-synced dates are in
[`references/_sources.md`](references/_sources.md).

---

## Core Principles

1. **Inspect before asking** — scan the codebase before asking anything; use what you find to skip obvious questions and ask targeted ones.
2. **Ask before coding** — gather unknowns through intake before writing implementation code; wrong assumptions waste the developer's time.
3. **Read the schema reference before emitting or confirming any enum value, parameter name, or field name** — whether writing code, reviewing code, or answering a question. Every value in the MPI request parameters, the `threeDSecure` object, and the payment request body is documented in `references/api-schema.md`. Read it first. Do not use training-data guesses. A plausible-sounding value that isn't in the reference will produce a 400 or a silent mismatch.
4. **Idempotency-Key on every POST.** Required on `POST /v1/payments`; not required on the MPI `GET` request. Value must be a UUID v4. Generate a fresh one per distinct payment — reuse only when retrying the exact same failed request.
5. **Never hardcode credentials.** API keys, terminal IDs, and tokens must come from environment variables or a secrets manager.
6. **The MPI result is asynchronous.** The MPI GET request does not return the result directly — the result arrives via a GET to your callback URL. The integration must handle async delivery before proceeding to Step 5.
7. **Do not proceed to payment on a declined MPI result.** If `result: "D"`, stop and surface the decline to the user. Submitting the payment anyway defeats the purpose of 3-D Secure.
8. **Validate before advancing** — don't move to the next step until the current step's checkpoint passes in UAT.
9. **3-D Secure scope** — 3DS applies only to cardholder-present e-commerce card transactions. It does not apply to ACH/bank transfer payments (which have no card network to authenticate against). It does not apply to merchant-initiated transactions (recurring, unscheduled MIT) — those use `credentialOnFile`/`standingInstructions` instead, not 3DS. Do not claim 3DS applies to payment types it does not cover.

---

## Intake

**First, scan the codebase.** Look for:
- Server-side language and framework
- Existing HTTP client setup and credential configuration
- Whether Hosted Fields is already integrated (provides the tokenization step)
- How environment variables are managed
- Any existing webhook/callback handler infrastructure

Use what you find to pre-fill obvious answers and ask targeted questions. Then confirm:

- **Tokenization method:** Are they using Hosted Fields (client-side) or API tokenization (server-side)? This determines Step 3 implementation.
- **Challenge preference:** Should they force a cardholder challenge (`REQUIRED`), leave it to the bank (`OPTIONAL`/omit), or make it configurable per transaction?
- **Payment type:** Sale (capture immediately, `autoCapture: true`) or pre-authorization (`autoCapture: false`)?
- **Callback URL:** Do they have a server endpoint ready to receive the async MPI response?

Use the answers to skip inapplicable sections. If the developer's use case is ambiguous, ask one targeted clarifying question before proceeding.

---

## Prerequisites

These are needed to **run and test** the integration in UAT — not to write the code. If the developer already has them, great. If not, don't stop: wire the code to read each value from an environment variable and keep building. The developer can populate the variables before they test.

1. **API key** — used to generate Bearer tokens from the Payroc identity service. Provisioned by the Payroc Integrations team with UAT access.
2. **Processing terminal ID** — the `processingTerminalId` used in both the MPI request and the payment request.
3. **3-D Secure enabled on the terminal** — 3DS is not enabled by default. The developer must contact `cs@payroc.com` or the Payroc Integrations team to enable it and register a **callback URL** (the server endpoint that will receive MPI responses).
4. **UAT environment** — Payroc's test environment. There is no self-serve signup; UAT terminals are provisioned manually by the Payroc Integrations team.

**If anything is missing — warn, don't block.** Scan the codebase for an existing env-var convention and match it; otherwise propose names like `PAYROC_API_KEY` and `PAYROC_TERMINAL_ID`. Write the code to read the credentials from those variables, then tell the developer:

> ⚠️ I've wired this to read credentials from `<VAR names>`. 3-D Secure also needs to be enabled on your terminal by the Payroc Integrations team — they'll need your callback URL when you contact them. You can build the integration now and enable 3DS before testing.

### Checkpoint

The developer knows what's needed, has confirmed which variables the code reads from, and understands that 3DS must be enabled before UAT testing.

---

## Step 1 — Enable 3-D Secure

**This is a one-time setup step, not a code step.**

3-D Secure is not enabled on Payroc terminals by default. Before the MPI service will respond, the developer must:

1. Contact Payroc Customer Support (`cs@payroc.com`) or the Payroc Integrations team.
2. Request 3-D Secure to be enabled on their terminal.
3. Provide a **callback URL** — the server endpoint where Payroc will deliver the MPI authentication result asynchronously. Payroc delivers the result as a **GET request** to this URL (query parameters, no body). The route handler at this URL must accept `GET`, not `POST`.

> **Local development note:** The callback URL must be publicly reachable at test time — `localhost` won't work. Use a tunnelling tool (e.g. ngrok, Cloudflare Tunnel) to expose a local port during UAT testing.

If the developer says 3DS is already enabled, confirm they have a callback URL registered and move to Step 2.

### Checkpoint

3-D Secure is enabled on the terminal and a callback URL is registered. The developer knows the URL and has a route handler ready (or to be built in Step 4b below).

---

## Step 2 — Authenticate

> Read `references/identity-call.md` before emitting any auth code. Do not guess the endpoint URL, header name, or response shape — use only what the reference documents.

Endpoints:
- UAT/test: `POST https://identity.uat.payroc.com/authorize`
- Production: `POST https://identity.payroc.com/authorize`

Header: `x-api-key: <api-key>`

The response contains `access_token`, `expires_in` (3600), and `token_type` ("Bearer"). All subsequent API requests use `Authorization: Bearer <access_token>`.

Implement a token-generation helper in the developer's language. For production code, include expiry tracking and refresh logic — tokens that expire mid-operation will produce 401s on otherwise valid requests.

Store the API key in an environment variable (e.g. `PAYROC_API_KEY`). Never inline it.

### Checkpoint

The helper generates a Bearer token without error. If it fails, check the `x-api-key` header value and confirm the API key is for the UAT environment.

---

## Step 3 — Tokenize the Card

Before calling the MPI service, the card must be converted into a single-use token. Two methods are available:

### Option A — Hosted Fields (recommended for web checkout)

Payroc's Hosted Fields embeds card-input widgets directly in the checkout page. On form submit, Hosted Fields exchanges the card data for a single-use token client-side. The token is then passed to your server.

> If the developer is already integrating Hosted Fields, the tokenization step is covered by that integration. Ask if they need help with Hosted Fields, or if they already have a token to use.

### Option B — API tokenization (server-side)

If the developer is not using Hosted Fields, card details can be tokenized via the Payroc API tokenization endpoint. Refer to the tokenization skill or the API reference for this step.

**Result:** a `singleUseToken` string — this value goes into both the MPI request (Step 4) and the payment request (Step 5).

> **Field name trap:** In the MPI request (Step 4) the query parameter is named `singleUseToken`. In the payment request body (Step 5) the field holding this same token is named `token` (inside `paymentMethod`), **not** `singleUseToken`. The `singleUseToken` string in `paymentMethod.type` is the type discriminator, not the field that holds the token value. Read `references/api-schema.md` `paymentMethod` table to confirm.

### Checkpoint

A valid single-use token is available. If the token was obtained from Hosted Fields, confirm the client-side script has completed its form submission before proceeding.

---

## Step 4 — Send the MPI Request

> **Read `references/api-schema.md` before writing the MPI request.** All parameter names, their types, and enum values are documented there. Do not infer them from the examples below — the reference is the contract.

**Method:** `GET` (query parameters only, no request body)

**Endpoint:**
- UAT: `https://payments.uat.payroc.com/merchant/mpi`
- Production: `https://payments.payroc.com/merchant/mpi`

Note: the MPI service uses `payments.uat.payroc.com`, **not** `api.uat.payroc.com`. These are different hosts.

**Required query parameters:**

| Parameter | Notes |
| --- | --- |
| `processingTerminalId` | Terminal identifier |
| `singleUseToken` | Token from Step 3 |
| `email` | Cardholder email address |
| `amount` | Integer, in the currency's lowest denomination (e.g. cents for USD) |
| `currency` | ISO 4217 code (e.g. `"USD"`, `"GBP"`) — use the same value in Step 5 |
| `orderId` | Merchant-assigned order ID — use the same value in Step 5 |

**Optional query parameter:**

| Parameter | Values | Notes |
| --- | --- | --- |
| `cardholderChallenge` | `"REQUIRED"` or `"OPTIONAL"` | Force a cardholder challenge (`REQUIRED`) or leave it to the bank (omit or `OPTIONAL`) |

**Required header:** `Authorization: Bearer <token>` (no `Content-Type` or `Idempotency-Key` — this is a GET request).

```bash
# Example MPI request (UAT)
curl -G https://payments.uat.payroc.com/merchant/mpi \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  --data-urlencode "processingTerminalId=$PAYROC_TERMINAL_ID" \
  --data-urlencode "singleUseToken=$SINGLE_USE_TOKEN" \
  --data-urlencode "email=cardholder@example.com" \
  --data-urlencode "amount=5000" \
  --data-urlencode "currency=USD" \
  --data-urlencode "orderId=ORDER-001"
```

### Step 4b — Build the callback handler

The MPI result is **not** returned synchronously in the response to the GET request. Payroc delivers the result asynchronously as a GET request to the callback URL registered in Step 1.

The callback GET request will include:

| Field | Values | Notes |
| --- | --- | --- |
| `result` | `"A"` or `"D"` | `"A"` = approved (proceed to payment); `"D"` = declined (do not proceed) |
| `status` | `"Y"`, `"A"`, `"N"`, `"U"` | Authentication outcome — read `references/api-schema.md` for meanings |
| `eci` | `"05"`, `"06"`, `"07"` | ECI indicator — `"05"` = authenticated, `"06"` = attempted, `"07"` = failed |
| `mpiReference` | string | **Save this value** — it is required in Step 5 |
| `orderId` | string | Echo of the merchant's `orderId` |

Implement a route handler at the callback URL that:
1. Reads these query parameters from the incoming GET request.
2. Looks up the pending order using `orderId`.
3. Checks `result`:
   - `"A"` → proceed to Step 5 (post the payment).
   - `"D"` → surface the decline to the user; do not post the payment.
4. Stores `mpiReference` for use in Step 5.

> **Branch on `result`, not `status`.** Both fields use `"A"` as a value but with different meanings: `result: "A"` means "approved — proceed"; `status: "A"` means "authentication attempted (not enrolled)". Branching on `status == "A"` will miss cases where `result: "D"` and produce a false proceed. Always check `result` first.

> **Never proceed to Step 5 if `result` is `"D"`.** The cardholder was not authenticated. Posting the payment anyway bypasses 3-D Secure's fraud protection.

### Checkpoint

The MPI request was sent without error. The callback handler is in place and correctly distinguishes `"A"` vs `"D"` results. The `mpiReference` is captured and stored.

---

## Step 5 — Post the Payment

> **Read `references/api-schema.md` before writing the payment request body.** The `channel`, `threeDSecure.serviceProvider`, and `paymentMethod.type` values are all documented there. Do not emit them from training data.

**Endpoint:**
- UAT: `POST https://api.uat.payroc.com/v1/payments`
- Production: `POST https://api.payroc.com/v1/payments`

Note: the payment endpoint uses `api.uat.payroc.com`, **not** `payments.uat.payroc.com`.

**Required headers:**
```
Authorization:   Bearer <token>
Content-Type:    application/json
Idempotency-Key: <uuid-v4>
```

Generate a fresh UUID v4 for `Idempotency-Key`. On retry of the *same* failed payment, reuse the same key. On a genuinely new payment, generate a new UUID.

**Request body:**

```json
{
  "channel": "web",
  "processingTerminalId": "<your-terminal-id>",
  "order": {
    "orderId": "<same-orderId-from-step-4>",
    "amount": 5000,
    "currency": "USD"
  },
  "paymentMethod": {
    "type": "singleUseToken",
    "token": "<singleUseToken-from-step-3>"
  },
  "threeDSecure": {
    "serviceProvider": "gateway",
    "mpiReference": "<mpiReference-from-step-4-callback>"
  }
}
```

> **Confirm `channel`, `paymentMethod.type`, and `threeDSecure.serviceProvider` values from `references/api-schema.md`** before emitting them. The values above are correct — document them from the reference, not from this example.

Key field notes:
- `channel` must be `"web"` for 3-D Secure e-commerce payments — do not use `"pos"` or `"moto"`.
- `order.orderId` and `order.amount`/`order.currency` must match the values sent in Step 4.
- `paymentMethod.type` must be `"singleUseToken"` — not `"card"` or `"token"`.
- `threeDSecure.serviceProvider` must be `"gateway"` when using Payroc's MPI service.
- `threeDSecure.mpiReference` is the exact `mpiReference` string from the Step 4 callback.
- `autoCapture` defaults to `true` (sale — capture immediately). Set to `false` for pre-authorization.

```bash
curl -X POST https://api.uat.payroc.com/v1/payments \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: $(uuidgen | tr '[:upper:]' '[:lower:]')" \
  -d '{
    "channel": "web",
    "processingTerminalId": "'$PAYROC_TERMINAL_ID'",
    "order": {
      "orderId": "ORDER-001",
      "amount": 5000,
      "currency": "USD"
    },
    "paymentMethod": {
      "type": "singleUseToken",
      "token": "'$SINGLE_USE_TOKEN'"
    },
    "threeDSecure": {
      "serviceProvider": "gateway",
      "mpiReference": "'$MPI_REFERENCE'"
    }
  }'
```

### Handle the response

**201 Created** — payment accepted:
```json
{
  "paymentId": "<unique-payment-id>",
  "status": "...",
  "approvalCode": "..."
}
```

Persist `paymentId` — it is required for refunds, adjustments, disputes, and any subsequent operations on this transaction.

### Checkpoint

Does the Payments API return HTTP 201 with a `paymentId`? If not, work through the error taxonomy below.

---

## Error Taxonomy

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| 401 on MPI or Payment request | Token missing, expired, or wrong API key | Re-generate Bearer token; verify `x-api-key` header value is correct UAT API key |
| MPI GET returns an error | Wrong terminal ID or 3DS not enabled | Confirm terminal ID; confirm 3-D Secure is enabled on the terminal (contact Payroc Integrations) |
| Callback not received after MPI request | Callback URL not registered or not reachable | Verify the URL registered in Step 1 is publicly reachable; check server logs; confirm 3DS setup completed |
| `result: "D"` from callback | Cardholder authentication failed or not authenticated | Surface the decline to the user; do not post the payment |
| 400 on POST /v1/payments — field validation | Missing required field or wrong enum value | Check `errors[].parameter` to identify the failing field; read `references/api-schema.md` for the correct value |
| 400 — `idempotencyKeyMissing` | Missing `Idempotency-Key` header on POST | Add `Idempotency-Key: <uuid-v4>` to the payment POST |
| 400 — `channel` rejected | Wrong channel value | Use `"web"` for 3-D Secure e-commerce; read `references/api-schema.md` for the documented enum values |
| 400 — `threeDSecure` rejected | Wrong `serviceProvider` value or missing `mpiReference` | `serviceProvider` must be `"gateway"` when using Payroc's MPI; `mpiReference` must be the exact string from the callback |
| 400 — `paymentMethod.type` rejected | Wrong type value | Must be `"singleUseToken"`; read `references/api-schema.md` |
| 409 — duplicate `Idempotency-Key` | Same key reused for a different payment | Generate a fresh UUID for each new payment |
| 409 — `idempotencyKeyInUse` | Key already in use for a different payload | Generate a new UUID for the new submission |
| 500 | Server error | Retry with exponential backoff; surface `errors` array if present |

**Reading validation errors** — error responses use the **RFC 7807 problem-details envelope** (`type`,
`title`, `status`, `detail`, `instance`); Payroc **extends** it with an `errors` array. Each `errors[]`
item has a `parameter` (JSON path of the failing field), a `detail` (short reason), and a `message`
(human-readable explanation). Use `parameter` to map each error back to the request body field that failed.

---

## Third-Party 3-D Secure (informational)

If the developer is using an external 3-D Secure provider (not Payroc's MPI service), the `threeDSecure` object uses the `thirdParty` variant:

```json
{
  "threeDSecure": {
    "serviceProvider": "thirdParty",
    "eci": "fullyAuthenticated",
    "xid": "<transaction-id>",            // optional
    "cavv": "<cardholder-auth-value>",    // optional — only include if your 3DS provider gives you this value
    "dsTransactionId": "<ds-tx-id>"       // optional — only include if your 3DS provider gives you this value
  }
}
```

> **`cavv`, `xid`, and `dsTransactionId` are all optional.** Only include them if your third-party 3DS provider supplies the value. Do not send a placeholder string (e.g. `"<cardholder-auth-value>"`) for a field you don't have — omit the field entirely. Sending a non-empty placeholder will produce a 400.

> **`eci` enum trap — read this before writing the value.** The `eci` values for the `thirdParty` payment request field (`"fullyAuthenticated"`, `"attemptedAuthentication"`) are **completely different** from the MPI callback `eci` values (`"05"`, `"06"`, `"07"`). Do not copy the MPI callback value directly into the payment request. Read `references/api-schema.md` Enums section — `threeDSecure.eci (thirdParty variant)` — before emitting this value.

This skill focuses on the Payroc MPI (`serviceProvider: "gateway"`) path. If the developer is using a third-party 3DS provider, they should confirm the correct field mapping with that provider's documentation.

---

## Validation Checklist

- [ ] 3-D Secure is enabled on the terminal — confirmed with Payroc Integrations
- [ ] Callback URL registered with Payroc and reachable from the internet
- [ ] API key and terminal ID sourced from environment variables — never hardcoded
- [ ] Bearer token generated from identity service — never hardcoded
- [ ] Single-use token obtained via Hosted Fields or API tokenization
- [ ] MPI request uses `payments.uat.payroc.com` host (not `api.uat.payroc.com`)
- [ ] `orderId`, `amount`, and `currency` match between MPI request (Step 4) and payment request (Step 5)
- [ ] Callback handler checks `result` before proceeding — declines (`"D"`) are NOT submitted as payments
- [ ] `mpiReference` captured from callback and stored for use in payment request
- [ ] Payment request uses `api.uat.payroc.com` host (not `payments.uat.payroc.com`)
- [ ] `Idempotency-Key` header present and set to a UUID v4 on the payment POST
- [ ] `channel: "web"` in payment request
- [ ] `paymentMethod.type: "singleUseToken"` in payment request
- [ ] `threeDSecure.serviceProvider: "gateway"` in payment request (for Payroc MPI path)
- [ ] `paymentId` captured from payment response and stored
- [ ] UAT endpoints used (`*.uat.payroc.com`) — not production during testing

---

## Completion

Once all checklist items pass:

> **3-D Secure integration complete.** Here's what you've built:
>
> - **Authentication** — Bearer token generation from the Payroc identity service; credentials in env vars.
> - **Tokenization** — Card tokenized via [Hosted Fields / API tokenization].
> - **MPI authentication** — Card sent to Payroc's MPI service; callback handler processes the async result.
> - **Payment posting** — Payment submitted with `mpiReference` when authentication is approved.
> - **Validated in UAT** — End-to-end 3DS flow confirmed.
>
> **Before going live:** swap `*.uat.payroc.com` hosts for `*.payroc.com` (both `payments.payroc.com` and `api.payroc.com`), point credentials to production terminal and API key, and confirm 3-D Secure is enabled on the production terminal.

Offer next steps:
- **Credential-on-file / tokenization** — save the card for future merchant-initiated charges using `credentialOnFile` in the payment request
- **Recurring payments / subscriptions** — set up a payment plan for repeat charges
- **Refunds** — handle refund flows using the `paymentId` captured in this integration
