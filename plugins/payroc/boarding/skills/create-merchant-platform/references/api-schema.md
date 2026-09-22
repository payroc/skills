# Create Merchant Platform — Full API Schema Reference

`POST https://api.payroc.com/v1/merchant-platforms`

---

## Enums

### organizationType
`privateCorporation` | `publicCorporation` | `nonProfit` | `privateLlc` | `publicLlc` |
`privatePartnership` | `publicPartnership` | `soleProprietor`

### businessType
`retail` | `restaurant` | `internet` | `moto` | `lodging` | `notForProfit`

### timezone
`Pacific/Honolulu` | `America/Anchorage` | `America/Los_Angeles` | `America/Denver` |
`America/Phoenix` | `America/Chicago` | `America/New_York`

### fundingSchedule
`standard` | `nextday` | `sameday`

### fundingAccountType
`checking` | `savings` | `generalLedger`

### fundingAccountUse
`credit` | `debit` | `creditAndDebit`

### contactMethodType
`email` | `phone` | `mobile` | `fax`

> `phone`/`mobile`/`fax` `value` must contain **digits only** — no `+`, spaces, or punctuation
> (e.g. `5125550199`, not `+1 512 555 0199`). The live API rejects non-digit characters.

### addressType
`legalAddress` | `mailingAddress`

### monthsOfOperation
`jan` | `feb` | `mar` | `apr` | `may` | `jun` | `jul` | `aug` | `sep` | `oct` | `nov` | `dec`

### pricingPlanType (processor)
`interchangePlus` | `interchangePlusPlus` | `tiered3` | `tiered4` | `tiered6` |
`flatRate` | `consumerChoice` | `rewardPayChoice`

### processor (backend processor — top-level field on processingAccounts[], not the pricing object's `processor` above)
`tsys` | `fiserv` (default `tsys`). Send it explicitly — don't rely on the default.

### addendumType
`installmentPaymentsV1` | `moneyServicesV1` | `telehealthV1` | `firearmsV1` |
`pharmacyCnpComplianceV1` | `cbdV1` | `tobaccoCnpV1` | `donationsV1` |
`cloverMerchantProcessingAmendmentV1` | `rocGivingV1`. See [Addendums](#addendums) below.

---

## Request body

```json
{
  "business": { ... },             // required
  "processingAccounts": [ { ... } ], // required, min 1
  "metadata": { }                  // optional — your key/value pairs, echoed in responses
}
```

---

## business object

```json
{
  "name": "Acme Corp LLC",                    // string, required
  "taxId": "12-3456789",                      // string, required
  "organizationType": "privateLlc",           // enum, required
  "countryOfOperation": "US",                 // ISO-3166, required
  "addresses": [                              // required, min 1
    {
      "type": "legalAddress",                 // required for at least one entry
      "address1": "123 Main St",
      "address2": "Suite 400",                // optional
      "address3": "",                         // optional
      "city": "Chicago",
      "state": "IL",
      "country": "US",
      "postalCode": "60601"
    }
  ],
  "contactMethods": [                         // required, email required
    { "type": "email", "value": "owner@acme.com" },
    { "type": "phone", "value": "3125550100" }     // optional — digits only, no + or punctuation
  ]
}
```

---

## processingAccounts[] object

`businessType` and `categoryCode` are optional (previously both required — send them when
known, downstream boarding review still uses them). `addendums` is required, but not required
to be non-empty — send `"addendums": []` when none of the [Addendums](#addendums) forms apply.

```json
{
  "doingBusinessAs": "Acme Widgets",          // string, required
  "businessType": "retail",                   // enum, optional — send if known
  "categoryCode": 5999,                       // integer MCC, optional — send if known
  "processor": "tsys",                        // enum tsys|fiserv, optional, default tsys — send explicitly
  "merchandiseOrServiceSold": "Office supplies and widgets",  // string, required
  "businessStartDate": "2018-06-01",          // YYYY-MM-DD, required
  "timezone": "America/Chicago",              // enum, required
  "addendums": [ ],                           // required — [] if none apply, see Addendums
  "website": "https://acme.example.com",      // optional, but REQUIRED when processing.volumeBreakdown.ecommerce > 0

  "address": {                                // required
    "address1": "123 Main St",
    "city": "Chicago",
    "state": "IL",
    "country": "US",
    "postalCode": "60601"
  },

  "contactMethods": [                         // required, email required
    { "type": "email", "value": "billing@acme.com" }
  ],

  "owners": [ { ... } ],                      // required — see owners object below

  "processing": { ... },                      // required — see processing object below
  "funding": { ... },                         // required — see funding object below
  "pricing": { ... },                         // required — see pricing object below
  "signature": { ... }                        // required — see signature object below
}
```

---

## owners[] object

Every processing account needs at minimum:
- exactly one owner with `relationship.isControlProng: true` (only one control prong is allowed)
- one owner with `relationship.isAuthorizedSignatory: true`

A single owner **cannot** be both control prong and authorized signatory at once — the live API
rejects it (*"it must be one or the other or neither"*). So you need **at least two owners**: one
control prong and a different authorized signatory.

```json
{
  "firstName": "Jane",                        // required
  "lastName": "Smith",                        // required
  "dateOfBirth": "1985-04-15",               // YYYY-MM-DD, required

  "address": {                                // required
    "address1": "456 Oak Ave",
    "city": "Chicago",
    "state": "IL",
    "country": "US",
    "postalCode": "60602"
  },

  "identifiers": [                            // required
    {
      "type": "nationalId",
      "value": "123-45-6789"                  // SSN (US)
    }
  ],

  "contactMethods": [                         // required, email required
    { "type": "email", "value": "jane@acme.com" }
  ],

  "relationship": {                           // required
    "isControlProng": true,                   // this owner is the control prong...
    "isAuthorizedSignatory": false,           // ...so NOT also the signatory (an owner can't be both)
    "equityPercentage": 60,                   // number 0-100
    "title": "CEO"                            // string, optional
  }
}
// A second owner is required as the authorized signatory: "isControlProng": false, "isAuthorizedSignatory": true.
```

---

## Addendums

`addendums` (on each `processingAccounts[]` entry) is an array of polymorphic `addendumEntry`
objects, each discriminated by `type`. Send `[]` if none apply. Eight of the ten types are
attestation-only — the entire object is just the discriminator:

```json
{ "type": "installmentPaymentsV1" }
```

| `type` | Send it when the merchant… |
| --- | --- |
| `installmentPaymentsV1` | offers installment payments, loans, or leases |
| `moneyServicesV1` | offers money services (e.g. traveler's checks) |
| `telehealthV1` | provides telehealth services |
| `firearmsV1` | sells firearms |
| `pharmacyCnpComplianceV1` | is a pharmacy accepting card-not-present transactions |
| `cbdV1` | sells CBD, synthetic THC/cannabis, HHC, kratom, tianeptine, or delta 8/9/10/0 THC products |
| `tobaccoCnpV1` | sells tobacco and accepts card-not-present transactions |
| `donationsV1` | accepts donations |

The other two carry real payloads:

**`cloverMerchantProcessingAmendmentV1`** — merchant is ordering Clover equipment. `lineItems`
is required, an object keyed by device SKU (`cloverCompact`, `cloverFlex4thGen`,
`cloverFlexPocket`, `cloverMiniLte3rdGen`, `cloverSoloPosSystem`,
`cloverStationDuoGen2PosSystem`, `cloverCompactTetherCable`, `cloverCashDrawer`,
`cloverKitchenPrinter`, `cloverKitchenPrinterThermal`, `cloverWeightScale`,
`cloverHandsFreeScanner`, `cloverBarCodeScanner`, `cloverKds24`, `cloverKds14`), at least one
key present, each value `{ "quantity": <int, min 1>, "totalPrice": <int cents, min 0> }`:

```json
{
  "type": "cloverMerchantProcessingAmendmentV1",
  "lineItems": {
    "cloverSoloPosSystem": { "quantity": 1, "totalPrice": 149900 },
    "cloverCashDrawer": { "quantity": 2, "totalPrice": 19800 }
  }
}
```

**`rocGivingV1`** — merchant uses Roc Giving. Required: `accountAdminContact`
(`firstName`, `lastName`, `emailAddress` required; `phone` optional), `autoCloseTime`
(`HH:mm`, 24-hour clock), `donorSupportPercentage` (number, 0–100). Optional `plan`:
`basic` (default) | `advanced`.

```json
{
  "type": "rocGivingV1",
  "accountAdminContact": { "firstName": "Jane", "lastName": "Doe", "emailAddress": "jane.doe@example.com" },
  "autoCloseTime": "23:40",
  "donorSupportPercentage": 2.5,
  "plan": "basic"
}
```

The response's `addendums` array (`readOnly`) echoes back which addendum types were accepted
and appended to the Merchant Processing Agreement — empty if none were requested.

---

## processing object

```json
{
  "transactionAmounts": {                     // required, values in cents
    "average": 5000,                          // $50.00 average transaction
    "highest": 50000                          // $500.00 maximum transaction
  },
  "monthlyAmounts": {                         // required, values in cents
    "average": 1000000,                       // $10,000/month average
    "highest": 2000000                        // $20,000/month peak
  },
  "volumeBreakdown": {                        // required, must sum to 100
    "cardPresent": 80,
    "mailOrTelephone": 0,
    "ecommerce": 20
  },

  "isSeasonal": false,                        // optional boolean
  "monthsOfOperation": ["jan","feb","mar"],   // optional — only if isSeasonal: true

  "ach": {                                    // optional; bi-directional: if present, pricing MUST include processor.ach — and if pricing includes processor.ach, this field MUST be present
    "naics": "441110",                        // string NAICS code — field is `naics`, NOT `naicsCode`
    "transactionTypes": ["webInitiatedPayment"],  // enum: prearrangedPayment | corpCashDisbursement | telephoneInitiatedPayment | webInitiatedPayment | other  (NOT web/ppd)
    "estimatedMonthlyTransactions": 100,      // required — integer count
    "previouslyTerminatedForAch": false,      // required — boolean
    "refunds": { "writtenRefundPolicy": false },                          // required object
    "limits": { "singleTransaction": 0, "dailyDeposit": 0, "monthlyDeposit": 0 }  // required object — cents
  },

  "cardAcceptance": {                         // optional
    "cardsAccepted": ["visa", "mastercard", "discover", "amexOptBlue"],  // enum array — American Express is amexOptBlue, NOT amex
    "debitOnly": false,
    "hsaFsa": false
  }
}
```

> **`ach` and `cardAcceptance` shapes corrected 2026-06-19 (verified against UAT).** Earlier
> revisions showed `ach` with `naicsCode`, `transactionTypes: ["web","ppd"]`, and
> `monthlyTransactionLimit`/`monthlyTransactionVolume` — all rejected by the live API. The real
> `ach` object uses `naics`, the `transactionTypes` enum above, and requires
> `estimatedMonthlyTransactions`, `previouslyTerminatedForAch`, `refunds`, and `limits`.
> `cardAcceptance` uses a `cardsAccepted` enum array (not per-brand booleans / `specialtyCards`).
> Three cross-rules: (1) the ACH constraint is **bi-directional** — if `processing.ach` is
> present the `pricing` must include `processor.ach`, AND if the pricing intent carries
> `processor.ach` fees then `processing.ach` must be declared on the account (UAT error:
> `"'Processing Ach' cannot be null when 'Pricing Processor Ach' is populated."`);
> (2) the default `cardsAccepted` includes `amexOptBlue`, and if `amexOptBlue` is accepted the
> pricing must carry Amex OptBlue fees (and vice versa);
> (3) drop `amexOptBlue` from `cardsAccepted` if the pricing has no Amex OptBlue fees.

---

## funding object

> **Payment-method shape (corrected 2026-06-18).** Each `fundingAccounts[].paymentMethods[]`
> entry nests the bank numbers under `value`: `{ "type": "ach", "value": { "routingNumber",
> "accountNumber" } }`. Earlier revisions of this file showed them flat on the payment method;
> the spec and the generated SDKs use the `value` wrapper.

```json
{
  "status": "enabled",                        // "enabled" | "disabled"
  "fundingSchedule": "standard",             // "standard" | "nextday" | "sameday"
  "acceleratedFundingFee": 25,               // cents — required if nextday or sameday
  "dailyDiscount": false,                    // optional boolean

  "fundingAccounts": [                        // array of bank accounts
    {
      "type": "checking",                     // "checking" | "savings" | "generalLedger"
      "use": "creditAndDebit",               // "credit" | "debit" | "creditAndDebit"
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

---

## pricing object

### Variant 1 — Intent (preferred when you have a pricing template)

```json
{
  "type": "intent",
  "pricingIntentId": "PI-XXXX"
}
```

### Variant 2 — Full agreement

```json
{
  "type": "agreement",
  "country": "US",
  "version": "5.2",

  "base": {
    "addressVerification": 10,               // cents per transaction
    "annualFee": 9900,                       // cents
    "pciNonCompliance": 1500                 // cents per month
  },

  "processor": {
    "plan": "interchangePlus",               // see pricingPlanType enum
    "cardTransactionFee": 20,               // cents per transaction
    "cardDiscountRate": 0.25,               // percentage
    "achTransactionFee": 50
  },

  "gateway": {
    "monthlyFee": 2500,
    "setupFee": 0,
    "perTransactionFee": 10
  },

  "services": []
}
```

---

## signature object

### Variant 1 — Email (most common)

The merchant receives an email with a link to sign their contract.

```json
{
  "type": "requestedViaEmail"
}
```

### Variant 2 — Direct link

Your application redirects the merchant to the signing flow. The `href` comes from
a HATEOAS link in a previous API response.

```json
{
  "type": "requestedViaDirectLink",
  "link": {
    "rel": "sign",
    "method": "GET",
    "href": "https://api.payroc.com/v1/..."
  }
}
```

---

## Complete annotated example

A minimal end-to-end request body for a sole-proprietor retail merchant:

```json
{
  "business": {
    "name": "Jane's Flower Shop",
    "taxId": "98-7654321",
    "organizationType": "soleProprietor",
    "countryOfOperation": "US",
    "addresses": [
      {
        "type": "legalAddress",
        "address1": "789 Blossom Rd",
        "city": "Austin",
        "state": "TX",
        "country": "US",
        "postalCode": "73301"
      }
    ],
    "contactMethods": [
      { "type": "email", "value": "jane@janesflowers.com" },
      { "type": "phone", "value": "5125550199" }
    ]
  },

  "processingAccounts": [
    {
      "doingBusinessAs": "Jane's Flower Shop",
      "businessType": "retail",
      "categoryCode": 5992,
      "merchandiseOrServiceSold": "Fresh flowers and floral arrangements",
      "businessStartDate": "2019-03-01",
      "timezone": "America/Chicago",
      "website": "https://janesflowers.com",

      "address": {
        "address1": "789 Blossom Rd",
        "city": "Austin",
        "state": "TX",
        "country": "US",
        "postalCode": "73301"
      },

      "contactMethods": [
        { "type": "email", "value": "jane@janesflowers.com" }
      ],

      "owners": [
        {
          "firstName": "Jane",
          "lastName": "Flores",
          "dateOfBirth": "1982-11-20",
          "address": {
            "address1": "100 Home St",
            "city": "Austin",
            "state": "TX",
            "country": "US",
            "postalCode": "73302"
          },
          "identifiers": [
            { "type": "nationalId", "value": "987-65-4321" }
          ],
          "contactMethods": [
            { "type": "email", "value": "jane@janesflowers.com" }
          ],
          "relationship": {
            "isControlProng": true,
            "isAuthorizedSignatory": false,
            "equityPercentage": 60,
            "title": "Owner"
          }
        },
        {
          "firstName": "Carlos",
          "lastName": "Mendez",
          "dateOfBirth": "1980-07-12",
          "address": {
            "address1": "240 Pecan St",
            "city": "Austin",
            "state": "TX",
            "country": "US",
            "postalCode": "73303"
          },
          "identifiers": [
            { "type": "nationalId", "value": "876-54-3210" }
          ],
          "contactMethods": [
            { "type": "email", "value": "carlos@janesflowers.com" }
          ],
          "relationship": {
            "isControlProng": false,
            "isAuthorizedSignatory": true,
            "equityPercentage": 40,
            "title": "Partner"
          }
        }
      ],

      "processing": {
        "transactionAmounts": { "average": 3500, "highest": 25000 },
        "monthlyAmounts": { "average": 500000, "highest": 800000 },
        "volumeBreakdown": {
          "cardPresent": 70,
          "mailOrTelephone": 5,
          "ecommerce": 25
        }
      },

      "funding": {
        "status": "enabled",
        "fundingSchedule": "standard",
        "fundingAccounts": [
          {
            "type": "checking",
            "use": "creditAndDebit",
            "nameOnAccount": "Jane Flores",
            "paymentMethods": [
              {
                "type": "ach",
                "value": {
                  "routingNumber": "111000025",
                  "accountNumber": "9876543210"
                }
              }
            ]
          }
        ]
      },

      "pricing": {
        "type": "intent",
        "pricingIntentId": "PI-RETAIL-STANDARD"
      },

      "signature": {
        "type": "requestedViaEmail"
      },

      "addendums": []
    }
  ],

  "metadata": {
    "internalCustomerId": "CUST-00123",
    "salesRepId": "REP-456"
  }
}
```

---

## Headers reference

| Header | Required | Notes |
|--------|----------|-------|
| `Authorization` | Yes | `Bearer <access_token>` |
| `Idempotency-Key` | Yes | UUID v4; reuse on retry of same submission |
| `Content-Type` | Yes | `application/json` |

---

## Response schema (201 Created)

```json
{
  "merchantPlatformId": "MP-XXXX",
  "createdDate": "2026-05-01T12:00:00Z",
  "lastModifiedDate": "2026-05-01T12:00:00Z",
  "business": { ... },
  "processingAccounts": [
    {
      "processingAccountId": "PA-XXXX",
      "doingBusinessAs": "Jane's Flower Shop",
      "processor": "tsys",                // required in the response — which processor authorizes/settles this account
      "status": "entered",   // may also be "pending" depending on timing
      "signature": { ... },
      "addendums": [ ]                    // required, readOnly — accepted addendum types, [] if none requested
    }
  ],
  "metadata": { ... },
  "links": [
    { "rel": "self", "method": "GET", "href": "https://api.payroc.com/v1/merchant-platforms/MP-XXXX" }
  ]
}
```

---

## Errors

Errors use the **RFC 7807 problem-details envelope** (`type`, `title`, `status`, `detail`, `instance`) extended with a Payroc `errors[]` array. See `references/error-response-format.md` for the envelope shape and the canonical error `type` catalog; read `errors[].parameter` to map each failure to your request body.

Status codes this endpoint returns: `400` (validation, incl. `idempotencyKeyMissing`), `401`
(auth/expired token), `403` (permissions), `409` (conflict — `resourceAlreadyExists`,
`idempotencyKeyInUse`, `taxIdInUse`), `500` (server — retry with backoff).

**Addendum and processor validation.** Four `400` scenarios are specific to `addendums`/`processor` —
recognize these rather than treating them as an opaque failure:

| `errors[].parameter` pattern | `errors[].detail` | Cause |
| --- | --- | --- |
| `...addendums[N].type` | `Unrecognized addendum type.` | `type` isn't one of the 10 values in [Addendums](#addendums) |
| `...addendums[N].type` | `Duplicate addendum type.` | The same `type` appears more than once in the array |
| `...addendums[N].<field>` | `Missing required field.` | An addendum entry is missing a field its type requires (e.g. `cloverMerchantProcessingAmendmentV1` without `lineItems`) |
| `...processor` | `Unrecognized processor.` | `processor` isn't `tsys` or `fiserv` |
