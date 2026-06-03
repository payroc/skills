> **Local snapshot — authoritative for this skill.** Source: https://docs.payroc.com/essentials/hosted-fields/create-a-payment-form.md
> Last synced: 2026-06-01. Verbatim copy of the Payroc narrative guide. To refresh, re-fetch the source and regenerate this file (see _sources.md).

# Create a payment form

To create a payment form with Hosted Fields you need to add HTML for the fields, and then add and configure our JavaScript library.

We provide HTML and JavaScript libraries for the following payment types:

* Card
* ACH
* PAD

You also need to add event listeners so that you can receive responses when a customer submits their payment details or if an error occurs. When a customer uses the payment form to submit their payment details, we return a single-use token that you need to run a sale.

## Before you begin

Make sure that your integration can [create a session token](authenticate-your-session) each time you initialize Hosted Fields.

## Integration steps

**Step 1**. Add HTML for each payment type.\
**Step 2**. Add and configure JavaScript.\
**Step 3**. Add event listeners.

## Step 1. Add HTML for each payment type.

**Important:** Each webpage can support only one payment type. To accept a different payment type, you need to create another webpage.

* Add the HTML for one of the payment types.

```html title="Card"
<div class="card-container payroc-form">
  <label for="card-holder-name">Cardholder Name</label>
  <div class="card-holder-name"></div>
  <div class="card-holder-name-error error-message"></div>
  <label for="card-number">Card Number</label>
  <div class="card-number"></div>
  <div class="card-number-error error-message"></div>
  <div class="cols-2">
    <div class="col">
      <label for="card-expiry">Expires (MM/YY)</label>
      <div class="card-expiry"></div>
      <div class="card-expiry-error error-message"></div>
    </div>
    <div class="card-cvv-wrapper">
      <div class="col">
        <label for="card-cvv">CVV</label>
        <div class="card-cvv"></div>
        <div class="card-cvv-error error-message"></div>
      </div>
    </div>
  </div>
  <div class="card-submit submit-button"></div>
</div>
```

```html title="ACH"
<div class="ach-container payroc-form">
  <div class="hosted-fields-message-container" id="hosted-fields-message-container"></div>
  <label for="ach-account-holder">Accountholder Name</label>
  <div class="ach-account-holder"></div>
  <div class="ach-account-holder-error error-message"></div>
  <label for="ach-account-type">Account Type</label>
  <div class="ach-account-type"></div>
  <div class="ach-account-type-error error-message"></div>
  <label for="ach-account-number">Account Number</label>
  <div class="ach-account-number"></div>
  <div class="ach-account-number-error error-message"></div>
  <label for="ach-routing-number">Routing Number</label>
  <div class="ach-routing-number"></div>
  <div class="ach-routing-number-error error-message"></div>
  <div class="ach-submit submit-button"></div>
</div>
```

```html title="PAD"
<div class="pad-container payroc-form">
  <label for="pad-account-holder">Accountholder Name</label>
  <div class="pad-account-holder"></div>
  <div class="pad-account-holder-error error-message"></div>
  <label for="pad-account-holder">Account Number</label>
  <div class="pad-account-number"></div>
  <div class="pad-account-number-error error-message"></div>
  <label for="pad-institution-number">Institution Number</label>
  <div class="pad-institution-number"></div>
  <div class="pad-institution-number-error error-message"></div>
  <label for="pad-transit-number">Transit Number</label>
  <div class="pad-transit-number"></div>
  <div class="pad-transit-number-error error-message"></div>
  <div class="pad-submit submit-button"></div>
</div>
```

**Note:** For the card HTML, we added the `col` and `col-2` custom CSS attributes to create the structure for the example form.

## Step 2. Add and configure the JavaScript library

We provide you with different JavaScript configurations depending on the payment type.

To add and configure JavaScript for Hosted Fields, complete the following steps:

* **Step 2a.** Insert the JavaScript library into your webpage.
* **Step 2b.** Configure the JavaScript library.

### Step 2a. Insert the JavaScript library into your webpage

Add the JavaScript library for your payment type to your webpage and ensure that the `<script>` tag loads and runs before the init code.

For card transactions, you also need to include the `wrapperTarget` property and either send a CSS selector for the wrapper element, or send a value of `false` if there is no wrapper.

```js title="Card"
<script
  src="https://cdn.uat.payroc.com/js/hosted-fields/hosted-fields-1.7.0.261457.js"
  integrity="sha384-m1A0nfFYa8sAfpDN0d60o4ztd/aCPC2xDVaOT31Urrmn4xypfHqgHQMayZeIK1PM"
  crossorigin="anonymous"
></script>

<script>
  const cardForm = new Payroc.hostedFields({
    sessionToken: YOUR_SESSION_TOKEN,
    mode: "payment",
    fields: {
      card: {
        cardholderName: {
          target: ".card-holder-name",
          errorTarget: ".card-holder-name-error",
          placeholder: "Cardholder Name",
        },
        cardNumber: {
          target: ".card-number",
          errorTarget: ".card-number-error",
          placeholder: "1234 5678 1234 1211",
        },
        cvv: {
          wrapperTarget: ".card-cvv-wrapper",
          target: ".card-cvv",
          errorTarget: ".card-cvv-error",
          placeholder: "CVV",
        },
        expiryDate: {
          target: ".card-expiry",
          errorTarget: ".card-expiry-error",
          placeholder: "MM/YY",
        },
        submit: {
          target: ".submit-button",
          value: "Pay Now",
        },
      },
    },
  });
  cardForm.initialize();
</script>
```

```js title="ACH"
<script
  src="https://cdn.uat.payroc.com/js/hosted-fields/hosted-fields-1.7.0.261457.js"
  integrity="sha384-m1A0nfFYa8sAfpDN0d60o4ztd/aCPC2xDVaOT31Urrmn4xypfHqgHQMayZeIK1PM"
  crossorigin="anonymous"
></script>

<script>
  const achForm = new Payroc.hostedFields({
    sessionToken: YOUR_SESSION_TOKEN,
    mode: "payment",
    fields: {
      ach: {
        nameOnAccount: {
          target: ".ach-account-holder",
          errorTarget: ".ach-account-holder-error",
          placeholder: "Accountholder Name",
        },
        accountType: {
          target: ".ach-account-type",
          errorTarget: ".ach-account-type-error",
        },
        achAccountNumber: {
          target: ".ach-account-number",
          errorTarget: ".ach-account-number-error",
          placeholder: "Account Number",
        },
        routingNumber: {
          target: ".ach-routing-number",
          errorTarget: ".ach-routing-number-error",
          placeholder: "Routing Number",
        },
        submit: {
          target: ".submit-button",
          value: "Pay Now",
        },
      },
    },
  });
  achForm.initialize();
</script>
```

```js title="PAD"
<script
  src="https://cdn.uat.payroc.com/js/hosted-fields/hosted-fields-1.7.0.261457.js"
  integrity="sha384-m1A0nfFYa8sAfpDN0d60o4ztd/aCPC2xDVaOT31Urrmn4xypfHqgHQMayZeIK1PM"
  crossorigin="anonymous"
></script>

<script>
  const padForm = new Payroc.hostedFields({
    sessionToken: YOUR_SESSION_TOKEN,
    mode: "payment",
    fields: {
      pad: {
        nameOnAccount: {
          target: ".pad-account-holder",
          errorTarget: ".pad-account-holder-error",
          placeholder: "Accountholder Name",
        },
        padAccountNumber: {
          target: ".pad-account-number",
          errorTarget: ".pad-account-number-error",
          placeholder: "Account Number",
        },
        institutionNumber: {
          target: ".pad-institution-number",
          errorTarget: ".pad-institution-number-error",
          placeholder: "Institution Number",
        },
        transitNumber: {
          target: ".pad-transit-number",
          errorTarget: ".pad-transit-number-error",
          placeholder: "Transit Number",
        },
        submit: {
          target: ".submit-button",
          value: "Pay Now",
        },
      },
    },
  });
  padForm.initialize();
</script>
```

### Step 2b. Configure the JavaScript library

1. In the sessionToken field, include your session token.
2. To test your integration in our test environment or run transactions in our production environment, use one of the following JavaScript configurations:

<table>
  <thead>
    <tr>
      <th>
        Environment
      </th>

      <th>
        Parameter
      </th>

      <th>
        Value
      </th>
    </tr>
  </thead>

  <tbody>
    <tr>
      <td rowspan="2">
        Test
      </td>

      <td>
        src
      </td>

      <td>
        [https://cdn.uat.payroc.com/js/hosted-fields/hosted-fields-1.7.0.261457.js](https://cdn.uat.payroc.com/js/hosted-fields/hosted-fields-1.7.0.261457.js)
      </td>
    </tr>

    <tr>
      <td>
        integrity
      </td>

      <td>
        sha384-m1A0nfFYa8sAfpDN0d60o4ztd/aCPC2xDVaOT31Urrmn4xypfHqgHQMayZeIK1PM
      </td>
    </tr>

    <tr>
      <td rowspan="2">
        Production
      </td>

      <td>
        src
      </td>

      <td>
        [https://cdn.payroc.com/js/hosted-fields/hosted-fields-1.7.0.261471.js](https://cdn.payroc.com/js/hosted-fields/hosted-fields-1.7.0.261471.js)
      </td>
    </tr>

    <tr>
      <td>
        integrity
      </td>

      <td>
        sha384-4KD8EaeEaCR2jLV6vnBwfEAEy/o2bR0GkODVpr8iePLTK5eOOmjoPuDVKJ0wM1oP
      </td>
    </tr>
  </tbody>
</table>

## Step 3. Add event listeners

To receive and handle responses from the payment form, you need to add event listeners to subscribe to the following events:

* **submissionSuccess** - Triggers when a customer successfully submits their payment details.
* **error** - Triggers when an error occurs with the payment form.

### submissionSuccess

When the customer successfully submits their payment details, our gateway tokenizes them and returns a single-use token in a submissionSuccess event. The response also includes the expiry time of the single-use token.

**Important:** Each webpage can support only one payment type. To accept a different payment type, you need to create another webpage.

To subscribe to the submissionSuccess event, add an event listener to the payment form. For example:

```js
cardForm.on("submissionSuccess", ({ token, expiresAt }) => {	 
});
```

When the submissionSuccess event triggers, we return the following fields:

| Field     | Description                                                      |
| :-------- | :--------------------------------------------------------------- |
| token     | Single-use token that represents the customer's payment details. |
| expiresAt | Expiry date and time of the single-use token.                    |

#### Example response

```js
{
  "token": "c96cb928e39c34bd05022cd821d2cbba2349f047ce0cef4f77cd2b5762be7608fb7c23e673bf014d58c64672928eb8256e38aa26911a22853143d22dd48ac9aa",
  "expiresAt": "2024-05-18T23:17:34.844Z"
}
```

### error

To help you identify and fix any errors that you might encounter when using Hosted Fields, subscribe to our error event. To subscribe to the error event, add an event listener to the form. For example:

```js
cardForm.on("error", ({ type, field, message }) => {
});
```

When the error event triggers, we return the following fields:

| Field   | Description                                                                                                                                                                                                                                                                                        |
| :------ | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| type    | Type of error. The value is one of the following:  • `config` - Error with the config object.  • `init` - Error occurred when we tried to initialize the JavaScript Library.  • `field` - Error occurred when we tried to embed a field.  • `submission` - Error with the cardholder’s submission. |
| field   | Field that has caused the error. If the error didn’t occur with a field, we return a value of `undefined`.                                                                                                                                                                                         |
| message | Details about the error.                                                                                                                                                                                                                                                                           |

#### Example response

```js
{
  "type": "field",
  "field": "cardNumber",
  "message": "The maximum number of retries to embed this field has been reached."
}
```

The following lists include the messages that we return for each type of error:

## `config` errors

* "The mode should be either 'payment' or 'tokenization'."
* "The gateway origin is not defined."
* "The api origin is not defined."
* "A valid config is required to use hosted fields."
* "An authentication token is required to use hosted fields."
* "Secure token must be a string."
* "Authentication token must be a string."
* "You have passed a secure token or are in tokenization mode but the terminal is not setup to allow secure tokens."
* "The mode must be set to 'tokenization' to use secure tokens."
* "A processing terminal ID is required to use hosted fields."
* "Processing terminal ID must be a number."
* "The css value in your config must be supported by the property."
* "The css key in your config must be an object as per the documentation."
* "Card, ACH or PAD fields are required for hosted fields."
* "Only one of Card, ACH or PAD fields should be supplied for hosted fields."
* "A card number field is required for card forms."
* "A card holder name field is required for card forms."
* "A card expiry field is required for card forms."
* "A card CVV field is required for card forms."
* "A card issue number field is required for card forms."
* "A submit button is required for payment forms."
* "An account holder field is required for PAD and ACH forms."
* "An account number field is required for PAD forms."
* "An institution number field is required for PAD forms."
* "A transit number field is required for PAD forms."
* "An account number field is required for ACH forms."
* "A routing number field is required for ACH forms."
* "An account type field is required for ACH forms."
* "An SEC code field is required for ACH forms."
* "The target selector supplied for card number either occurs more than once or does not exist on the page."
* "The target selector supplied for card issue number either occurs more than once or does not exist on the page."
* "The target selector supplied for card issue number wrapper either occurs more than once or does not exist on the page."
* "The target selector supplied for CVV wrapper either occurs more than once or does not exist on the page."
* "The target selector supplied for card issue number error either occurs more than once or does not exist on the page."
* "Card issue number wrapper is required for card forms. If you do not have a wrapper, please provide false."
* "CVV wrapper is required for card forms. If you do not have a wrapper, please provide false."
* "The target selector supplied for cardholder name either occurs more than once or does not exist on the page."
* "The target selector supplied for card expiry either occurs more than once or does not exist on the page."
* "The target selector supplied for card CVV either occurs more than once or does not exist on the page."
* "The target selector supplied for submit button either occurs more than once or does not exist on the page."
* "The target selector supplied for account holder either occurs more than once or does not exist on the page."
* "The target selector supplied for account number either occurs more than once or does not exist on the page."
* "The target selector supplied for institution number either occurs more than once or does not exist on the page."
* "The target selector supplied for transit number either occurs more than once or does not exist on the page."
* "The target selector supplied for account holder either occurs more than once or does not exist on the page."
* "The target selector supplied for account number either occurs more than once or does not exist on the page."
* "The target selector supplied for routing number either occurs more than once or does not exist on the page."
* "The target selector supplied for account type either occurs more than once or does not exist on the page."
* "The target selector supplied for SEC code either occurs more than once or does not exist on the page."
* "The error container target selector supplied for card number either occurs more than once or does not exist on the page."
* "The error container target selector supplied for cardholder name either occurs more than once or does not exist on the page."
* "The error container target selector supplied for card expiry either occurs more than once or does not exist on the page."
* "The error container target selector supplied for card CVV either occurs more than once or does not exist on the page."
* "The error container target selector supplied for submit button either occurs more than once or does not exist on the page."
* "The error container target selector supplied for account holder either occurs more than once or does not exist on the page."
* "The error container target selector supplied for account number either occurs more than once or does not exist on the page."
* "The error container target selector supplied for institution number either occurs more than once or does not exist on the page."
* "The error container target selector supplied for transit number either occurs more than once or does not exist on the page."
* "The error container target selector supplied for account holder either occurs more than once or does not exist on the page."
* "The error container target selector supplied for account number either occurs more than once or does not exist on the page."
* "The error container target selector supplied for routing number either occurs more than once or does not exist on the page."
* "The error container target selector supplied for account type either occurs more than once or does not exist on the page."
* "The error container target selector supplied for SEC code either occurs more than once or does not exist on the page."

## `init` errors

* "A session token is required to use hosted fields and was not received."
* "The request is unauthorised, please check your credentials."
* "The maximum number of retries to authenticate has been reached, please check your credentials."
* "Session request response is invalid."
* "You have passed ACH fields but the terminal is not setup to allow ACH."
* "You have passed PAD fields but the terminal is not setup to allow PAD."
* "You have passed PAD or ACH fields but the terminal is not setup to allow banks transfers."
* "The terminal does not support the capability you are trying to use."

## `field` errors

* "field must be provided in URL query parameters"
* "token must be provided in URL query parameters"
* "auth token must be provided in URL query parameters"
* "targetOrigin must be provided in URL query parameters"
* "Could not find input element on page"
* "Could not find radio buttons for ACH account type"
* "Could not find button element on page"
* "The maximum number of retries to embed this field has been reached."
* "The maximum number of retries to submit this field has been reached."

## `submission` errors

* "Invalid response from the payment gateway when submitting details"
* "Max number of retries has been reached"