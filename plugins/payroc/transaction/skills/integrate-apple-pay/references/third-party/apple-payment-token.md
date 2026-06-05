> Derived reference (our own words — factual API surface only). Source: https://developer.apple.com/documentation/applepayontheweb/applepaypaymenttoken. Last synced: 2026-06-05. Re-derive or repoint to source to refresh. See ../_sources.md

# Apple Pay payment token — factual structure

When `onpaymentauthorized` fires, the event carries the authorized payment. The token field names below are what the integration reads to extract the encrypted payment data that gets forwarded to Payroc.

## Where the token sits on the event

```
event.payment.token.paymentData
```

- `event.payment` — the `ApplePayPayment` object.
- `event.payment.token` — the `ApplePayPaymentToken`.
- `event.payment.token.paymentData` — the encrypted payment data object (the part Payroc needs).
- `event.payment.token.paymentMethod` — non-encrypted descriptor of the card used (`displayName`, `network`, `type`).
- `event.payment.token.transactionIdentifier` — unique identifier string for the transaction.

## paymentData object (the encrypted payload)

`paymentData` is a JSON object with these top-level field names:

| Field | Notes |
| --- | --- |
| `data` | Base64-encoded, encrypted payment data (the sensitive content). |
| `signature` | Detached signature over the payload. |
| `version` | Encryption scheme identifier string (e.g. `EC_v1` for ECC, `RSA_v1` for RSA). |
| `header` | Object with key-exchange/cryptographic metadata. |

### header sub-object field names

| Field | Notes |
| --- | --- |
| `ephemeralPublicKey` | Present for the `EC_v1` scheme — sender's ephemeral public key. |
| `wrappedKey` | Present for the `RSA_v1` scheme instead of `ephemeralPublicKey`. |
| `publicKeyHash` | Hash of the public key associated with the merchant certificate. |
| `transactionId` | Transaction identifier (hex). |
| `applicationData` | Hash of any application data, when supplied. |

## Forwarding to Payroc

Payroc's payment request expects this token JSON serialized and hex-encoded as `paymentMethod.encryptedData` (see ../api-schema.md for the Payroc-side field names and the hex requirement described in the narrative guide). Apple owns the token structure above; Payroc owns the wrapper it goes into.
