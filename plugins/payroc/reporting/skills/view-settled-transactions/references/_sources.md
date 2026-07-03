# References — Source Registry

All files in this `references/` directory are local snapshots of external sources. This file records where each was fetched from and when. Regenerate from these URLs if a file looks stale.

Last synced: 2026-06-22.

---

## identity-call.md

**Local file:** `references/identity-call.md`
**Source:** https://docs.payroc.com/essentials/hosted-fields/authenticate-your-session.md (Step 1 only — Bearer token exchange)
**Purpose:** Canonical Payroc Identity Service schema — endpoint URL, request headers, response fields. Read this before emitting any auth code; do not guess these values.
**Last synced:** 2026-06-22

---

## api-schema.md

**Local file:** `references/api-schema.md`
**Sources:**
- https://docs.payroc.com/api/schema/reporting/settlement/list-batches.md
- https://docs.payroc.com/api/schema/reporting/settlement/retrieve-batch.md
- https://docs.payroc.com/api/schema/reporting/settlement/list-transactions.md
- https://docs.payroc.com/api/schema/reporting/settlement/retrieve-transaction.md
**Purpose:** All endpoint paths, query parameters, required-field sets, enum values, and response schemas for the settlement reporting API. Read this before emitting any query parameter value or response field name.
**Last synced:** 2026-06-22

---

## settlement-data-guide.md

**Local file:** `references/settlement-data-guide.md`
**Source:** https://docs.payroc.com/solutions/full-stack/view-reports/settlement-data.md
**Purpose:** Narrative guide covering the settlement workflow, reconciliation use cases, and the difference between the Reporting API and the Payments API. Read for context on how batches and transactions relate.
**Last synced:** 2026-06-22
