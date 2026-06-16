# Google Pay Web — PaymentsClient (derived notes)

> Derived reference (our own words — factual API surface only). Source: https://developers.google.com/pay/api/web/reference/client. Last synced: 2026-06-01. Re-derive or repoint to source to refresh. See ../_sources.md

Factual API surface (constructor, method names, argument/return types, property names, allowed constant
values) for `google.payments.api.PaymentsClient`. No prose copied from Google — names and shapes only.

---

## Constructor

`new PaymentsClient(paymentOptions)` → returns a `PaymentsClient` instance.

`paymentOptions` (PaymentOptions) properties:
- `environment` — `TEST` | `PRODUCTION`
- `merchantInfo`
- `paymentDataCallbacks`

(See `google-request-objects.md` for the shapes of these.)

## Methods

| Method | Argument | Returns |
| --- | --- | --- |
| `isReadyToPay` | `IsReadyToPayRequest` | `Promise<IsReadyToPayResponse>` |
| `loadPaymentData` | `PaymentDataRequest` | `Promise<PaymentData>` |
| `createButton` | `ButtonOptions` | `HTMLElement` |
| `prefetchPaymentData` | `PaymentDataRequest` | `void` |
| `onPaymentAuthorized` (callback) | `PaymentData` | `Promise<PaymentAuthorizationResult>` |
| `onPaymentDataChanged` (callback) | `IntermediatePaymentData` | `Promise<PaymentDataRequestUpdate>` |

## ButtonOptions (argument to `createButton`)

Property names include:
- `onClick`
- `buttonColor`
- `buttonType`
- `buttonSizeMode`

(Allowed string values for `buttonColor` / `buttonType` / `buttonSizeMode` are enumerated in the source;
confirm there when refreshing.)

## Usage notes (facts only)

- `isReadyToPay` is the readiness check; render the button only when it resolves truthy.
- `loadPaymentData` opens the payment sheet and resolves with a `PaymentData` object containing the
  encrypted token (path: `paymentMethodData.tokenizationData.token`).
- The Google Pay JS library is loaded from `https://pay.google.com/gp/p/js/pay.js`.
