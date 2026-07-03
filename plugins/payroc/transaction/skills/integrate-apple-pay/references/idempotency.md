> **Canonical reference — Payroc idempotency keys.** Source: https://docs.payroc.com/api/idempotency
> Last synced: 2026-07-02. Authoritative for all skills that emit `POST`/`PATCH` calls against the Payroc REST API.

# Idempotency keys

Shared knowledge for **API-oriented Payroc skills**. Any skill that emits a `POST` or `PATCH`
request against a Payroc endpoint must generate and send an `Idempotency-Key` header. Adapt the
wording to the skill's voice; keep the mechanics and the facts.

## The mechanic

Idempotency prevents a record from being changed twice if the same request is sent more than
once. This matters most for retries: if a client sends a payment request, the gateway processes
it, but a network error prevents the client from receiving the response, a naive retry would
risk a duplicate charge. With a stable `Idempotency-Key`, the retry instead receives the original
response — nothing is processed twice.

## Requirements

- **Every `POST` and `PATCH` request must include an `Idempotency-Key` header.** Omitting it
  returns `400 Bad Request`.
- **The value must be a UUID v4.** Generate a fresh one per logical operation — not per HTTP
  attempt. A retry of the *same* operation should reuse the *same* key; a genuinely new operation
  needs a new key.

## How the API resolves a key

The API checks the combination of `Idempotency-Key` + URI + request body:

| Combination | Result |
|---|---|
| New key | Processed normally |
| Same key, same URI, same body | Returns the saved response from the first attempt — not reprocessed |
| Same key, but different URI or body | `409 Conflict` |

Payroc retains the request/response pairing for **7 days**.

## Drop-in wording for a skill's auth/request section

> Every `POST` and `PATCH` request must carry an `Idempotency-Key` header set to a fresh UUID v4.
> If you retry the same operation, reuse the same key — the API returns the original response
> instead of processing it again. Reusing a key with a different URI or body returns
> `409 Conflict`. Omitting the header returns `400 Bad Request`.

For the endpoint-specific consequences of a `409` (e.g. whether to regenerate the key or fix the
mismatched body), keep that guidance in the skill — this document standardizes only the
idempotency mechanic itself.
