> **Canonical reference — Payroc Identity Service.** Source: https://docs.payroc.com/essentials/hosted-fields/authenticate-your-session.md (Step 1 only; the Hosted Fields session-token step is not included here).
> Last synced: 2026-06-22. Authoritative for all skills that call the Payroc REST API.

# Payroc Identity Service — Bearer Token Exchange

Every Payroc REST API call requires a Bearer token in the `Authorization` header. Bearer tokens are obtained by exchanging an API key against the Identity Service. Tokens expire after 3600 seconds (1 hour) — exchange a new token before each session, or refresh proactively before expiry.

> **Do not guess this endpoint URL, the request header name, or the response field names.** Emit them verbatim from this file.

---

## Endpoint

| Environment | URL |
| --- | --- |
| Test (UAT) | `https://identity.uat.payroc.com/authorize` |
| Production | `https://identity.payroc.com/authorize` |

Note the URL pattern: UAT has `.uat.` before `payroc.com`; production does not.

---

## Request

**Method:** `POST`

**Header:**

| Header | Value |
| --- | --- |
| `x-api-key` | Your API key for the environment |

No request body is required.

### Example request

```bash
# Test / UAT
curl -X POST https://identity.uat.payroc.com/authorize \
  -H "x-api-key: YOUR_API_KEY"

# Production
curl -X POST https://identity.payroc.com/authorize \
  -H "x-api-key: YOUR_API_KEY"
```

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

---

## Using the token on subsequent requests

Include the token in the `Authorization` header of every Payroc REST API call:

```text
Authorization: Bearer <access_token>
```

**Token lifetime guidance:**
- Exchange once per session (not once per request).
- If a request returns `401 Unauthorized` with a message indicating the token has expired, exchange a new one and retry.
- The Payroc SDKs (TypeScript, Python, C#, PHP, Go, Java, Ruby) handle token exchange automatically — see https://docs.payroc.com/api/payroc-sd-ks-beta.

---

## Environment variable names

Use environment variables for credentials — never hardcode API keys in source code.

| Purpose | Public env var name (skills + docs) | Notes |
| --- | --- | --- |
| API key | `PAYROC_API_KEY` | One per environment (test/prod) |

Internal test environments may use different names (`PAYROC_API_KEY_PAYMENTS`, etc.). Always check the integration context and use whatever env var name is already established in the codebase.
