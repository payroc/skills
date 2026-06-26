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

```json
{
  "doingBusinessAs": "Acme Widgets",          // string, required
  "businessType": "retail",                   // enum, required
  "categoryCode": 5999,                       // integer MCC, required
  "merchandiseOrServiceSold": "Office supplies and widgets",  // string, required
  "businessStartDate": "2018-06-01",          // YYYY-MM-DD, required
  "timezone": "America/Chicago",              // enum, required
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
      }
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
      "status": "entered",   // may also be "pending" depending on timing
      "signature": { ... }
    }
  ],
  "metadata": { ... },
  "links": [
    { "rel": "self", "method": "GET", "href": "https://api.payroc.com/v1/merchant-platforms/MP-XXXX" }
  ]
}
```
