> **Canonical reference — Payroc list pagination.** Source: https://docs.payroc.com/api/pagination
> Last synced: 2026-07-02. Authoritative for all skills that call a Payroc "list" endpoint.

# Pagination

Shared knowledge for **API-oriented Payroc skills**. Any skill that calls a Payroc endpoint
returning a list should describe pagination using the model below. Adapt the wording to the
skill's voice; keep the parameter names and the facts.

## The mechanic

Payroc's list endpoints use **cursor-based pagination** — results are split into pages you
retrieve with sequential requests, rather than returned all at once.

## Request parameters

| Parameter | Behavior |
|---|---|
| `before` | Retrieve results preceding a specified cursor value. Cannot be combined with `after`. |
| `after` | Retrieve results following a specified cursor value. Cannot be combined with `before`. |
| `limit` | Maximum results per page. Defaults to `10` if omitted. |

Omit both `before` and `after` to fetch the first page.

### Example request

```bash
curl -G https://api.payroc.com/v1/processing-accounts/38765/contacts \
     -H "Authorization: Bearer <token>" \
     -d limit=2
```

## Response shape

| Field | Description |
|---|---|
| `limit` | Maximum capacity of the page you requested. |
| `count` | Actual number of results returned on this page. |
| `hasMore` | `true` if further pages exist. |
| `data` | Array of the requested results. |
| `links` | HATEOAS array; each entry has `rel` (`next`/`previous`), `method` (HTTP verb), and `href` (URI for the adjacent page). |

### Example response

```json
{
  "limit": 2,
  "count": 2,
  "hasMore": true,
  "links": [
    {
      "rel": "next",
      "method": "get",
      "href": "https://api.payroc.com/v1/processing-accounts/38765/contacts?after=87926&limit=2"
    }
  ],
  "data": [
    { "contactId": 87925, "type": "manager", "firstName": "Jane", "lastName": "Doe" },
    { "contactId": 87926, "type": "representative", "firstName": "Fred", "lastName": "Nerk" }
  ]
}
```

## Drop-in wording for a skill's list-endpoint section

> This endpoint uses cursor-based pagination via `before`/`after`/`limit` query parameters
> (default `limit` is 10). Check `hasMore` in the response to know if further pages exist, and
> follow `links[].href` (where `rel` is `next`) rather than constructing the next URL yourself.

For the specific cursor field each endpoint paginates on (e.g. `contactId`, `transactionId`),
keep that in the skill — this document standardizes only the pagination mechanic itself.
