> **Canonical reference — Payroc Identity Service.** Source: https://docs.payroc.com/api/authentication
> Hosts: one endpoint for test and live keys, per the same page (Endpoint note).
> Last synced: 2026-11-03. Authoritative for all skills that call the Payroc REST API.

# Payroc Identity Service — Bearer Token Exchange

Every Payroc REST API call requires a Bearer token in the `Authorization` header. Bearer tokens are obtained by exchanging an API key against the Identity Service. Tokens expire after 3600 seconds (1 hour). Reuse one token across requests and exchange a new one shortly before it expires.

> **Do not guess this endpoint URL, the request header name, or the response field names.** Emit them verbatim from this file.

---

## Endpoint

`https://identity.payroc.com/authorize`

There is one identity endpoint and one API host (`https://api.payroc.com/v1`) for testing and for live
traffic. Your API key decides which: Payroc sends requests that use a test API key to its test environment,
so you don't change the endpoint to test. Create a test API key in the Payroc Developer Portal
(https://developers.payroc.com). Moving to production means swapping the key, not the URL.

> **Older test keys.** Payroc's earlier test setup used separate hosts, `identity.uat.payroc.com` and
> `api.uat.payroc.com`. A test key issued for those hosts may work only there, and gets a `401` from
> `identity.payroc.com`. If that happens, create a current test key in the Developer Portal. Don't write new
> code against the `.uat.` hosts.

---

## Request

**Method:** `POST`

**Header:**

| Header | Value |
| --- | --- |
| `x-api-key` | Your API key (test or live) |

No request body is required.

### Example request

```bash
curl -X POST https://identity.payroc.com/authorize \
  -H "x-api-key: YOUR_API_KEY"
```

### Client notes

Seen in the test environment in October 2026, when it ran on the separate `.uat.` hosts. The current
shared host and live traffic were not tested, so apply both everywhere.

- **Set a `User-Agent` on every request**, to the identity host and the API host. The default of Python's
  standard-library `urllib.request` (`Python-urllib/<version>`) is refused with `403` and the plain-text body
  `error code: 1010`. Use your own, for example your application's name and version. The default User-Agent
  strings of other common HTTP clients were accepted.
- **Never send `Content-Type: application/x-www-form-urlencoded`.** The identity call refuses that label with
  `415`, with or without a body. Send the `POST` with no body and no `Content-Type`, as in the example above.
  If your client always sets a `Content-Type`, use `application/json`: an empty body or `{}` with that label is
  accepted. In Python's `urllib.request`, pass `data=None`, because `data=b""` adds the form label.

---

## Response

### Success (HTTP 200)

| Field | Type | Description |
| --- | --- | --- |
| `access_token` | string | The Bearer token. Use in `Authorization: Bearer <access_token>` on all subsequent Payroc REST API calls. |
| `expires_in` | integer | Seconds until the token expires. Always `3600` (1 hour). |
| `scope` | string | Space-separated list of service identifiers that the token covers. |
| `token_type` | string | Always `"Bearer"`. |

### Example response

```json
{
  "access_token": "eyJhbGc....adQssw5c",
  "expires_in": 3600,
  "scope": "service_a service_b",
  "token_type": "Bearer"
}
```

### Failure responses

Check the status code before you parse the body: the `403` and `415` bodies are not JSON. Never use a token
from a response that is not `200`.

| Status | Meaning | What to do |
| --- | --- | --- |
| `401` | The API key is not valid, or it is an older test key issued for the earlier `.uat.` test hosts (see Endpoint). | Check the key. If it is an older test key, create a current one in the Developer Portal. Don't retry. |
| `403` with the plain-text body `error code: 1010` | Your client's `User-Agent` was refused. This is not a key or permissions problem. | Set a `User-Agent` (see Client notes). |
| `415` | The request carried a form `Content-Type`. | Send no body and no `Content-Type`, or use `application/json`. |
| `5xx` or timeout | Service or network failure. | Retry a few times with backoff, then fail and report the status code. |

---

## Using the token on subsequent requests

Include the token in the `Authorization` header of every Payroc REST API call, along with `Content-Type: application/json` and (on `POST`/`PATCH` requests) an `Idempotency-Key`:

```text
Authorization: Bearer <access_token>
Content-Type: application/json
Idempotency-Key: <UUID v4>
```

Some endpoints require a different `Content-Type`. Check that skill's own reference material for exceptions before assuming `application/json`.

**Token lifetime guidance:**
- Reuse one token for many requests. Record when you received it and its `expires_in`, then exchange a new
  one shortly before it expires (for example, a minute early). Don't exchange a token per request, and don't
  keep one past its hour in a long-running service.
- A `401` from an API call can mean the token is expired, missing or malformed. Payroc documents one generic
  body for all three (`"detail": "Your identity could not be verified"`), so don't wait for a message about
  expiry. On a `401`, exchange one new token and retry that request once, with the same `Idempotency-Key`.
  If the retry also returns `401`, stop and report it: the key may not cover that service (compare the
  token's `scope`).
- A `401` from the identity call itself means the API key is wrong (see Failure responses). Don't treat it
  as an expired token.

---

## Environment variable names

Use environment variables for credentials — never hardcode API keys in source code. Make the identity call
only from your server. Never put the API key in browser, mobile-app or other client-side code, and don't send
the Bearer token there either.

| Purpose | Public env var name (skills + docs) | Notes |
| --- | --- | --- |
| API key | `PAYROC_API_KEY` | A test key while you build, a live key in production. Same URLs for both |

Your codebase may already use different names. Always check the integration context and use whatever env var name is already established in the codebase.
