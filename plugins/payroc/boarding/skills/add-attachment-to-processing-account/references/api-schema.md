# Add Attachment to Processing Account — API Schema Reference

> **Local snapshot — authoritative for this skill.** Source: `https://docs.payroc.com/openapi.yml`
> (paths `POST /processing-accounts/{processingAccountId}/attachments`,
> `GET /attachments/{attachmentId}`; schemas `attachment`, `AttachmentType`,
> `AttachmentUploadStatus`, `AttachmentEntityType`, `AttachmentEntity`,
> `ProcessingAccountsProcessingAccountIdAttachmentsPostRequestBodyContentMultipartFormDataSchemaAttachment`).
> Last synced: 2026-06-22. Emit field names and enum values from this file — not from memory.

---

## Contents

- [Endpoints](#endpoints)
- [Headers](#headers)
- [Request — Upload (multipart/form-data)](#request--upload-multipartform-data)
- [Enums](#enums)
- [Response — `attachment` object](#response--attachment-object)
- [Errors](#errors)
- [File constraints](#file-constraints)

---

## Endpoints

| Operation | Method & path | Request | Response |
|-----------|---------------|---------|----------|
| Upload attachment to processing account | `POST /v1/processing-accounts/{processingAccountId}/attachments` | `multipart/form-data` | `201` → `attachment` |
| Retrieve attachment details | `GET /v1/attachments/{attachmentId}` | — (path only) | `200` → `attachment` |

UAT host: `https://api.uat.payroc.com`  ·  Production host: `https://api.payroc.com`

> **Two different path roots.** The upload endpoint lives under `/processing-accounts/{id}/attachments`.
> Once uploaded, you retrieve an attachment directly by its own id under `/attachments/{attachmentId}`.

---

## Headers

| Header | Required on | Notes |
|--------|-------------|-------|
| `Authorization` | all | `Bearer <access_token>` |
| `Idempotency-Key` | `POST` (upload) | UUID v4; reuse on retry of the same submission |
| `Content-Type` | `POST` | `multipart/form-data` (set automatically by HTTP clients that support multipart) |

> **Do not set `Content-Type: application/json` on the upload.** The request body is
> `multipart/form-data` — the attachment metadata (`attachment` part) is a JSON object sent as
> one part of the multipart body, and the `file` part is binary. Most HTTP clients that support
> multipart (curl, Python requests, Go net/http, etc.) set the correct boundary automatically.

---

## Request — Upload (multipart/form-data)

The upload request has **two required parts**:

| Part name | Content | Required |
|-----------|---------|----------|
| `attachment` | JSON object describing the file — `type`, optional `description`, optional `metadata` | Yes |
| `file` | Binary content of the file | Yes |

### `attachment` part schema

```json
{
  "type": "bankingEvidence",        // required — AttachmentType enum
  "description": "Q4 bank statement", // optional — short text summary
  "metadata": {                     // optional — your key/value pairs
    "internalRef": "DOC-2026-001"
  }
}
```

Required: `type`.
Optional: `description`, `metadata`.

### curl example

```bash
curl -X POST https://api.uat.payroc.com/v1/processing-accounts/{processingAccountId}/attachments \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Idempotency-Key: $(uuidgen | tr '[:upper:]' '[:lower:]')" \
  -F 'attachment={"type":"bankingEvidence","description":"Q4 bank statement"};type=application/json' \
  -F 'file=@/path/to/statement.pdf;type=application/pdf'
```

> **Sending the `attachment` part as JSON.** In curl use `-F 'attachment=<json>;type=application/json'`.
> In other clients (Python requests, etc.) set the part's `Content-Type` to `application/json`
> explicitly so the server can parse it. If you send it as plain text, the server may reject it.

---

## Enums

### AttachmentType (upload `type` field)

Read this list from this file before emitting any `type` value. Do not guess.

| Value | Meaning |
|-------|---------|
| `bankingEvidence` | Bank account evidence / verification |
| `questionnairesAndLicenses` | Questionnaires, licenses, or permits |
| `merchantStatements` | Merchant processing statements |
| `taxDocuments` | Tax-related documents |
| `mpaOrAmendment` | Merchant Processing Agreement or amendment |
| `proofOfBusiness` | Business verification documents |
| `financialStatements` | Financial statements |
| `personalIdentification` | Personal ID documents |
| `other` | Any document that doesn't fit the above categories |

### AttachmentUploadStatus (response `uploadStatus` field — read-only)

| Value | Meaning |
|-------|---------|
| `pending` | Payroc has not yet processed the uploaded file |
| `accepted` | File was successfully uploaded and accepted |
| `rejected` | Payroc rejected the upload (file constraint violation or content issue) |

### AttachmentEntityType (response `entity.type` field — read-only)

| Value | Meaning |
|-------|---------|
| `processingAccount` | Attachment is linked to a processing account |

---

## Response — `attachment` object

Returned on both `POST` (201) and `GET` (200).

```json
{
  "attachmentId": "ATT-XXXX",
  "type": "bankingEvidence",
  "uploadStatus": "pending",
  "fileName": "statement.pdf",
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

**Required response fields:** `attachmentId`, `type`, `uploadStatus`, `fileName`, `contentType`,
`entity`, `createdDate`, `lastModifiedDate`.

**Note:** The upload status on a freshly created attachment is typically `pending`. Poll
`GET /v1/attachments/{attachmentId}` to check whether it transitions to `accepted` or `rejected`.

**IDs are opaque.** The `ATT-XXXX` / `PA-XXXX` forms in these examples are for readability only.
Treat every ID as an opaque string whose format is not guaranteed and varies by environment — in
UAT they come back as plain integers or UUID-like strings. Don't validate or parse them against a
`PREFIX-XXXX` pattern.

> **The retrieve endpoint does not return the original file bytes.** `GET /v1/attachments/{id}`
> returns metadata only (status, entity, dates, etc.) — not the file content.

---

## Errors

Errors use the **RFC 7807 problem-details envelope** (`type`, `title`, `status`, `detail`, `instance`) extended with a Payroc `errors[]` array. See `references/error-response-format.md` for the envelope shape and the canonical error `type` catalog; read `errors[].parameter` to map each failure to your request body.

Status codes these endpoints return: `400` (validation, incl. `idempotencyKeyMissing`), `401`
(auth/expired token), `403` (permissions), `404` (unknown `processingAccountId`/`attachmentId`),
`406` (content negotiation), `409` (idempotency-key reuse with a different body), `413` (payload
too large), `415` (unsupported media type), `500` (server — retry with backoff).

| Status | Scenario | Action |
|--------|----------|--------|
| 400 validation | Missing required part or field | Check that both `attachment` and `file` parts are present; fix each `errors[].parameter` field |
| 400 `idempotencyKeyMissing` | `Idempotency-Key` header absent | Add `Idempotency-Key: <uuid-v4>` to the request |
| 401 | Token expired or invalid | Re-authenticate; exchange API key for a fresh bearer token |
| 403 | Insufficient permissions | Check API key scope; contact Payroc support |
| 404 | Unknown `processingAccountId` | Verify the ID; use List Processing Accounts to find it |
| 406 | Not acceptable | Verify `Accept` header; omit or set to `application/json` |
| 409 | Conflict (e.g. duplicate idempotency key with different body) | Generate a fresh UUID for a new submission |
| 413 | Payload too large | Ensure file is under 50 MB uncompressed |
| 415 | Unsupported media type | Verify the file format is in the allowed list; use `multipart/form-data` content type |
| 500 | Server error | Retry with exponential backoff |

---

## File constraints

The attachment must be an **uncompressed file under 50 MB** in one of these formats:

`.bmp` `.csv` `.doc` `.docx` `.gif` `.htm` `.html` `.jpg` `.jpeg` `.msg` `.pdf` `.png`
`.ppt` `.pptx` `.tif` `.tiff` `.txt` `.xls` `.xlsx`

Compressed files (`.zip`, `.gz`, `.rar`, etc.) are not accepted.
