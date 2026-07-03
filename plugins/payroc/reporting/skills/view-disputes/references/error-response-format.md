# Payroc API error responses — RFC 7807 envelope + `errors[]`

Read this before writing any error-handling code. Emit error `type` URIs, status codes, and the
field shape from here — not from memory. (Local copy of the cross-skill error standard; the
status codes an *individual* endpoint returns are listed in that endpoint's section of
`api-schema.md`.)

## Shape: a standard envelope wrapping a Payroc-specific array

Payroc serves errors as `Content-Type: application/problem+json`, in two layers that come from
different places — keep them distinct:

1. **The envelope is [RFC 7807](https://datatracker.ietf.org/doc/html/rfc7807) Problem Details.**
   Top-level `type`, `title`, `status`, `detail`, and `instance` are the *standard* RFC members.
   "Errors follow RFC 7807" refers to **only** this envelope.
2. **The `errors` array is a Payroc extension** — not defined by RFC 7807. Each item carries:
   - **`parameter`** — JSON path of the field that failed (e.g. `country`, `base.annualFee.amount`).
     The most useful field: it maps an error straight back to your request body.
   - **`detail`** — a short reason (e.g. `"Invalid format"`, `"Required field not populated"`).
     **A different field from the top-level RFC `detail`** despite the shared name; don't conflate.
   - **`message`** — the human-readable explanation (e.g. `"The 'country' field is required"`).

`403` and `404` additionally carry a `resource` member (the resource type acted on); `403`, `404`,
and some `409`s carry `instance`.

## Verified shape

Real `400` from UAT (`POST` with an empty body — fails validation, creates nothing):

```json
{
  "type": "https://docs.payroc.com/api/errors#bad-request",
  "title": "Bad request",
  "status": 400,
  "detail": "One or more validation errors occurred, see error section for more info",
  "instance": "https://api.uat.payroc.com/v1/pricing-intents",
  "errors": [
    { "parameter": "country", "detail": "Invalid format", "message": "The 'country' field is required" }
  ]
}
```

## Canonical error `type` catalog

Problem `type` URIs live under `https://docs.payroc.com/api/errors#…`. Cite the ones the endpoint
can actually return; don't invent new ones.

| Status | `type` fragment | Meaning |
|--------|-----------------|---------|
| 400 | `#bad-request` | Validation error — inspect `errors[]` |
| 400 | `#idempotency-key-missing` | `Idempotency-Key` header required and absent |
| 400 | `#kyc-check-failed` | Entity rejected due to failed KYC checks |
| 400 | `#funding-accounts-limit-reached` | More than two funding accounts on the entity |
| 400 | `#no-control-prong-or-authorized-signatory` | Set one owner as the control prong or the authorized signatory |
| 400 | `#too-many-control-prongs` | Only one owner may be the control prong |
| 400 | `#daily-discount-and-reward-pay-conflict` | Daily Discount cannot combine with RewardPayChoice |
| 401 | `#not-authorized` | Identity could not be verified — re-authenticate |
| 403 | `#forbidden` | API key lacks the required permission |
| 404 | `#not-found` | Unknown resource id |
| 406 | `#not-acceptable` | Requested representation unsupported |
| 409 | `#idempotency-key-in-use` | Key already used against a *different* request |
| 409 | `#resource-already-exists` | The resource already exists |
| 409 | `#attribute-conflict` | A unique attribute (e.g. `key`) is already in use |
| 413 | `#payload-too-large` | Request body too large |
| 415 | `#unsupported-media-type` | Body sent in an unsupported format |
| 500 | `#api-error` | Server error — retry with exponential backoff |

## Spec vs. live — a known gap

The published OpenAPI (`docs.payroc.com/openapi.yml`) defines the error item schema `ErrorsItems`
with **only `message`**. The live API and prose docs (`docs.payroc.com/api/errors`) also return
`parameter` and `detail`. Build guidance from the **live** shape and read `errors[].parameter` to
find what failed. SDK/error types generated from the spec may expose only `message` until
`ErrorsItems` is corrected — mention this if the skill leans on generated error models.
