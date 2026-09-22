---
name: add-attachment-to-processing-account
description: >
  Guides developers through uploading a document file (PDF, image, spreadsheet, etc.) to a
  Payroc processing account (also called a merchant account) via the Boarding API multipart
  POST /v1/processing-accounts/{processingAccountId}/attachments endpoint. Use this skill when
  the user wants to upload or attach a document to a processing account, submit a supporting
  document file for merchant boarding or compliance, upload a bank statement or banking evidence
  document, attach merchant statements, tax documents, an MPA or amendment, proof of business,
  financial statements, personal identification documents, or any other file attachment to a
  Payroc processing account. Also use when the user asks how to use the
  /processing-accounts/{id}/attachments API endpoint, how to send a multipart/form-data
  upload to a processing account, how to retrieve attachment metadata or check the status of a
  previously uploaded file, or how to check the uploadStatus of an attachment. Do NOT use for
  creating or registering a new processing account, adding a bank account or funding account to
  a merchant, running payments or transactions, or any operation that does not involve uploading
  or retrieving file attachment metadata for an existing processing account.
metadata:
  version: "0.1.1"
  category: boarding
  status: draft
---

# Add Attachment to Processing Account

## Version check (run this first)

Before announcing anything or starting the flow, confirm this skill is current:

1. Read this skill's version from the `metadata.version` field in the frontmatter above.
2. Fetch the published copy and read its `metadata.version`:
   `https://raw.githubusercontent.com/payroc/skills/main/plugins/payroc/boarding/skills/add-attachment-to-processing-account/SKILL.md`
3. Compare the two as semantic versions:
   - **This version >= published** → continue silently, no message. (A developer running an unreleased newer version is expected and fine.)
   - **This version < published** → tell the developer:
     > ⚠️ A newer version of this skill (v\<published\>) has been published — you're running v\<current\>. Upgrading is recommended for the best results.

     Then ask whether they'd like to continue with the current version or stop and upgrade first, and honour their answer.
   - **Couldn't fetch** (offline, network error, 404) → note briefly that the version couldn't be verified and continue.

---

`POST https://api.payroc.com/v1/processing-accounts/{processingAccountId}/attachments` uploads
a supporting document to a processing account in the Payroc boarding system. Use this to
submit compliance, onboarding, or verification documents — banking evidence, statements,
identification, MPA copies, and more.

For the complete field reference, enum values, and a curl example, read
`references/api-schema.md` (load it when you need enum values, the `attachment` response
shape, or the exact multipart request structure).

---

## Quick reference

```
POST https://api.payroc.com/v1/processing-accounts/{processingAccountId}/attachments
Authorization:   Bearer <token>
Idempotency-Key: <uuid-v4>
Content-Type:    multipart/form-data   ← set by the HTTP client; do NOT set application/json
```

**Retrieve (after upload):**

```
GET https://api.payroc.com/v1/attachments/{attachmentId}
Authorization: Bearer <token>
```

---

## References

All enum values and schemas live in the local `references/` files — this skill emits from them,
not from live lookups or from memory.

| Source | Local file | Use for |
|--------|-----------|---------|
| API schema reference | `references/api-schema.md` | All enum values for `type` (AttachmentType); `uploadStatus` values; request body schema; response shape; error codes; file constraints |
| Auth reference | `references/identity-call.md` | Bearer token endpoint URL, request header name, response fields |
| Error format | `references/error-response-format.md` | Error envelope (RFC 7807) + Payroc errors[] + canonical error type catalog |

These are local snapshots, authoritative for this skill. Source URLs and last-synced dates are
in [`references/_sources.md`](references/_sources.md).

---

## Core Principles

1. **Inspect before asking** — scan the codebase before asking questions; use what you find to skip obvious setup questions.
2. **Ask before coding** — gather unknowns through intake before writing implementation code.
3. **Read the schema reference before emitting any enum value.** The `type` field on an attachment request accepts only the values documented in `references/api-schema.md` (`bankingEvidence`, `questionnairesAndLicenses`, `merchantStatements`, `taxDocuments`, `mpaOrAmendment`, `proofOfBusiness`, `financialStatements`, `personalIdentification`, `other`). Read the reference before you emit the value. Do not use training-data guesses.
4. **The request is `multipart/form-data`, not JSON.** This endpoint is the exception to the boarding API's usual `application/json` convention. The body has two parts: `attachment` (a JSON object sent as one multipart part) and `file` (binary content).
5. **Idempotency-Key on every POST.** The header value must be a UUID v4. Omitting it causes a 400. Generate a fresh UUID for each distinct upload.
6. **Obtain `processingAccountId` before uploading.** This is a hard prerequisite. If the developer doesn't have it, they must retrieve it from the boarding API before this skill can proceed.
7. **Privacy and consent first.** Before writing any upload code, tell the developer: they must comply with local privacy regulations and obtain the merchant's consent to process their information before uploading personal or business data on their behalf.
8. **Never hardcode credentials.** API keys and processing account IDs must come from environment variables or a secrets manager.

---

## Intake

**First, scan the codebase.** Look for:
- Server-side language and framework
- Existing HTTP client setup or file upload utilities
- Credential configuration (env vars, config files)
- Whether a `processingAccountId` is already available

Then ask the developer:

1. **What document are you uploading?** (Knowing the document type helps select the right `type` enum value — confirm the exact value against `references/api-schema.md`.)
2. **Do you have the `processingAccountId`** for the processing account you're attaching this to? If not, use the `add-processing-account` or `create-merchant-platform` skill first to create the account, or the Retrieve Merchant Platform endpoint to look it up.
3. **Do you also need to retrieve and check the upload status after submitting?** (If yes, include the retrieve step.)

---

## Prerequisites

These are needed to **run and test** the integration in UAT — not to write the code. If the developer already has them, proceed. If not, wire the code to read each value from an environment variable and keep building.

1. **API key** — used to generate Bearer tokens. Provisioned by the Payroc Integrations team.
2. **Processing account ID (`processingAccountId`)** — the ID of the processing account to attach the document to. This is a hard dependency — the upload endpoint path requires it.
3. **UAT environment** — Payroc's test environment. There is no self-serve signup; terminals and accounts are provisioned by the Payroc Integrations team.
4. **A test file** — any small document in an allowed format (PDF, JPEG, PNG, etc.) for testing.

**If anything is missing — warn, don't block.** Propose env var names like `PAYROC_API_KEY` and `PAYROC_PROCESSING_ACCOUNT_ID`. Write the code to read from those variables, then tell the developer:

> ⚠️ I've wired this to read your API key from `PAYROC_API_KEY` and the processing account ID from `PAYROC_PROCESSING_ACCOUNT_ID`. You'll need a Payroc UAT processing account to test this. Contact the Payroc Integrations team to get access.

### Checkpoint

Either the developer has confirmed the `processingAccountId` and API key, or they know what's outstanding and have chosen to proceed with code that reads from environment variables.

---

## Step 1 — Get a bearer token

> Read `references/identity-call.md` before emitting any auth code. Do not guess the endpoint URL, header name, or response shape — use only what the reference documents.

Tokens expire after 3600 seconds (1 hour). Exchange your API key once per session.

```bash
# Test / UAT
curl -X POST https://identity.uat.payroc.com/authorize \
  -H "x-api-key: $PAYROC_API_KEY"

# Production
curl -X POST https://identity.payroc.com/authorize \
  -H "x-api-key: $PAYROC_API_KEY"
```

Response:
```json
{
  "access_token": "eyJhbGc....",
  "expires_in": 3600,
  "token_type": "Bearer"
}
```

Use `Authorization: Bearer <access_token>` on every subsequent request. The Payroc SDKs
(TypeScript, Python, C#, PHP, Go, Java, Ruby) handle token exchange automatically — see
https://docs.payroc.com/api/payroc-sd-ks-beta.

### Checkpoint

Can a Bearer token be obtained without error? If not, verify the `x-api-key` header and confirm the API key is correct for the environment.

---

## Step 2 — Privacy and consent gate

**Before writing any upload code**, confirm with the developer that:

> You must follow local privacy regulations and obtain the merchant's consent to process their
> personal and business information before uploading documents on their behalf.

This is a gate — if the developer is building a system that will handle merchant documents
automatically, prompt them to add a consent step to their own flow before calling this API.

---

## Step 3 — Prepare the attachment metadata

> **Read `references/api-schema.md` before writing the `attachment` part.** The `type` field
> accepts only the values listed in the `AttachmentType` enum in the reference. Do not emit any
> type value from training data — use the documented enum value.

The `attachment` part of the multipart request is a JSON object:

| Field | Required | Notes |
|-------|----------|-------|
| `type` | Yes | Enum — read from `references/api-schema.md`. See AttachmentType. |
| `description` | No | Short plain-text summary of the file. |
| `metadata` | No | Your own key/value pairs (strings only); echoed back in the response. |

Help the developer select the right `type` value based on what they described in intake. The
enum values and their meanings are in `references/api-schema.md`. Match the document to the
most specific type; fall back to `other` only when nothing else fits.

---

## Step 4 — Upload the attachment

This is a `multipart/form-data` POST — **not** a JSON POST. The body has two parts:

- `attachment` — the JSON metadata object (Part 3 above). **Part name is `attachment` (singular)**, even though the upload URL path ends in `/attachments` (plural). Sending `attachments` (plural) as the part name will cause a 400.
- `file` — the **binary content** of the file, not a path string. In Python (requests library), pass `files={'file': open('/path/to/doc.pdf', 'rb')}` — not `files={'file': '/path/to/doc.pdf'}` (a string path). In curl, the `@` prefix (`-F 'file=@/path/to/doc.pdf'`) reads the bytes; do not omit it.

**Critical:** Do not set `Content-Type: application/json`. Most HTTP clients that support
multipart (curl, Python requests, etc.) set the correct `Content-Type: multipart/form-data`
boundary header automatically.

Always generate a fresh UUID v4 for `Idempotency-Key`. The key is bound to the request body, so
reuse the same key *only* to retry a byte-for-byte identical submission. On a new upload — or a
corrected re-upload after a `400`/`rejected` — generate a new UUID; reusing the old key with a
changed body returns `409`.

**Header name and casing.** The header must be spelled `Idempotency-Key` (capital I, capital K, hyphen). HTTP transit is case-insensitive, but some frameworks and API clients lowercase all header names before sending (e.g. a config map with `idempotency-key` or a camelCase SDK key `idempotencyKey`). If the server receives a missing or unrecognisable `Idempotency-Key` it returns `400 idempotencyKeyMissing`. Verify your HTTP client preserves the canonical casing.

**UUID value casing.** Standard UUID v4 generators often produce uppercase hex (e.g. `550E8400-E29B-41D4-A716-446655440000`). The curl examples pipe through `tr '[:upper:]' '[:lower:]'` as a defensive measure. If your language's UUID library produces uppercase and the API returns a 400, try lowercasing the value.

### curl example

```bash
curl -X POST https://api.uat.payroc.com/v1/processing-accounts/$PAYROC_PROCESSING_ACCOUNT_ID/attachments \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Idempotency-Key: $(uuidgen | tr '[:upper:]' '[:lower:]')" \
  -F 'attachment={"type":"bankingEvidence","description":"Q4 bank statement"};type=application/json' \
  -F 'file=@/path/to/document.pdf;type=application/pdf'
```

> **Sending the `attachment` part as JSON.** In curl, append `;type=application/json` to the
> `-F` value for the attachment part. In Python (requests library), pass `files={'attachment':
> (None, json.dumps(attachment_dict), 'application/json'), 'file': (filename, file_bytes, content_type)}`.
> The server needs to be able to parse the `attachment` part as JSON, so its content type must
> be set explicitly.

**File constraints** (read from `references/api-schema.md` before advising the developer):
- Maximum size: **50 MB uncompressed**
- Allowed formats: `.bmp`, `.csv`, `.doc`, `.docx`, `.gif`, `.htm`, `.html`, `.jpg`, `.jpeg`,
  `.msg`, `.pdf`, `.png`, `.ppt`, `.pptx`, `.tif`, `.tiff`, `.txt`, `.xls`, `.xlsx`
- Compressed files (`.zip`, `.gz`, `.rar`, etc.) are **not** accepted

### Checkpoint

Does the API return HTTP 201 with an `attachmentId`? If not, work through the error taxonomy below.

---

## Step 5 — Handle the upload response

**201 Created** — upload received:

```json
{
  "attachmentId": "ATT-XXXX",
  "type": "bankingEvidence",
  "uploadStatus": "pending",
  "fileName": "document.pdf",
  "contentType": "application/pdf",
  "description": "Q4 bank statement",
  "entity": {
    "type": "processingAccount",
    "id": "PA-XXXX"
  },
  "createdDate": "2026-06-22T10:00:00Z",
  "lastModifiedDate": "2026-06-22T10:00:00Z",
  "metadata": {
    "internalRef": "DOC-2026-001"
  }
}
```

The `metadata` field is optional and is echoed back in the response if you supplied it in the upload request. If you did not send `metadata`, it will be absent from the response.

**Persist `attachmentId` immediately.** The initial `uploadStatus` is `"pending"` — the file
has been received but not yet processed. Poll the retrieve endpoint to check for transition.

**IDs are opaque.** The `ATT-XXXX` / `PA-XXXX` forms in examples are for readability. In UAT,
IDs may be plain integers or UUID-like strings. Do not parse or validate them against a pattern.

---

## Step 6 — Poll upload status (if needed)

*(Include this section if the developer needs to confirm the document was accepted.)*

> **Different path root.** The retrieve endpoint lives under `/v1/attachments/{attachmentId}`, **not** under `/v1/processing-accounts/{id}/attachments/{attachmentId}`. A REST client with a base path of `/v1/processing-accounts/{id}` must use the standalone `/v1/attachments/{id}` path for retrieval.

```bash
curl https://api.uat.payroc.com/v1/attachments/$ATTACHMENT_ID \
  -H "Authorization: Bearer $ACCESS_TOKEN"
```

Response returns the `attachment` object. Check `uploadStatus`:

| Value | Meaning | Action |
|-------|---------|--------|
| `pending` | Not yet processed | Wait and poll again |
| `accepted` | Upload accepted | Document is on record; no further action needed |
| `rejected` | Upload rejected | Investigate: wrong file type, corrupted file, content policy. Re-upload with a corrected file and a new idempotency key |

> **The retrieve endpoint does not return the file bytes.** It returns metadata only. If you
> need to verify the file content, you must check your own copy.

### Checkpoint

Is `uploadStatus` `"accepted"`? If `"rejected"`, diagnose the cause and re-upload with a corrected file.

---

## Error taxonomy

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| 400 — missing required field | `attachment` part missing `type`, or `file` part absent | Ensure both `attachment` and `file` parts are in the multipart body; `type` is required on the `attachment` part |
| 400 — invalid `type` value | Enum value not from the reference | Read `references/api-schema.md` `AttachmentType` section; use only the documented values |
| 400 — `idempotencyKeyMissing` | `Idempotency-Key` header absent | Add `Idempotency-Key: <uuid-v4>` to every POST |
| 401 | Token missing, expired, or API key wrong | Re-generate token; verify `x-api-key` header is the correct UAT API key |
| 403 | Insufficient permissions | Check API key scope; contact Payroc support |
| 404 | Unknown `processingAccountId` | Verify the ID; use List Processing Accounts to find the correct ID |
| 406 | Not acceptable | Omit `Accept` header or set it to `application/json` |
| 409 — duplicate idempotency key | Same UUID reused with different payload | Generate a fresh UUID for a new upload |
| 413 — payload too large | File exceeds 50 MB | Split or reduce the document to under 50 MB uncompressed. Do **not** compress it — compressed formats (`.zip`, `.gz`, `.rar`, etc.) are not accepted and will cause a 415 |
| 415 — unsupported media type | File format not in the allowed list, or wrong `Content-Type` on request | Verify file extension is in the allowed list; check that the request `Content-Type` is `multipart/form-data` (not `application/json`) |
| `uploadStatus: rejected` | File failed backend processing | Check file integrity; verify the file is uncompressed; retry with a corrected file and a new idempotency key |
| 500 | Server error | Retry with exponential backoff; surface `errors` array if present |

**Reading validation errors** — the response uses the **RFC 7807 problem-details envelope**
(`type`, `title`, `status`, `detail`, `instance`); Payroc **extends** it with an `errors`
array (not defined by RFC 7807). Each `errors[]` item has `parameter` (JSON path of the
failing field), `detail` (short reason), and `message` (human-readable). Use `parameter`
to map each error back to the request. See
`references/error-response-format.md` for the envelope shape and the canonical error `type`
catalog.

---

## Common pitfalls

- **Wrong `Content-Type` on the request** — setting `application/json` on a multipart upload causes a `415` or parse error. Use `multipart/form-data`; let the HTTP client set the boundary.
- **`attachment` part not sent as JSON** — the `attachment` metadata part must have `Content-Type: application/json` within the multipart body. Sending it as plain text may cause the server to reject it.
- **Compressed files** — `.zip`, `.gz`, `.rar`, and other compressed formats are not accepted. The 50 MB limit is for the raw (uncompressed) file.
- **`type` enum wrong casing** — enum values are camelCase (`bankingEvidence`, not `banking_evidence` or `BankingEvidence`). Read the enum from `references/api-schema.md`. Two values have non-obvious casing traps:
  - `questionnairesAndLicenses` — both nouns are **plural** (`questionnaires`, not `questionnaire`; `Licenses`, not `License`). Common misspellings: `questionnaireAndLicense`, `questionnairesAndLicense`.
  - `mpaOrAmendment` — the conjunction `Or` has a **capital O** (it is part of the camelCase word boundary). Common misspelling: `mpaorAmendment` or `mpa_or_amendment`.
- **Missing `processingAccountId`** — this ID is required in the URL path. There is no attachment endpoint that doesn't require it.
- **Missing idempotency key** — all POST requests require `Idempotency-Key` or you get a `400 idempotencyKeyMissing`.
- **`uploadStatus: pending` is not a failure** — the file is received and queued for processing. Wait and poll before concluding the upload failed.

---

## Capability boundaries

This skill covers the two documented attachment endpoints only. If a developer asks about anything outside these operations, state clearly that it is not supported by the current API — do **not** invent or suggest undocumented endpoints.

| Operation | Supported? | Notes |
|-----------|-----------|-------|
| Upload an attachment to a processing account | Yes | `POST /v1/processing-accounts/{processingAccountId}/attachments` |
| Retrieve attachment details by ID | Yes | `GET /v1/attachments/{attachmentId}` — returns metadata only |
| List all attachments for a processing account | **No** | There is no documented endpoint to list all attachments. Do not invent a `GET /processing-accounts/{id}/attachments` list endpoint — it does not exist in the spec. |
| Download the uploaded file bytes | **No** | `GET /v1/attachments/{attachmentId}` returns attachment **metadata only** — not the file content. File bytes cannot be retrieved via the documented API. |
| Delete an attachment | **No** | There is no documented delete endpoint. |
| Update attachment metadata | **No** | There is no documented update/PATCH endpoint. |

If a developer asks to list all attachments, or to download file bytes, tell them clearly:
- Listing all attachments for a processing account is **not a documented API operation**.
- The only way to retrieve attachment information is by ID via `GET /v1/attachments/{attachmentId}`, which returns metadata only — not the file content.

---

## Validation checklist

- [ ] Privacy and consent confirmed before uploading merchant documents
- [ ] `processingAccountId` confirmed and read from environment variable — never hardcoded
- [ ] API key sourced from environment variable — never hardcoded
- [ ] Bearer token generated from identity service — never hardcoded
- [ ] `Idempotency-Key` header present and set to a UUID v4 on the upload POST
- [ ] `type` value read from `references/api-schema.md` `AttachmentType` enum — not from training data
- [ ] Request `Content-Type` is `multipart/form-data` (not `application/json`)
- [ ] `attachment` part includes `type` (required); `description` populated if useful
- [ ] `file` part is the binary file content, not a path string
- [ ] File is under 50 MB uncompressed and in an allowed format
- [ ] `attachmentId` captured from creation response for follow-on retrieval
- [ ] UAT endpoints used (`api.uat.payroc.com`) — not production endpoints during testing

---

## Full field reference

Read `references/api-schema.md` for:
- All `AttachmentType` enum values (9 values — do not guess)
- `AttachmentUploadStatus` enum values (`pending`, `accepted`, `rejected`)
- Complete `attachment` response schema
- File format restrictions and size limit
- Error table with HTTP status codes
