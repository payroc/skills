---
name: create-merchant-platform
description: >
  Guides developers through creating a new merchant platform record via the Payroc Boarding API
  (POST /v1/merchant-platforms). Use this skill when the user wants to board a new merchant,
  onboard a merchant, register a merchant with Payroc, create a merchant account or merchant
  platform, implement the boarding flow, or work with the /v1/merchant-platforms endpoint.
  Also use when the user is building a boarding integration, asking how to submit merchant
  data to Payroc, generating a boarding request payload, asking about MID provisioning,
  merchant registration, owner/control-prong requirements, pricing agreements, or signature
  capture during boarding — even if they don't use the word "skill" or "boarding API" explicitly.
metadata:
  version: "0.1.0"
  category: boarding
  status: draft
---

# Create Merchant Platform

## Version check (run this first)

Before announcing anything or starting the flow, confirm this skill is current:

1. Read this skill's version from the `metadata.version` field in the frontmatter above.
2. Fetch the published copy and read its `metadata.version`:
   `https://raw.githubusercontent.com/payroc/skills/main/plugins/payroc/boarding/skills/create-merchant-platform/SKILL.md`
3. Compare the two as semantic versions:
   - **This version >= published** → continue silently, no message. (A developer running an unreleased newer version is expected and fine.)
   - **This version < published** → tell the developer:
     > ⚠️ A newer version of this skill (v\<published\>) has been published — you're running v\<current\>. Upgrading is recommended for the best results.

     Then ask whether they'd like to continue with the current version or stop and upgrade first, and honour their answer.
   - **Couldn't fetch** (offline, network error, 404) → note briefly that the version couldn't be verified and continue.

---

`POST https://api.payroc.com/v1/merchant-platforms` initiates the boarding process for a new
merchant. Payroc reviews the submission and assigns a `merchantPlatformId` and
`processingAccountId` — save both, as they're required for terminal ordering and all follow-on
boarding operations.

For the complete field reference and an annotated example request, read
`references/api-schema.md` (load it when you need enum values, nested field details, or a
full worked example).

---

## Quick reference

```
POST  https://api.payroc.com/v1/merchant-platforms
Authorization:   Bearer <token>
Idempotency-Key: <uuid-v4>
Content-Type:    application/json
```

---

## Step 1 — Get a bearer token

Tokens expire in ~1 hour. Exchange your API key before each session (or refresh proactively).

```bash
# Test / sandbox
curl -X POST https://identity.uat.payroc.com/authorize \
  -H "x-api-key: YOUR_API_KEY"

# Production
curl -X POST https://identity.payroc.com/authorize \
  -H "x-api-key: YOUR_API_KEY"
```

Response:
```json
{
  "access_token": "eyJhbGc....",
  "expires_in": 3600,
  "token_type": "Bearer"
}
```

Use `Authorization: Bearer <access_token>` on every subsequent request. The Payroc SDKs
(TypeScript, Python, C#, PHP, Go, Java, Ruby) handle token exchange automatically — see
https://docs.payroc.com/api/payroc-sd-ks-beta for installation and SDK usage.

---

## Step 2 — Build the request body

The body has two required top-level keys:

```json
{
  "business": { ... },
  "processingAccounts": [ { ... } ],
  "metadata": {}
}
```

`metadata` is optional — use it to attach your own key/value pairs (e.g. your internal
customer ID) that Payroc echoes back in responses.

### Business object

Describes the legal entity. Required fields:

| Field | Type | Notes |
|-------|------|-------|
| `name` | string | Legal business name |
| `taxId` | string | EIN (US) |
| `organizationType` | enum | See schema reference for values |
| `countryOfOperation` | string | `"US"` |
| `addresses` | array | Must include one entry with `"type": "legalAddress"` |
| `contactMethods` | array | Must include at least one `"type": "email"` entry |

### Processing accounts

Each element provisions one MID. The array must have at least one entry. Key required fields
per account:

| Field | Notes |
|-------|-------|
| `doingBusinessAs` | Trading/DBA name |
| `businessType` | `retail`, `restaurant`, `internet`, `moto`, `lodging`, `notForProfit` |
| `categoryCode` | 4-digit MCC integer |
| `merchandiseOrServiceSold` | Plain-English description |
| `businessStartDate` | `YYYY-MM-DD` |
| `timezone` | e.g. `"America/New_York"` — see schema reference for full list |
| `address` | Physical business address |
| `contactMethods` | Email required |
| `owners` | See ownership rules below |
| `processing` | Transaction volumes and card acceptance |
| `funding` | Bank account and settlement schedule |
| `pricing` | Pricing intent ID or full pricing agreement |
| `signature` | How the merchant signs the contract |

**Ownership rules** — every processing account needs:
- At least one owner with `relationship.isControlProng: true`
- At least one owner with `relationship.isAuthorizedSignatory: true`

The same person can be both. Each owner also needs `firstName`, `lastName`, `dateOfBirth`
(`YYYY-MM-DD`), `address`, `identifiers` (national ID / SSN), and an email in
`contactMethods`.

**Pricing shortcut** — if you have a pricing template, use:
```json
{ "type": "intent", "pricingIntentId": "<id>" }
```
Otherwise provide the full `agreement` object (see schema reference for structure).

**Signature** — send a signing link by email with:
```json
{ "type": "requestedViaEmail" }
```
Or use `"requestedViaDirectLink"` with a HATEOAS link object if you're managing the redirect.

**Volume breakdown** — `processing.volumeBreakdown.cardPresent + mailOrTelephone + ecommerce`
must sum to exactly 100.

**Amounts are in cents** — `transactionAmounts.average: 5000` means $50.00.

---

## Step 3 — Send the request

Always generate a fresh UUID v4 for `Idempotency-Key`. On retry of the *same* submission,
reuse the same key — the API returns the original response instead of creating a duplicate.
On a genuinely new submission, generate a new UUID.

```bash
curl -X POST https://api.payroc.com/v1/merchant-platforms \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Idempotency-Key: $(uuidgen | tr '[:upper:]' '[:lower:]')" \
  -H "Content-Type: application/json" \
  -d @merchant-payload.json
```

---

## Step 4 — Handle the response

**201 Created** — boarding submission accepted:
```json
{
  "merchantPlatformId": "MP-XXXX",
  "processingAccounts": [
    {
      "processingAccountId": "PA-XXXX",
      "status": "pending"
    }
  ],
  "links": [ ... ]
}
```

Persist `merchantPlatformId` and each `processingAccountId` immediately. The `status` is
`pending` while Payroc reviews the application; poll or use webhooks to detect status changes.

---

## Step 5 — Handle errors

Errors follow [RFC 7807](https://datatracker.ietf.org/doc/html/rfc7807) and include a `type`
URL linking to Payroc docs, plus an `errors` array for validation failures.

| Status | Scenario | Action |
|--------|----------|--------|
| 400 validation | Field issues | Fix each field in `errors[].parameter`; resubmit with same idempotency key |
| 400 `idempotencyKeyMissing` | Missing header | Add `Idempotency-Key: <uuid-v4>` to the request |
| 401 | Token expired or invalid | Re-authenticate and get a fresh bearer token |
| 403 | Insufficient permissions | Check API key scope; contact Payroc support |
| 409 `resourceAlreadyExists` | Duplicate merchant | Check if merchant was already boarded; retrieve existing record |
| 409 `idempotencyKeyInUse` | Key reused with different payload | Generate a new UUID for the new submission |
| 409 `taxIdInUse` | Merchant with that Tax ID exists | Retrieve existing merchant platform instead |
| 500 | Server error | Retry with exponential backoff; surface `errors` array if present |

**Reading validation errors:**
```json
{
  "status": 400,
  "title": "Bad request",
  "errors": [
    {
      "parameter": "processingAccounts[0].owners",
      "issue": "noControlProng",
      "message": "At least one owner must be designated as the control prong"
    },
    {
      "parameter": "processingAccounts[0].processing.volumeBreakdown",
      "issue": "invalidValue",
      "message": "Volume percentages must sum to 100"
    }
  ]
}
```

Each `parameter` path maps exactly to the request body field that failed. Fix all flagged
fields in a single corrected payload and resubmit.

---

## Common pitfalls

- **No control prong / authorized signatory**: Both roles are required in every processing account's `owners` array — one person can hold both
- **Volume breakdown doesn't sum to 100**: `cardPresent + mailOrTelephone + ecommerce` must equal exactly 100
- **Amounts in cents**: All monetary values (`transactionAmounts`, `monthlyAmounts`, `acceleratedFundingFee`) are integers in cents
- **Date format**: `dateOfBirth` and `businessStartDate` must be `YYYY-MM-DD`
- **Missing idempotency key**: All POST requests require `Idempotency-Key` or you get a 400
- **Reusing a key for a different payload**: Each unique submission needs its own UUID

---

## Full field reference

Read `references/api-schema.md` for:
- All enum values (organizationType, businessType, timezone, fundingSchedule, etc.)
- Complete nested object schemas (owners, processing, funding, pricing, signature)
- An annotated end-to-end example request body
