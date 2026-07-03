# References — Source Registry

All files in this `references/` directory are local snapshots of external sources. This file records
where each snapshot came from and when it was last synced, so they can be refreshed when needed.

---

| File | Source URL | Last synced | Notes |
| --- | --- | --- | --- |
| `identity-call.md` | https://docs.payroc.com/essentials/hosted-fields/authenticate-your-session.md (Step 1 only — Bearer token exchange) | 2026-06-22 | Canonical auth reference; copied from `plugins/payroc/_shared/identity-call.md`. Refresh from `_shared/` if stale. |
| `api-schema.md` | https://docs.payroc.com/openapi.yml (paths: `/payments/{paymentId}/refund`, `/refunds`, `/refunds/{refundId}`, `/refunds/{refundId}/adjust`, `/refunds/{refundId}/reverse`; schemas: `referencedRefund`, `unreferencedRefund`, `retrievedRefund`, `refundAdjustment`, `refundSummary`, `payment`, `transactionResult`) | 2026-06-22 | Curated YAML slice covering card payment refund endpoints only. |
