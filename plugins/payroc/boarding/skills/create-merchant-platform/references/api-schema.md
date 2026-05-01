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
    { "type": "phone", "value": "+13125550100" }   // optional
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
- one owner with `relationship.isControlProng: true`
- one owner with `relationship.isAuthorizedSignatory: true`

The same person can satisfy both roles.

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
    "isControlProng": true,                   // boolean, required
    "isAuthorizedSignatory": true,            // boolean
    "equityPercentage": 100,                  // number 0-100
    "title": "CEO"                            // string, optional
  }
}
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

  "ach": {                                    // optional
    "naicsCode": "441110",
    "transactionTypes": ["web", "ppd"],
    "monthlyTransactionLimit": 50000,         // in cents
    "monthlyTransactionVolume": 1000000       // in cents
  },

  "cardAcceptance": {                         // optional
    "visa": true,
    "mastercard": true,
    "discover": true,
    "amexOptBlue": false,
    "specialtyCards": []
  }
}
```

---

## funding object

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
          "routingNumber": "021000021",
          "accountNumber": "123456789"
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
      { "type": "phone", "value": "+15125550199" }
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
            "isAuthorizedSignatory": true,
            "equityPercentage": 100,
            "title": "Owner"
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
                "routingNumber": "111000025",
                "accountNumber": "9876543210"
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
      "status": "pending",
      "signature": { ... }
    }
  ],
  "metadata": { ... },
  "links": [
    { "rel": "self", "method": "GET", "href": "https://api.payroc.com/v1/merchant-platforms/MP-XXXX" }
  ]
}
```
