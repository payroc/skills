# References — Source Registry

Last synced: 2026-09-16

| File | Source URL | Notes |
| --- | --- | --- |
| `identity-call.md` | https://docs.payroc.com/essentials/hosted-fields/authenticate-your-session.md (Step 1 only — Bearer token exchange) | Canonical auth reference; copied from `plugins/payroc/_shared/identity-call.md` |
| `api-schema.md` | https://docs.payroc.com/openapi.yml + https://docs.payroc.com/api/schema/notifications/event-subscriptions/ | Event subscription endpoints, request/response schemas, enum values extracted from OpenAPI spec and per-operation docs |
| `event-subscriptions-guide.md` | https://docs.payroc.com/guides/board-merchants/event-subscriptions.md + https://docs.payroc.com/guides/board-merchants/event-subscriptions/create-an-event-subscription.md | Narrative setup guide including webhook delivery behaviour, CloudEvents format, secret verification |

## Event type documentation

| Event type | Source URL |
| --- | --- |
| `processingAccount.status.changed` | https://docs.payroc.com/knowledge/events/events-list/processing-account-status-changed.md |
| `processingAccount.riskStatus.changed` | https://docs.payroc.com/knowledge/events/processingaccount-riskstatus-changed.md |
| `processingAccount.signature.signed` | https://docs.payroc.com/knowledge/events/processingaccount-signature-signed.md |
| `terminalOrder.status.changed` | https://docs.payroc.com/knowledge/events/events-list/terminal-order-status-changed.md |
| Events list overview | https://docs.payroc.com/knowledge/events/events-list.md |

## Regeneration

To refresh any file, re-fetch from the source URL(s) above and update the "Last synced" date here and in the file's own header.
