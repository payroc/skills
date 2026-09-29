# Payment Links — API Schema Reference

> **Local snapshot — authoritative for this skill.** Source: `https://docs.payroc.com/openapi.yml`
> (Payment Links schemas). Last synced: 2026-06-01. This is the offline source of truth this skill emits
> from — read enum values and required-field sets from here, not from memory. To refresh, re-fetch the
> source and regenerate this file (see [`_sources.md`](./_sources.md)).

Payment Links is a pure REST/JSON API — there is no form-POST surface. Every enum value and schema below
comes from the OpenAPI spec.

---

## Endpoints

| Operation | Method & path |
| --- | --- |
| [Create a payment link](#create-a-payment-link) | `POST /v1/processing-terminals/{processingTerminalId}/payment-links` |
| [List links for a terminal](#list-links-for-a-terminal) | `GET /v1/processing-terminals/{processingTerminalId}/payment-links` |
| [Retrieve a link](#retrieve-a-link) | `GET /v1/payment-links/{paymentLinkId}` |
| [Update a link (JSON Patch)](#update-a-link-json-patch) | `PATCH /v1/payment-links/{paymentLinkId}` |
| [Deactivate a link](#deactivate-a-link) | `POST /v1/payment-links/{paymentLinkId}/deactivate` |
| [Share a link by email](#share-a-link-by-email) | `POST /v1/payment-links/{paymentLinkId}/sharing-events` |
| [List sharing events](#list-sharing-events) | `GET /v1/payment-links/{paymentLinkId}/sharing-events` |

### Create a payment link

`POST /v1/processing-terminals/{processingTerminalId}/payment-links` — request/response body is
`multiUsePaymentLink` or `singleUsePaymentLink` (see [Schemas](#schemas) below, discriminated by `type`).
Returns `paymentLinkId` and `assets.paymentUrl`/`assets.paymentButton` on success (`201`).

### List links for a terminal

`GET /v1/processing-terminals/{processingTerminalId}/payment-links` — returns a
`paymentLinkPaginatedList` (see [Pagination](#pagination-list-endpoints)). Supports the
[List filter enums](#list-filter-enums) as query params (`linkType`, `chargeType`, `status`).

### Retrieve a link

`GET /v1/payment-links/{paymentLinkId}` — returns the full `multiUsePaymentLink` or
`singleUsePaymentLink` representation for the given `paymentLinkId`, including its current
`status`.

### Update a link (JSON Patch)

`PATCH /v1/payment-links/{paymentLinkId}` — body is a JSON Patch document (RFC 6902) array of
operations; see [JSON Patch `op` values](#json-patch-op-values-patch-request-rfc-6902). Typical
use: patch `expiresOn` to extend/shorten expiration. Requires the
[`Idempotency-Key` header](./idempotency.md).

### Deactivate a link

`POST /v1/payment-links/{paymentLinkId}/deactivate` — no request body. Transitions `status` to
`deactivated`; the link stops accepting payments. This endpoint does **not** require an
[`Idempotency-Key` header](./idempotency.md), unlike the other POST endpoints here.

### Share a link by email

`POST /v1/payment-links/{paymentLinkId}/sharing-events` — body is a `paymentLinkEmailShareEvent`
(see [Sharing](#sharing-paymentlinkemailshareevent-share-request-response)). Requires the [`Idempotency-Key` header](./idempotency.md). You need the `paymentLinkId` from the
create response (or from [List links for a terminal](#list-links-for-a-terminal) if you don't have
it) before you can share.

### List sharing events

`GET /v1/payment-links/{paymentLinkId}/sharing-events` — returns a `sharingEventPaginatedList`
(see [Pagination](#pagination-list-endpoints)) of every time the link was shared, each with its
`sharingEventId` and `dateTime`.

UAT host: `https://api.uat.payroc.com`  ·  Production host: `https://api.payroc.com`
Identity (UAT/test): `POST https://identity.uat.payroc.com/authorize` with header `x-api-key`.
Identity (production): `POST https://identity.payroc.com/authorize` with header `x-api-key`.

---

## Enums

### type (link type)
`multiUse` | `singleUse`

- `multiUse` — accepts unlimited payments.
- `singleUse` — one successful payment, then the link transitions to `completed`.

### authType (transaction type)
`sale` | `preAuthorization`

- `sale` — funds captured immediately.
- `preAuthorization` — funds held; capture later via the Payments API using the payment's ID.
- **Note:** if `authType` is `preAuthorization`, the customer must pay by card.

### paymentMethods[] (array items)
`card` | `bankTransfer`

### charge.type (discriminator)
`preset` | `prompt`

- `preset` — merchant sets the amount (`amount` is required and sits beside `type`).
- `prompt` — customer enters the amount at payment time (no `amount` field).

### status (read-only, returned by the API)
`active` | `completed` | `deactivated` | `expired`

### sharingMethod
`email`

### customLabels[].element
`paymentButton` (the only element whose label you can customise)

### credentialOnFile.mitAgreement
`unscheduled` (default) | `recurring` | `installment`
**Note:** if you send `mitAgreement`, you must also send the `standingInstructions` object in the payment order.

### JSON Patch `op` values (PATCH request, RFC 6902)
`add` | `remove` | `replace` | `move` | `copy` | `test`

### List filter enums
- `linkType`: `multiUse` | `singleUse`
- `chargeType`: `preset` | `prompt`
- `status`: `active` | `completed` | `deactivated` | `expired`

---

## Schemas

### charge (polymorphic, discriminated by `type`)

`charge` is a **single flat object** — `preset`/`prompt` are the *values* of `type`, not nested keys.
`amount`/`currency` are **siblings** of `type`.

```jsonc
// preset — merchant sets the amount
{ "type": "preset", "amount": 10000, "currency": "GBP" }   // required: type, amount, currency

// prompt — customer enters the amount (no amount field)
{ "type": "prompt", "currency": "GBP" }                     // required: type, currency
```

`amount` is an integer in the currency's lowest denomination (e.g. cents). `currency` is an ISO 4217 code.

> **Common mistake — the nested-`preset` trap.** `"charge": { "preset": { "amount": …, "currency": … } }`
> is wrong and the API returns 400. There is no `preset`/`prompt` *key*.

### multiUsePaymentLink (create request / response)

Required: `type`, `merchantReference`, `order`, `authType`, `paymentMethods`.

| Field | Type | Notes |
| --- | --- | --- |
| `type` | `multiUse` | required |
| `merchantReference` | string | required — merchant's own identifier for the payment |
| `order` | object | required — `{ description?, charge }`; `charge` required |
| `authType` | enum | required — `sale` \| `preAuthorization` |
| `paymentMethods` | array | required — items `card` \| `bankTransfer` |
| `customLabels` | array | optional — `{ element: "paymentButton", label }` |
| `assets` | object | response only — `{ paymentUrl, paymentButton }` |
| `status` | enum | response only |
| `paymentLinkId` | string | response only |
| `createdOn` | date `YYYY-MM-DD` | response only |
| `expiresOn` | date `YYYY-MM-DD` | optional |
| `credentialOnFile` | object | optional — `{ tokenize?, mitAgreement? }` |

`multiUsePaymentLinkOrder` requires only `charge` (`description` optional).

### singleUsePaymentLink (create request / response)

Required: `type`, `merchantReference`, `order`, `authType`, `paymentMethods`, **`expiresOn`**.

Same field set as multi-use, with two differences:

- `order` is a `singleUsePaymentLinkOrder` which **requires `orderId`** (and `charge`); `description` optional.
- `expiresOn` (`YYYY-MM-DD`) is **required** at the root.

### paymentLinkAssets (in responses)
`{ paymentUrl, paymentButton }` — both required. `paymentUrl` is the shareable URL; `paymentButton` is
embeddable HTML. Capture `paymentLinkId` and `assets.paymentUrl` from the create response.

### Sharing paymentLinkEmailShareEvent (share request / response)

```jsonc
{
  "sharingMethod": "email",          // required
  "recipients": [                     // required — array
    { "name": "Customer Name", "email": "customer@example.com" }  // both required
  ],
  "message": "Optional message",      // optional
  "merchantCopy": false               // optional, default false
}
```

Response (201) adds `sharingEventId` and `dateTime` (ISO 8601).

### Pagination (list endpoints)
`paymentLinkPaginatedList` / `sharingEventPaginatedList`: `{ limit, count, hasMore, links[], data[] }`.
Cursor-based via `limit`, `after`, `before` query params; `hasMore` indicates another page exists.

---

## Errors

Errors use the **RFC 7807 problem-details envelope** (`type`, `title`, `status`, `detail`, `instance`) extended with a Payroc `errors[]` array. See `references/error-response-format.md` for the envelope shape and the canonical error `type` catalog; read `errors[].parameter` to map each failure to your request body.

Across these endpoints, expect: `400`, `401`, `403`, `404` (unknown `paymentLinkId` / `processingTerminalId` in the path), `409` (idempotency-key reuse on a POST or PATCH), `500`.

---

## Required headers

| Header | Where | Notes |
| --- | --- | --- |
| `Authorization: Bearer <token>` | every request | token from the identity service; expires in 3600s |
| `Content-Type: application/json` | POST / PATCH | |
| `Idempotency-Key: <UUID v4>` | every POST and PATCH — **except** the deactivate sub-endpoint | required; fresh UUID per distinct operation (reuse → 409) |

`POST /v1/payment-links/{paymentLinkId}/deactivate` does not require `Idempotency-Key`. Sending
the header anyway is harmless; the gateway ignores it.
