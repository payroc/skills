> Derived reference (our own words — factual API surface only). Source: https://developer.apple.com/documentation/applepayontheweb/applepaysession. Last synced: 2026-06-05. Re-derive or repoint to source to refresh. See ../_sources.md

# ApplePaySession — factual API surface

`ApplePaySession` is the browser-side class (Apple Pay JS API, Safari/WebKit only) that drives the Apple Pay payment sheet. The notes below list the names and signatures the integration wires against. Names are case-sensitive — emit them exactly as listed.

## Constructor

```
new ApplePaySession(version, paymentRequest)
```

- `version` — integer Apple Pay JS API version number (e.g. `3`). Pick the version whose features your `paymentRequest` uses; higher versions are not supported on older OS releases.
- `paymentRequest` — an object describing the payment (see fields below).

Constructing the session must happen synchronously inside the user-gesture handler (the click/tap on the Apple Pay button), otherwise the browser blocks the sheet.

## paymentRequest fields (constructor argument)

| Field | Notes |
| --- | --- |
| `countryCode` | Two-letter ISO 3166-1 country code of the merchant. |
| `currencyCode` | Three-letter ISO 4217 currency code. |
| `merchantCapabilities` | Array of capability strings; `supports3DS` is the standard entry for web. |
| `supportedNetworks` | Array of card-network identifier strings (e.g. `visa`, `masterCard`, `amex`, `discover`). Spelling is Apple's — read the source for the current set and exact casing. |
| `total` | Line-item object: `{ label, amount, type? }`. `amount` is a decimal string (major units, e.g. `"10.00"`). |
| `lineItems` | Optional array of additional line-item objects, same shape as `total`. |
| `requiredBillingContactFields` / `requiredShippingContactFields` | Optional arrays of contact-field name strings. |

## Static methods (on the class)

| Method | Returns / behaviour |
| --- | --- |
| `ApplePaySession.canMakePayments()` | Synchronous boolean. `true` if the device/browser can present Apple Pay. Gate button rendering on this. |
| `ApplePaySession.canMakePaymentsWithActiveCard(merchantIdentifier)` | Returns a Promise resolving to a boolean — also checks a provisioned card is present. |
| `ApplePaySession.supportsVersion(version)` | Boolean — whether the given JS API version is supported. |

## Instance methods

| Method | Behaviour |
| --- | --- |
| `begin()` | Presents the payment sheet. Call after constructing the session and assigning event handlers. Must run in the user-gesture context. |
| `completeMerchantValidation(merchantSession)` | Pass the opaque merchant-session object obtained from your server (which got it from the Payroc start-session call). Supply the raw object Apple returned, unwrapped. |
| `completePayment(result)` | Dismisses the sheet after authorization processing. Accepts either a status constant or a result object `{ status, errors? }`. |
| `abort()` | Cancels the session and dismisses the sheet. |
| `completeShippingContactSelection(...)` / `completeShippingMethodSelection(...)` / `completePaymentMethodSelection(...)` | Resolve the corresponding selection events when used. |

## Event handlers (assigned as properties on the session instance)

These are set as callbacks (e.g. `session.onvalidatemerchant = (event) => { ... }`), not added via `addEventListener` in typical usage.

| Handler | Fires when | Key event payload |
| --- | --- | --- |
| `onvalidatemerchant` | The sheet opens and Apple needs the merchant validated. | `event.validationURL` — pass this to your server verbatim; the server uses it to start the Payroc/Apple session. |
| `onpaymentauthorized` | The customer authorizes with Face ID / Touch ID / passcode. | `event.payment` — contains the payment token (see apple-payment-token.md). Process server-side, then call `completePayment`. |
| `onpaymentmethodselected` | The customer changes payment card. | `event.paymentMethod`. |
| `onshippingcontactselected` | The customer changes shipping contact. | `event.shippingContact`. |
| `onshippingmethodselected` | The customer changes shipping method. | `event.shippingMethod`. |
| `oncancel` | The customer dismisses the sheet, or the session is cancelled. | — |

## Status constants (static, on the class)

Pass to `completePayment`. Names are exact:

- `ApplePaySession.STATUS_SUCCESS`
- `ApplePaySession.STATUS_FAILURE`

Additional contact/error constants exist for selection failures (e.g. `STATUS_INVALID_BILLING_POSTAL_ADDRESS`, `STATUS_INVALID_SHIPPING_POSTAL_ADDRESS`, `STATUS_INVALID_SHIPPING_CONTACT`, `STATUS_PIN_REQUIRED`, `STATUS_PIN_INCORRECT`, `STATUS_PIN_LOCKOUT`) — check the source if you branch on those.

## Typical flow (names only)

1. `ApplePaySession.canMakePayments()` → render button only if `true`.
2. On click: `const session = new ApplePaySession(version, paymentRequest)`.
3. Assign `session.onvalidatemerchant`, `session.onpaymentauthorized`, `session.oncancel`.
4. `session.begin()`.
5. In `onvalidatemerchant`: server starts session → `session.completeMerchantValidation(merchantSession)`.
6. In `onpaymentauthorized`: server processes `event.payment.token` → `session.completePayment(ApplePaySession.STATUS_SUCCESS | STATUS_FAILURE)`.
