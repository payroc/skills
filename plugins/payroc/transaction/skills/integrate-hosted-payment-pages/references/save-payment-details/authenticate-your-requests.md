> **Local snapshot — authoritative for this skill.** Source: https://docs.payroc.com/essentials/hosted-payment-page/extend-your-integration/save-a-customers-payment-details/authenticate-your-requests.md
> Last synced: 2026-06-04. Verbatim copy of the Payroc narrative guide. To refresh, re-fetch the source and regenerate this file (see ../_sources.md).

# Authenticate your requests

To load the Hosted Payment Page, you need to include a SHA-512 hash in the HASH parameter. The hash authenticates your request and prevents tampering with sensitive values during transit to our gateway.

Because you've already integrated with Hosted Payment Pages to [run a sale](../../run-a-sale), you've already added a terminal secret. However, the hash string for saving a customer's payment details is made up of different values.

## Build and hash the request string

Create a colon-delimited string from specific request parameter values, append your terminal secret, and then convert the string to a SHA-512 hash.

To create the hash string to save a customer's payment details, complete the following steps:

1. Build your hash with your parameter values in the following order:
   * `[TERMINALID]:[MERCHANTREF]:[DATETIME]:[ACTION]:[SECRET]`
2. Replace the placeholders with actual values:
   * `3204004:561234:10-02-2026:09:14:54:058:register:example_secret_123`
3. Use a hashing library in your programming language to convert the string to a SHA-512 hash:
   * `a674cad40ad2c6bb9421c053e254dbe5fa49335babd0360e15a7875b43c1dedb880df5ca000946a1376237a039bd36c33758c1a3a4c396a324d2534fbddacb44`

You send this value in the HASH parameter of your request to load the Hosted Payment Page.

> **Note (skill annotation, not part of the source page):** This hash recipe is **different from the sale/pre-auth recipe**. The sale recipe is `[TERMINALID]:[ORDERID]:[AMOUNT]:[DATETIME]:[SECRET]`. The save-card recipe **has no AMOUNT** (you are tokenizing, not charging), uses **MERCHANTREF** in place of ORDERID, and adds the **ACTION** field. Do not reuse the sale hash function unchanged.

## Next steps

* [Load the Hosted Payment Page](load-hosted-payment-page)
