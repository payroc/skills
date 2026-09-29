# References — source manifest

This skill emits from the local `references/` files below. Nothing is fetched live at runtime.
To refresh a file, re-fetch its source, regenerate it, then update the "Last synced" date here
and in the file's header.

| Local file | Source URL | Last synced | Provenance |
| --- | --- | --- | --- |
| `api-schema.md` | https://docs.payroc.com/openapi.yml (paths `POST /processing-accounts/{processingAccountId}/attachments`, `GET /attachments/{attachmentId}`; schemas `attachment`, `AttachmentType`, `AttachmentUploadStatus`, `AttachmentEntityType`, `AttachmentEntity`, `ProcessingAccountsProcessingAccountIdAttachmentsPostRequestBodyContentMultipartFormDataSchemaAttachment`) | 2026-09-16 | payroc-verbatim (curated slice) |
| `identity-call.md` | https://docs.payroc.com/essentials/hosted-fields/authenticate-your-session.md (Step 1 only — Bearer token exchange) | 2026-09-16 | payroc-verbatim (curated slice) |

Provenance legend: `payroc-verbatim` = Payroc-owned content copied/curated directly. The
attachment schemas are entirely Payroc-owned, so this skill has no `third-party-derived`
references.

## Notes

- The `attachment` response schema's required fields per the OpenAPI spec: `attachmentId`, `type`,
  `uploadStatus`, `fileName`, `contentType`, `entity`, `createdDate`, `lastModifiedDate`.
- The upload request body is `multipart/form-data` (not JSON) — this is unusual relative to most
  Payroc boarding endpoints which use `application/json`.
- The `uploadStatus` starts as `pending` immediately after upload. Poll the retrieve endpoint
  to check for transition to `accepted` or `rejected`.
- The retrieve endpoint (`GET /attachments/{attachmentId}`) returns metadata only — not file bytes.
- UAT testability is **yellow**: the upload path can be tested against UAT; however, the transition
  from `pending` to `accepted`/`rejected` depends on backend processing timing and may not be
  immediately observable.
