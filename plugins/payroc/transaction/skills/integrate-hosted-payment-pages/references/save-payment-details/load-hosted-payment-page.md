> **Local snapshot — authoritative for this skill.** Source: https://docs.payroc.com/essentials/hosted-payment-page/extend-your-integration/save-a-customers-payment-details/load-hosted-payment-page.md
> Last synced: 2026-06-04. Verbatim copy of the Payroc narrative guide. To refresh, re-fetch the source and regenerate this file (see ../_sources.md).

# Load the Hosted Payment Page

When your customer wants to save their payment details, load the Hosted Payment Page. To do this, add a button to your checkout page that sends a POST request to our gateway. When we receive the POST request, the Hosted Payment Page loads and the customer can submit their payment details.

**Note:** The Hosted Payment Page doesn't return a transaction type in the transaction response. Because you can run sales, run pre-authorizations, and save a customer's payment details, we recommend that you record the transaction type in your system.

You can also use this page to update a customer's payment details. When you load the Hosted Payment Page, provide the MERCHANTREF to indicate the customer's secure token that you want to update and send a value for the ACTION parameter of `update` instead of `register`.

## Send a POST request to load the Hosted Payment Page

To load the page, send a POST request to the Secure Card Page URL.

| Environment | URL                                                                                                                |
| :---------- | :----------------------------------------------------------------------------------------------------------------- |
| Test        | [https://payments.uat.payroc.com/merchant/securecardpage](https://payments.uat.payroc.com/merchant/securecardpage) |
| Production  | [https://payments.payroc.com/merchant/securecardpage](https://payments.payroc.com/merchant/securecardpage)         |

> **Note (skill annotation, not part of the source page):** This endpoint is **`/merchant/securecardpage`**, not the sale endpoint `/merchant/paymentpage` and not the pre-auth endpoint `/merchant/preauthpage`. Saving a customer's payment details uses its own URL.

### Request parameters

To create the body of your request, use the following parameters:

| Parameter           | Type   | Size             | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| ------------------- | ------ | ---------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| ACTION              | Enum   |                  | Indicates if the customer is saving new payment details or if they are updating existing payment details. The value is one of the following:<br />- `register` - Customer is saving new payment details.<br />- `update` - Customer is updating existing payment details.                                                                                                                                                                                                    |
| TERMINALID          | String | 1-50 characters  | Unique identifier that we assigned to the terminal.                                                                                                                                                                                                                                                                                                                                                                                                                         |
| MERCHANTREF         | String | 1-200 characters | Unique identifier that the merchant assigns to the secure token.<br /><br />**Note:** We recommend that you store this value.                                                                                                                                                                                                                                                                                                                                               |
| DATETIME            | String |                  | Date and time that you send the request. Send this value in **DD-MM-YYYY:HH:MM:SS:SSS** format, for example, `06-02-2026:12:23:23:719`.                                                                                                                                                                                                                                                                                                                                     |
| HASH                | String | 1-128 characters | SHA-512 hash value that you generate with values from the request parameters and the terminal secret. For more information about how to create your hash, go to [Authenticate your requests].                                                                                                                                                                                                                                                                                |
| STOREDCREDENTIALUSE | Enum   |                  | Indicates how the merchant can use the card details, as agreed by the customer:<br />- `UNSCHEDULED` - Transactions for a fixed or variable amount that are run at a certain predefined event.<br />- `RECURRING` - Transactions for a fixed amount that are run at regular intervals, for example, monthly. Recurring transactions don't have a fixed duration and run until the customer cancels the agreement.<br />- `INSTALLMENT` - Transactions for a fixed amount that are run at regular intervals, for example, monthly. Installment transactions have a fixed duration.<br /><br />**Note:** Send a value for this parameter if the customer is saving card details. |

> **Note (skill annotation, not part of the source page):** On this HPP form POST, `STOREDCREDENTIALUSE` values are **UPPERCASE** (`UNSCHEDULED` / `RECURRING` / `INSTALLMENT`). The equivalent REST-API field (`mitAgreement` on the Secure Tokens / Payments API) uses the **lowercase** spelling (`unscheduled` / `recurring` / `installment`). Same concept, different casing per surface — read the surface you are emitting for.

## Next steps

* [Build the merchant's receipt page]()
