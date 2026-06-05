# Google Pay Web — Request Objects (derived notes)

> Derived reference (our own words — factual API surface only). Source: https://developers.google.com/pay/api/web/reference/request-objects. Last synced: 2026-06-01. Re-derive or repoint to source to refresh. See ../_sources.md

Factual API surface (object names, property names, structure, allowed constant values) for the request-side
objects of the Google Pay JS API. No prose copied from Google — names and shapes only. Confirm details
against the source URL when refreshing.

---

## PaymentOptions (passed to the PaymentsClient constructor)

| Property | Type | Required |
| --- | --- | --- |
| `environment` | string | optional |
| `merchantInfo` | MerchantInfo | optional |
| `paymentDataCallbacks` | PaymentDataCallbacks | optional |

`environment` accepts: `TEST`, `PRODUCTION`.

## IsReadyToPayRequest

| Property | Type | Required |
| --- | --- | --- |
| `apiVersion` | number | required |
| `apiVersionMinor` | number | required |
| `allowedPaymentMethods` | PaymentMethod[] | required |
| `existingPaymentMethodRequired` | boolean | optional |

## PaymentDataRequest

| Property | Type | Required |
| --- | --- | --- |
| `apiVersion` | number | required |
| `apiVersionMinor` | number | required |
| `merchantInfo` | MerchantInfo | required |
| `allowedPaymentMethods` | PaymentMethod[] | required |
| `transactionInfo` | TransactionInfo | conditional |
| `callbackIntents` | string[] | optional |
| `emailRequired` | boolean | optional |
| `shippingAddressRequired` | boolean | optional |
| `shippingAddressParameters` | ShippingAddressParameters | optional |
| `shippingOptionRequired` | boolean | optional |
| `shippingOptionParameters` | ShippingOptionParameters[] | optional |

(Recurring/deferred/automatic-reload transaction-info variants also exist; see source.)
`callbackIntents` accepts: `OFFER`, `PAYMENT_AUTHORIZATION`, `SHIPPING_ADDRESS`, `SHIPPING_OPTION`.

## PaymentDataCallbacks

| Property | Type | Required |
| --- | --- | --- |
| `onPaymentDataChanged` | function | optional |
| `onPaymentAuthorized` | function | required (when callbacks are used) |

## MerchantInfo

| Property | Type | Required |
| --- | --- | --- |
| `merchantId` | string | required |
| `merchantName` | string | optional |

## PaymentMethod (entry in `allowedPaymentMethods`)

| Property | Type | Required |
| --- | --- | --- |
| `type` | string | required |
| `parameters` | object (CardParameters for card) | required |
| `tokenizationSpecification` | TokenizationSpecification | optional |

`type` accepts: `CARD`.

## CardParameters (the `parameters` object when `type` is `CARD`)

| Property | Type | Required |
| --- | --- | --- |
| `allowedAuthMethods` | string[] | required |
| `allowedCardNetworks` | string[] | required |

`allowedAuthMethods` accepts: `PAN_ONLY`, `CRYPTOGRAM_3DS`.
`allowedCardNetworks` accepts: `AMEX`, `DISCOVER`, `INTERAC`, `JCB`, `MASTERCARD`, `VISA`.

## TokenizationSpecification

| Property | Type | Required |
| --- | --- | --- |
| `type` | string | required |
| `parameters` | object | required |

`type` accepts: `PAYMENT_GATEWAY`, `DIRECT`.

When `type` is `PAYMENT_GATEWAY`, the `parameters` object carries gateway keys:

| Key | Type |
| --- | --- |
| `gateway` | string |
| `gatewayMerchantId` | string |

> **Payroc owns the values for these two keys** — `gateway` and `gatewayMerchantId`. Read their exact values
> and derivation from the Payroc narrative copy (`../google-pay.md`), not from this Google reference. Google
> defines the *container* (where the keys sit inside `PaymentMethod.tokenizationSpecification.parameters`);
> Payroc defines what goes in them.

## TransactionInfo

| Property | Type | Required |
| --- | --- | --- |
| `totalPriceStatus` | string | required |
| `totalPrice` | string | required |
| `currencyCode` | string | required |
| `displayItems` | DisplayItem[] | optional |
| `totalPriceLabel` | string | optional |

`totalPriceStatus` accepts: `FINAL`, `ESTIMATED`, `NOT_CURRENTLY_KNOWN`.

## DisplayItem

| Property | Type | Required |
| --- | --- | --- |
| `label` | string | required |
| `type` | string | required |
| `price` | string | required |

`type` accepts: `LINE_ITEM`, `SUBTOTAL`, `TAX`, `SHIPPING`.

## Structure note

The encrypted payment token returned to the client lives inside the `PaymentData` result of
`loadPaymentData`, under `paymentMethodData.tokenizationData.token`. That token string is what Payroc expects
(hex-encoded) as `paymentMethod.encryptedData` — confirm the exact path against the source when refreshing.
