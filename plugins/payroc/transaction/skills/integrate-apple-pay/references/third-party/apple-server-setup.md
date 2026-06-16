> Derived reference (our own words — factual API surface only). Source: https://developer.apple.com/documentation/applepayontheweb/setting-up-your-server. Last synced: 2026-06-05. Re-derive or repoint to source to refresh. See ../_sources.md

# Apple Pay on the Web — merchant-validation flow (factual notes)

These notes cover the server-side merchant-validation handshake at the level of names and sequence. With Payroc, the start-session call that Apple's docs describe is made by Payroc on your behalf — your server forwards the validation URL to Payroc rather than calling Apple directly. The facts below explain what each side is doing.

## Domain association file

- File name (exact, no extension): `apple-developer-merchantid-domain-association`.
- Served at path: `/.well-known/apple-developer-merchantid-domain-association` over HTTPS, publicly reachable.
- Must be reachable before the domain is registered, because Apple fetches it during registration. (With Payroc, you download this file and register the domain through the Payroc Self-Care Portal — see the Payroc narrative guide.)

## Merchant validation sequence (names and order)

1. The browser fires `onvalidatemerchant` when the payment sheet opens. The event exposes `validationURL` (an Apple-hosted URL, valid briefly).
2. Your server must perform a "start session" / "merchant validation" request to that `validationURL`. The request body carries merchant identification:
   - `merchantIdentifier` — the registered Apple merchant ID.
   - `displayName` — merchant name shown on the sheet.
   - `initiative` — `web` for Apple Pay on the Web.
   - `initiativeContext` — the fully-qualified domain name serving the payment page.
   This request is authenticated with the Apple Pay Merchant Identity certificate (mutual TLS). With Payroc, Payroc holds the certificate and makes this call — your server posts the `validationURL` (and your Payroc `appleDomainId`) to Payroc's start-session endpoint instead.
3. Apple responds with an opaque **merchant session** object (a JSON blob). It is short-lived.
4. Your client passes that object, unmodified, to `session.completeMerchantValidation(merchantSession)`.

## Key facts that drive correct code

- The `validationURL` must be passed through verbatim — no re-encoding, trimming, or wrapping.
- The merchant session object returned must be handed to `completeMerchantValidation` exactly as received (do not re-serialize or nest it).
- The merchant session expires quickly; validate on demand per sheet open, do not cache and reuse.
