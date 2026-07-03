# View Authorizations — API Schema Reference

> **Local snapshot — authoritative for this skill.** Source: `https://docs.payroc.com/openapi.yml`
> (Authorizations schemas). Last synced: 2026-06-22. This is the offline source of truth this skill
> emits from — read enum values and required-field sets from here, not from memory. To refresh,
> re-fetch the source and regenerate this file (see [`_sources.md`](./_sources.md)).

Authorizations is a read-only reporting API. It surfaces the batch-level authorization records
for settlement reporting. Every enum value and schema below comes from the OpenAPI spec and
the published schema pages.

---

## Endpoints

| Operation | Method & path |
| --- | --- |
| List authorizations | `GET /v1/authorizations` |
| Retrieve an authorization | `GET /v1/authorizations/{authorizationId}` |

UAT host: `https://api.uat.payroc.com`  ·  Production host: `https://api.payroc.com`

**Note:** These are GET-only endpoints. There are no POST/PATCH/DELETE operations on the
`/authorizations` resource — authorizations are created implicitly by payment transactions, not
by direct API calls to this endpoint.

---

## Authentication

Bearer token required. See `references/identity-call.md` for the token exchange procedure.

```
Authorization: Bearer <access_token>
```

**No Idempotency-Key header** is required for GET requests (read-only endpoints).

---

## GET /v1/authorizations — List Authorizations

### Query Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `date` | string (YYYY-MM-DD) | Conditional | Filter by batch submission date. Either `date` or `batchId` must be provided. |
| `batchId` | integer | Conditional | Filter by batch identifier. Either `date` or `batchId` must be provided. |
| `merchantId` | string | No | Filter by the unique identifier that the processor assigned to the merchant. |
| `before` | string | No | Cursor: return the previous page of results before this value. Cannot be used with `after`. |
| `after` | string | No | Cursor: return the next page of results after this value. Cannot be used with `before`. |
| `limit` | integer | No | Maximum results per page. Default: 10. |

**Constraint:** Either `date` or `batchId` must be present — the request is invalid without at
least one of these filters.

### Response Schema (200)

```yaml
limit: integer        # Maximum results per page
count: integer        # Results on this page (not the total)
hasMore: boolean      # Whether additional pages exist
links:                # HATEOAS navigation links
  - rel: string
    method: string
    href: string
data:                 # Array of authorization objects
  - $ref: '#/components/schemas/Authorization'
```

---

## GET /v1/authorizations/{authorizationId} — Retrieve Authorization

### Path Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `authorizationId` | integer | Yes | Unique identifier of the authorization |

### Response Schema (200)

The response is a single `authorization` object (see schema below).

---

## Authorization Object Schema

```yaml
authorizationId:
  type: integer
  description: Unique identifier assigned to the authorization
createdDate:
  type: string (date, YYYY-MM-DD)
  description: Date the authorization was received
lastModifiedDate:
  type: string (date, YYYY-MM-DD)
  description: Date the authorization was last modified
authorizationResponse:
  type: string (enum)
  description: The bank's response code — see enum values below
preauthorizationRequestAmount:
  type: integer
  description: Requested amount in lowest currency denomination (e.g. cents for USD)
currency:
  type: string (ISO 4217)
  description: Currency code (e.g. "USD", "GBP", "EUR")
batch:
  type: object | null
  description: Batch summary — null if not yet batched
  properties:
    batchId: integer
    date: string (YYYY-MM-DD)
    cycle: string   # e.g. "am" — see Batch Cycle note below
    link:
      rel: string
      method: string
      href: string
card:
  type: object
  description: Card details
  properties:
    cardNumber: string  # Masked — e.g. "453985******7062"
    type: string (enum) # See card type enum below
    cvvPresenceIndicator: boolean
    avsRequest: boolean
    avsResponse: string
merchant:
  type: object
  description: Merchant information
  properties:
    merchantId: string
    doingBusinessAs: string
    processingAccountId: integer
    link:
      rel: string
      method: string
      href: string
transaction:
  type: object
  description: Associated transaction summary
  properties:
    transactionId: integer | null
    type: string (enum)      # See transaction type enum below
    date: string (YYYY-MM-DD)
    entryMethod: string (enum) # See entry method enum below
    amount: integer
    link:
      rel: string
      method: string
      href: string
```

---

## Enums

### authorizationResponse

Read these values from this file before emitting any code that compares or displays the
authorization response — do not guess or infer from training data.

`activityCountLimitExceeded` | `alreadyReversed` | `approved` | `approveVip` | `approveWithId` |
`cannotVerifyPin` | `cardAuthenticationFailed` | `cardTypeVerificationError` |
`cashRequestExceedsIssuerLimit` | `cashServiceNotAvailable` | `cidVerificationError` |
`contactCardIssuer` | `cryptographicFailure` | `dailyThresholdExceeded` | `declineCvv2Failure` |
`deny` | `denyAccountCanceled` | `denyClosedMerchant` | `denyNewCardIssued` | `denyPickUpCard` |
`destinationCannotBeFoundForRouting` | `doNotHonor` | `duplicateTransmissionDetected` | `error` |
`exceedsWithdrawalAmountLimit` | `expiredCard` | `fileTemporarilyUnavailable` | `forceStip` |
`formatError` | `forwardToIssuer` | `functionNotSupported` | `honorWithId` | `incorrectCvv` |
`incorrectPin` | `ineligibleForResubmission` | `insufficientFunds` | `invalidAccount` |
`invalidAccountNumber` | `invalidAmount` | `invalidAuthorizationLifeCycle` |
`invalidBillerInformation` | `invalidCardSecurityCode` | `invalidCurrencyCode` |
`invalidMerchant` | `invalidResponse` | `invalidTransaction` | `issuerNotAvailable` |
`issuerTimeout` | `issuerUnavailable` | `noActionTaken` | `noCardRecord` | `noCheckingAccount` |
`noCreditAccount` | `noFinancialImpact` | `noReasonToDecline` | `noSavingsAccount` |
`noSuchIssuer` | `partialApproval` | `partialAuthorization` | `pickUpCard` |
`pickUpCardSpecialCondition` | `pinChangeRequestDeclined` | `pinCryptographicErrorFound` |
`pinEntryTriesExceeded` | `pinNotChanged` | `pleaseCallIssuer` | `reenterTransaction` |
`referToCardIssuer` | `referToCardIssuerSpecialCondition` | `restrictedCard` | `reversal` |
`reversalDataInconsistent` | `revokeAllAuthorizationsOrder` |
`scheduledTransactionstoppedByCardholder` | `securityViolation` | `successful` |
`surchargeAmountNotPermitted` | `suspectFraud` | `systemMalfunction` |
`transactionAmountExceedsApprovalAmount` | `transactionCannotBeCompleted` |
`transactionNotAllowedAtMerchant` | `transactionNotAllowedAtTerminal` |
`transactionNotPermitted` | `transactionNotPermittedToCardholder` | `unableToGoOnline` |
`unableToLocateRecordInFile` | `unableToVerifyPin` | `unacceptablePin` | `unknown` | `unsafePin`

**Positive / approved-family values** (for filtering/display purposes):
`approved`, `approveVip`, `approveWithId`, `honorWithId`, `partialApproval`,
`partialAuthorization`, `successful`

**Reversal values:** `alreadyReversed`, `reversal`

### card.type

`visa` | `masterCard` | `discover` | `debit` | `ebt` | `wrightExpress` | `voyager` | `amex` |
`privateLabel` | `storedValue` | `discoverRetained` | `jcbNonSettled` | `dinersClub` |
`amexOptBlue` | `fuelman` | `unknown`

### transaction.type

`capture` | `return`

### transaction.entryMethod

`barcodeRead` | `smartChipRead` | `swipedOriginUnknown` | `contactlessChip` | `ecommerce` |
`manuallyEntered` | `manuallyEnteredFallback` | `swiped` | `swipedFallback` | `swipedError` |
`scannedCheckReader` | `credentialOnFile` | `unknown`

### batch.cycle

The API documentation example shows `"am"`. No exhaustive enum is documented — treat as a
free string; do not assume a fixed set of values.

---

## HTTP Status Codes

| Status | Meaning |
| --- | --- |
| 200 | Success — returns authorization object or paginated list |
| 400 | Bad request — validation error (see RFC 7807 error format) |
| 401 | Authentication failed — token missing, expired, or invalid |
| 403 | Forbidden — insufficient permissions for this resource |
| 404 | Not found — `authorizationId` does not exist (retrieve endpoint only) |
| 406 | Not acceptable — content type issue |
| 500 | Server error |

---

## Errors

Errors use the **RFC 7807 problem-details envelope** (`type`, `title`, `status`, `detail`, `instance`) extended with a Payroc `errors[]` array. See `references/error-response-format.md` for the envelope shape and the canonical error `type` catalog; read `errors[].parameter` to map each failure to your request body.

These are read/reporting (GET) endpoints, so the typical status set is `400` (invalid query params), `401` (auth), `403` (permissions), `404` (unknown `authorizationId`, retrieve endpoint only), `406` (content negotiation), and `500` (server).

---

## Example Response — Single Authorization

```json
{
  "authorizationId": 65,
  "createdDate": "2024-07-02",
  "lastModifiedDate": "2024-07-02",
  "authorizationResponse": "successful",
  "preauthorizationRequestAmount": 10000,
  "currency": "USD",
  "batch": {
    "batchId": 12,
    "date": "2024-07-02",
    "cycle": "am",
    "link": {
      "rel": "batch",
      "method": "get",
      "href": "https://api.payroc.com/v1/batches/12"
    }
  },
  "card": {
    "cardNumber": "453985******7062",
    "type": "visa",
    "cvvPresenceIndicator": true,
    "avsRequest": true,
    "avsResponse": "Y"
  },
  "merchant": {
    "merchantId": "4525644354",
    "doingBusinessAs": "Pizza Doe",
    "processingAccountId": 38765,
    "link": {
      "rel": "processingAccount",
      "method": "get",
      "href": "https://api.payroc.com/v1/processing-accounts/38765"
    }
  },
  "transaction": {
    "transactionId": 442233,
    "type": "capture",
    "date": "2024-07-02",
    "entryMethod": "swiped",
    "amount": 100,
    "link": {
      "rel": "transaction",
      "method": "get",
      "href": "https://api.payroc.com/v1/transactions/442233"
    }
  }
}
```

---

## Example Response — List (single page, no more results)

```json
{
  "limit": 10,
  "count": 1,
  "hasMore": false,
  "links": [
    {
      "rel": "self",
      "method": "get",
      "href": "https://api.payroc.com/v1/authorizations?date=2024-07-02"
    }
  ],
  "data": [
    { ...authorization object as above... }
  ]
}
```

## Example Response — List (paginated, more results available)

When `hasMore` is `true`, the `links` array includes a `rel: "next"` entry whose `href` is a
fully-formed URL for the next page. **Use this URL directly** — do not parse a cursor token out
of it. Add only the `Authorization` header.

```json
{
  "limit": 10,
  "count": 10,
  "hasMore": true,
  "links": [
    {
      "rel": "self",
      "method": "get",
      "href": "https://api.payroc.com/v1/authorizations?date=2024-07-02&limit=10"
    },
    {
      "rel": "next",
      "method": "get",
      "href": "https://api.payroc.com/v1/authorizations?date=2024-07-02&limit=10&after=eyJhd..."
    }
  ],
  "data": [
    { ...authorization objects... }
  ]
}
```

**Pagination note:** The `after` value embedded in the `next` link's `href` is an opaque cursor —
do not attempt to generate or modify it. When there are no more pages, `hasMore` is `false` and
no `rel: "next"` link is present.
