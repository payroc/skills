# Add Processing Account — Full API Schema Reference

Snapshot of the Payroc Boarding API surface for adding and reading processing accounts on an
**existing** merchant platform. Sourced from `https://docs.payroc.com/openapi.yml` (see
`_sources.md`). Emit field names and enum values from this file — never from memory.

---

## Contents

- [Endpoints](#endpoints)
- [Headers](#headers)
- [Enums](#enums)
- [Request body — `createProcessingAccount`](#request-body--createprocessingaccount)
- [Response — `processingAccount`](#response--processingaccount-201-on-add-200-on-retrieve)
- [List (pagination)](#list--get-merchant-platformsmerchantplatformidprocessing-accounts)
- [Reminders](#reminders--post-processing-accountsprocessingaccountidreminders)
- [Related reads (by `processingAccountId`)](#related-reads-by-processingaccountid)
- [Errors](#errors)
- [Complete annotated example](#complete-annotated-example--add-one-retail-account-to-an-existing-platform)

---

## Endpoints

| Operation | Method & path | Request | Response |
|-----------|---------------|---------|----------|
| Add a processing account | `POST /v1/merchant-platforms/{merchantPlatformId}/processing-accounts` | `createProcessingAccount` | `201` → `processingAccount` |
| List a platform's processing accounts | `GET /v1/merchant-platforms/{merchantPlatformId}/processing-accounts` | — (query params) | `200` → `paginatedProcessingAccounts` |
| Retrieve one processing account | `GET /v1/processing-accounts/{processingAccountId}` | — | `200` → `processingAccount` |
| Retrieve its pricing agreement | `GET /v1/processing-accounts/{processingAccountId}/pricing` | — | `200` → pricing agreement |
| List its owners | `GET /v1/processing-accounts/{processingAccountId}/owners` | — | `200` → owners list |
| List its contacts | `GET /v1/processing-accounts/{processingAccountId}/contacts` | — | `200` → contacts list |
| List its funding accounts | `GET /v1/processing-accounts/{processingAccountId}/funding-accounts` | — | `200` → funding accounts list |
| Create a signing reminder | `POST /v1/processing-accounts/{processingAccountId}/reminders` | `createReminder` | `201` → reminder |

Base URLs: production `https://api.payroc.com`, test/UAT `https://api.uat.payroc.com`.

> **Two different path roots.** You *add* and *list* accounts under the **merchant platform**
> (`/merchant-platforms/{merchantPlatformId}/processing-accounts`), but once an account exists
> you address it directly by its own id under **`/processing-accounts/{processingAccountId}`**
> for retrieve, pricing, owners, contacts, funding accounts, and reminders.

---

## Headers

| Header | Required on | Notes |
|--------|-------------|-------|
| `Authorization` | all | `Bearer <access_token>` |
| `Idempotency-Key` | `POST` (add account, reminder) | UUID v4; reuse on retry of the same submission |
| `Content-Type` | `POST` | `application/json` |

---

## Enums

### businessType (`CreateProcessingAccountBusinessType`)
`retail` | `restaurant` | `internet` | `moto` | `lodging` | `notForProfit`

### timezone
`Pacific/Midway` | `Pacific/Honolulu` | `America/Anchorage` | `America/Los_Angeles` |
`America/Denver` | `America/Phoenix` | `America/Chicago` | `America/Indiana/Indianapolis` |
`America/New_York`

### ProcessingAccountStatus (response only)
`entered` | `pending` | `approved` | `subjectTo` | `dormant` | `nonProcessing` | `rejected` |
`terminated` | `cancelled`

- `entered` — received, not yet reviewed
- `pending` — reviewed, not yet approved
- `approved` — approved for processing and funding
- `subjectTo` — approved, awaiting further information
- `dormant` — closed for a period
- `nonProcessing` — approved, no transaction run yet
- `rejected` / `terminated` / `cancelled` — closed states (returned in lists only when `includeClosed=true`)

Subscribe to the `processingAccount.status.changed` event to be notified of status changes
instead of polling.

### fundingSchedule (`CreateFundingFundingSchedule`)
`standard` | `nextday` | `sameday` (default `standard`). If `nextday`/`sameday`, also send
`acceleratedFundingFee` (cents).

### fundingAccountType / fundingAccountUse
type: `checking` | `savings` | `generalLedger` — use: `credit` | `debit` | `creditAndDebit`

### contactMethod type
`email` | `phone` | `mobile` | `fax`

### identifier type
`nationalId` (SSN/SIN)

### monthsOfOperation
`jan` | `feb` | `mar` | `apr` | `may` | `jun` | `jul` | `aug` | `sep` | `oct` | `nov` | `dec`

---

## Request body — `createProcessingAccount`

The body **is** a single processing-account object (no `business` wrapper, no
`processingAccounts` array — that wrapper belongs to `POST /merchant-platforms`). It is the
exact same object as one element of the `processingAccounts` array in Create Merchant Platform.

Required: `doingBusinessAs`, `owners`, `businessType`, `categoryCode`,
`merchandiseOrServiceSold`, `businessStartDate`, `timezone`, `address`, `contactMethods`,
`processing`, `funding`, `pricing`, `signature`.
Optional: `website`, `contacts`, `metadata`.

```json
{
  "doingBusinessAs": "Acme Widgets",          // required, string
  "businessType": "retail",                   // required, enum
  "categoryCode": 5999,                       // required, integer MCC
  "merchandiseOrServiceSold": "Office supplies and widgets",  // required, string
  "businessStartDate": "2018-06-01",          // required, YYYY-MM-DD
  "timezone": "America/Chicago",              // required, enum
  "website": "https://acme.example.com",      // optional — but REQUIRED when processing.volumeBreakdown.ecommerce > 0

  "address": { ... },                         // required — address object
  "contactMethods": [ ... ],                  // required, email required
  "owners": [ ... ],                          // required — see owners
  "processing": { ... },                      // required
  "funding": { ... },                         // required — createFunding
  "pricing": { ... },                         // required — intent or agreement
  "signature": { ... },                       // required
  "contacts": [ ... ],                        // optional
  "metadata": { }                             // optional — your key/value pairs, echoed back
}
```

### address object

Required: `address1`, `city`, `state`, `country`, `postalCode`. Optional: `address2`,
`address3`.

```json
{
  "address1": "123 Main St",
  "address2": "Suite 400",
  "city": "Chicago",
  "state": "IL",
  "country": "US",          // ISO-3166-1 two-letter
  "postalCode": "60601"
}
```

### contactMethod object

`{ "type": "email", "value": "billing@acme.com" }` — `type` and `value` both required. At
least one `email` is required on the account's `contactMethods` (and on each owner's).

### owners[] (`owner`)

Required per owner: `firstName`, `lastName`, `dateOfBirth`, `address`, `identifiers`,
`contactMethods`, `relationship`. Optional: `middleName`.

Ownership rules:
- Exactly one control prong — `relationship.isControlProng: true` (the spec allows **only one**
  control prong per processing account).
- At least one authorized signatory — `relationship.isAuthorizedSignatory: true`.
- A single owner **cannot** be both control prong and authorized signatory at once — the live API
  rejects it (*"it must be one or the other or neither"*). So you need **at least two owners**:
  one control prong and a different authorized signatory.

```json
{
  "firstName": "Jane",
  "lastName": "Smith",
  "dateOfBirth": "1985-04-15",                // YYYY-MM-DD
  "address": { "address1": "456 Oak Ave", "city": "Chicago", "state": "IL", "country": "US", "postalCode": "60602" },
  "identifiers": [
    { "type": "nationalId", "value": "123-45-6789" }   // type + value required
  ],
  "contactMethods": [
    { "type": "email", "value": "jane@acme.com" }      // email required for owners
  ],
  "relationship": {
    "isControlProng": true,                   // this owner is the control prong...
    "isAuthorizedSignatory": false,           // ...so NOT also the signatory (an owner can't be both)
    "equityPercentage": 60,                   // optional, number, default 0
    "title": "Owner"                          // optional
  }
  // A second owner carries "isAuthorizedSignatory": true (and "isControlProng": false).
}
```

### processing object

Required: `transactionAmounts`, `monthlyAmounts`, `volumeBreakdown`. Optional: `isSeasonal`,
`monthsOfOperation` (only when `isSeasonal: true`), `ach`, `cardAcceptance`.

```json
{
  "transactionAmounts": { "average": 5000, "highest": 50000 },   // cents, both required, > 0
  "monthlyAmounts":     { "average": 1000000, "highest": 2000000 }, // cents, both required
  "volumeBreakdown": {
    "cardPresent": 80,
    "mailOrTelephone": 0,
    "ecommerce": 20
  },                                          // all three required, must sum to exactly 100
                                              // NOTE: if ecommerce > 0, the account's top-level `website` is required

  "isSeasonal": false,                        // optional
  "monthsOfOperation": ["jun","jul","aug"],   // optional, only if isSeasonal: true

  "cardAcceptance": {                         // optional
    "debitOnly": false,
    "hsaFsa": false,
    "cardsAccepted": ["visa","mastercard","discover","amexOptBlue"]  // enum — note amexOptBlue, not amex
  }
}
```

> **`cardsAccepted` enum** is `visa` | `mastercard` | `discover` | `amexOptBlue` — American Express
> is `amexOptBlue`, **not** `amex`. **Cross-rule (verified against UAT):** the default
> `cardsAccepted` *includes* `amexOptBlue`, and if `amexOptBlue` is accepted the `pricing` must
> carry Amex OptBlue fees (and vice versa) — so omitting `cardAcceptance` entirely still requires
> Amex pricing. Drop `amexOptBlue` from `cardsAccepted` if the pricing has no Amex fees.
>
> **`processing.ach` is optional and not gathered by this skill's intake.** Don't emit it unless
> the merchant genuinely takes ACH. If you do, note it is *not* a `{naicsCode, transactionTypes}`
> stub. Verified against UAT (2026-06-19), the `ach` object uses the field name `naics` (not
> `naicsCode`) and **requires** `estimatedMonthlyTransactions` (integer), `previouslyTerminatedForAch`
> (boolean), `refunds` (e.g. `{ "writtenRefundPolicy": false }`), and `limits` (e.g.
> `{ "singleTransaction", "dailyDeposit", "monthlyDeposit" }`, cents). Its `transactionTypes` enum is
> `prearrangedPayment` | `corpCashDisbursement` | `telephoneInitiatedPayment` |
> `webInitiatedPayment` | `other` (not `web`/`ppd`). **Cross-rule (bi-directional, verified UAT
> 2026-06-19):** if `processing.ach` is present, the `pricing` must include `processor.ach`; AND
> if the pricing intent carries `processor.ach` fees, `processing.ach` must be declared on the
> account (UAT error: `"'Processing Ach' cannot be null when 'Pricing Processor Ach' is populated."`).
> Use a card-only pricing intent when the account does not take ACH.

### funding object (`createFunding`)

Optional top-level: `status` (`enabled`|`disabled`), `fundingSchedule` (default `standard`),
`acceleratedFundingFee` (cents — required if schedule is `nextday`/`sameday`), `dailyDiscount`.
Each `fundingAccounts[]` entry requires `type`, `use`, `nameOnAccount`, `paymentMethods`.

**Payment methods are a discriminated array — routing/account numbers live inside `value`:**

```json
{
  "status": "enabled",
  "fundingSchedule": "standard",
  "fundingAccounts": [
    {
      "type": "checking",                     // checking | savings | generalLedger
      "use": "creditAndDebit",                // credit | debit | creditAndDebit
      "nameOnAccount": "Acme Corp LLC",
      "paymentMethods": [
        {
          "type": "ach",
          "value": {
            "routingNumber": "021000021",
            "accountNumber": "123456789"
          }
        }
      ]
    }
  ]
}
```

> **Watch the shape.** `paymentMethods[]` is `{ "type": "ach", "value": { routingNumber,
> accountNumber } }` — the bank numbers are nested under `value`, not flat on the payment
> method. (Create Merchant Platform's older reference shows them flat; the spec and generated
> SDKs use the `value` wrapper — see `_sources.md`.)

### pricing object — two variants

**Variant 1 — Intent (preferred — reuses a pricing-intent template).** Both fields required.

```json
{ "type": "intent", "pricingIntentId": "PI-XXXX" }
```

Get the `pricingIntentId` from the **create-pricing-intent** skill, or from a pricing intent
already created for this merchant. The intent must be `active`.

**Variant 2 — Agreement (inline one-off pricing).** `type` required; `country`, `version`,
`base`, `processor`, `gateway`, `services` describe the full Merchant Processing Agreement.

```json
{ "type": "agreement", "country": "US", "version": "5.2", "base": { ... }, "processor": { ... }, "gateway": { ... }, "services": [ ] }
```

The full inline `agreement` structure (`baseUs`, `processor`, `gatewayUs5.2`, `servicesUs5.0`
and all fee fields) is large and identical to the agreement documented in the
**create-pricing-intent** skill's `references/api-schema.md`. Read that file when you need the
inline-agreement field detail; prefer the intent variant whenever a template exists.

### signature object — two variants

```json
{ "type": "requestedViaEmail" }              // merchant gets an email link to sign (most common)
```
```json
{ "type": "requestedViaDirectLink", "link": { "rel": "sign", "method": "GET", "href": "https://..." } }
```

Only `requestedViaEmail` makes the account eligible for signing **reminders** (see below).

### contacts[] (optional)

`{ "type": "manager" | "representative" | "others", "firstName": "...", "lastName": "...", "contactMethods": [ ... ] }`

---

## Response — `processingAccount` (201 on add, 200 on retrieve)

```json
{
  "processingAccountId": "PA-XXXX",
  "createdDate": "2026-06-18T12:00:00Z",
  "lastModifiedDate": "2026-06-18T12:00:00Z",
  "status": "entered",                        // ProcessingAccountStatus enum — may also be "pending" on create depending on timing
  "doingBusinessAs": "Acme Widgets",
  "owners": [                                 // summarised: ownerId + name + HATEOAS link
    { "ownerId": 123, "firstName": "Jane", "lastName": "Smith", "link": { "rel": "owner", "method": "GET", "href": "..." } }
  ],
  "businessType": "retail",
  "categoryCode": 5999,
  "merchandiseOrServiceSold": "Office supplies and widgets",
  "businessStartDate": "2018-06-01",
  "timezone": "America/Chicago",
  "address": { ... },
  "contactMethods": [ ... ],
  "processing": { ... },
  "funding": {                                // summarised — funding accounts as id + status + link
    "status": "enabled",
    "fundingSchedule": "standard",
    "fundingAccounts": [ { "fundingAccountId": 456, "status": "pending", "link": { ... } } ]
  },
  "pricing": { "link": { "rel": "pricing", "method": "GET", "href": "https://.../processing-accounts/PA-XXXX/pricing" } },
  "contacts": [ ... ],
  "signature": { "type": "requestedViaEmail" },
  "metadata": { },
  "links": [ { "rel": "self", "method": "GET", "href": "https://.../processing-accounts/PA-XXXX" } ]
}
```

Persist `processingAccountId` immediately — it's required for every follow-on read, ordering a
terminal, and reminders. The new account may start in `"entered"` or `"pending"` depending on
timing; poll or subscribe to events to detect approval. The request returns `201` even though
approval is asynchronous.

**IDs are opaque.** The `PA-XXXX` / `MP-XXXX` / `PI-XXXX` forms in these examples are for
readability only. Treat every ID as an opaque string whose format is not guaranteed and varies
by environment — in UAT they come back as plain integers (e.g. `287019`). Don't validate or
parse them against a `PREFIX-XXXX` pattern.

> The response `owners`/`funding`/`pricing` are **summaries with HATEOAS links**, not the full
> objects you sent. To read the full owner, funding account, or pricing agreement, follow the
> link or call the dedicated `GET /processing-accounts/{id}/{owners|funding-accounts|pricing}`
> endpoint.

---

## List — `GET /merchant-platforms/{merchantPlatformId}/processing-accounts`

Query parameters (all optional):

| Param | Type | Notes |
|-------|------|-------|
| `before` | string | Return the page before this cursor. Not with `after`. |
| `after` | string | Return the page after this cursor. Not with `before`. |
| `limit` | integer | Max results per page (default 10). |
| `includeClosed` | boolean | Include `terminated`/`cancelled`/`rejected` accounts (default `false` — open only). |

Response — `paginatedProcessingAccounts`:

```json
{
  "limit": 10,
  "count": 2,
  "hasMore": true,
  "links": [ { "rel": "next", "method": "GET", "href": "...?after=..." } ],
  "data": [ { /* processingAccount */ }, { /* processingAccount */ } ]
}
```

Paginate by following the `next`/`prev` links (or by passing `after`/`before` cursors); use
`hasMore` to decide whether to keep going. `count` is the size of the current page, not the
total.

---

## Reminders — `POST /processing-accounts/{processingAccountId}/reminders`

Prompts the merchant to sign their pricing agreement by re-sending the signing email. Only
works if the account's `signature.type` was `requestedViaEmail` at creation.

Request body (`createReminder`) — polymorphic, `type` required:

```json
{ "type": "pricingAgreement" }
```

Response `201` (`createReminder` response):

```json
{ "type": "pricingAgreement", "reminderId": "RMD-XXXX" }
```

Requires `Authorization` and `Idempotency-Key`. A `409` means the agreement is already signed
or otherwise not in a remindable state; a `400`/`403` typically means the account wasn't set up
for email signing.

---

## Related reads (by `processingAccountId`)

- `GET /processing-accounts/{id}/pricing` — full pricing agreement applied to the account.
- `GET /processing-accounts/{id}/owners` — list of owners (`ownerId` + names + links).
- `GET /processing-accounts/{id}/contacts` — list of contacts.
- `GET /processing-accounts/{id}/funding-accounts` — list of funding accounts with status.

> **Owners can't be changed.** The `PUT`/`DELETE /owners/{ownerId}` operations explicitly reject
> processing-account owners — you can update or delete owners only for funding recipients. Get
> the owners right in the add request.

---

## Errors

Errors use the **RFC 7807 problem-details envelope** (`type`, `title`, `status`, `detail`,
`instance`) **extended** with a Payroc `errors[]` array. Each `errors[]` item has `parameter`
(JSON path of the failing field), `detail` (short reason), and `message` (human-readable). See
[`_shared/error-response-format.md`](../../../_shared/error-response-format.md) for the
cross-skill standard. Example `400` from adding an empty account body:

```json
{
  "type": "https://docs.payroc.com/api/errors#bad-request",
  "title": "Bad request",
  "status": 400,
  "detail": "One or more validation errors occurred, see error section for more info",
  "instance": "https://api.uat.payroc.com/v1/merchant-platforms/MP-XXXX/processing-accounts",
  "errors": [
    { "parameter": "processingAccount.owners", "detail": "Required field not populated", "message": "'owners' must not be empty." }
  ]
}
```

| Status | Scenario | Action |
|--------|----------|--------|
| 400 validation | Field issues | Fix each `errors[].parameter` path; resubmit with the same idempotency key |
| 400 `idempotencyKeyMissing` | Missing header | Add `Idempotency-Key: <uuid-v4>` |
| 401 | Token expired/invalid | Re-authenticate for a fresh bearer token |
| 403 | Insufficient permissions / account not email-signing (reminders) | Check API key scope; confirm `requestedViaEmail` for reminders |
| 404 | Unknown `merchantPlatformId` or `processingAccountId` | Verify the id; use List Merchant Platforms / List Processing Accounts to find it |
| 409 | Conflict (duplicate, or reminder when already signed) | Inspect existing state before retrying |
| 500 | Server error | Retry with exponential backoff; surface `errors` if present |

(The published OpenAPI `ErrorsItems` schema lists only `message`; the live API also returns
`parameter` + `detail` + a top-level `instance` — verified against UAT, 2026-06-16.)

---

## Complete annotated example — add one retail account to an existing platform

`POST https://api.payroc.com/v1/merchant-platforms/MP-7K2P/processing-accounts`

```json
{
  "doingBusinessAs": "Thread & Needle - Lakeview",
  "businessType": "retail",
  "categoryCode": 5651,
  "merchandiseOrServiceSold": "Clothing and apparel",
  "businessStartDate": "2021-04-01",
  "timezone": "America/Chicago",
  "website": "https://threadandneedle.com",   // required because ecommerce volume > 0 (see below)

  "address": {
    "address1": "920 W Belmont Ave",
    "city": "Chicago",
    "state": "IL",
    "country": "US",
    "postalCode": "60657"
  },

  "contactMethods": [
    { "type": "email", "value": "lakeview@threadandneedle.com" }
  ],

  "owners": [
    {
      "firstName": "Maria",
      "lastName": "Rossi",
      "dateOfBirth": "1979-08-14",
      "address": { "address1": "55 Lakeview Dr", "city": "Chicago", "state": "IL", "country": "US", "postalCode": "60614" },
      "identifiers": [ { "type": "nationalId", "value": "234-56-7890" } ],
      "contactMethods": [ { "type": "email", "value": "maria@threadandneedle.com" } ],
      "relationship": { "isControlProng": true, "isAuthorizedSignatory": false, "equityPercentage": 60, "title": "Owner" }
    },
    {
      "firstName": "James",
      "lastName": "Park",
      "dateOfBirth": "1982-02-09",
      "address": { "address1": "910 N Clark St", "city": "Chicago", "state": "IL", "country": "US", "postalCode": "60610" },
      "identifiers": [ { "type": "nationalId", "value": "345-67-8901" } ],
      "contactMethods": [ { "type": "email", "value": "james@threadandneedle.com" } ],
      "relationship": { "isControlProng": false, "isAuthorizedSignatory": true, "equityPercentage": 40, "title": "Partner" }
    }
  ],

  "processing": {
    "transactionAmounts": { "average": 6500, "highest": 40000 },
    "monthlyAmounts": { "average": 1800000, "highest": 3000000 },
    "volumeBreakdown": { "cardPresent": 95, "mailOrTelephone": 0, "ecommerce": 5 }
  },

  "funding": {
    "status": "enabled",
    "fundingSchedule": "standard",
    "fundingAccounts": [
      {
        "type": "checking",
        "use": "creditAndDebit",
        "nameOnAccount": "Thread and Needle LLC",
        "paymentMethods": [
          { "type": "ach", "value": { "routingNumber": "021000021", "accountNumber": "1122334455" } }
        ]
      }
    ]
  },

  "pricing": { "type": "intent", "pricingIntentId": "PI-RETAIL-STD" },

  "signature": { "type": "requestedViaEmail" },

  "metadata": { "internalLocationId": "LOC-LAKEVIEW-02" }
}
```

Headers: `Authorization: Bearer <token>`, `Idempotency-Key: <uuid-v4>`,
`Content-Type: application/json`.
