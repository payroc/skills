---
name: set-up-a-funding-recipient
description: >
  Guides developers through registering and creating a funding recipient via the Payroc
  Funding API (POST /v1/funding-recipients). Use this skill when the user wants to set up
  a funding recipient, create a new recipient entity for fund distribution, register a
  third-party to receive merchant settlement proceeds, implement dynamic funding, configure
  fund splitting or fund routing to a recipient, set up a payout recipient, create a
  funding account for a recipient, or work with the /v1/funding-recipients endpoint. Also
  use when the user asks about KYC requirements for a funding recipient, recipient approval
  status (approved/pending/rejected), owner or beneficial owner details for a funding
  recipient, or linking a bank account to a newly created funding recipient (including ACH
  routing and account numbers on the recipient creation request) — even if they don't use
  the word "skill" or "funding API" explicitly. Do NOT use for sending or disbursing
  funds to an existing recipient, viewing funding activity or reports, processing ACH
  payments unrelated to recipient setup, or onboarding a merchant processing account.
metadata:
  version: "0.2.1"
  category: funding
  status: draft
---

# Set Up a Funding Recipient

## Version check (run this first)

Before announcing anything or starting the flow, confirm this skill is current:

1. Read this skill's version from the `metadata.version` field in the frontmatter above.
2. Fetch the published copy and read its `metadata.version`:
   `https://raw.githubusercontent.com/payroc/skills/main/plugins/payroc/funding/skills/set-up-a-funding-recipient/SKILL.md`
3. Compare the two as semantic versions:
   - **This version >= published** → continue silently, no message. (A developer running an unreleased newer version is expected and fine.)
   - **This version < published** → tell the developer:
     > ⚠️ A newer version of this skill (v\<published\>) has been published — you're running v\<current\>. Upgrading is recommended for the best results.

     Then ask whether they'd like to continue with the current version or stop and upgrade first, and honour their answer.
   - **Couldn't fetch** (offline, network error, 404) → note briefly that the version couldn't be verified and continue.

---

## KYC validation in UAT

> If Payroc returns a recipient with `status: rejected` or stuck at `pending` even
> though the submitted data is correct, this is usually a UAT-environment KYC-simulation
> limitation rather than a problem with your request or this skill — contact the Payroc
> Integrations team if you need KYC simulation enabled for your UAT key. The skill's field
> names, enum values, and request/response schemas are derived directly from the Payroc
> OpenAPI specification and official documentation.

---

## What this skill builds

A **funding recipient** is a third-party entity that receives funds via Payroc's Dynamic Funding model.
Recipients cannot process card sales directly — they receive allocations from merchant settlement proceeds,
as defined by funding instructions.

Setting up a funding recipient involves three API operations:

1. **Create the recipient** — register the entity with Payroc (this skill's primary focus)
2. **Add owner information** — provide KYC identity data for beneficial owners
3. **Associate a funding account** — link the bank account that will receive funds

This skill covers all three, plus recipient retrieval and lifecycle management.

---

## Quick reference

```
POST   https://api.uat.payroc.com/v1/funding-recipients
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
| API schema reference | `references/api-schema.md` | **All** enum values, required fields, request/response schemas, error codes |
| Setup narrative guide | `references/set-up-a-funding-recipient-guide.md` | Process context, KYC rules, funding model overview, post-creation steps |
| Identity call reference | `references/identity-call.md` | Bearer token exchange — endpoint URL, headers, response shape |
| Error response format | `references/error-response-format.md` | Error envelope (RFC 7807) + Payroc errors[] + canonical error type catalog |

These are local snapshots, authoritative for this skill. Their source URLs and last-synced dates are
recorded in [`references/_sources.md`](references/_sources.md) — regenerate from there if they look stale.

---

## Core principles

1. **Read `references/api-schema.md` before answering any question involving enum values, field names,
   or request/response schemas** — whether you are writing code, reviewing submitted code, validating a
   payload, or answering a factual question about the API. This applies equally to codegen and dialog
   responses. Every field that accepts a fixed set of strings — `recipientType`, `fundingAccount.type`,
   `fundingAccount.use`, `contactMethod.type`, `identifier.type`, `paymentMethod.type`, `status` — is
   documented there. Do not emit verdicts or values from training-data memory. A plausible-sounding
   string that is not in the documented enum will produce a 400 error.
2. **Idempotency-Key on every POST.** The header value must be a UUID v4. This is required — omitting it
   causes a 400. Generate a fresh UUID for each distinct operation. When retrying the exact same
   submission after a failure, reuse the original UUID — the API will return the original response
   instead of creating a duplicate.
3. **Never hardcode credentials.** API keys must come from environment variables or a secrets manager.
4. **recipientId is an integer.** Do not treat it as a prefixed string (e.g. `FR-XXXX`) — it comes back
   as a plain integer in UAT and production.
5. **KYC status may be non-deterministic in UAT.** A `pending` or `rejected` status in the test
   environment does not necessarily indicate a problem with the submitted data.
6. **Diagnose before proceeding.** If a step fails, pause and work through the error taxonomy before
   continuing.

---

## Intake

**First, scan the codebase.** Look for:
- Server-side language and framework
- Existing HTTP client setup or credential configuration
- Any existing funding or payout-related code
- How environment variables are managed

Use what you find to pre-fill obvious answers. Then ask:

1. **What is the recipient entity type?** (e.g. sole proprietor, private corporation, LLC — this maps to
   a `recipientType` enum value; read `references/api-schema.md` for the full list)
2. **Do you have the recipient's EIN/SSN, legal name, address, and owner identity details?** (Required
   for KYC compliance — cannot be omitted or substituted with dummy data in production)
3. **Do you already have a UAT API key for the funding endpoints?** (Funding may require a separate
   credential from card payment terminals)

If any of the above is missing, warn without blocking — wire the code to read from environment variables
and continue.

---

## Prerequisites

These are needed to run and test the integration in UAT — not to write the code. If already present,
great. If not, don't stop — wire to env vars and keep building.

1. **API key** — provisioned by the Payroc Integrations team for UAT access. May be a different key
   from card-payment terminals. Store as `PAYROC_API_KEY`.
2. **Recipient data** — legal name, EIN/tax ID, physical address, and at least one owner's full KYC
   details (name, date of birth, national ID, address, contact).
3. **Bank account details** — ACH routing number and account number for the funding account.

**If anything is missing — warn, don't block:**

> ⚠️ I've wired this to read your API key from `PAYROC_API_KEY`. Funding recipient creation requires
> real KYC data (name, tax ID, owner identity) — you cannot use test data in production. Contact the
> Payroc Integrations team if you need a UAT API key that supports funding endpoints.

---

## Step 1 — Get a Bearer token

> Read `references/identity-call.md` before emitting any auth code. Do not guess the endpoint URL, header name, or response shape — use only what the reference documents.

Tokens expire after 3,600 seconds (1 hour). Exchange your API key once per session.

```bash
# Test / UAT
curl -X POST https://identity.uat.payroc.com/authorize \
  -H "x-api-key: $PAYROC_API_KEY"

# Production
curl -X POST https://identity.payroc.com/authorize \
  -H "x-api-key: $PAYROC_API_KEY"
```

Response:
```json
{
  "access_token": "eyJhbGc....",
  "expires_in": 3600,
  "token_type": "Bearer"
}
```

Use `Authorization: Bearer <access_token>` on every subsequent request.

### Checkpoint

Can the helper generate a Bearer token without error? If not, check the `x-api-key` header and confirm
the API key is correct for the UAT environment.

---

## Step 2 — Build the recipient request body

> **Read `references/api-schema.md` before writing the request body.** The enum values for
> `recipientType`, `fundingAccount.type`, `fundingAccount.use`, `contactMethod.type`, and
> `identifier.type` are all defined there. Do not emit any of these from training data — the
> reference is the contract.

The body has seven required top-level fields:

```json
{
  "recipientType": "<enum>",
  "taxId": "<EIN or SSN>",
  "doingBusinessAs": "<legal name>",
  "address": { ... },
  "contactMethods": [ ... ],
  "owners": [ ... ],
  "fundingAccounts": [ ... ]
}
```

### recipientType

Read the correct camelCase value from `references/api-schema.md`. The following are examples only — there are 9 values total in the spec:

- `privateCorporation` — private company
- `privateLlc` — private LLC
- `soleProprietor` — individual / sole trader
- `nonProfit` — non-profit organisation (note capital P)
- `privatePartnership`, `publicPartnership`, `publicCorporation`, `publicLlc`, `government` — others

**The full enum list is in `references/api-schema.md` — read it before emitting a value.** Do not use the short list above as your complete reference. A wrong casing (e.g. `private_llc`, `PrivateLLC`, `nonprofit`) will produce a 400 validation error.

### address

```json
{
  "address1": "100 Commerce St",
  "city": "Austin",
  "state": "TX",
  "country": "US",
  "postalCode": "78701"
}
```

`country` must be ISO 3166-1 alpha-2 (two-letter uppercase code, e.g. `"US"`).

### contactMethods

At least one `email` type is required:

```json
[
  { "type": "email", "value": "accounts@recipient.com" },
  { "type": "phone", "value": "5125550100" }
]
```

> **Phone/fax values must contain digits only** — no `+`, spaces, or punctuation (e.g. `5125550100`,
> not `+1 512 555 0100`).

Contact method type values come from `references/api-schema.md` — read them before emitting.

### owners

Each owner provides the KYC identity data. At least one owner is required. Exactly one owner must have
`relationship.isControlProng: true`.

```json
[
  {
    "firstName": "Jane",
    "lastName": "Doe",
    "dateOfBirth": "1980-04-15",
    "address": {
      "address1": "42 Oak Lane",
      "city": "Austin",
      "state": "TX",
      "country": "US",
      "postalCode": "78702"
    },
    "identifiers": [
      { "type": "nationalId", "value": "123-45-6789" }
    ],
    "contactMethods": [
      { "type": "email", "value": "jane.doe@example.com" }
    ],
    "relationship": {
      "isControlProng": true,
      "equityPercentage": 100,
      "title": "CEO",
      "isAuthorizedSignatory": true
    }
  }
]
```

> **Caution:** Setting both `isControlProng: true` and `isAuthorizedSignatory: true` on the same owner
> in a single request has not been confirmed to work in this API. If you receive a validation error on
> submission, try separating the control prong and the authorized signatory across different owner entries
> (i.e. set `isAuthorizedSignatory: true` on a different owner than the control prong).

Key rules:
- `dateOfBirth` must be `YYYY-MM-DD` format
- `identifiers[].type` must be `"nationalId"` — read from `references/api-schema.md`
- **Exactly one** owner must have `isControlProng: true` — multiple control prongs are rejected
- **`isControlProng` is required on every owner object** (schema marks it Yes). Set it to `true` on the control prong and `false` on all other owners — do not omit the field.
- Each owner needs at least one email in their `contactMethods`

### fundingAccounts

```json
[
  {
    "type": "checking",
    "use": "credit",
    "nameOnAccount": "Jane Doe",
    "paymentMethods": [
      {
        "type": "ach",
        "value": {
          "routingNumber": "021000021",
          "accountNumber": "987654321"
        }
      }
    ]
  }
]
```

> **`use` must be `"credit"` for funding recipients.** Do not use `"debit"` or `"creditAndDebit"` —
> those are for accounts that initiate outbound transfers. Read the `use` enum values from
> `references/api-schema.md` before emitting.

`type` values (`checking`, `savings`, `generalLedger`) — read from `references/api-schema.md`.

---

## Step 3 — Send the create request

Generate a fresh UUID v4 for `Idempotency-Key`. On retry of the *same* submission (network failure,
timeout), reuse the same key — the API returns the original response instead of creating a duplicate.
On a genuinely new submission, generate a new UUID.

```bash
curl -X POST https://api.uat.payroc.com/v1/funding-recipients \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Idempotency-Key: $(uuidgen | tr '[:upper:]' '[:lower:]')" \
  -H "Content-Type: application/json" \
  -d @recipient-payload.json
```

---

## Step 4 — Handle the response

**201 Created** — recipient created:

```json
{
  "recipientId": 9901,
  "status": "pending",
  "createdDate": "2026-06-22T10:00:00Z",
  "lastModifiedDate": "2026-06-22T10:00:00Z",
  "recipientType": "privateCorporation",
  "taxId": "12-3456789",
  "doingBusinessAs": "Acme Supplies LLC",
  "address": { ... },
  "contactMethods": [ ... ],
  "owners": [
    {
      "ownerId": 1234,
      "links": [ { "rel": "self", "href": "..." } ]
    }
  ],
  "fundingAccounts": [
    {
      "fundingAccountId": 5678,
      "status": "pending",
      "links": [ { "rel": "self", "href": "..." } ]
    }
  ]
}
```

**Persist immediately:**
- `recipientId` — integer, required for all subsequent operations (retrieve, update, delete, fund)
- Each `fundingAccountId` — needed when configuring funding instructions
- Each `ownerId` — needed if updating or managing individual owners

**Initial status:** The `status` field reflects the KYC outcome:
- `pending` — KYC review in progress (most common initial state)
- `approved` — KYC passed immediately — recipient is ready to receive funds
- `rejected` — KYC failed — contact Payroc support before retrying

**Bank account masking:** `routingNumber` and `accountNumber` in the response are partially masked
(shown as asterisks for most digits). This is expected — do not treat it as an error.

---

## Step 5 — Monitor recipient status

If the initial response is `status: pending`, poll the retrieve endpoint until the status resolves
or configure webhooks for event-based notification.

```bash
curl https://api.uat.payroc.com/v1/funding-recipients/{recipientId} \
  -H "Authorization: Bearer $ACCESS_TOKEN"
```

| Status | Meaning | Next action |
| --- | --- | --- |
| `pending` | KYC in progress | Wait and poll, or use webhooks |
| `approved` | Ready to receive funds | Proceed to funding instructions |
| `rejected` | Failed KYC | Contact Payroc support — do not resubmit blindly |
| `hold` | Flagged by Risk team | Contact Payroc support |

In UAT, `status` may remain `pending` or return `rejected` regardless of submitted data — see the
KYC validation note at the top of this skill.

---

## Step 6 — Handle errors

Errors follow RFC 7807 Problem Details — the envelope (`type`, `title`, `status`, `detail`, `instance`)
is the RFC standard; the `errors[]` array is a Payroc extension. Each item in `errors[]` has:
- `parameter` — JSON path of the failing field (use this to locate and fix the problem)
- `detail` — short reason (distinct from the top-level `detail`)
- `message` — human-readable explanation

| HTTP status | Scenario | Action |
| --- | --- | --- |
| 400 validation | Field issues | Fix each field in `errors[].parameter`; **generate a new UUID v4 for `Idempotency-Key`** — a corrected payload is a new submission. Reusing the same key after a validation failure returns the cached error response instead of processing your fix. |
| 400 `idempotencyKeyMissing` | Missing header | Add `Idempotency-Key: <uuid-v4>` header to every POST. For the first attempt: generate a fresh UUID v4. When retrying the *same* failed submission: reuse the UUID from that attempt — the API returns the original response instead of creating a duplicate. Generate a new UUID only for a genuinely new (different) submission. |
| 401 | Token expired or invalid | Re-authenticate and get a fresh Bearer token |
| 403 | Insufficient permissions | Check API key scope; contact Payroc Integrations team |
| 404 | Recipient not found | Verify the `recipientId` — it is a plain integer (e.g. `9901`), not a prefixed string |
| 406 | Not acceptable format | Check `Content-Type: application/json` header is set |
| 409 `resourceAlreadyExists` | Duplicate recipient | Retrieve the existing recipient using the HATEOAS link in the response |
| 500 | Server error | Retry with exponential back-off; surface `errors[]` array if present |

**Reading validation errors:**
```json
{
  "type": "https://docs.payroc.com/api/errors#bad-request",
  "title": "Bad request",
  "status": 400,
  "detail": "One or more validation errors occurred, see error section for more info",
  "instance": "https://api.uat.payroc.com/v1/funding-recipients",
  "errors": [
    {
      "parameter": "owners[0].identifiers",
      "detail": "Required field not populated",
      "message": "'identifiers' must not be empty."
    }
  ]
}
```

Fix every field listed in `errors[].parameter` in a single corrected payload and resubmit.

---

## Common pitfalls

- **Wrong `recipientType` casing**: Enum values are camelCase — read from `references/api-schema.md`.
  `private_llc`, `PrivateLLC`, and `private-llc` all produce 400 errors.
- **Wrong `fundingAccount.use` value**: Must be `"credit"` for recipients. Using `"debit"` or
  `"creditAndDebit"` will be rejected.
- **Multiple control prongs**: Only one owner can have `isControlProng: true`. Having two or more will
  produce a validation error.
- **Omitting `isControlProng` on secondary owners**: The `isControlProng` field is required on every owner
  object (not just the control prong). Set it to `false` on non-controlling owners — do not omit the field.
- **Missing nationalId identifier**: Each owner must have at least one `identifier` with `type:
  "nationalId"`. Omitting `identifiers` entirely causes a 400.
- **Phone digits only**: `phone`, `mobile`, and `fax` values must be digits only — no `+`, spaces,
  parentheses, or hyphens.
- **Missing email contact method**: Both the recipient's `contactMethods` and each owner's
  `contactMethods` must include at least one `email` type entry.
- **Missing idempotency key**: All POST requests require `Idempotency-Key: <uuid-v4>` or you get a 400.
- **recipientId is an integer**: Treat it as a plain integer, not a prefixed string. In UAT it is a
  plain number (e.g. `9901`).

---

## Full field reference

Read `references/api-schema.md` for:
- All enum values (`recipientType`, `fundingAccount.type`, `fundingAccount.use`, `contactMethod.type`,
  `identifier.type`, `paymentMethod.type`, `status`)
- Complete nested object schemas (address, owner, relationship, funding account, ACH method)
- Response schema details (field types, masking behaviour)
- Retrieve, List, Update, and Delete endpoint schemas

Read `references/set-up-a-funding-recipient-guide.md` for:
- Dynamic funding model context (how recipients fit into the broader funding flow)
- KYC process and status lifecycle
- Post-creation steps (funding instructions, funding activity)
