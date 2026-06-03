> **Local snapshot — authoritative for this skill.** Source: https://docs.payroc.com/essentials/hosted-fields/extend-your-integration/add-your-own-fields.md
> Last synced: 2026-06-01. Verbatim copy of the Payroc narrative guide. To refresh, re-fetch the source and regenerate this file (see _sources.md).

# Add your own fields

You can add your own HTML fields to capture additional information about the customer or the transaction, for example, address information for the address verification service (AVS). After you capture the customer’s address information, you can send it in the payment request.

**Important:** If you add your own HTML fields, you are responsible for handling the additional information that you capture.

To help you understand how to add your own fields, we have created a worked example that you can follow. In our example, we capture billing details from the customer and then use the billing details in the payment request.

In our example, we complete the following actions:

1. [Add our own HTML fields.](#step-1-add-your-own-html-fields)
2. [Validate the data in the fields.](#step-2-validate-the-data-in-the-fields)
3. [Handle the response.](#step-3-handle-the-response)
4. [Retrieve the data from the fields.](#step-4-retrieve-the-data-from-the-fields)
5. [Create a payment request.](#step-5-create-payment-request)

## Step 1. Add your own HTML fields

In the following code block, we created a `<div>` to capture the customer's billing details and an error message for each required field.

```html
  <div class="billing-details">
      <!-- First Name and Last Name -->
      <div class="row" style="margin-bottom: -13px;">
        <div>
          <label for="firstName">First Name</label>
          <input class="input-box" type="text" id="firstName" required="">
          <div class="error" id="firstName-error">*Required</div>
        </div>
        <div>
          <label for="lastName">Last Name</label>
          <input class="input-box" type="text" id="lastName" required="">
          <div class="error" id="lastName-error">*Required</div>
        </div>
      </div>
      <!-- Street Address 1 -->
      <div>
        <label for="address1">Street Address</label>
        <input class="input-box" type="text" id="address1" required="">
        <div class="error" id="address1-error">*Required</div>
      </div>
      <!-- Street Address 2 -->
      <div>
        <label for="address2">Street Address 2</label>
        <input class="input-box" type="text" id="address2">
        <div></div>
      </div>
      <!-- City and Postal Code -->
      <div class="row" style="margin-bottom: -13px;">
        <div>
          <label for="city">City</label>
          <input class="input-box" type="text" id="city" required="">
          <div class="error" id="city-error">*Required</div>
        </div>
        <div>
          <label for="postalCode">Post Code</label>
          <input class="input-box" type="text" id="postalCode" required="">
          <div class="error" id="postalCode-error">*Required</div>
        </div>
      </div>
      <!-- Country-->
      <div class="container">
        <label for="country">Country</label>
        <select class="input-box" id="country">
          <option value="GB">Great Britain (GB)</option>
          <option value="IE">Republic of Ireland (IE)</option>
          <option value="US">United States (US)</option>
          <option value="CA">Canada (CA)</option>
          <option value="BR">Brazil (BR)</option>
        </select>
      </div>
  </div>
```

## Step 2. Validate the data in the fields

We use the onPreSubmit function to validate the data that the customer provides in our fields. If the field is empty or if the data doesn't match the format that we specify, the JS library doesn't submit the form to our gateway.

To use the onPreSubmit function in our worked example, we complete the following actions:

**Step 2a.** Add the onPreSubmit function.\
**Step 2b.** Define the onPreSubmit function.

### Step 2a. Add the onPreSubmit function

To delay the submission of the form until we validate the data the customer provides, we add the onPreSubmit function.

In the following code block, we add the onPreSubmit function.

```js
  this.form = new Payroc.hostedFields({
              sessionToken: sessionRequest['token'],
              mode: scenario,
              fields: fields,
              // Add the onPreSubmit function to validate the data in the fields before the JS Library sends the request to our gateway.
              onPreSubmit: () => this.validateCustomerDetails(),
          });
```

### Step 2b. Define the onPreSubmit function

We define the onPreSubmit function to specify the format and rules for the values that the customer must enter into the fields. If the field is missing a value, we call a [displayMissingFieldsError](#displaymissingfieldserror-function) function to display the error.

In the following code block, we check if the customer provides a value for each field.

```js
  async validateCustomerDetails() {
          // Check if the .billing-details is present, and returns false if there are no values in any of the fields.
          const customerDetails = document.querySelector(".billing-details");
          if (!customerDetails) return false;

          let validation = true;
          // Retrieve all values from inside the .billing-details div
          const requiredFields = customerDetails.querySelectorAll("input[required]");
          for (const field of requiredFields) {
                  // Check that the customer has provided a value for each field and that the value is in the correct format. 
                  if (!field.value.trim()) {
                  // Call a function to display any errors.
                  displayMissingFieldsError(field.id);
                  validation = false;
              }
          }
          // If the values are present and in the correct format, the JS Library sends the request to our gateway.
          return validation;
      }
```

#### displayMissingFieldsError function

If the customer doesn't enter a value in a field, the displayMissingFieldsError function displays an error for five seconds.

```js
  function displayMissingFieldsError(id) {
        const input = document.getElementById(id);
        // Locate the element that contains the error.
        const errorMessage = document.getElementById(id + "-error");
        input.classList.add('invalid');

        errorMessage.style.visibility = 'visible';  // Show the error message.
        setTimeout(() => {
          input.classList.remove('invalid');
          errorMessage.style.visibility = 'hidden'; // Hide the error message after five seconds.
        }, 5000); // 5000 ms = 5 seconds
      }
```

## Step 3. Handle the response

If the onPreSubmit function validates the values that the customer provides the JS library sends the request to our gateway, which returns a single-use token in the response.

In the following code block, we handle the response and close the Hosted Fields session.

```js
  this.form.on("submissionSuccess", async ({ token, expiresAt }) => {
              // Get the customer object using the data that the customer provided.
              const customer = this._getCustomerObject();
              // Forward all the required data to the server to create a payment request. 
              const response = scenario === "payment"
                  ? await yourServer.createPayment(customer, token)
                  : await yourServer.createSecureToken(customer, token);

              // Close the Hosted Fields session and display a response.
              document.querySelector('.billing-details').style.display = "none";
              document.querySelector(".pyrc-hosted-fields").style.display = "none";
              this._renderJSONResponse(response);
          });
```

## Step 4. Retrieve the data from the fields

After we sent the request and received the single-use token, we use the information from the form to create a payment request.

In the following code block, we retrieve the billing details that the customer provides and organize them into a billingAddress object.

```js
  // Retrieve the data from the fields and organize them into a billingDetails object within a customer object.
  _getCustomerObject() {
        let data = {};
              const billingAddress = this._getCustomFieldValues();
        if (Object.keys(billingAddress).length > 0) data['billingAddress'] = billingAddress;
        return data;
      }

      _getCustomFieldValues() {
          const fields = document.querySelectorAll(".billing-details input, .billing-details select");
          const values = {};

          fields.forEach(field => {
              const value = field.value;
              if (value) values[field.id] = value.trim();
          });

          return values;
      }
```

## Step 5. Create payment request

We add the information that we received from the customer and the single-use token to a [payment request](/api/schema/card-payments/payments/create), and then send the payment request to our gateway. For more information about how to create a payment request, go to [Run a card sale](/guides/take-payments/payments/run-a-card-sale).

In the following code block, we create a payment request using the billing details that the customer provides and the single-use token that we receive from the gateway.

```js
{
  "channel": "web",
  "processingTerminalId": "{TerminalID}",
  "order": {
    "orderId": "{OrderId}",
    "amount": 4999,
    "currency": "USD"
  },
  "customer": {
    "firstName": "Joe",
    "lastName": "Bloggs",
    "billingAddress": data['billingAddress']
  },
  "paymentMethod": {
    "secCode": "web",
    "token": "{single use token}",  
    "type": "singleUseToken"
  }
}
```