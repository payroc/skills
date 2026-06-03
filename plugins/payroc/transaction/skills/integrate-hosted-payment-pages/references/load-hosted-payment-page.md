> **Local snapshot — authoritative for this skill.** Source: https://docs.payroc.com/essentials/hosted-payment-page/run-a-sale/load-hosted-payment-page.md
> Last synced: 2026-06-01. Verbatim copy of the Payroc narrative guide. To refresh, re-fetch the source and regenerate this file (see _sources.md).

# Load the Hosted Payment Page

When your customer is ready to pay, you need to load the Hosted Payment Page. To do this, add a button to your checkout page that sends a POST request to our gateway. When we receive the POST request, the Hosted Payment Page loads and the customer can submit their payment details.

**Note:** The Hosted Payment Page doesn't return a transaction type in the transaction response. Because you can run sales, run pre-authorizations, and save a customer's payment details, we recommend that you record the transaction type in your system.

## Before you begin

Make sure you have the unique identifier that we assigned to the merchant's terminal. Send this in your POST request in the TERMINALID parameter.

## Send a POST request to load the Hosted Payment Page

To load the page, send a POST request to the Payment Page URL.

| Environment | URL                                                                                                          |
| :---------- | :----------------------------------------------------------------------------------------------------------- |
| Test        | [https://payments.uat.payroc.com/merchant/paymentpage](https://payments.uat.payroc.com/merchant/paymentpage) |
| Production  | [https://payments.payroc.com/merchant/paymentpage](https://payments.payroc.com/merchant/paymentpage)         |

### Request parameters

To create the body of your request, use the following parameters:

| Parameter  | Type   | Size             | Description                                                                                                                                                                                                               |
| :--------- | :----- | :--------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| TERMINALID | String | 1-50 characters  | Unique identifier that we assigned to the terminal.                                                                                                                                                                       |
| ORDERID    | String | 1-24 characters  | Unique identifier that the merchant assigns to the transaction.                                                                                                                                                           |
| CURRENCY   | String | 3 characters     | Currency of the transaction. The value for the currency follows the [ISO 4217](https://www.iso.org/iso-4217-currency-codes.html) standard.                                                                                |
| AMOUNT     | Double |                  | Subtotal of the transaction including taxes. Don't include surcharges or convenience fees.                                                                                                                                |
| DATETIME   | String |                  | Date and time that you send the request. Send this value in **DD-MM-YYYY:HH:MM:SS:SSS** format, for example, `06-02-2026:12:23:23:719`.                                                                                   |
| HASH       | String | 1-128 characters | SHA-512 hash value that you generate with values from the request parameters and the terminal secret. For more information about how to create your HASH, go to [Authenticate your requests](authenticate-your-requests). |

### Example request

```html
    <html>
        <body>
            <form action="https://payments.uat.payroc.com/merchant/paymentpage” method="post">
                <input type="hidden" name="TERMINALID" value="3204004" />
                <input type="hidden" name="ORDERID" value="HPP874417810" />
                <input type="hidden" name="CURRENCY" value="USD" />
                <input type="hidden" name="AMOUNT" value="10.00" />
                <input type="hidden" name="DATETIME" value="09-02-2026:14:37:58:558" />
                <input type="hidden" name="HASH" value="3fd844ad29c7bb0866ee412922dce796f4249587302d739ad4876dd606f5346cd2615c0c92350b3c062889037728390be813008af35e915a336f9da8c2c280ec" />
                <input type="submit" value="Pay Now" />
            </form>
        </body>
    </html>
```

## Errors

### INVALID HASH

If we can't authenticate your request, the Hosted Payment Page displays **INVALID HASH** in plain text. Check that you have set up your HASH correctly. For more information about the hash, go to [Authenticate your requests]().

### Validation Errors

The Hosted Payment Page runs basic validation checks on the customer's input. If the customer enters incorrect information, for example, a card number that is too short, the page displays an error message and prompts the customer to correct the information.

Your integration doesn't need to handle these validation errors because the Hosted Payment Page handles these errors for you.

## Next steps

* [Build the merchant’s receipt page](build-receipt-page).