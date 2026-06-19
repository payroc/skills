---
name: create-pricing-intent
description: >
  Guides developers through creating and managing pricing intents — reusable Merchant Processing
  Agreement (MPA) fee templates — via the Payroc Boarding API (POST/GET/PUT/PATCH/DELETE
  /v1/pricing-intents). Use this skill whenever the user wants to: create or reuse a pricing
  template / fee schedule across many merchants; choose a pricing program (interchange plus,
  interchange plus plus, tiered, flat rate, consumer choice / surcharge / cash discount, reward pay
  choice); define processor, gateway, base, or ACH fees (transaction or discount rates, gateway
  monthly/setup/per-transaction fees, annual, PCI non-compliance, or chargeback fees); build, fix
  (including 400 validation errors), update, replace, retrieve, list, or delete a
  /v1/pricing-intents request; or obtain a pricingIntentId to assign to a processing account during
  boarding — even if they don't say "skill" or "pricing intent" explicitly (for example, they
  describe reusing one fee structure for many merchants). A pricing intent is a fee *template* and
  never takes, authorises, captures, or refunds money. Do NOT use this skill for taking,
  authorising, or refunding payments or transactions — some gateways call that a "payment intent",
  but Payroc handles it via its separate transactions/payments API — nor for boarding a merchant
  end-to-end or adding processing accounts (use create-merchant-platform), nor for general merchant
  or transaction management. If the user says "payment intent" but clearly wants a reusable fee
  template, use this skill and confirm.
metadata:
  version: "0.3.4"
  category: boarding
  status: draft
---

# Create Pricing Intent

## Version check (run this first)

Before announcing anything or starting the flow, confirm this skill is current:

1. Read this skill's version from the `metadata.version` field in the frontmatter above.
2. Fetch the published copy and read its `metadata.version`:
   `https://raw.githubusercontent.com/payroc/skills/main/plugins/payroc/boarding/skills/create-pricing-intent/SKILL.md`
3. Compare the two as semantic versions:
   - **This version >= published** → continue silently, no message. (A developer running an unreleased newer version is expected and fine.)
   - **This version < published** → tell the developer:
     > ⚠️ A newer version of this skill (v\<published\>) has been published — you're running v\<current\>. Upgrading is recommended for the best results.

     Then ask whether they'd like to continue with the current version or stop and upgrade first, and honour their answer.
   - **Couldn't fetch** (offline, network error, 404) → note briefly that the version couldn't be verified and continue.

---

A **pricing intent** is a reusable Merchant Processing Agreement (MPA) template. You define the fees
once, Payroc reviews and approves it, and you then assign its `id` to processing accounts during
boarding — one short reference replaces a deeply nested pricing agreement.

`POST https://api.payroc.com/v1/pricing-intents` creates the template. Payroc returns an `id` and a
`status` of `pendingReview`; once `active`, you can reference it from
[`create-merchant-platform`](../create-merchant-platform/SKILL.md) (see "Using the ID" below).

> **A pricing intent is not a "payment intent."** A pricing *intent* is a reusable **fee template**
> used during boarding — it does not take, authorise, or capture any money. Some other gateways
> (e.g. Stripe) use "payment intent" for a transaction/authorisation object; Payroc has no such
> endpoint (payments live under the separate transactions API). If the developer says "payment
> intent," or seems to want to **charge a card or take a payment** rather than define fees, pause and
> confirm which they mean before building anything — if they want to move money, point them to the
> payments/transaction APIs, not this skill.

> **Pricing intents are optional.** `create-merchant-platform` accepts either
> `pricing.type: "intent"` (a `pricingIntentId` reference) **or** `pricing.type: "agreement"` (the
> full fee object inline). Use a pricing intent when you board many merchants on the same fee
> structure; skip it for a one-off agreement.

For the complete field reference — every enum, the per-plan `fees` shapes, and a full worked
example — read `references/api-schema.md`. Load it whenever you need enum values, nested field
details, or units. **Emit enum values and field names from that reference, not from memory.**

---

## How this works

This skill is an **interview, not a form to fill in**. The developer describes their pricing in
plain business terms — *"interchange plus, 0.25% + 10¢ on Mastercard/Visa/Discover, $99 annual fee,
$25/month gateway"* — and the skill translates that into the correct nested, polymorphic JSON body.
Don't ask the developer to hand over a complete JSON structure, and don't dump a blank template at
them: collect the values conversationally (start with the `planType` in Step 2), then assemble the
request.

If the developer *does* paste a full or partial JSON body, take it as-is and fill the gaps — validate
it against `references/api-schema.md` and ask only for what's missing.

---

## Quick reference

```
Base URL (test):  https://api.uat.payroc.com/v1
Base URL (prod):  https://api.payroc.com/v1

GET    /pricing-intents                     # list (paginated)
POST   /pricing-intents                     # create            (Idempotency-Key required)
GET    /pricing-intents/{pricingIntentId}   # retrieve
PUT    /pricing-intents/{pricingIntentId}   # full replace      -> 204 No Content
PATCH  /pricing-intents/{pricingIntentId}   # JSON Patch (RFC 6902, Idempotency-Key required)
DELETE /pricing-intents/{pricingIntentId}   # delete            -> 204 No Content

Authorization:   Bearer <token>     (all operations)
Idempotency-Key: <uuid-v4>          (POST and PATCH only)
Content-Type:    application/json    (POST, PUT, PATCH)
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

## Step 2 — Choose a pricing program

The most consequential decision is `processor.card.planType` — it determines the shape of the
`fees` object. Pick one:

| `planType` | Pricing model | Use when |
|------------|---------------|----------|
| `interchangePlus` | Pass-through interchange + a fixed markup | Transparent cost-plus; most common |
| `interchangePlusPlus` | Interchange + markup, split by qualified/mid/non-qualified | Cost-plus with rate buckets |
| `tiered3` | 3 tiers: qualified / mid-qualified / non-qualified | Simple tiered pricing |
| `tiered4` | 3 tiers + premium | Tiered with a premium-card bucket |
| `tiered6` | Premium + regulated / unregulated debit buckets | Granular tiered pricing |
| `flatRate` | One flat % + per-transaction fee | Simple, predictable pricing |
| `consumerChoice` | Monthly subscription + surcharge/cash-discount on non-cash | Surcharging / cash-discount programs |
| `rewardPayChoice` | Subscription + separate debit & credit handling | Reward-card differentiation |

Read the matching subsection of `references/api-schema.md` for the exact `fees` fields that variant
requires before building the body. The `planType` discriminator value must come from the reference.

---

## Step 3 — Build the request body

Four top-level keys are **required**: `key`, `country`, `version`, `base`. `processor`, `gateway`,
`services`, and `metadata` are optional (but you'll almost always include `processor` and `gateway`).

```json
{
  "key": "RETAIL-STANDARD-2026",
  "country": "US",
  "version": "5.2",
  "base": { ... },
  "processor": { "card": { "planType": "...", "fees": { ... } }, "ach": { ... } },
  "gateway": { "fees": { ... } },
  "services": [ ... ],
  "metadata": {}
}
```

Key rules:

- **`key`** is your own identifier for the template (your records), distinct from the `id` Payroc
  assigns. It is required.
- **`country`** accepts only `US`; **`version`** accepts only `5.2`.
- **All monetary amounts are in cents** — `transaction: 10` is $0.10, `monthly: 2500` is $25.00.
- **Percentages** (`volume`, discount rates) are numbers up to 2 decimal places — `0.25` means
  0.25%.
- **`base`** requires all seven of `addressVerification`, `annualFee` (an object with its own
  required `amount`), `regulatoryAssistanceProgram`, `merchantAdvantage`, `maintenance`, `minimum`,
  and `batch` — **every key must be present with a numeric value**, or you get a 400. The OpenAPI
  spec marks `addressVerification`, `regulatoryAssistanceProgram`, and `merchantAdvantage` as
  nullable, but **the live UAT API rejects `null` for all three** (`"must not be empty"`, verified
  2026-06-19) — so send a number, and use `0` when the merchant isn't charged for one. Don't drop
  the key either; an omitted required key also fails validation. Optional fees (`pciNonCompliance`,
  `chargeback`, etc.) have server defaults — see the reference.
- **`processor.card.fees`** shape varies by `planType` (see Step 2 and the reference). For
  `interchangePlus`, `fees.mastercardVisaDiscover` is required.
- **`gateway.fees`** requires `monthly`, `setup`, `perTransaction`, and `perDeviceMonthly`.
- **ACH-only templates:** `processor.card` is optional — if the merchant only processes ACH, omit
  `card` entirely and send just `processor.ach` (its `fees` object has its own required keys; see
  the reference). `gateway` is optional too: omit the whole object rather than sending zeroed
  gateway fees when there's no gateway. `base` is still required even on an ACH-only template.

Minimal `interchangePlus` example:

```json
{
  "key": "RETAIL-STANDARD-2026",
  "country": "US",
  "version": "5.2",
  "base": {
    "addressVerification": 10,
    "annualFee": { "amount": 9900, "billInMonth": "december" },
    "regulatoryAssistanceProgram": 0,
    "merchantAdvantage": 0,
    "maintenance": 995,
    "minimum": 2500,
    "batch": 25
  },
  "processor": {
    "card": {
      "planType": "interchangePlus",
      "fees": {
        "mastercardVisaDiscover": { "volume": 0.25, "transaction": 10 },
        "amex": { "type": "optBlue", "volume": 0.30, "transaction": 10 }
      }
    }
  },
  "gateway": {
    "fees": { "monthly": 2500, "setup": 0, "perTransaction": 10, "perDeviceMonthly": 0 }
  }
}
```

Minimal `flatRate` example — note the card `fees` use `standardCards` (there is **no**
`mastercardVisaDiscover`), `amex` here only supports the `direct` variant, and the spec-nullable
`base` fields are sent as `0` (UAT rejects `null`):

```json
{
  "key": "SOFTWARE-SUBS-FLATRATE-2026",
  "country": "US",
  "version": "5.2",
  "base": {
    "addressVerification": 0,
    "annualFee": { "amount": 0, "billInMonth": "december" },
    "regulatoryAssistanceProgram": 0,
    "merchantAdvantage": 0,
    "maintenance": 0,
    "minimum": 0,
    "batch": 0
  },
  "processor": {
    "card": {
      "planType": "flatRate",
      "fees": {
        "standardCards": { "volume": 2.90, "transaction": 30 }
      }
    }
  },
  "gateway": {
    "fees": { "monthly": 0, "setup": 0, "perTransaction": 0, "perDeviceMonthly": 0 }
  }
}
```

For any other `planType`, read its subsection in `references/api-schema.md` for the exact `fees`
shape rather than guessing — only `interchangePlus` uses a flat `mastercardVisaDiscover`, the tiered
plans use `qualRates`-style objects, and the subscription plans (`consumerChoice`, `rewardPayChoice`)
use a `monthlySubscription` shape.

### Suggested starting values

The spec defines **defaults** for some `base` fees — use these as starting points if the developer
doesn't specify them (all in cents):

| Field | Default |
|-------|---------|
| `base.pciNonCompliance` | `7495` (monthly) |
| `base.voiceAuthorization` | `95` |
| `base.chargeback` | `2500` |
| `base.retrieval` | `1500` |
| `base.earlyTermination` | `57500` |
| `base.annualFee.billInMonth` | `december` |
| `base.platinumSecurity.amount` | `1295` monthly / `15540` annual |
| `rewardPayChoice` credit `cardChargePercentage` | `3` |
| `rewardPayChoice` credit `merchantChargePercentage` | `0.9` |

**The negotiable rates have no API-enforced range and no documented "typical" value** — the markup
`volume` percentages and per-`transaction` fees are commercially negotiated per merchant. Don't
invent a likely range or suggest a "normal" rate; ask the developer for the agreed figure. (These
defaults are the only value guidance the spec provides — see `references/api-schema.md`.)

---

## Step 4 — Create the pricing intent (POST)

Always generate a fresh UUID v4 for `Idempotency-Key`. On retry of the *same* submission, reuse the
same key — the API returns the original response instead of creating a duplicate. On a genuinely new
submission, generate a new UUID.

```bash
curl -X POST https://api.payroc.com/v1/pricing-intents \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Idempotency-Key: $(uuidgen | tr '[:upper:]' '[:lower:]')" \
  -H "Content-Type: application/json" \
  -d @pricing-intent.json
```

**201 Created** — the intent is created and waiting for approval:
```json
{
  "id": "PI-XXXX",
  "key": "RETAIL-STANDARD-2026",
  "status": "pendingReview",
  "createdDate": "2026-06-16T12:00:00Z",
  "base": { ... },
  "processor": { ... }
}
```

Persist `id` immediately. The `status` is `pendingReview` until Payroc reviews it; it becomes
`active` (approved) or `rejected`. You can only assign an intent to a merchant once it's `active`.

**IDs are opaque.** The `PI-XXXX` form used in these examples is for readability only. Treat the
`id` as an opaque string whose format is not guaranteed and varies by environment — in UAT it
comes back as a plain integer (e.g. `5722`). Don't validate or parse it against a `PREFIX-XXXX`
pattern.

**Offer the assembled body back to the developer.** After a successful create, give them the final
request JSON you built (or write it to a file). It's worth keeping for audit, and it's the starting
point for later changes — re-submit the whole thing via `PUT` (full replace) or adapt a copy via
`PATCH` (see Step 6).

---

## Step 5 — Read and list (GET)

Retrieve one by ID:
```bash
curl https://api.payroc.com/v1/pricing-intents/PI-XXXX \
  -H "Authorization: Bearer $ACCESS_TOKEN"
```

List (paginated — `limit`, and `before`/`after` cursors, which are mutually exclusive):
```bash
curl "https://api.payroc.com/v1/pricing-intents?limit=20" \
  -H "Authorization: Bearer $ACCESS_TOKEN"
```

The list response wraps results in `{ limit, count, hasMore, links, data: [ ... ] }`. Use `links`
or the `after` cursor to page forward. If you don't have an `id`, use list to find the intent.

---

## Step 6 — Update (PUT vs PATCH)

Updating a pricing intent does **not** change merchants you've already onboarded. The docs do
**not** specify whether an update sends the intent itself back to `pendingReview` for re-approval —
so don't assume a re-review (or assume there isn't one) in your answer. If a workflow depends on the
post-update status, re-GET the intent and read its `status` rather than guessing.

**PUT — full replace.** Send a complete `pricingIntent` body (same shape as create). Returns
`204 No Content`. No idempotency key.
```bash
curl -X PUT https://api.payroc.com/v1/pricing-intents/PI-XXXX \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d @full-pricing-intent.json
```

**PATCH — partial update via [RFC 6902](https://datatracker.ietf.org/doc/html/rfc6902) JSON Patch.**
The body is an **array of operations**, not a partial object. Requires `Idempotency-Key`. Returns
`200` with the updated intent.
```bash
curl -X PATCH https://api.payroc.com/v1/pricing-intents/PI-XXXX \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Idempotency-Key: $(uuidgen | tr '[:upper:]' '[:lower:]')" \
  -H "Content-Type: application/json" \
  -d '[ { "op": "replace", "path": "/gateway/fees/monthly", "value": 1995 } ]'
```

**Safe single-field patch.** RFC 6902 lets you prepend a `test` op that asserts the current value;
if the assertion fails the whole patch is rejected, so you never overwrite a value that isn't what
you expected (useful against concurrent edits). Recommend this idiom when changing one fee:

```json
[
  { "op": "test",    "path": "/gateway/fees/monthly", "value": 2500 },
  { "op": "replace", "path": "/gateway/fees/monthly", "value": 1995 }
]
```

Use PATCH for targeted changes (a single fee), PUT when you're replacing the whole template. You can
update fees, the custom `key`/name, and the `services` array.

---

## Step 7 — Delete (DELETE)

```bash
curl -X DELETE https://api.payroc.com/v1/pricing-intents/PI-XXXX \
  -H "Authorization: Bearer $ACCESS_TOKEN"
```

Returns `204 No Content`. **Deletion is permanent** — you can't recover the intent or assign it to
future boarding applications afterwards.

---

## Step 8 — Handle errors

Errors use the [RFC 7807](https://datatracker.ietf.org/doc/html/rfc7807) problem-details format as
the **envelope**: the top-level `type`, `title`, `status`, `detail`, and `instance` are the standard
RFC members. Payroc **extends** the envelope with an `errors` array — the array and its contents are
Payroc's own, *not* defined by RFC 7807. **Each `errors[]` item carries `parameter`, `detail`, and
`message`** — `parameter` is the JSON path of the field that failed (e.g. `country`,
`base.annualFee.amount`); `detail` is a short reason (`"Invalid format"`, `"Required field not
populated"`) and is distinct from the top-level RFC `detail`; `message` is the human-readable
explanation. Use `parameter` to map each error straight back to the field in your request body. (See
[`_shared/error-response-format.md`](../../../_shared/error-response-format.md) for the cross-skill
standard.)

> The published OpenAPI spec only documents `message` on each item, but the live API also returns
> `parameter` and `detail` (verified against UAT, 2026-06-16). Read `parameter` — it's the fastest
> way to find what to fix.

| Status | Scenario | Action |
|--------|----------|--------|
| 400 | Validation error | Use each `errors[].parameter` to find the field, `message`/`detail` for why; fix the body and resubmit (reuse the same idempotency key) |
| 401 | Token expired or invalid | Re-authenticate and get a fresh bearer token |
| 403 | Insufficient permissions | Check API key scope; `instance`/`resource` name what was attempted |
| 404 | Pricing intent not found | Verify the `pricingIntentId`; use list to find it |
| 406 | Not acceptable | Check `Content-Type` / `Accept` headers and body shape |
| 409 | Conflict — idempotency key reused with a *changed* body | Don't reflexively re-POST with a new key; see the note below — you may already have created the intent |
| 500 | Server error | Retry with exponential backoff; surface `errors` if present |

> **A 409 on create needs care — you may already have created the intent.** A 409 means an
> `Idempotency-Key` was reused with a *different* body (classically: you fixed a typo and
> resubmitted with the original key). Before you resubmit, work out whether the **first** POST
> actually succeeded — because the fix is different in each case:
>
> - **It succeeded** (you got a `201`/`id`, or the intent shows up in `GET /pricing-intents`) → the
>   intent already exists with the old values. Correct it **in place** with `PATCH` (or `PUT`) — do
>   **not** re-POST, or you'll leave a duplicate `pendingReview` intent behind.
> - **It never created anything** (no `id` was ever returned) → POST again with a **fresh** UUID
>   `Idempotency-Key` and the corrected body.
>
> Reuse the *same* key only to retry a byte-for-byte identical request; any change to the body
> needs a new key. (Use `GET /pricing-intents` to check what exists if you're unsure.)

---

## Using the ID with create-merchant-platform

Once a pricing intent is `active`, assign it to a processing account's `pricing` field when boarding:

```json
"pricing": {
  "type": "intent",
  "pricingIntentId": "PI-XXXX"
}
```

This is the `intent` variant of the merchant-platform `pricing` object — the alternative is the
inline `agreement` variant. See [`create-merchant-platform`](../create-merchant-platform/SKILL.md).

---

## Common pitfalls

- **PATCH is JSON Patch, not a partial object**: send `[{ "op": "...", "path": "...", "value": ... }]`, not `{ "gateway": { ... } }`
- **PUT returns 204 with no body**: don't expect the updated record back — re-GET if you need it
- **`base` fees need a number, not `null`**: `addressVerification`, `regulatoryAssistanceProgram`, and `merchantAdvantage` are required keys; despite being spec-nullable, UAT rejects `null` ("must not be empty") — send a numeric value (`0` when not charged), and never omit the key
- **Build a complete body, including when fixing a 400**: a corrected payload must still carry all required `base` keys and all four `gateway.fees` keys, or you just earn a fresh 400
- **Amounts in cents**: every fee is an integer in cents; percentages are numbers (≤2 dp)
- **`key` is required and is yours**: it's your own template identifier, separate from the Payroc `id`
- **Idempotency key only on POST and PATCH**: PUT, GET, and DELETE don't take one
- **`fees` shape follows `planType`**: read the matching reference subsection before filling it in
- **Only `US` / `5.2`**: `country` and `version` accept a single value each today

---

## Full field reference

Read `references/api-schema.md` for:
- All enum values (`planType`, `status`, `amex.type`, `billInMonth`, `billingFrequency`, etc.)
- The per-`planType` `fees` schemas (interchange plus, tiered 3/4/6, flat rate, consumer/reward choice)
- `base`, `gateway`, `ach`, and `services` object schemas with units
- Annotated create-request and PATCH examples, and the error schema
