> Derived reference (our own words — factual API surface only). Sources: https://developer.apple.com/documentation/applepayontheweb/displaying-apple-pay-buttons-using-javascript and https://developer.apple.com/documentation/applepayontheweb/loading-the-latest-version-of-apple-pay-js. Last synced: 2026-06-05. Re-derive or repoint to source to refresh. See ../_sources.md

# Apple Pay button — rendering and gating (factual surface)

How the Apple Pay button is *drawn* is owned by Apple and is separate from the `ApplePaySession`
JS API in `apple-applepaysession.md` (which only covers presenting the sheet). Apple offers **two**
rendering approaches. Pick one and emit it completely — mixing them, or using the web component
without its SDK script, produces a button that never appears. Both render the real button only in
Safari / WebKit; on every other browser there is no Apple Pay and you must show a fallback.

## Approach A — CSS button (no script to load)

Style a normal element (e.g. a `<button>`) with Apple's button appearance. Nothing is loaded.

```css
.apple-pay-button {
  -webkit-appearance: -apple-pay-button;
  appearance: -apple-pay-button;
  -apple-pay-button-type: buy;     /* e.g. buy | plain | donate | checkout … */
  -apple-pay-button-style: black;  /* black | white | white-outline */
}
```

- Do **not** set the `--apple-pay-button-*` CSS custom properties here — those belong to the web
  component (Approach B), not the `-apple-pay-button` appearance. Mixing them is a no-op at best.
- Size/shape with ordinary CSS (`width`, `height`, `border-radius`).

## Approach B — `<apple-pay-button>` web component (requires the SDK script)

The `<apple-pay-button>` custom element is registered by Apple's Apple Pay JS SDK. You **must** load
the SDK script or the element never upgrades and renders nothing (zero height, no glyph):

```html
<script crossorigin src="https://applepay.cdn-apple.com/jsapi/1.latest/apple-pay-sdk.js"></script>
<apple-pay-button buttonstyle="black" type="buy" locale="en-US"></apple-pay-button>
```

- `1.latest` is Apple's recommended auto-updating path; a pinned major path also exists.
- Style via the `--apple-pay-button-*` CSS custom properties (`--apple-pay-button-width`,
  `--apple-pay-button-height`, `--apple-pay-button-border-radius`, …).
- The comment "the Apple Pay JS API is provided by Safari/WebKit, there is no script to load" is true
  for `ApplePaySession` — it is **false** for the `<apple-pay-button>` web component, which needs the
  SDK script above.

## Gating — hide the button until Apple Pay is available (and verify it actually hides)

Render/enable the button only when `ApplePaySession.canMakePayments()` is `true` (see
`apple-applepaysession.md`); otherwise show an alternative payment method.

**Pitfall — the `hidden` attribute can be silently overridden by your own CSS.** `hidden` works via
the user-agent rule `[hidden] { display: none }`. A normal author rule that sets `display` on the
button (e.g. `.apple-pay-button { display: block }`) **wins over** that UA rule (author origin beats
user-agent origin), so the button stays visible even though `hidden` is set — the gate is defeated
and the button appears on non-Apple browsers.

Gate so the hide actually takes effect:

- Toggle visibility in JS — set `el.style.display` / add-remove a class — rather than relying on the
  `hidden` attribute alone; **or**
- Keep the button's base CSS free of any `display` declaration (so the UA `[hidden]` rule can win),
  and apply layout `display` only in the class you add when Apple Pay is available.

Either way, confirm the rendered button is actually hidden when `ApplePaySession` is absent — do not
assume the `hidden` attribute beats your stylesheet.

```js
if (window.ApplePaySession && ApplePaySession.canMakePayments()) {
  applePayButton.style.display = 'block';      // explicit show — not just removing [hidden]
  applePayButton.addEventListener('click', onApplePayClicked);
} else {
  applePayButton.style.display = 'none';        // explicit hide — survives author CSS
  fallback.style.display = 'block';
}
```
