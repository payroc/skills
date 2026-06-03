> **Local snapshot — authoritative for this skill.** Source: https://docs.payroc.com/essentials/hosted-fields/extend-your-integration/update-a-customers-payment-details.md
> Last synced: 2026-06-01. Verbatim copy of the Payroc narrative guide. To refresh, re-fetch the source and regenerate this file (see _sources.md).

# Update a customer's payment details

If a customer uses Hosted Fields to change their payment details, our gateway returns a single-use token that represents the updated payment details. To update the customer’s saved payment details, send the single-use token to our gateway to update the secure token.

You can use a single-use token to update only the payment details linked to a secure token. To update the customer's contact details or the merchant-initiated transaction (MIT) agreement, go to Update a secure token.

## Before you begin

Make sure that you’ve set up your integration to [save payment details](save-a-customers-payment-details).

### Headers

To create the header of each POST request, you must include the following parameters:

* **Content-Type:** Include application/json as the value for this parameter.
* **Authorization:** Include your Bearer token in this parameter.
* **Idempotency-Key:** Include a UUID v4 to make the request idempotent.

```curl
-H "Content-Type: application/json"
-H "Authorization: <Bearer token>"
-H "Idempotency-Key: <UUID v4>"
```

To create the header of each GET request, include the Authorization header parameter.

```curl
-H "Authorization: <Bearer token>"
```

### Errors

Make sure that your integration can handle errors. If a request is unsuccessful, we return an error that follows the [RFC 7807 format](https://www.rfc-editor.org/rfc/rfc7807). For more information about errors, go to [Errors](/api/errors).

## Integration steps

1. List secure tokens.
2. Generate a session token.
3. Update the JavaScript library.
4. Update the secure token.

## Step 1. List secure tokens

Before you update the customer’s payment details, you need the secureTokenId of the secure token that represents the customer's payments details.

To search for the secureTokenId, use our List Secure Tokens method to view all the secure tokens associated with the processing terminal. You can use query parameters to filter your search, for example, you can filter by the customer’s name or email address.

To view the secure tokens associated with the processing terminal, send a GET request to our Secure Tokens endpoint.

| Endpoint   | Prefix     | URL                                                                                                                                                                                  |
| :--------- | :--------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Test       | `api.uat.` | [https://api.uat.payroc.com/v1/processing-terminals/\{processingTerminalId}/secure-tokens](https://api.uat.payroc.com/v1/processing-terminals/\{processingTerminalId}/secure-tokens) |
| Production | `api.`     | [https://api.payroc.com/v1/processing-terminals/\{processingTerminalId}/secure-tokens](https://api.payroc.com/v1/processing-terminals/\{processingTerminalId}/secure-tokens)         |

### Request parameters

To create your request, use the following parameters:

### Schema (`request`)

```yaml
openapi: 3.1.0
info:
  title: API
  version: 1.0.0
paths:
  /processing-terminals/{processingTerminalId}/secure-tokens:
    get:
      operationId: list
      summary: List secure tokens
      description: "Use this method to return a [paginated](https://docs.payroc.com/api/pagination) list of secure tokens.  \n\n**Note:** If you want to view the details of a specific secure token and you have its secureTokenId, use our [Retrieve Secure Token](https://docs.payroc.com/api/schema/tokenization/secure-tokens/retrieve) method.  \n\nUse query parameters to filter the list of results that we return, for example, to search for secure tokens by customer or by the first four digits of a card number.  \n\nOur gateway returns information about the following for each secure token in the list:  \n\n  -\tPayment details that the secure token represents.  \n  -\tCustomer details, including shipping and billing addresses.  \n  -\tSecure token that you can use to carry out transactions.  \n\n  For each secure token, we also return the secureTokenId, which you can use to perform follow-on actions.\n"
      tags:
        - subpackage_tokenization.subpackage_tokenization/secureTokens
      parameters:
        - name: processingTerminalId
          in: path
          description: Unique identifier that we assigned to the terminal.
          required: true
          schema:
            type: string
        - name: secureTokenId
          in: query
          description: Unique identifier that the merchant assigned to the secure token.
          required: false
          schema:
            type: string
        - name: customerName
          in: query
          description: Filter by the customer's name.
          required: false
          schema:
            type: string
        - name: phone
          in: query
          description: Filter by the customer's phone number.
          required: false
          schema:
            type: string
        - name: email
          in: query
          description: Filter by the customer's email address.
          required: false
          schema:
            type: string
        - name: token
          in: query
          description: >-
            Filter by the token that the merchant used in a transaction to
            represent the customer's payment details.
          required: false
          schema:
            type: string
        - name: first6
          in: query
          description: Filter by the first six digits of the card number.
          required: false
          schema:
            type: string
        - name: last4
          in: query
          description: Filter by the last four digits of the card or account number.
          required: false
          schema:
            type: string
        - name: before
          in: query
          description: >
            Return the previous page of results before the value that you
            specify.  


            You can’t send the before parameter in the same request as the after
            parameter. 
          required: false
          schema:
            type: string
        - name: after
          in: query
          description: >
            Return the next page of results after the value that you specify.  


            You can’t send the after parameter in the same request as the before
            parameter. 
          required: false
          schema:
            type: string
        - name: limit
          in: query
          description: Limit the maximum number of results that we return for each page.
          required: false
          schema:
            type: integer
            default: 10
      responses:
        '200':
          description: >-
            Successful request. Returns a list of secure tokens that are
            currently saved on the terminal.
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/secureTokenPaginatedListWithAccountType'
        '400':
          description: Invalid request
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/400'
        '401':
          description: Identity could not be verified
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/401'
        '403':
          description: Do not have permissions to perform this action
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/403'
        '406':
          description: Not acceptable
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/406'
        '500':
          description: An error has occured
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/500'
servers:
  - url: https://api.payroc.com/v1
  - url: https://api.uat.payroc.com/v1
components:
  schemas:
    '400':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
        errors:
          type: array
          items:
            $ref: '#/components/schemas/ErrorsItems'
      required:
        - type
        - title
        - status
        - detail
      title: '400'
    '401':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
      required:
        - type
        - title
        - status
        - detail
      title: '401'
    '403':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
        instance:
          type: string
          description: Resource path the action was attempted on
        resource:
          type: string
          description: Resource the action was attempted on
      required:
        - type
        - title
        - status
        - detail
      title: '403'
    '406':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
      required:
        - type
        - title
        - status
        - detail
      title: '406'
    '500':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
        errors:
          type: array
          items:
            $ref: '#/components/schemas/ErrorsItems'
      required:
        - type
        - title
        - status
        - detail
      title: '500'
    link:
      type: object
      properties:
        rel:
          type: string
          description: >-
            Indicates the relationship between the current resource and the
            target resource.
        method:
          type: string
          description: HTTP method that you need to use with the target resource.
        href:
          type: string
          description: URL of the target resource.
      required:
        - rel
        - method
        - href
      description: Object that contains HATEOAS links for the resource.
      title: link
    SecureTokenWithAccountTypeMitAgreement:
      type: string
      enum:
        - unscheduled
        - recurring
        - installment
      description: >
        Indicates how the merchant can use the customer's card details, as
        agreed by the customer:


        - `unscheduled` - Transactions for a fixed or variable amount that are
        run at a certain pre-defined event.

        - `recurring` - Transactions for a fixed amount that are run at regular
        intervals, for example, monthly. Recurring transactions don't have a
        fixed duration and run until the customer cancels the agreement.

        - `installment` - Transactions for a fixed amount that are run at
        regular intervals, for example, monthly. Installment transactions have a
        fixed duration.
      title: SecureTokenWithAccountTypeMitAgreement
    retrievedAddress:
      type: object
      properties:
        address1:
          type: string
          description: Address line 1.
        address2:
          type: string
          description: Address line 2.
        address3:
          type: string
          description: Address line 3.
        city:
          type: string
          description: City.
        state:
          type: string
          description: Name of the state or state abbreviation.
        country:
          type: string
          description: >-
            Two-digit country code for the country that the business operates
            in. The format follows the
            [ISO-3166-1](https://www.iso.org/iso-3166-country-codes.html)
            standard.
        postalCode:
          type: string
          description: Zip code or postal code.
      description: Object that contains information about the address.
      title: retrievedAddress
    retrievedShipping:
      type: object
      properties:
        recipientName:
          type: string
          description: Recipient's name.
        address:
          $ref: '#/components/schemas/retrievedAddress'
      description: >-
        Object that contains information about the customer and their shipping
        address.
      title: retrievedShipping
    contactMethod:
      oneOf:
        - type: object
          properties:
            type:
              type: string
              enum:
                - email
              description: 'Discriminator value: email'
            value:
              type: string
              description: Email address.
          required:
            - type
            - value
          description: email variant
        - type: object
          properties:
            type:
              type: string
              enum:
                - phone
              description: 'Discriminator value: phone'
            value:
              type: string
              description: Phone number.
          required:
            - type
            - value
          description: phone variant
        - type: object
          properties:
            type:
              type: string
              enum:
                - mobile
              description: 'Discriminator value: mobile'
            value:
              type: string
              description: Mobile number.
          required:
            - type
            - value
          description: mobile variant
        - type: object
          properties:
            type:
              type: string
              enum:
                - fax
              description: 'Discriminator value: fax'
            value:
              type: string
              description: Fax number.
          required:
            - type
            - value
          description: fax variant
      discriminator:
        propertyName: type
      title: contactMethod
    RetrievedCustomerNotificationLanguage:
      type: string
      enum:
        - en
        - fr
      description: >
        Language that the customer uses for notifications. This code follows the
        [ISO 639-1](https://www.iso.org/iso-639-language-code) alpha-2
        standard. 
      title: RetrievedCustomerNotificationLanguage
    retrievedCustomer:
      type: object
      properties:
        firstName:
          type: string
          description: Customer's first name.
        lastName:
          type: string
          description: Customer's last name.
        dateOfBirth:
          type: string
          format: date
          description: >-
            Customer's date of birth. The format for this value is
            **YYYY-MM-DD**.
        referenceNumber:
          type: string
          description: >
            Identifier of the transaction, also known as a customer code. 


            For requests, you must send a value for **referenceNumber** if the
            customer provides one. 
        billingAddress:
          $ref: '#/components/schemas/retrievedAddress'
          description: >-
            Object that contains information about the address that the card is
            registered to.
        shippingAddress:
          $ref: '#/components/schemas/retrievedShipping'
        contactMethods:
          type: array
          items:
            $ref: '#/components/schemas/contactMethod'
          description: "Array of polymorphic objects, which contain contact information.  \n\nThe value of the type parameter determines which variant you should use:  \n-\t`email` - Email address \n-\t`phone` - Phone number\n-\t`mobile` - Mobile number\n-\t`fax` - Fax number\n"
        notificationLanguage:
          $ref: '#/components/schemas/RetrievedCustomerNotificationLanguage'
          description: >
            Language that the customer uses for notifications. This code follows
            the [ISO 639-1](https://www.iso.org/iso-639-language-code) alpha-2
            standard. 
      description: >-
        Object that contains the customer's contact details and address
        information.
      title: retrievedCustomer
    AchSourceWithAccountTypeType:
      type: string
      enum:
        - ach
      title: AchSourceWithAccountTypeType
    AchSourceWithAccountTypeAccountType:
      type: string
      enum:
        - checking
        - savings
      description: |
        Indicates the customer's account type.
      title: AchSourceWithAccountTypeAccountType
    PadSourceWithAccountTypeType:
      type: string
      enum:
        - pad
      title: PadSourceWithAccountTypeType
    PadSourceWithAccountTypeAccountType:
      type: string
      enum:
        - checking
        - savings
      description: |
        Indicates the customer's account type.
      title: PadSourceWithAccountTypeAccountType
    currency:
      type: string
      enum:
        - AED
        - AFN
        - ALL
        - AMD
        - ANG
        - AOA
        - ARS
        - AUD
        - AWG
        - AZN
        - BAM
        - BBD
        - BDT
        - BGN
        - BHD
        - BIF
        - BMD
        - BND
        - BOB
        - BOV
        - BRL
        - BSD
        - BTN
        - BWP
        - BYR
        - BZD
        - CAD
        - CDF
        - CHE
        - CHF
        - CHW
        - CLF
        - CLP
        - CNY
        - COP
        - COU
        - CRC
        - CUC
        - CUP
        - CVE
        - CZK
        - DJF
        - DKK
        - DOP
        - DZD
        - EGP
        - ERN
        - ETB
        - EUR
        - FJD
        - FKP
        - GBP
        - GEL
        - GHS
        - GIP
        - GMD
        - GNF
        - GTQ
        - GYD
        - HKD
        - HNL
        - HRK
        - HTG
        - HUF
        - IDR
        - ILS
        - INR
        - IQD
        - IRR
        - ISK
        - JMD
        - JOD
        - JPY
        - KES
        - KGS
        - KHR
        - KMF
        - KPW
        - KRW
        - KWD
        - KYD
        - KZT
        - LAK
        - LBP
        - LKR
        - LRD
        - LSL
        - LTL
        - LVL
        - LYD
        - MAD
        - MDL
        - MGA
        - MKD
        - MMK
        - MNT
        - MOP
        - MRO
        - MRU
        - MUR
        - MVR
        - MWK
        - MXN
        - MXV
        - MYR
        - MZN
        - NAD
        - NGN
        - NIO
        - NOK
        - NPR
        - NZD
        - OMR
        - PAB
        - PEN
        - PGK
        - PHP
        - PKR
        - PLN
        - PYG
        - QAR
        - RON
        - RSD
        - RUB
        - RWF
        - SAR
        - SBD
        - SCR
        - SDG
        - SEK
        - SGD
        - SHP
        - SLL
        - SOS
        - SRD
        - SSP
        - STD
        - STN
        - SVC
        - SYP
        - SZL
        - THB
        - TJS
        - TMT
        - TND
        - TOP
        - TRY
        - TTD
        - TWD
        - TZS
        - UAH
        - UGX
        - USD
        - USN
        - USS
        - UYI
        - UYU
        - UZS
        - VEF
        - VES
        - VND
        - VUV
        - WST
        - XAF
        - XCD
        - XOF
        - XPF
        - YER
        - ZAR
        - ZMW
        - ZWL
      description: >-
        Currency of the transaction. The value for the currency follows the [ISO
        4217](https://www.iso.org/iso-4217-currency-codes.html) standard.
      title: currency
    surcharging:
      type: object
      properties:
        allowed:
          type: boolean
          description: >-
            Indicates if the merchant can add a surcharge when the customer uses
            this card.
        amount:
          type: integer
          format: int64
          description: >
            Surcharge amount to add to the transaction.  

            **Note:** Our gateway returns the surcharge amount only if you
            include a transaction amount in the request.
        percentage:
          type: number
          format: double
          description: Surcharge rate that the merchant configures on their account.
        disclosure:
          type: string
          description: Statement that informs the customer about the surcharge fee.
      required:
        - allowed
      description: >-
        Object that contains surcharge information. Our gateway returns this
        object only if the merchant adds a surcharge to transactions.
      title: surcharging
    SecureTokenWithAccountTypeSource:
      oneOf:
        - type: object
          properties:
            type:
              $ref: '#/components/schemas/AchSourceWithAccountTypeType'
            nameOnAccount:
              type: string
              description: Customer's name.
            accountNumber:
              type: string
              description: Customer's account number.
            routingNumber:
              type: string
              description: Routing number of the customer's account.
            accountType:
              $ref: '#/components/schemas/AchSourceWithAccountTypeAccountType'
              description: |
                Indicates the customer's account type.
          required:
            - type
            - nameOnAccount
            - accountNumber
            - routingNumber
          description: ach variant
        - type: object
          properties:
            type:
              $ref: '#/components/schemas/PadSourceWithAccountTypeType'
            nameOnAccount:
              type: string
              description: Customer's name.
            accountNumber:
              type: string
              description: Customer's account number.
            transitNumber:
              type: string
              description: Five-digit code that represents the customer's banking branch.
            institutionNumber:
              type: string
              description: Three-digit code that represents the customer's bank.
            accountType:
              $ref: '#/components/schemas/PadSourceWithAccountTypeAccountType'
              description: |
                Indicates the customer's account type.
          required:
            - type
            - nameOnAccount
            - accountNumber
            - transitNumber
            - institutionNumber
          description: pad variant
        - type: object
          properties:
            type:
              type: string
              enum:
                - card
              description: 'Discriminator value: card'
            cardholderName:
              type: string
              description: Cardholder's name.
            cardNumber:
              type: string
              description: Primary account number of the customer's card.
            expiryDate:
              type: string
              description: Expiry date of the customer's card.
            cardType:
              type: string
              description: Card brand of the card, for example, Visa.
            currency:
              $ref: '#/components/schemas/currency'
            debit:
              type: boolean
              description: Indicates if the card is a debit card.
            surcharging:
              $ref: '#/components/schemas/surcharging'
          required:
            - type
            - cardholderName
            - cardNumber
          description: Object that contains the customer's card details.
      discriminator:
        propertyName: type
      description: "Polymorphic object that contains the payment method that we tokenized.  \n\nThe value of the type parameter determines which variant you should use:  \n-\t`ach` - Automated Clearing House (ACH) details\n-\t`pad` - Pre-authorized debit (PAD) details\n-\t`card` - Payment card details\n"
      title: SecureTokenWithAccountTypeSource
    SecureTokenWithAccountTypeStatus:
      type: string
      enum:
        - notValidated
        - cvvValidated
        - validationFailed
        - issueNumberValidated
        - cardNumberValidated
        - bankAccountValidated
      description: >
        Outcome of a security check on the status of the customer's payment card
        or bank account.  


        **Note:** Depending on the merchant's account settings, this feature may
        be unavailable. 
      title: SecureTokenWithAccountTypeStatus
    customField:
      type: object
      properties:
        name:
          type: string
          description: Name of the custom field.
        value:
          type: string
          description: Value for the custom field.
      required:
        - name
        - value
      title: customField
    secureTokenWithAccountType:
      type: object
      properties:
        secureTokenId:
          type: string
          description: >-
            Unique identifier that the merchant created for the secure token
            that represents the customer's payment details.
        processingTerminalId:
          type: string
          description: Unique identifier that we assigned to the terminal.
        mitAgreement:
          $ref: '#/components/schemas/SecureTokenWithAccountTypeMitAgreement'
          description: >
            Indicates how the merchant can use the customer's card details, as
            agreed by the customer:


            - `unscheduled` - Transactions for a fixed or variable amount that
            are run at a certain pre-defined event.

            - `recurring` - Transactions for a fixed amount that are run at
            regular intervals, for example, monthly. Recurring transactions
            don't have a fixed duration and run until the customer cancels the
            agreement.

            - `installment` - Transactions for a fixed amount that are run at
            regular intervals, for example, monthly. Installment transactions
            have a fixed duration.
        customer:
          $ref: '#/components/schemas/retrievedCustomer'
        source:
          $ref: '#/components/schemas/SecureTokenWithAccountTypeSource'
          description: "Polymorphic object that contains the payment method that we tokenized.  \n\nThe value of the type parameter determines which variant you should use:  \n-\t`ach` - Automated Clearing House (ACH) details\n-\t`pad` - Pre-authorized debit (PAD) details\n-\t`card` - Payment card details\n"
        token:
          type: string
          description: >
            Token that the merchant can use in future transactions to represent
            the customer's payment details. The token:  

            - Begins with the six-digit identification number **296753**.

            - Contains up to 12 digits.  

            - Contains a single check digit that we calculate using the Luhn
            algorithm.
        status:
          $ref: '#/components/schemas/SecureTokenWithAccountTypeStatus'
          description: >
            Outcome of a security check on the status of the customer's payment
            card or bank account.  


            **Note:** Depending on the merchant's account settings, this feature
            may be unavailable. 
        customFields:
          type: array
          items:
            $ref: '#/components/schemas/customField'
          description: |
            Array of customField objects.
      required:
        - secureTokenId
        - processingTerminalId
        - source
        - token
        - status
      description: Object that contains information about the secure token.
      title: secureTokenWithAccountType
    secureTokenPaginatedListWithAccountType:
      type: object
      properties:
        limit:
          type: integer
          description: Maximum number of results that we return for each page.
        count:
          type: integer
          description: >
            Number of results we returned on this page. 


            **Note:** This might not be the total number of results that match
            your query. 
        hasMore:
          type: boolean
          description: Indicates whether there is another page of results available.
        links:
          type: array
          items:
            $ref: '#/components/schemas/link'
          description: >-
            Reference links to navigate to the previous page of results or to
            the next page of results.
        data:
          type: array
          items:
            $ref: '#/components/schemas/secureTokenWithAccountType'
          description: Array of saved payment details.
      required:
        - limit
        - count
        - hasMore
        - data
      title: secureTokenPaginatedListWithAccountType
    ErrorsItems:
      type: object
      properties:
        message:
          type: string
          description: Error message
      title: ErrorsItems

```

### Example request

### Request

GET [https://api.payroc.com/v1/processing-terminals/\{processingTerminalId}/secure-tokens](https://api.payroc.com/v1/processing-terminals/\{processingTerminalId}/secure-tokens)

```curl Paginated Secure Token
curl -G https://api.payroc.com/v1/processing-terminals/1234001/secure-tokens \
     -H "Authorization: Bearer <token>" \
     -d secureTokenId=MREF_abc1de23-f4a5-6789-bcd0-12e345678901fa \
     --data-urlencode customerName=Sarah%20Hazel%20Hopper \
     -d phone=2025550165 \
     --data-urlencode email=sarah.hopper@example.com \
     -d token=296753123456 \
     -d first6=453985 \
     -d last4=7062 \
     -d before=2571 \
     -d after=8516 \
     -d limit=25
```

```typescript Paginated Secure Token
import { PayrocClient } from "payroc";

async function main() {
    const client = new PayrocClient();
    await client.tokenization.secureTokens.list("1234001", {
        secureTokenId: "MREF_abc1de23-f4a5-6789-bcd0-12e345678901fa",
        customerName: "Sarah%20Hazel%20Hopper",
        phone: "2025550165",
        email: "sarah.hopper@example.com",
        token: "296753123456",
        first6: "453985",
        last4: "7062",
        before: "2571",
        after: "8516",
        limit: 25,
    });
}
main();

```

```python Paginated Secure Token
from payroc import Payroc

client = Payroc()

client.tokenization.secure_tokens.list(
    processing_terminal_id="1234001",
    secure_token_id="MREF_abc1de23-f4a5-6789-bcd0-12e345678901fa",
    customer_name="Sarah%20Hazel%20Hopper",
    phone="2025550165",
    email="sarah.hopper@example.com",
    token="296753123456",
    first_6="453985",
    last_4="7062",
    before="2571",
    after="8516",
    limit=25,
)

```

```java Paginated Secure Token
package com.example.usage;

import com.payroc.api.PayrocApiClient;
import com.payroc.api.resources.tokenization.securetokens.requests.ListSecureTokensRequest;

public class Example {
    public static void main(String[] args) {
        PayrocApiClient client = PayrocApiClient
            .builder()
            .build();

        client.tokenization().secureTokens().list(
            "1234001",
            ListSecureTokensRequest
                .builder()
                .secureTokenId("MREF_abc1de23-f4a5-6789-bcd0-12e345678901fa")
                .customerName("Sarah%20Hazel%20Hopper")
                .phone("2025550165")
                .email("sarah.hopper@example.com")
                .token("296753123456")
                .first6("453985")
                .last4("7062")
                .before("2571")
                .after("8516")
                .limit(25)
                .build()
        );
    }
}
```

```ruby Paginated Secure Token
require "payroc"

client = Payroc::Client.new

client.tokenization.secure_tokens.list(
  processing_terminal_id: "1234001",
  secure_token_id: "MREF_abc1de23-f4a5-6789-bcd0-12e345678901fa",
  customer_name: "Sarah%20Hazel%20Hopper",
  phone: "2025550165",
  email: "sarah.hopper@example.com",
  token: "296753123456",
  first_6: "453985",
  last_4: "7062",
  before: "2571",
  after: "8516",
  limit: 25
)

```

```csharp Paginated Secure Token
using Payroc;
using System.Threading.Tasks;
using Payroc.Tokenization.SecureTokens;

namespace Usage;

public class Example
{
    public async Task Do() {
        var client = new PayrocClient();

        await client.Tokenization.SecureTokens.ListAsync(
            new ListSecureTokensRequest {
                ProcessingTerminalId = "1234001",
                SecureTokenId = "MREF_abc1de23-f4a5-6789-bcd0-12e345678901fa",
                CustomerName = "Sarah%20Hazel%20Hopper",
                Phone = "2025550165",
                Email = "sarah.hopper@example.com",
                Token = "296753123456",
                First6 = "453985",
                Last4 = "7062",
                Before = "2571",
                After = "8516",
                Limit = 25
            }
        );
    }

}

```

```go Paginated Secure Token
package main

import (
	"fmt"
	"net/http"
	"io"
)

func main() {

	url := "https://api.payroc.com/v1/processing-terminals/1234001/secure-tokens?secureTokenId=MREF_abc1de23-f4a5-6789-bcd0-12e345678901fa&customerName=Sarah%2520Hazel%2520Hopper&phone=2025550165&email=sarah.hopper%40example.com&token=296753123456&first6=453985&last4=7062&before=2571&after=8516&limit=25"

	req, _ := http.NewRequest("GET", url, nil)

	req.Header.Add("Authorization", "Bearer <token>")

	res, _ := http.DefaultClient.Do(req)

	defer res.Body.Close()
	body, _ := io.ReadAll(res.Body)

	fmt.Println(res)
	fmt.Println(string(body))

}
```

```php Paginated Secure Token
<?php
require_once('vendor/autoload.php');

$client = new \GuzzleHttp\Client();

$response = $client->request('GET', 'https://api.payroc.com/v1/processing-terminals/1234001/secure-tokens?secureTokenId=MREF_abc1de23-f4a5-6789-bcd0-12e345678901fa&customerName=Sarah%2520Hazel%2520Hopper&phone=2025550165&email=sarah.hopper%40example.com&token=296753123456&first6=453985&last4=7062&before=2571&after=8516&limit=25', [
  'headers' => [
    'Authorization' => 'Bearer <token>',
  ],
]);

echo $response->getBody();
```

```swift Paginated Secure Token
import Foundation

let headers = ["Authorization": "Bearer <token>"]

let request = NSMutableURLRequest(url: NSURL(string: "https://api.payroc.com/v1/processing-terminals/1234001/secure-tokens?secureTokenId=MREF_abc1de23-f4a5-6789-bcd0-12e345678901fa&customerName=Sarah%2520Hazel%2520Hopper&phone=2025550165&email=sarah.hopper%40example.com&token=296753123456&first6=453985&last4=7062&before=2571&after=8516&limit=25")! as URL,
                                        cachePolicy: .useProtocolCachePolicy,
                                    timeoutInterval: 10.0)
request.httpMethod = "GET"
request.allHTTPHeaderFields = headers

let session = URLSession.shared
let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
  if (error != nil) {
    print(error as Any)
  } else {
    let httpResponse = response as? HTTPURLResponse
    print(httpResponse)
  }
})

dataTask.resume()
```

### Response fields

If your request is successful, we return a list of secure tokens associated with the processing terminal. The response contains the following fields:

### Schema (`response.body`)

```yaml
openapi: 3.1.0
info:
  title: API
  version: 1.0.0
paths:
  /processing-terminals/{processingTerminalId}/secure-tokens:
    get:
      operationId: list
      summary: List secure tokens
      description: "Use this method to return a [paginated](https://docs.payroc.com/api/pagination) list of secure tokens.  \n\n**Note:** If you want to view the details of a specific secure token and you have its secureTokenId, use our [Retrieve Secure Token](https://docs.payroc.com/api/schema/tokenization/secure-tokens/retrieve) method.  \n\nUse query parameters to filter the list of results that we return, for example, to search for secure tokens by customer or by the first four digits of a card number.  \n\nOur gateway returns information about the following for each secure token in the list:  \n\n  -\tPayment details that the secure token represents.  \n  -\tCustomer details, including shipping and billing addresses.  \n  -\tSecure token that you can use to carry out transactions.  \n\n  For each secure token, we also return the secureTokenId, which you can use to perform follow-on actions.\n"
      tags:
        - subpackage_tokenization.subpackage_tokenization/secureTokens
      parameters:
        - name: processingTerminalId
          in: path
          description: Unique identifier that we assigned to the terminal.
          required: true
          schema:
            type: string
        - name: secureTokenId
          in: query
          description: Unique identifier that the merchant assigned to the secure token.
          required: false
          schema:
            type: string
        - name: customerName
          in: query
          description: Filter by the customer's name.
          required: false
          schema:
            type: string
        - name: phone
          in: query
          description: Filter by the customer's phone number.
          required: false
          schema:
            type: string
        - name: email
          in: query
          description: Filter by the customer's email address.
          required: false
          schema:
            type: string
        - name: token
          in: query
          description: >-
            Filter by the token that the merchant used in a transaction to
            represent the customer's payment details.
          required: false
          schema:
            type: string
        - name: first6
          in: query
          description: Filter by the first six digits of the card number.
          required: false
          schema:
            type: string
        - name: last4
          in: query
          description: Filter by the last four digits of the card or account number.
          required: false
          schema:
            type: string
        - name: before
          in: query
          description: >
            Return the previous page of results before the value that you
            specify.  


            You can’t send the before parameter in the same request as the after
            parameter. 
          required: false
          schema:
            type: string
        - name: after
          in: query
          description: >
            Return the next page of results after the value that you specify.  


            You can’t send the after parameter in the same request as the before
            parameter. 
          required: false
          schema:
            type: string
        - name: limit
          in: query
          description: Limit the maximum number of results that we return for each page.
          required: false
          schema:
            type: integer
            default: 10
      responses:
        '200':
          description: >-
            Successful request. Returns a list of secure tokens that are
            currently saved on the terminal.
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/secureTokenPaginatedListWithAccountType'
        '400':
          description: Invalid request
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/400'
        '401':
          description: Identity could not be verified
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/401'
        '403':
          description: Do not have permissions to perform this action
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/403'
        '406':
          description: Not acceptable
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/406'
        '500':
          description: An error has occured
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/500'
servers:
  - url: https://api.payroc.com/v1
  - url: https://api.uat.payroc.com/v1
components:
  schemas:
    '400':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
        errors:
          type: array
          items:
            $ref: '#/components/schemas/ErrorsItems'
      required:
        - type
        - title
        - status
        - detail
      title: '400'
    '401':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
      required:
        - type
        - title
        - status
        - detail
      title: '401'
    '403':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
        instance:
          type: string
          description: Resource path the action was attempted on
        resource:
          type: string
          description: Resource the action was attempted on
      required:
        - type
        - title
        - status
        - detail
      title: '403'
    '406':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
      required:
        - type
        - title
        - status
        - detail
      title: '406'
    '500':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
        errors:
          type: array
          items:
            $ref: '#/components/schemas/ErrorsItems'
      required:
        - type
        - title
        - status
        - detail
      title: '500'
    link:
      type: object
      properties:
        rel:
          type: string
          description: >-
            Indicates the relationship between the current resource and the
            target resource.
        method:
          type: string
          description: HTTP method that you need to use with the target resource.
        href:
          type: string
          description: URL of the target resource.
      required:
        - rel
        - method
        - href
      description: Object that contains HATEOAS links for the resource.
      title: link
    SecureTokenWithAccountTypeMitAgreement:
      type: string
      enum:
        - unscheduled
        - recurring
        - installment
      description: >
        Indicates how the merchant can use the customer's card details, as
        agreed by the customer:


        - `unscheduled` - Transactions for a fixed or variable amount that are
        run at a certain pre-defined event.

        - `recurring` - Transactions for a fixed amount that are run at regular
        intervals, for example, monthly. Recurring transactions don't have a
        fixed duration and run until the customer cancels the agreement.

        - `installment` - Transactions for a fixed amount that are run at
        regular intervals, for example, monthly. Installment transactions have a
        fixed duration.
      title: SecureTokenWithAccountTypeMitAgreement
    retrievedAddress:
      type: object
      properties:
        address1:
          type: string
          description: Address line 1.
        address2:
          type: string
          description: Address line 2.
        address3:
          type: string
          description: Address line 3.
        city:
          type: string
          description: City.
        state:
          type: string
          description: Name of the state or state abbreviation.
        country:
          type: string
          description: >-
            Two-digit country code for the country that the business operates
            in. The format follows the
            [ISO-3166-1](https://www.iso.org/iso-3166-country-codes.html)
            standard.
        postalCode:
          type: string
          description: Zip code or postal code.
      description: Object that contains information about the address.
      title: retrievedAddress
    retrievedShipping:
      type: object
      properties:
        recipientName:
          type: string
          description: Recipient's name.
        address:
          $ref: '#/components/schemas/retrievedAddress'
      description: >-
        Object that contains information about the customer and their shipping
        address.
      title: retrievedShipping
    contactMethod:
      oneOf:
        - type: object
          properties:
            type:
              type: string
              enum:
                - email
              description: 'Discriminator value: email'
            value:
              type: string
              description: Email address.
          required:
            - type
            - value
          description: email variant
        - type: object
          properties:
            type:
              type: string
              enum:
                - phone
              description: 'Discriminator value: phone'
            value:
              type: string
              description: Phone number.
          required:
            - type
            - value
          description: phone variant
        - type: object
          properties:
            type:
              type: string
              enum:
                - mobile
              description: 'Discriminator value: mobile'
            value:
              type: string
              description: Mobile number.
          required:
            - type
            - value
          description: mobile variant
        - type: object
          properties:
            type:
              type: string
              enum:
                - fax
              description: 'Discriminator value: fax'
            value:
              type: string
              description: Fax number.
          required:
            - type
            - value
          description: fax variant
      discriminator:
        propertyName: type
      title: contactMethod
    RetrievedCustomerNotificationLanguage:
      type: string
      enum:
        - en
        - fr
      description: >
        Language that the customer uses for notifications. This code follows the
        [ISO 639-1](https://www.iso.org/iso-639-language-code) alpha-2
        standard. 
      title: RetrievedCustomerNotificationLanguage
    retrievedCustomer:
      type: object
      properties:
        firstName:
          type: string
          description: Customer's first name.
        lastName:
          type: string
          description: Customer's last name.
        dateOfBirth:
          type: string
          format: date
          description: >-
            Customer's date of birth. The format for this value is
            **YYYY-MM-DD**.
        referenceNumber:
          type: string
          description: >
            Identifier of the transaction, also known as a customer code. 


            For requests, you must send a value for **referenceNumber** if the
            customer provides one. 
        billingAddress:
          $ref: '#/components/schemas/retrievedAddress'
          description: >-
            Object that contains information about the address that the card is
            registered to.
        shippingAddress:
          $ref: '#/components/schemas/retrievedShipping'
        contactMethods:
          type: array
          items:
            $ref: '#/components/schemas/contactMethod'
          description: "Array of polymorphic objects, which contain contact information.  \n\nThe value of the type parameter determines which variant you should use:  \n-\t`email` - Email address \n-\t`phone` - Phone number\n-\t`mobile` - Mobile number\n-\t`fax` - Fax number\n"
        notificationLanguage:
          $ref: '#/components/schemas/RetrievedCustomerNotificationLanguage'
          description: >
            Language that the customer uses for notifications. This code follows
            the [ISO 639-1](https://www.iso.org/iso-639-language-code) alpha-2
            standard. 
      description: >-
        Object that contains the customer's contact details and address
        information.
      title: retrievedCustomer
    AchSourceWithAccountTypeType:
      type: string
      enum:
        - ach
      title: AchSourceWithAccountTypeType
    AchSourceWithAccountTypeAccountType:
      type: string
      enum:
        - checking
        - savings
      description: |
        Indicates the customer's account type.
      title: AchSourceWithAccountTypeAccountType
    PadSourceWithAccountTypeType:
      type: string
      enum:
        - pad
      title: PadSourceWithAccountTypeType
    PadSourceWithAccountTypeAccountType:
      type: string
      enum:
        - checking
        - savings
      description: |
        Indicates the customer's account type.
      title: PadSourceWithAccountTypeAccountType
    currency:
      type: string
      enum:
        - AED
        - AFN
        - ALL
        - AMD
        - ANG
        - AOA
        - ARS
        - AUD
        - AWG
        - AZN
        - BAM
        - BBD
        - BDT
        - BGN
        - BHD
        - BIF
        - BMD
        - BND
        - BOB
        - BOV
        - BRL
        - BSD
        - BTN
        - BWP
        - BYR
        - BZD
        - CAD
        - CDF
        - CHE
        - CHF
        - CHW
        - CLF
        - CLP
        - CNY
        - COP
        - COU
        - CRC
        - CUC
        - CUP
        - CVE
        - CZK
        - DJF
        - DKK
        - DOP
        - DZD
        - EGP
        - ERN
        - ETB
        - EUR
        - FJD
        - FKP
        - GBP
        - GEL
        - GHS
        - GIP
        - GMD
        - GNF
        - GTQ
        - GYD
        - HKD
        - HNL
        - HRK
        - HTG
        - HUF
        - IDR
        - ILS
        - INR
        - IQD
        - IRR
        - ISK
        - JMD
        - JOD
        - JPY
        - KES
        - KGS
        - KHR
        - KMF
        - KPW
        - KRW
        - KWD
        - KYD
        - KZT
        - LAK
        - LBP
        - LKR
        - LRD
        - LSL
        - LTL
        - LVL
        - LYD
        - MAD
        - MDL
        - MGA
        - MKD
        - MMK
        - MNT
        - MOP
        - MRO
        - MRU
        - MUR
        - MVR
        - MWK
        - MXN
        - MXV
        - MYR
        - MZN
        - NAD
        - NGN
        - NIO
        - NOK
        - NPR
        - NZD
        - OMR
        - PAB
        - PEN
        - PGK
        - PHP
        - PKR
        - PLN
        - PYG
        - QAR
        - RON
        - RSD
        - RUB
        - RWF
        - SAR
        - SBD
        - SCR
        - SDG
        - SEK
        - SGD
        - SHP
        - SLL
        - SOS
        - SRD
        - SSP
        - STD
        - STN
        - SVC
        - SYP
        - SZL
        - THB
        - TJS
        - TMT
        - TND
        - TOP
        - TRY
        - TTD
        - TWD
        - TZS
        - UAH
        - UGX
        - USD
        - USN
        - USS
        - UYI
        - UYU
        - UZS
        - VEF
        - VES
        - VND
        - VUV
        - WST
        - XAF
        - XCD
        - XOF
        - XPF
        - YER
        - ZAR
        - ZMW
        - ZWL
      description: >-
        Currency of the transaction. The value for the currency follows the [ISO
        4217](https://www.iso.org/iso-4217-currency-codes.html) standard.
      title: currency
    surcharging:
      type: object
      properties:
        allowed:
          type: boolean
          description: >-
            Indicates if the merchant can add a surcharge when the customer uses
            this card.
        amount:
          type: integer
          format: int64
          description: >
            Surcharge amount to add to the transaction.  

            **Note:** Our gateway returns the surcharge amount only if you
            include a transaction amount in the request.
        percentage:
          type: number
          format: double
          description: Surcharge rate that the merchant configures on their account.
        disclosure:
          type: string
          description: Statement that informs the customer about the surcharge fee.
      required:
        - allowed
      description: >-
        Object that contains surcharge information. Our gateway returns this
        object only if the merchant adds a surcharge to transactions.
      title: surcharging
    SecureTokenWithAccountTypeSource:
      oneOf:
        - type: object
          properties:
            type:
              $ref: '#/components/schemas/AchSourceWithAccountTypeType'
            nameOnAccount:
              type: string
              description: Customer's name.
            accountNumber:
              type: string
              description: Customer's account number.
            routingNumber:
              type: string
              description: Routing number of the customer's account.
            accountType:
              $ref: '#/components/schemas/AchSourceWithAccountTypeAccountType'
              description: |
                Indicates the customer's account type.
          required:
            - type
            - nameOnAccount
            - accountNumber
            - routingNumber
          description: ach variant
        - type: object
          properties:
            type:
              $ref: '#/components/schemas/PadSourceWithAccountTypeType'
            nameOnAccount:
              type: string
              description: Customer's name.
            accountNumber:
              type: string
              description: Customer's account number.
            transitNumber:
              type: string
              description: Five-digit code that represents the customer's banking branch.
            institutionNumber:
              type: string
              description: Three-digit code that represents the customer's bank.
            accountType:
              $ref: '#/components/schemas/PadSourceWithAccountTypeAccountType'
              description: |
                Indicates the customer's account type.
          required:
            - type
            - nameOnAccount
            - accountNumber
            - transitNumber
            - institutionNumber
          description: pad variant
        - type: object
          properties:
            type:
              type: string
              enum:
                - card
              description: 'Discriminator value: card'
            cardholderName:
              type: string
              description: Cardholder's name.
            cardNumber:
              type: string
              description: Primary account number of the customer's card.
            expiryDate:
              type: string
              description: Expiry date of the customer's card.
            cardType:
              type: string
              description: Card brand of the card, for example, Visa.
            currency:
              $ref: '#/components/schemas/currency'
            debit:
              type: boolean
              description: Indicates if the card is a debit card.
            surcharging:
              $ref: '#/components/schemas/surcharging'
          required:
            - type
            - cardholderName
            - cardNumber
          description: Object that contains the customer's card details.
      discriminator:
        propertyName: type
      description: "Polymorphic object that contains the payment method that we tokenized.  \n\nThe value of the type parameter determines which variant you should use:  \n-\t`ach` - Automated Clearing House (ACH) details\n-\t`pad` - Pre-authorized debit (PAD) details\n-\t`card` - Payment card details\n"
      title: SecureTokenWithAccountTypeSource
    SecureTokenWithAccountTypeStatus:
      type: string
      enum:
        - notValidated
        - cvvValidated
        - validationFailed
        - issueNumberValidated
        - cardNumberValidated
        - bankAccountValidated
      description: >
        Outcome of a security check on the status of the customer's payment card
        or bank account.  


        **Note:** Depending on the merchant's account settings, this feature may
        be unavailable. 
      title: SecureTokenWithAccountTypeStatus
    customField:
      type: object
      properties:
        name:
          type: string
          description: Name of the custom field.
        value:
          type: string
          description: Value for the custom field.
      required:
        - name
        - value
      title: customField
    secureTokenWithAccountType:
      type: object
      properties:
        secureTokenId:
          type: string
          description: >-
            Unique identifier that the merchant created for the secure token
            that represents the customer's payment details.
        processingTerminalId:
          type: string
          description: Unique identifier that we assigned to the terminal.
        mitAgreement:
          $ref: '#/components/schemas/SecureTokenWithAccountTypeMitAgreement'
          description: >
            Indicates how the merchant can use the customer's card details, as
            agreed by the customer:


            - `unscheduled` - Transactions for a fixed or variable amount that
            are run at a certain pre-defined event.

            - `recurring` - Transactions for a fixed amount that are run at
            regular intervals, for example, monthly. Recurring transactions
            don't have a fixed duration and run until the customer cancels the
            agreement.

            - `installment` - Transactions for a fixed amount that are run at
            regular intervals, for example, monthly. Installment transactions
            have a fixed duration.
        customer:
          $ref: '#/components/schemas/retrievedCustomer'
        source:
          $ref: '#/components/schemas/SecureTokenWithAccountTypeSource'
          description: "Polymorphic object that contains the payment method that we tokenized.  \n\nThe value of the type parameter determines which variant you should use:  \n-\t`ach` - Automated Clearing House (ACH) details\n-\t`pad` - Pre-authorized debit (PAD) details\n-\t`card` - Payment card details\n"
        token:
          type: string
          description: >
            Token that the merchant can use in future transactions to represent
            the customer's payment details. The token:  

            - Begins with the six-digit identification number **296753**.

            - Contains up to 12 digits.  

            - Contains a single check digit that we calculate using the Luhn
            algorithm.
        status:
          $ref: '#/components/schemas/SecureTokenWithAccountTypeStatus'
          description: >
            Outcome of a security check on the status of the customer's payment
            card or bank account.  


            **Note:** Depending on the merchant's account settings, this feature
            may be unavailable. 
        customFields:
          type: array
          items:
            $ref: '#/components/schemas/customField'
          description: |
            Array of customField objects.
      required:
        - secureTokenId
        - processingTerminalId
        - source
        - token
        - status
      description: Object that contains information about the secure token.
      title: secureTokenWithAccountType
    secureTokenPaginatedListWithAccountType:
      type: object
      properties:
        limit:
          type: integer
          description: Maximum number of results that we return for each page.
        count:
          type: integer
          description: >
            Number of results we returned on this page. 


            **Note:** This might not be the total number of results that match
            your query. 
        hasMore:
          type: boolean
          description: Indicates whether there is another page of results available.
        links:
          type: array
          items:
            $ref: '#/components/schemas/link'
          description: >-
            Reference links to navigate to the previous page of results or to
            the next page of results.
        data:
          type: array
          items:
            $ref: '#/components/schemas/secureTokenWithAccountType'
          description: Array of saved payment details.
      required:
        - limit
        - count
        - hasMore
        - data
      title: secureTokenPaginatedListWithAccountType
    ErrorsItems:
      type: object
      properties:
        message:
          type: string
          description: Error message
      title: ErrorsItems

```

### Example response

### Response (200)

```json
{
  "limit": 2,
  "count": 2,
  "hasMore": true,
  "data": [
    {
      "secureTokenId": "MREF_abc1de23-f4a5-6789-bcd0-12e345678901fa",
      "processingTerminalId": "1234001",
      "source": {
        "type": "card",
        "cardNumber": "453985******7062",
        "cardholderName": "Sarah Hopper",
        "expiryDate": "1230"
      },
      "token": "296753123456",
      "status": "notValidated",
      "mitAgreement": "unscheduled",
      "customer": {
        "firstName": "Sarah",
        "lastName": "Hopper",
        "dateOfBirth": "1990-07-15",
        "referenceNumber": "Customer-12",
        "billingAddress": {
          "address1": "1 Example Ave.",
          "address2": "Example Address Line 2",
          "address3": "Example Address Line 3",
          "city": "Chicago",
          "state": "Illinois",
          "country": "US",
          "postalCode": "60056"
        },
        "shippingAddress": {
          "recipientName": "Sarah Hopper",
          "address": {
            "address1": "1 Example Ave.",
            "address2": "Example Address Line 2",
            "address3": "Example Address Line 3",
            "city": "Chicago",
            "state": "Illinois",
            "country": "US",
            "postalCode": "60056"
          }
        }
      }
    },
    {
      "secureTokenId": "MREF_fe0d9876-cba5-432f-e10d-9cb87654a3f2e1",
      "processingTerminalId": "1234001",
      "source": {
        "type": "card",
        "cardNumber": "500165******0000",
        "cardholderName": "Sarah Hazel Hopper",
        "expiryDate": "0328"
      },
      "token": "307864234567",
      "status": "notValidated",
      "mitAgreement": "unscheduled",
      "customer": {
        "firstName": "Sarah",
        "lastName": "Hopper",
        "dateOfBirth": "1990-07-15",
        "referenceNumber": "Customer-12",
        "billingAddress": {
          "address1": "1 Example Ave.",
          "address2": "Example Address Line 2",
          "address3": "Example Address Line 3",
          "city": "Chicago",
          "state": "Illinois",
          "country": "US",
          "postalCode": "60056"
        },
        "shippingAddress": {
          "recipientName": "Sarah Hopper",
          "address": {
            "address1": "1 Example Ave.",
            "address2": "Example Address Line 2",
            "address3": "Example Address Line 3",
            "city": "Chicago",
            "state": "Illinois",
            "country": "US",
            "postalCode": "60056"
          }
        }
      },
      "customFields": [
        {
          "name": "yourCustomField",
          "value": "abc123"
        }
      ]
    }
  ],
  "links": [
    {
      "rel": "next",
      "method": "get",
      "href": "https://api.payroc.com/v1/processing-terminals/1234001/secure-tokens?limit=2&after=MREF_fe0d9876-cba5-432f-e10d-9cb87654a3f2e1"
    },
    {
      "rel": "previous",
      "method": "get",
      "href": "https://api.payroc.com/v1/processing-terminals/1234001/secure-tokens?limit=2&before=MREF_abc1de23-f4a5-6789-bcd0-12e345678901fa"
    }
  ]
}
```

## Step 2. Generate a session token

When you generate the session token, you need to include the secureTokenId of the secure token that you want to update.

To generate a session token, send a POST request to our Processing Terminals endpoint.

| Endpoint   | Prefix     | URL                                                                                                                                                                                                    |
| :--------- | :--------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Test       | `api.uat.` | [https://api.uat.payroc.com/v1/processing-terminals/\{processingTerminalId}/hosted-fields-sessions](https://api.uat.payroc.com/v1/processing-terminals/\{processingTerminalId}/hosted-fields-sessions) |
| Production | `api.`     | [https://api.payroc.com/v1/processing-terminals/\{processingTerminalId}/hosted-fields-sessions](https://api.payroc.com/v1/processing-terminals/\{processingTerminalId}/hosted-fields-sessions)         |

### Request parameters

To create the body of your request, use the following parameters:

### Schema (`request.body`)

```yaml
openapi: 3.1.0
info:
  title: API
  version: 1.0.0
paths:
  /processing-terminals/{processingTerminalId}/hosted-fields-sessions:
    post:
      operationId: create
      summary: Create Hosted Fields session
      description: >
        Use this method to create a Hosted Fields session token. You need to
        generate a new session token each time you load Hosted Fields on a
        webpage.  


        In your request, you need to indicate whether the merchant is using
        Hosted Fields to run a sale, save payment details, or update saved
        payment details.  


        In the response, our gateway returns the session token and the time that
        it expires. You need the session token when you configure the JavaScript
        for Hosted Fields.  


        For more information about adding Hosted Fields to a webpage, go to
        [Hosted
        Fields](https://docs.payroc.com/guides/take-payments/hosted-fields). 
      tags:
        - subpackage_hostedFields
      parameters:
        - name: processingTerminalId
          in: path
          description: Unique identifier that we assigned to the terminal.
          required: true
          schema:
            type: string
        - name: Idempotency-Key
          in: header
          description: >-
            Unique identifier that you generate for each request. You must use
            the [UUID v4 format](https://www.rfc-editor.org/rfc/rfc4122) for the
            identifier. For more information about the idempotency key, go to
            [Idempotency](https://docs.payroc.com/api/idempotency).
          required: true
          schema:
            type: string
            format: uuid
      responses:
        '201':
          description: >-
            Successful request. We created the session and returned a session
            token.
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/hostedFieldsCreateSessionResponse'
        '400':
          description: Validation error
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/400'
        '401':
          description: Identity could not be verified
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/401'
        '403':
          description: Do not have permissions to perform this action
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/403'
        '406':
          description: Not acceptable
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/406'
        '409':
          description: Conflict
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/409'
        '415':
          description: Unsupported media type
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/415'
        '500':
          description: An error has occured
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/500'
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/hostedFieldsCreateSessionRequest'
servers:
  - url: https://api.payroc.com/v1
  - url: https://api.uat.payroc.com/v1
components:
  schemas:
    '400':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
        errors:
          type: array
          items:
            $ref: '#/components/schemas/ErrorsItems'
      required:
        - type
        - title
        - status
        - detail
      title: '400'
    '401':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
      required:
        - type
        - title
        - status
        - detail
      title: '401'
    '403':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
        instance:
          type: string
          description: Resource path the action was attempted on
        resource:
          type: string
          description: Resource the action was attempted on
      required:
        - type
        - title
        - status
        - detail
      title: '403'
    '406':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
      required:
        - type
        - title
        - status
        - detail
      title: '406'
    '409':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
        instance:
          type: string
          description: Resource path to the existing resource
        errors:
          type: array
          items:
            $ref: '#/components/schemas/ErrorsItems'
        link:
          $ref: '#/components/schemas/link'
      required:
        - type
        - title
        - status
        - detail
      title: '409'
    '415':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
      required:
        - type
        - title
        - status
        - detail
      title: '415'
    '500':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
        errors:
          type: array
          items:
            $ref: '#/components/schemas/ErrorsItems'
      required:
        - type
        - title
        - status
        - detail
      title: '500'
    HostedFieldsCreateSessionRequestScenario:
      type: string
      enum:
        - payment
        - tokenization
      description: >
        Indicates if a merchant wants to take a payment or tokenize a customer's
        payment details:  


        - `payment` - The merchant wants to run a sale or run a sale and
        tokenize in the same transaction.  

        - `tokenization` - The merchant wants to save the customer's payment
        details to take a payment later or to update a customer's payment
        details that they've already saved.  
      title: HostedFieldsCreateSessionRequestScenario
    hostedFieldsCreateSessionRequest:
      type: object
      properties:
        libVersion:
          type: string
          description: >
            Version of the Hosted Fields JavaScript library that you are
            using.  


            The current production version is `1.7.0.261471`.
        scenario:
          $ref: '#/components/schemas/HostedFieldsCreateSessionRequestScenario'
          description: >
            Indicates if a merchant wants to take a payment or tokenize a
            customer's payment details:  


            - `payment` - The merchant wants to run a sale or run a sale and
            tokenize in the same transaction.  

            - `tokenization` - The merchant wants to save the customer's payment
            details to take a payment later or to update a customer's payment
            details that they've already saved.  
        secureTokenId:
          type: string
          description: >
            Unique identifier that represents a customer's payment details.  


            If a merchant wants to update a customer's payment details that are
            linked to a secure token, include the secureTokenId in your
            request.  
      required:
        - libVersion
        - scenario
      description: >-
        Object that contains information about Hosted Fields initialization
        request.
      title: hostedFieldsCreateSessionRequest
    hostedFieldsCreateSessionResponse:
      type: object
      properties:
        processingTerminalId:
          type: string
          description: Unique identifier that we assigned to the terminal.
        token:
          type: string
          description: |
            Token that our gateway assigned to the Hosted Fields session.  

            Include this session token in the config file for Hosted Fields.  

            The session token expires after 10 minutes.
        expiresAt:
          type: string
          format: date-time
          description: >-
            Date and time that the token expires. We return this value in the
            [ISO 8601](https://www.iso.org/iso-8601-date-and-time-format.html)
            format.
      required:
        - processingTerminalId
        - token
        - expiresAt
      title: hostedFieldsCreateSessionResponse
    ErrorsItems:
      type: object
      properties:
        message:
          type: string
          description: Error message
      title: ErrorsItems
    link:
      type: object
      properties:
        rel:
          type: string
          description: >-
            Indicates the relationship between the current resource and the
            target resource.
        method:
          type: string
          description: HTTP method that you need to use with the target resource.
        href:
          type: string
          description: URL of the target resource.
      required:
        - rel
        - method
        - href
      description: Object that contains HATEOAS links for the resource.
      title: link

```

### Example request

### Request

POST [https://api.payroc.com/v1/processing-terminals/\{processingTerminalId}/hosted-fields-sessions](https://api.payroc.com/v1/processing-terminals/\{processingTerminalId}/hosted-fields-sessions)

```curl Create session response
curl -X POST https://api.payroc.com/v1/processing-terminals/1234001/hosted-fields-sessions \
     -H "Idempotency-Key: 8e03978e-40d5-43e8-bc93-6894a57f9324" \
     -H "Authorization: Bearer <token>" \
     -H "Content-Type: application/json"
```

```python Create session response
import requests

url = "https://api.payroc.com/v1/processing-terminals/1234001/hosted-fields-sessions"

headers = {
    "Idempotency-Key": "8e03978e-40d5-43e8-bc93-6894a57f9324",
    "Authorization": "Bearer <token>",
    "Content-Type": "application/json"
}

response = requests.post(url, headers=headers)

print(response.json())
```

```javascript Create session response
const url = 'https://api.payroc.com/v1/processing-terminals/1234001/hosted-fields-sessions';
const options = {
  method: 'POST',
  headers: {
    'Idempotency-Key': '8e03978e-40d5-43e8-bc93-6894a57f9324',
    Authorization: 'Bearer <token>',
    'Content-Type': 'application/json'
  },
  body: undefined
};

try {
  const response = await fetch(url, options);
  const data = await response.json();
  console.log(data);
} catch (error) {
  console.error(error);
}
```

```go Create session response
package main

import (
	"fmt"
	"net/http"
	"io"
)

func main() {

	url := "https://api.payroc.com/v1/processing-terminals/1234001/hosted-fields-sessions"

	req, _ := http.NewRequest("POST", url, nil)

	req.Header.Add("Idempotency-Key", "8e03978e-40d5-43e8-bc93-6894a57f9324")
	req.Header.Add("Authorization", "Bearer <token>")
	req.Header.Add("Content-Type", "application/json")

	res, _ := http.DefaultClient.Do(req)

	defer res.Body.Close()
	body, _ := io.ReadAll(res.Body)

	fmt.Println(res)
	fmt.Println(string(body))

}
```

```ruby Create session response
require 'uri'
require 'net/http'

url = URI("https://api.payroc.com/v1/processing-terminals/1234001/hosted-fields-sessions")

http = Net::HTTP.new(url.host, url.port)
http.use_ssl = true

request = Net::HTTP::Post.new(url)
request["Idempotency-Key"] = '8e03978e-40d5-43e8-bc93-6894a57f9324'
request["Authorization"] = 'Bearer <token>'
request["Content-Type"] = 'application/json'

response = http.request(request)
puts response.read_body
```

```java Create session response
import com.mashape.unirest.http.HttpResponse;
import com.mashape.unirest.http.Unirest;

HttpResponse<String> response = Unirest.post("https://api.payroc.com/v1/processing-terminals/1234001/hosted-fields-sessions")
  .header("Idempotency-Key", "8e03978e-40d5-43e8-bc93-6894a57f9324")
  .header("Authorization", "Bearer <token>")
  .header("Content-Type", "application/json")
  .asString();
```

```php Create session response
<?php
require_once('vendor/autoload.php');

$client = new \GuzzleHttp\Client();

$response = $client->request('POST', 'https://api.payroc.com/v1/processing-terminals/1234001/hosted-fields-sessions', [
  'headers' => [
    'Authorization' => 'Bearer <token>',
    'Content-Type' => 'application/json',
    'Idempotency-Key' => '8e03978e-40d5-43e8-bc93-6894a57f9324',
  ],
]);

echo $response->getBody();
```

```csharp Create session response
using RestSharp;

var client = new RestClient("https://api.payroc.com/v1/processing-terminals/1234001/hosted-fields-sessions");
var request = new RestRequest(Method.POST);
request.AddHeader("Idempotency-Key", "8e03978e-40d5-43e8-bc93-6894a57f9324");
request.AddHeader("Authorization", "Bearer <token>");
request.AddHeader("Content-Type", "application/json");
IRestResponse response = client.Execute(request);
```

```swift Create session response
import Foundation

let headers = [
  "Idempotency-Key": "8e03978e-40d5-43e8-bc93-6894a57f9324",
  "Authorization": "Bearer <token>",
  "Content-Type": "application/json"
]

let request = NSMutableURLRequest(url: NSURL(string: "https://api.payroc.com/v1/processing-terminals/1234001/hosted-fields-sessions")! as URL,
                                        cachePolicy: .useProtocolCachePolicy,
                                    timeoutInterval: 10.0)
request.httpMethod = "POST"
request.allHTTPHeaderFields = headers

let session = URLSession.shared
let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
  if (error != nil) {
    print(error as Any)
  } else {
    let httpResponse = response as? HTTPURLResponse
    print(httpResponse)
  }
})

dataTask.resume()
```

### Response fields

If your request is successful, our gateway generates a session token. The response contains the following fields:

### Schema (`response.body`)

```yaml
openapi: 3.1.0
info:
  title: API
  version: 1.0.0
paths:
  /processing-terminals/{processingTerminalId}/hosted-fields-sessions:
    post:
      operationId: create
      summary: Create Hosted Fields session
      description: >
        Use this method to create a Hosted Fields session token. You need to
        generate a new session token each time you load Hosted Fields on a
        webpage.  


        In your request, you need to indicate whether the merchant is using
        Hosted Fields to run a sale, save payment details, or update saved
        payment details.  


        In the response, our gateway returns the session token and the time that
        it expires. You need the session token when you configure the JavaScript
        for Hosted Fields.  


        For more information about adding Hosted Fields to a webpage, go to
        [Hosted
        Fields](https://docs.payroc.com/guides/take-payments/hosted-fields). 
      tags:
        - subpackage_hostedFields
      parameters:
        - name: processingTerminalId
          in: path
          description: Unique identifier that we assigned to the terminal.
          required: true
          schema:
            type: string
        - name: Idempotency-Key
          in: header
          description: >-
            Unique identifier that you generate for each request. You must use
            the [UUID v4 format](https://www.rfc-editor.org/rfc/rfc4122) for the
            identifier. For more information about the idempotency key, go to
            [Idempotency](https://docs.payroc.com/api/idempotency).
          required: true
          schema:
            type: string
            format: uuid
      responses:
        '201':
          description: >-
            Successful request. We created the session and returned a session
            token.
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/hostedFieldsCreateSessionResponse'
        '400':
          description: Validation error
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/400'
        '401':
          description: Identity could not be verified
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/401'
        '403':
          description: Do not have permissions to perform this action
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/403'
        '406':
          description: Not acceptable
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/406'
        '409':
          description: Conflict
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/409'
        '415':
          description: Unsupported media type
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/415'
        '500':
          description: An error has occured
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/500'
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/hostedFieldsCreateSessionRequest'
servers:
  - url: https://api.payroc.com/v1
  - url: https://api.uat.payroc.com/v1
components:
  schemas:
    '400':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
        errors:
          type: array
          items:
            $ref: '#/components/schemas/ErrorsItems'
      required:
        - type
        - title
        - status
        - detail
      title: '400'
    '401':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
      required:
        - type
        - title
        - status
        - detail
      title: '401'
    '403':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
        instance:
          type: string
          description: Resource path the action was attempted on
        resource:
          type: string
          description: Resource the action was attempted on
      required:
        - type
        - title
        - status
        - detail
      title: '403'
    '406':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
      required:
        - type
        - title
        - status
        - detail
      title: '406'
    '409':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
        instance:
          type: string
          description: Resource path to the existing resource
        errors:
          type: array
          items:
            $ref: '#/components/schemas/ErrorsItems'
        link:
          $ref: '#/components/schemas/link'
      required:
        - type
        - title
        - status
        - detail
      title: '409'
    '415':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
      required:
        - type
        - title
        - status
        - detail
      title: '415'
    '500':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
        errors:
          type: array
          items:
            $ref: '#/components/schemas/ErrorsItems'
      required:
        - type
        - title
        - status
        - detail
      title: '500'
    HostedFieldsCreateSessionRequestScenario:
      type: string
      enum:
        - payment
        - tokenization
      description: >
        Indicates if a merchant wants to take a payment or tokenize a customer's
        payment details:  


        - `payment` - The merchant wants to run a sale or run a sale and
        tokenize in the same transaction.  

        - `tokenization` - The merchant wants to save the customer's payment
        details to take a payment later or to update a customer's payment
        details that they've already saved.  
      title: HostedFieldsCreateSessionRequestScenario
    hostedFieldsCreateSessionRequest:
      type: object
      properties:
        libVersion:
          type: string
          description: >
            Version of the Hosted Fields JavaScript library that you are
            using.  


            The current production version is `1.7.0.261471`.
        scenario:
          $ref: '#/components/schemas/HostedFieldsCreateSessionRequestScenario'
          description: >
            Indicates if a merchant wants to take a payment or tokenize a
            customer's payment details:  


            - `payment` - The merchant wants to run a sale or run a sale and
            tokenize in the same transaction.  

            - `tokenization` - The merchant wants to save the customer's payment
            details to take a payment later or to update a customer's payment
            details that they've already saved.  
        secureTokenId:
          type: string
          description: >
            Unique identifier that represents a customer's payment details.  


            If a merchant wants to update a customer's payment details that are
            linked to a secure token, include the secureTokenId in your
            request.  
      required:
        - libVersion
        - scenario
      description: >-
        Object that contains information about Hosted Fields initialization
        request.
      title: hostedFieldsCreateSessionRequest
    hostedFieldsCreateSessionResponse:
      type: object
      properties:
        processingTerminalId:
          type: string
          description: Unique identifier that we assigned to the terminal.
        token:
          type: string
          description: |
            Token that our gateway assigned to the Hosted Fields session.  

            Include this session token in the config file for Hosted Fields.  

            The session token expires after 10 minutes.
        expiresAt:
          type: string
          format: date-time
          description: >-
            Date and time that the token expires. We return this value in the
            [ISO 8601](https://www.iso.org/iso-8601-date-and-time-format.html)
            format.
      required:
        - processingTerminalId
        - token
        - expiresAt
      title: hostedFieldsCreateSessionResponse
    ErrorsItems:
      type: object
      properties:
        message:
          type: string
          description: Error message
      title: ErrorsItems
    link:
      type: object
      properties:
        rel:
          type: string
          description: >-
            Indicates the relationship between the current resource and the
            target resource.
        method:
          type: string
          description: HTTP method that you need to use with the target resource.
        href:
          type: string
          description: URL of the target resource.
      required:
        - rel
        - method
        - href
      description: Object that contains HATEOAS links for the resource.
      title: link

```

### Example response

### Response (201)

```json
{
  "processingTerminalId": "1234001",
  "token": "abcdef1234567890abcdef1234567890",
  "expiresAt": "2025-07-02T15:30:00.000+02:00"
}
```

## Step 3. Update the JavaScript library

In the JavaScript configuration, change the value for the mode parameter from payment to `tokenization`.

```js title="Card"
<script
  src="https://cdn.uat.payroc.com/js/hosted-fields/hosted-fields-1.7.0.261457.js"
  integrity="sha384-m1A0nfFYa8sAfpDN0d60o4ztd/aCPC2xDVaOT31Urrmn4xypfHqgHQMayZeIK1PM"
  crossorigin="anonymous"
></script>

<script>
  const cardForm = new Payroc.hostedFields({
    sessionToken: YOUR_SESSION_TOKEN,
    mode: "tokenization",
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
          value: "Submit",
        },
      },
    },
  });
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
    mode: "tokenization",
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
          value: "Submit",
        },
      },
    },
  });
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
    mode: "tokenization",
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
          value: "Submit",
        },
      },
    },
  });
</script>
```

## Step 4. Update the secure token

After the customer submits their new payment details and you receive the single-use token from the submissionSuccess event, send the single-use token to our gateway to update the secure token.

To send the single-use token to our gateway, send a POST request to our Secure Tokens endpoint.

| Endpoint   | Prefix     | URL                                                                                                                                                                                                                                                  |
| :--------- | :--------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Test       | `api.uat.` | [https://api.uat.payroc.com/v1/processing-terminals/\{processingTerminalId}/secure-tokens/\{secureTokenId}/update-account](https://api.uat.payroc.com/v1/processing-terminals/\{processingTerminalId}/secure-tokens/\{secureTokenId}/update-account) |
| Production | `api.`     | [https://api.payroc.com/v1/processing-terminals/\{processingTerminalId}/secure-tokens/\{secureTokenId}/update-account](https://api.payroc.com/v1/processing-terminals/\{processingTerminalId}/secure-tokens/\{secureTokenId}/update-account)         |

### Request parameters

To create the body of your request, use the following parameters:

### Schema (`request.body`)

```yaml
openapi: 3.1.0
info:
  title: API
  version: 1.0.0
paths:
  /processing-terminals/{processingTerminalId}/secure-tokens/{secureTokenId}/update-account:
    post:
      operationId: update-account
      summary: Update account details
      description: >
        Use this method to update a secure token if you have a single-use token
        from Hosted Fields.  


        **Note:** If you don't have a single-use token, you can update saved
        payment details with our [Update Secure
        Token](https://docs.payroc.com/api/resources#updateSecureToken) method.
        For more information about our two options to update a secure token, go
        to [Update saved payment
        details](https://docs.payroc.com/guides/take-payments/update-saved-payment-details).  
      tags:
        - subpackage_tokenization.subpackage_tokenization/secureTokens
      parameters:
        - name: processingTerminalId
          in: path
          description: Unique identifier that we assigned to the terminal.
          required: true
          schema:
            type: string
        - name: secureTokenId
          in: path
          description: Unique identifier that the merchant assigned to the secure token.
          required: true
          schema:
            type: string
        - name: Idempotency-Key
          in: header
          description: >-
            Unique identifier that you generate for each request. You must use
            the [UUID v4 format](https://www.rfc-editor.org/rfc/rfc4122) for the
            identifier. For more information about the idempotency key, go to
            [Idempotency](https://docs.payroc.com/api/idempotency).
          required: true
          schema:
            type: string
            format: uuid
      responses:
        '200':
          description: >-
            Successful request. We updated the payment details represented by
            the secure token.
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/secureToken'
        '400':
          description: Invalid request
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/400'
        '401':
          description: Identity could not be verified
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/401'
        '403':
          description: Do not have permissions to perform this action
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/403'
        '404':
          description: Resource not found
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/404'
        '406':
          description: Not acceptable
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/406'
        '409':
          description: Conflict
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/409'
        '413':
          description: Payload too large
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/413'
        '415':
          description: Unsupported media type
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/415'
        '500':
          description: An error has occured
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/500'
      requestBody:
        description: >-
          Polymorphic object that contains information about the single-use
          token.
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/accountUpdate'
servers:
  - url: https://api.payroc.com/v1
  - url: https://api.uat.payroc.com/v1
components:
  schemas:
    '400':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
        errors:
          type: array
          items:
            $ref: '#/components/schemas/ErrorsItems'
      required:
        - type
        - title
        - status
        - detail
      title: '400'
    '401':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
      required:
        - type
        - title
        - status
        - detail
      title: '401'
    '403':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
        instance:
          type: string
          description: Resource path the action was attempted on
        resource:
          type: string
          description: Resource the action was attempted on
      required:
        - type
        - title
        - status
        - detail
      title: '403'
    '404':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
        resource:
          type: string
          description: Resource that was not found
      required:
        - type
        - title
        - status
        - detail
      title: '404'
    '406':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
      required:
        - type
        - title
        - status
        - detail
      title: '406'
    '409':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
        instance:
          type: string
          description: Resource path to the existing resource
        errors:
          type: array
          items:
            $ref: '#/components/schemas/ErrorsItems'
        link:
          $ref: '#/components/schemas/link'
      required:
        - type
        - title
        - status
        - detail
      title: '409'
    '413':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
      required:
        - type
        - title
        - status
        - detail
      title: '413'
    '415':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
      required:
        - type
        - title
        - status
        - detail
      title: '415'
    '500':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
        errors:
          type: array
          items:
            $ref: '#/components/schemas/ErrorsItems'
      required:
        - type
        - title
        - status
        - detail
      title: '500'
    accountUpdate:
      oneOf:
        - type: object
          properties:
            type:
              type: string
              enum:
                - singleUseToken
              description: 'Discriminator value: singleUseToken'
            token:
              type: string
              description: >-
                Single-use token that the gateway assigned to the payment
                details.
          required:
            - type
            - token
          description: Object that contains the token.
      discriminator:
        propertyName: type
      description: Polymorphic object that contains information about the single-use token.
      title: accountUpdate
    SecureTokenMitAgreement:
      type: string
      enum:
        - unscheduled
        - recurring
        - installment
      description: >
        Indicates how the merchant can use the customer's card details, as
        agreed by the customer:


        - `unscheduled` - Transactions for a fixed or variable amount that are
        run at a certain pre-defined event.

        - `recurring` - Transactions for a fixed amount that are run at regular
        intervals, for example, monthly. Recurring transactions don't have a
        fixed duration and run until the customer cancels the agreement.

        - `installment` - Transactions for a fixed amount that are run at
        regular intervals, for example, monthly. Installment transactions have a
        fixed duration.
      title: SecureTokenMitAgreement
    retrievedAddress:
      type: object
      properties:
        address1:
          type: string
          description: Address line 1.
        address2:
          type: string
          description: Address line 2.
        address3:
          type: string
          description: Address line 3.
        city:
          type: string
          description: City.
        state:
          type: string
          description: Name of the state or state abbreviation.
        country:
          type: string
          description: >-
            Two-digit country code for the country that the business operates
            in. The format follows the
            [ISO-3166-1](https://www.iso.org/iso-3166-country-codes.html)
            standard.
        postalCode:
          type: string
          description: Zip code or postal code.
      description: Object that contains information about the address.
      title: retrievedAddress
    retrievedShipping:
      type: object
      properties:
        recipientName:
          type: string
          description: Recipient's name.
        address:
          $ref: '#/components/schemas/retrievedAddress'
      description: >-
        Object that contains information about the customer and their shipping
        address.
      title: retrievedShipping
    contactMethod:
      oneOf:
        - type: object
          properties:
            type:
              type: string
              enum:
                - email
              description: 'Discriminator value: email'
            value:
              type: string
              description: Email address.
          required:
            - type
            - value
          description: email variant
        - type: object
          properties:
            type:
              type: string
              enum:
                - phone
              description: 'Discriminator value: phone'
            value:
              type: string
              description: Phone number.
          required:
            - type
            - value
          description: phone variant
        - type: object
          properties:
            type:
              type: string
              enum:
                - mobile
              description: 'Discriminator value: mobile'
            value:
              type: string
              description: Mobile number.
          required:
            - type
            - value
          description: mobile variant
        - type: object
          properties:
            type:
              type: string
              enum:
                - fax
              description: 'Discriminator value: fax'
            value:
              type: string
              description: Fax number.
          required:
            - type
            - value
          description: fax variant
      discriminator:
        propertyName: type
      title: contactMethod
    RetrievedCustomerNotificationLanguage:
      type: string
      enum:
        - en
        - fr
      description: >
        Language that the customer uses for notifications. This code follows the
        [ISO 639-1](https://www.iso.org/iso-639-language-code) alpha-2
        standard. 
      title: RetrievedCustomerNotificationLanguage
    retrievedCustomer:
      type: object
      properties:
        firstName:
          type: string
          description: Customer's first name.
        lastName:
          type: string
          description: Customer's last name.
        dateOfBirth:
          type: string
          format: date
          description: >-
            Customer's date of birth. The format for this value is
            **YYYY-MM-DD**.
        referenceNumber:
          type: string
          description: >
            Identifier of the transaction, also known as a customer code. 


            For requests, you must send a value for **referenceNumber** if the
            customer provides one. 
        billingAddress:
          $ref: '#/components/schemas/retrievedAddress'
          description: >-
            Object that contains information about the address that the card is
            registered to.
        shippingAddress:
          $ref: '#/components/schemas/retrievedShipping'
        contactMethods:
          type: array
          items:
            $ref: '#/components/schemas/contactMethod'
          description: "Array of polymorphic objects, which contain contact information.  \n\nThe value of the type parameter determines which variant you should use:  \n-\t`email` - Email address \n-\t`phone` - Phone number\n-\t`mobile` - Mobile number\n-\t`fax` - Fax number\n"
        notificationLanguage:
          $ref: '#/components/schemas/RetrievedCustomerNotificationLanguage'
          description: >
            Language that the customer uses for notifications. This code follows
            the [ISO 639-1](https://www.iso.org/iso-639-language-code) alpha-2
            standard. 
      description: >-
        Object that contains the customer's contact details and address
        information.
      title: retrievedCustomer
    currency:
      type: string
      enum:
        - AED
        - AFN
        - ALL
        - AMD
        - ANG
        - AOA
        - ARS
        - AUD
        - AWG
        - AZN
        - BAM
        - BBD
        - BDT
        - BGN
        - BHD
        - BIF
        - BMD
        - BND
        - BOB
        - BOV
        - BRL
        - BSD
        - BTN
        - BWP
        - BYR
        - BZD
        - CAD
        - CDF
        - CHE
        - CHF
        - CHW
        - CLF
        - CLP
        - CNY
        - COP
        - COU
        - CRC
        - CUC
        - CUP
        - CVE
        - CZK
        - DJF
        - DKK
        - DOP
        - DZD
        - EGP
        - ERN
        - ETB
        - EUR
        - FJD
        - FKP
        - GBP
        - GEL
        - GHS
        - GIP
        - GMD
        - GNF
        - GTQ
        - GYD
        - HKD
        - HNL
        - HRK
        - HTG
        - HUF
        - IDR
        - ILS
        - INR
        - IQD
        - IRR
        - ISK
        - JMD
        - JOD
        - JPY
        - KES
        - KGS
        - KHR
        - KMF
        - KPW
        - KRW
        - KWD
        - KYD
        - KZT
        - LAK
        - LBP
        - LKR
        - LRD
        - LSL
        - LTL
        - LVL
        - LYD
        - MAD
        - MDL
        - MGA
        - MKD
        - MMK
        - MNT
        - MOP
        - MRO
        - MRU
        - MUR
        - MVR
        - MWK
        - MXN
        - MXV
        - MYR
        - MZN
        - NAD
        - NGN
        - NIO
        - NOK
        - NPR
        - NZD
        - OMR
        - PAB
        - PEN
        - PGK
        - PHP
        - PKR
        - PLN
        - PYG
        - QAR
        - RON
        - RSD
        - RUB
        - RWF
        - SAR
        - SBD
        - SCR
        - SDG
        - SEK
        - SGD
        - SHP
        - SLL
        - SOS
        - SRD
        - SSP
        - STD
        - STN
        - SVC
        - SYP
        - SZL
        - THB
        - TJS
        - TMT
        - TND
        - TOP
        - TRY
        - TTD
        - TWD
        - TZS
        - UAH
        - UGX
        - USD
        - USN
        - USS
        - UYI
        - UYU
        - UZS
        - VEF
        - VES
        - VND
        - VUV
        - WST
        - XAF
        - XCD
        - XOF
        - XPF
        - YER
        - ZAR
        - ZMW
        - ZWL
      description: >-
        Currency of the transaction. The value for the currency follows the [ISO
        4217](https://www.iso.org/iso-4217-currency-codes.html) standard.
      title: currency
    surcharging:
      type: object
      properties:
        allowed:
          type: boolean
          description: >-
            Indicates if the merchant can add a surcharge when the customer uses
            this card.
        amount:
          type: integer
          format: int64
          description: >
            Surcharge amount to add to the transaction.  

            **Note:** Our gateway returns the surcharge amount only if you
            include a transaction amount in the request.
        percentage:
          type: number
          format: double
          description: Surcharge rate that the merchant configures on their account.
        disclosure:
          type: string
          description: Statement that informs the customer about the surcharge fee.
      required:
        - allowed
      description: >-
        Object that contains surcharge information. Our gateway returns this
        object only if the merchant adds a surcharge to transactions.
      title: surcharging
    SecureTokenSource:
      oneOf:
        - type: object
          properties:
            type:
              type: string
              enum:
                - ach
              description: 'Discriminator value: ach'
            nameOnAccount:
              type: string
              description: Customer's name.
            accountNumber:
              type: string
              description: Customer's account number.
            routingNumber:
              type: string
              description: Routing number of the customer's account.
          required:
            - type
            - nameOnAccount
            - accountNumber
            - routingNumber
          description: Object that contains the customer's account details.
        - type: object
          properties:
            type:
              type: string
              enum:
                - pad
              description: 'Discriminator value: pad'
            nameOnAccount:
              type: string
              description: Customer's name.
            accountNumber:
              type: string
              description: Customer's account number.
            transitNumber:
              type: string
              description: Five-digit code that represents the customer's banking branch.
            institutionNumber:
              type: string
              description: Three-digit code that represents the customer's bank.
          required:
            - type
            - nameOnAccount
            - accountNumber
            - transitNumber
            - institutionNumber
          description: Object that contains the customer's account details.
        - type: object
          properties:
            type:
              type: string
              enum:
                - card
              description: 'Discriminator value: card'
            cardholderName:
              type: string
              description: Cardholder's name.
            cardNumber:
              type: string
              description: Primary account number of the customer's card.
            expiryDate:
              type: string
              description: Expiry date of the customer's card.
            cardType:
              type: string
              description: Card brand of the card, for example, Visa.
            currency:
              $ref: '#/components/schemas/currency'
            debit:
              type: boolean
              description: Indicates if the card is a debit card.
            surcharging:
              $ref: '#/components/schemas/surcharging'
          required:
            - type
            - cardholderName
            - cardNumber
          description: Object that contains the customer's card details.
      discriminator:
        propertyName: type
      description: "Polymorphic object that contains the payment method that we tokenized.  \n\nThe value of the type parameter determines which variant you should use:  \n-\t`ach` - Automated Clearing House (ACH) details\n-\t`pad` - Pre-authorized debit (PAD) details\n-\t`card` - Payment card details\n"
      title: SecureTokenSource
    SecureTokenStatus:
      type: string
      enum:
        - notValidated
        - cvvValidated
        - validationFailed
        - issueNumberValidated
        - cardNumberValidated
        - bankAccountValidated
      description: >
        Outcome of a security check on the status of the customer's payment card
        or bank account.  


        **Note:** Depending on the merchant's account settings, this feature may
        be unavailable. 
      title: SecureTokenStatus
    customField:
      type: object
      properties:
        name:
          type: string
          description: Name of the custom field.
        value:
          type: string
          description: Value for the custom field.
      required:
        - name
        - value
      title: customField
    secureToken:
      type: object
      properties:
        secureTokenId:
          type: string
          description: >-
            Unique identifier that the merchant created for the secure token
            that represents the customer's payment details.
        processingTerminalId:
          type: string
          description: Unique identifier that we assigned to the terminal.
        mitAgreement:
          $ref: '#/components/schemas/SecureTokenMitAgreement'
          description: >
            Indicates how the merchant can use the customer's card details, as
            agreed by the customer:


            - `unscheduled` - Transactions for a fixed or variable amount that
            are run at a certain pre-defined event.

            - `recurring` - Transactions for a fixed amount that are run at
            regular intervals, for example, monthly. Recurring transactions
            don't have a fixed duration and run until the customer cancels the
            agreement.

            - `installment` - Transactions for a fixed amount that are run at
            regular intervals, for example, monthly. Installment transactions
            have a fixed duration.
        customer:
          $ref: '#/components/schemas/retrievedCustomer'
        source:
          $ref: '#/components/schemas/SecureTokenSource'
          description: "Polymorphic object that contains the payment method that we tokenized.  \n\nThe value of the type parameter determines which variant you should use:  \n-\t`ach` - Automated Clearing House (ACH) details\n-\t`pad` - Pre-authorized debit (PAD) details\n-\t`card` - Payment card details\n"
        token:
          type: string
          description: >
            Token that the merchant can use in future transactions to represent
            the customer's payment details. The token:  

            - Begins with the six-digit identification number **296753**.

            - Contains up to 12 digits.  

            - Contains a single check digit that we calculate using the Luhn
            algorithm.
        status:
          $ref: '#/components/schemas/SecureTokenStatus'
          description: >
            Outcome of a security check on the status of the customer's payment
            card or bank account.  


            **Note:** Depending on the merchant's account settings, this feature
            may be unavailable. 
        customFields:
          type: array
          items:
            $ref: '#/components/schemas/customField'
          description: |
            Array of customField objects.
      required:
        - secureTokenId
        - processingTerminalId
        - source
        - token
        - status
      description: Object that contains information about the secure token.
      title: secureToken
    ErrorsItems:
      type: object
      properties:
        message:
          type: string
          description: Error message
      title: ErrorsItems
    link:
      type: object
      properties:
        rel:
          type: string
          description: >-
            Indicates the relationship between the current resource and the
            target resource.
        method:
          type: string
          description: HTTP method that you need to use with the target resource.
        href:
          type: string
          description: URL of the target resource.
      required:
        - rel
        - method
        - href
      description: Object that contains HATEOAS links for the resource.
      title: link

```

### Example request

### Request

POST [https://api.payroc.com/v1/processing-terminals/\{processingTerminalId}/secure-tokens/\{secureTokenId}/update-account](https://api.payroc.com/v1/processing-terminals/\{processingTerminalId}/secure-tokens/\{secureTokenId}/update-account)

```curl Secure Token
curl -X POST https://api.payroc.com/v1/processing-terminals/1234001/secure-tokens/MREF_abc1de23-f4a5-6789-bcd0-12e345678901fa/update-account \
     -H "Idempotency-Key: 8e03978e-40d5-43e8-bc93-6894a57f9324" \
     -H "Authorization: Bearer <token>" \
     -H "Content-Type: application/json"
```

```typescript Secure Token
import { PayrocClient } from "payroc";

async function main() {
    const client = new PayrocClient();
    await client.tokenization.secureTokens.updateAccount("1234001", "MREF_abc1de23-f4a5-6789-bcd0-12e345678901fa", {
        idempotencyKey: "8e03978e-40d5-43e8-bc93-6894a57f9324",
    });
}
main();

```

```python Secure Token
from payroc import Payroc

client = Payroc()

client.tokenization.secure_tokens.update_account(
    processing_terminal_id="1234001",
    secure_token_id="MREF_abc1de23-f4a5-6789-bcd0-12e345678901fa",
    idempotency_key="8e03978e-40d5-43e8-bc93-6894a57f9324",
)

```

```java Secure Token
package com.example.usage;

import com.payroc.api.PayrocApiClient;
import com.payroc.api.resources.tokenization.securetokens.requests.UpdateAccountSecureTokensRequest;

public class Example {
    public static void main(String[] args) {
        PayrocApiClient client = PayrocApiClient
            .builder()
            .build();

        client.tokenization().secureTokens().updateAccount(
            "1234001",
            "MREF_abc1de23-f4a5-6789-bcd0-12e345678901fa",
            UpdateAccountSecureTokensRequest
                .builder()
                .idempotencyKey("8e03978e-40d5-43e8-bc93-6894a57f9324")
                .build()
        );
    }
}
```

```ruby Secure Token
require "payroc"

client = Payroc::Client.new

client.tokenization.secure_tokens.update_account(
  processing_terminal_id: "1234001",
  secure_token_id: "MREF_abc1de23-f4a5-6789-bcd0-12e345678901fa",
  idempotency_key: "8e03978e-40d5-43e8-bc93-6894a57f9324"
)

```

```csharp Secure Token
using Payroc;
using System.Threading.Tasks;
using Payroc.Tokenization.SecureTokens;

namespace Usage;

public class Example
{
    public async Task Do() {
        var client = new PayrocClient();

        await client.Tokenization.SecureTokens.UpdateAccountAsync(
            new UpdateAccountSecureTokensRequest {
                ProcessingTerminalId = "1234001",
                SecureTokenId = "MREF_abc1de23-f4a5-6789-bcd0-12e345678901fa",
                IdempotencyKey = "8e03978e-40d5-43e8-bc93-6894a57f9324"
            }
        );
    }

}

```

```go Secure Token
package main

import (
	"fmt"
	"net/http"
	"io"
)

func main() {

	url := "https://api.payroc.com/v1/processing-terminals/1234001/secure-tokens/MREF_abc1de23-f4a5-6789-bcd0-12e345678901fa/update-account"

	req, _ := http.NewRequest("POST", url, nil)

	req.Header.Add("Idempotency-Key", "8e03978e-40d5-43e8-bc93-6894a57f9324")
	req.Header.Add("Authorization", "Bearer <token>")
	req.Header.Add("Content-Type", "application/json")

	res, _ := http.DefaultClient.Do(req)

	defer res.Body.Close()
	body, _ := io.ReadAll(res.Body)

	fmt.Println(res)
	fmt.Println(string(body))

}
```

```php Secure Token
<?php
require_once('vendor/autoload.php');

$client = new \GuzzleHttp\Client();

$response = $client->request('POST', 'https://api.payroc.com/v1/processing-terminals/1234001/secure-tokens/MREF_abc1de23-f4a5-6789-bcd0-12e345678901fa/update-account', [
  'headers' => [
    'Authorization' => 'Bearer <token>',
    'Content-Type' => 'application/json',
    'Idempotency-Key' => '8e03978e-40d5-43e8-bc93-6894a57f9324',
  ],
]);

echo $response->getBody();
```

```swift Secure Token
import Foundation

let headers = [
  "Idempotency-Key": "8e03978e-40d5-43e8-bc93-6894a57f9324",
  "Authorization": "Bearer <token>",
  "Content-Type": "application/json"
]

let request = NSMutableURLRequest(url: NSURL(string: "https://api.payroc.com/v1/processing-terminals/1234001/secure-tokens/MREF_abc1de23-f4a5-6789-bcd0-12e345678901fa/update-account")! as URL,
                                        cachePolicy: .useProtocolCachePolicy,
                                    timeoutInterval: 10.0)
request.httpMethod = "POST"
request.allHTTPHeaderFields = headers

let session = URLSession.shared
let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
  if (error != nil) {
    print(error as Any)
  } else {
    let httpResponse = response as? HTTPURLResponse
    print(httpResponse)
  }
})

dataTask.resume()
```

### Response fields

If your request is successful, we update the payment details associated with the secure token. The response contains the following fields:

**Note:** When we update the payment details associated with the secure token, we change only the payment details that the secure token represents. The values for the secureTokenId parameter and the token parameter stay the same.

### Schema (`response.body`)

```yaml
openapi: 3.1.0
info:
  title: API
  version: 1.0.0
paths:
  /processing-terminals/{processingTerminalId}/secure-tokens/{secureTokenId}/update-account:
    post:
      operationId: update-account
      summary: Update account details
      description: >
        Use this method to update a secure token if you have a single-use token
        from Hosted Fields.  


        **Note:** If you don't have a single-use token, you can update saved
        payment details with our [Update Secure
        Token](https://docs.payroc.com/api/resources#updateSecureToken) method.
        For more information about our two options to update a secure token, go
        to [Update saved payment
        details](https://docs.payroc.com/guides/take-payments/update-saved-payment-details).  
      tags:
        - subpackage_tokenization.subpackage_tokenization/secureTokens
      parameters:
        - name: processingTerminalId
          in: path
          description: Unique identifier that we assigned to the terminal.
          required: true
          schema:
            type: string
        - name: secureTokenId
          in: path
          description: Unique identifier that the merchant assigned to the secure token.
          required: true
          schema:
            type: string
        - name: Idempotency-Key
          in: header
          description: >-
            Unique identifier that you generate for each request. You must use
            the [UUID v4 format](https://www.rfc-editor.org/rfc/rfc4122) for the
            identifier. For more information about the idempotency key, go to
            [Idempotency](https://docs.payroc.com/api/idempotency).
          required: true
          schema:
            type: string
            format: uuid
      responses:
        '200':
          description: >-
            Successful request. We updated the payment details represented by
            the secure token.
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/secureToken'
        '400':
          description: Invalid request
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/400'
        '401':
          description: Identity could not be verified
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/401'
        '403':
          description: Do not have permissions to perform this action
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/403'
        '404':
          description: Resource not found
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/404'
        '406':
          description: Not acceptable
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/406'
        '409':
          description: Conflict
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/409'
        '413':
          description: Payload too large
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/413'
        '415':
          description: Unsupported media type
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/415'
        '500':
          description: An error has occured
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/500'
      requestBody:
        description: >-
          Polymorphic object that contains information about the single-use
          token.
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/accountUpdate'
servers:
  - url: https://api.payroc.com/v1
  - url: https://api.uat.payroc.com/v1
components:
  schemas:
    '400':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
        errors:
          type: array
          items:
            $ref: '#/components/schemas/ErrorsItems'
      required:
        - type
        - title
        - status
        - detail
      title: '400'
    '401':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
      required:
        - type
        - title
        - status
        - detail
      title: '401'
    '403':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
        instance:
          type: string
          description: Resource path the action was attempted on
        resource:
          type: string
          description: Resource the action was attempted on
      required:
        - type
        - title
        - status
        - detail
      title: '403'
    '404':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
        resource:
          type: string
          description: Resource that was not found
      required:
        - type
        - title
        - status
        - detail
      title: '404'
    '406':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
      required:
        - type
        - title
        - status
        - detail
      title: '406'
    '409':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
        instance:
          type: string
          description: Resource path to the existing resource
        errors:
          type: array
          items:
            $ref: '#/components/schemas/ErrorsItems'
        link:
          $ref: '#/components/schemas/link'
      required:
        - type
        - title
        - status
        - detail
      title: '409'
    '413':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
      required:
        - type
        - title
        - status
        - detail
      title: '413'
    '415':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
      required:
        - type
        - title
        - status
        - detail
      title: '415'
    '500':
      type: object
      properties:
        type:
          type: string
          description: URI reference identifying the problem type
        title:
          type: string
          description: Short description of the issue.
        status:
          type: integer
          description: Http status code
        detail:
          type: string
          description: Explanation of the problem
        errors:
          type: array
          items:
            $ref: '#/components/schemas/ErrorsItems'
      required:
        - type
        - title
        - status
        - detail
      title: '500'
    accountUpdate:
      oneOf:
        - type: object
          properties:
            type:
              type: string
              enum:
                - singleUseToken
              description: 'Discriminator value: singleUseToken'
            token:
              type: string
              description: >-
                Single-use token that the gateway assigned to the payment
                details.
          required:
            - type
            - token
          description: Object that contains the token.
      discriminator:
        propertyName: type
      description: Polymorphic object that contains information about the single-use token.
      title: accountUpdate
    SecureTokenMitAgreement:
      type: string
      enum:
        - unscheduled
        - recurring
        - installment
      description: >
        Indicates how the merchant can use the customer's card details, as
        agreed by the customer:


        - `unscheduled` - Transactions for a fixed or variable amount that are
        run at a certain pre-defined event.

        - `recurring` - Transactions for a fixed amount that are run at regular
        intervals, for example, monthly. Recurring transactions don't have a
        fixed duration and run until the customer cancels the agreement.

        - `installment` - Transactions for a fixed amount that are run at
        regular intervals, for example, monthly. Installment transactions have a
        fixed duration.
      title: SecureTokenMitAgreement
    retrievedAddress:
      type: object
      properties:
        address1:
          type: string
          description: Address line 1.
        address2:
          type: string
          description: Address line 2.
        address3:
          type: string
          description: Address line 3.
        city:
          type: string
          description: City.
        state:
          type: string
          description: Name of the state or state abbreviation.
        country:
          type: string
          description: >-
            Two-digit country code for the country that the business operates
            in. The format follows the
            [ISO-3166-1](https://www.iso.org/iso-3166-country-codes.html)
            standard.
        postalCode:
          type: string
          description: Zip code or postal code.
      description: Object that contains information about the address.
      title: retrievedAddress
    retrievedShipping:
      type: object
      properties:
        recipientName:
          type: string
          description: Recipient's name.
        address:
          $ref: '#/components/schemas/retrievedAddress'
      description: >-
        Object that contains information about the customer and their shipping
        address.
      title: retrievedShipping
    contactMethod:
      oneOf:
        - type: object
          properties:
            type:
              type: string
              enum:
                - email
              description: 'Discriminator value: email'
            value:
              type: string
              description: Email address.
          required:
            - type
            - value
          description: email variant
        - type: object
          properties:
            type:
              type: string
              enum:
                - phone
              description: 'Discriminator value: phone'
            value:
              type: string
              description: Phone number.
          required:
            - type
            - value
          description: phone variant
        - type: object
          properties:
            type:
              type: string
              enum:
                - mobile
              description: 'Discriminator value: mobile'
            value:
              type: string
              description: Mobile number.
          required:
            - type
            - value
          description: mobile variant
        - type: object
          properties:
            type:
              type: string
              enum:
                - fax
              description: 'Discriminator value: fax'
            value:
              type: string
              description: Fax number.
          required:
            - type
            - value
          description: fax variant
      discriminator:
        propertyName: type
      title: contactMethod
    RetrievedCustomerNotificationLanguage:
      type: string
      enum:
        - en
        - fr
      description: >
        Language that the customer uses for notifications. This code follows the
        [ISO 639-1](https://www.iso.org/iso-639-language-code) alpha-2
        standard. 
      title: RetrievedCustomerNotificationLanguage
    retrievedCustomer:
      type: object
      properties:
        firstName:
          type: string
          description: Customer's first name.
        lastName:
          type: string
          description: Customer's last name.
        dateOfBirth:
          type: string
          format: date
          description: >-
            Customer's date of birth. The format for this value is
            **YYYY-MM-DD**.
        referenceNumber:
          type: string
          description: >
            Identifier of the transaction, also known as a customer code. 


            For requests, you must send a value for **referenceNumber** if the
            customer provides one. 
        billingAddress:
          $ref: '#/components/schemas/retrievedAddress'
          description: >-
            Object that contains information about the address that the card is
            registered to.
        shippingAddress:
          $ref: '#/components/schemas/retrievedShipping'
        contactMethods:
          type: array
          items:
            $ref: '#/components/schemas/contactMethod'
          description: "Array of polymorphic objects, which contain contact information.  \n\nThe value of the type parameter determines which variant you should use:  \n-\t`email` - Email address \n-\t`phone` - Phone number\n-\t`mobile` - Mobile number\n-\t`fax` - Fax number\n"
        notificationLanguage:
          $ref: '#/components/schemas/RetrievedCustomerNotificationLanguage'
          description: >
            Language that the customer uses for notifications. This code follows
            the [ISO 639-1](https://www.iso.org/iso-639-language-code) alpha-2
            standard. 
      description: >-
        Object that contains the customer's contact details and address
        information.
      title: retrievedCustomer
    currency:
      type: string
      enum:
        - AED
        - AFN
        - ALL
        - AMD
        - ANG
        - AOA
        - ARS
        - AUD
        - AWG
        - AZN
        - BAM
        - BBD
        - BDT
        - BGN
        - BHD
        - BIF
        - BMD
        - BND
        - BOB
        - BOV
        - BRL
        - BSD
        - BTN
        - BWP
        - BYR
        - BZD
        - CAD
        - CDF
        - CHE
        - CHF
        - CHW
        - CLF
        - CLP
        - CNY
        - COP
        - COU
        - CRC
        - CUC
        - CUP
        - CVE
        - CZK
        - DJF
        - DKK
        - DOP
        - DZD
        - EGP
        - ERN
        - ETB
        - EUR
        - FJD
        - FKP
        - GBP
        - GEL
        - GHS
        - GIP
        - GMD
        - GNF
        - GTQ
        - GYD
        - HKD
        - HNL
        - HRK
        - HTG
        - HUF
        - IDR
        - ILS
        - INR
        - IQD
        - IRR
        - ISK
        - JMD
        - JOD
        - JPY
        - KES
        - KGS
        - KHR
        - KMF
        - KPW
        - KRW
        - KWD
        - KYD
        - KZT
        - LAK
        - LBP
        - LKR
        - LRD
        - LSL
        - LTL
        - LVL
        - LYD
        - MAD
        - MDL
        - MGA
        - MKD
        - MMK
        - MNT
        - MOP
        - MRO
        - MRU
        - MUR
        - MVR
        - MWK
        - MXN
        - MXV
        - MYR
        - MZN
        - NAD
        - NGN
        - NIO
        - NOK
        - NPR
        - NZD
        - OMR
        - PAB
        - PEN
        - PGK
        - PHP
        - PKR
        - PLN
        - PYG
        - QAR
        - RON
        - RSD
        - RUB
        - RWF
        - SAR
        - SBD
        - SCR
        - SDG
        - SEK
        - SGD
        - SHP
        - SLL
        - SOS
        - SRD
        - SSP
        - STD
        - STN
        - SVC
        - SYP
        - SZL
        - THB
        - TJS
        - TMT
        - TND
        - TOP
        - TRY
        - TTD
        - TWD
        - TZS
        - UAH
        - UGX
        - USD
        - USN
        - USS
        - UYI
        - UYU
        - UZS
        - VEF
        - VES
        - VND
        - VUV
        - WST
        - XAF
        - XCD
        - XOF
        - XPF
        - YER
        - ZAR
        - ZMW
        - ZWL
      description: >-
        Currency of the transaction. The value for the currency follows the [ISO
        4217](https://www.iso.org/iso-4217-currency-codes.html) standard.
      title: currency
    surcharging:
      type: object
      properties:
        allowed:
          type: boolean
          description: >-
            Indicates if the merchant can add a surcharge when the customer uses
            this card.
        amount:
          type: integer
          format: int64
          description: >
            Surcharge amount to add to the transaction.  

            **Note:** Our gateway returns the surcharge amount only if you
            include a transaction amount in the request.
        percentage:
          type: number
          format: double
          description: Surcharge rate that the merchant configures on their account.
        disclosure:
          type: string
          description: Statement that informs the customer about the surcharge fee.
      required:
        - allowed
      description: >-
        Object that contains surcharge information. Our gateway returns this
        object only if the merchant adds a surcharge to transactions.
      title: surcharging
    SecureTokenSource:
      oneOf:
        - type: object
          properties:
            type:
              type: string
              enum:
                - ach
              description: 'Discriminator value: ach'
            nameOnAccount:
              type: string
              description: Customer's name.
            accountNumber:
              type: string
              description: Customer's account number.
            routingNumber:
              type: string
              description: Routing number of the customer's account.
          required:
            - type
            - nameOnAccount
            - accountNumber
            - routingNumber
          description: Object that contains the customer's account details.
        - type: object
          properties:
            type:
              type: string
              enum:
                - pad
              description: 'Discriminator value: pad'
            nameOnAccount:
              type: string
              description: Customer's name.
            accountNumber:
              type: string
              description: Customer's account number.
            transitNumber:
              type: string
              description: Five-digit code that represents the customer's banking branch.
            institutionNumber:
              type: string
              description: Three-digit code that represents the customer's bank.
          required:
            - type
            - nameOnAccount
            - accountNumber
            - transitNumber
            - institutionNumber
          description: Object that contains the customer's account details.
        - type: object
          properties:
            type:
              type: string
              enum:
                - card
              description: 'Discriminator value: card'
            cardholderName:
              type: string
              description: Cardholder's name.
            cardNumber:
              type: string
              description: Primary account number of the customer's card.
            expiryDate:
              type: string
              description: Expiry date of the customer's card.
            cardType:
              type: string
              description: Card brand of the card, for example, Visa.
            currency:
              $ref: '#/components/schemas/currency'
            debit:
              type: boolean
              description: Indicates if the card is a debit card.
            surcharging:
              $ref: '#/components/schemas/surcharging'
          required:
            - type
            - cardholderName
            - cardNumber
          description: Object that contains the customer's card details.
      discriminator:
        propertyName: type
      description: "Polymorphic object that contains the payment method that we tokenized.  \n\nThe value of the type parameter determines which variant you should use:  \n-\t`ach` - Automated Clearing House (ACH) details\n-\t`pad` - Pre-authorized debit (PAD) details\n-\t`card` - Payment card details\n"
      title: SecureTokenSource
    SecureTokenStatus:
      type: string
      enum:
        - notValidated
        - cvvValidated
        - validationFailed
        - issueNumberValidated
        - cardNumberValidated
        - bankAccountValidated
      description: >
        Outcome of a security check on the status of the customer's payment card
        or bank account.  


        **Note:** Depending on the merchant's account settings, this feature may
        be unavailable. 
      title: SecureTokenStatus
    customField:
      type: object
      properties:
        name:
          type: string
          description: Name of the custom field.
        value:
          type: string
          description: Value for the custom field.
      required:
        - name
        - value
      title: customField
    secureToken:
      type: object
      properties:
        secureTokenId:
          type: string
          description: >-
            Unique identifier that the merchant created for the secure token
            that represents the customer's payment details.
        processingTerminalId:
          type: string
          description: Unique identifier that we assigned to the terminal.
        mitAgreement:
          $ref: '#/components/schemas/SecureTokenMitAgreement'
          description: >
            Indicates how the merchant can use the customer's card details, as
            agreed by the customer:


            - `unscheduled` - Transactions for a fixed or variable amount that
            are run at a certain pre-defined event.

            - `recurring` - Transactions for a fixed amount that are run at
            regular intervals, for example, monthly. Recurring transactions
            don't have a fixed duration and run until the customer cancels the
            agreement.

            - `installment` - Transactions for a fixed amount that are run at
            regular intervals, for example, monthly. Installment transactions
            have a fixed duration.
        customer:
          $ref: '#/components/schemas/retrievedCustomer'
        source:
          $ref: '#/components/schemas/SecureTokenSource'
          description: "Polymorphic object that contains the payment method that we tokenized.  \n\nThe value of the type parameter determines which variant you should use:  \n-\t`ach` - Automated Clearing House (ACH) details\n-\t`pad` - Pre-authorized debit (PAD) details\n-\t`card` - Payment card details\n"
        token:
          type: string
          description: >
            Token that the merchant can use in future transactions to represent
            the customer's payment details. The token:  

            - Begins with the six-digit identification number **296753**.

            - Contains up to 12 digits.  

            - Contains a single check digit that we calculate using the Luhn
            algorithm.
        status:
          $ref: '#/components/schemas/SecureTokenStatus'
          description: >
            Outcome of a security check on the status of the customer's payment
            card or bank account.  


            **Note:** Depending on the merchant's account settings, this feature
            may be unavailable. 
        customFields:
          type: array
          items:
            $ref: '#/components/schemas/customField'
          description: |
            Array of customField objects.
      required:
        - secureTokenId
        - processingTerminalId
        - source
        - token
        - status
      description: Object that contains information about the secure token.
      title: secureToken
    ErrorsItems:
      type: object
      properties:
        message:
          type: string
          description: Error message
      title: ErrorsItems
    link:
      type: object
      properties:
        rel:
          type: string
          description: >-
            Indicates the relationship between the current resource and the
            target resource.
        method:
          type: string
          description: HTTP method that you need to use with the target resource.
        href:
          type: string
          description: URL of the target resource.
      required:
        - rel
        - method
        - href
      description: Object that contains HATEOAS links for the resource.
      title: link

```

### Example response

### Response (200)

```json
{
  "secureTokenId": "MREF_abc1de23-f4a5-6789-bcd0-12e345678901fa",
  "processingTerminalId": "1234001",
  "source": {
    "type": "card",
    "cardNumber": "453985******7062",
    "cardholderName": "Sarah Hazel Hopper",
    "expiryDate": "1230"
  },
  "token": "296753123456",
  "status": "notValidated",
  "mitAgreement": "unscheduled",
  "customer": {
    "firstName": "Sarah",
    "lastName": "Hopper",
    "dateOfBirth": "1990-07-15",
    "referenceNumber": "Customer-12",
    "billingAddress": {
      "address1": "1 Example Ave.",
      "address2": "Example Address Line 2",
      "address3": "Example Address Line 3",
      "city": "Chicago",
      "state": "Illinois",
      "country": "US",
      "postalCode": "60056"
    },
    "shippingAddress": {
      "recipientName": "Sarah Hopper",
      "address": {
        "address1": "1 Example Ave.",
        "address2": "Example Address Line 2",
        "address3": "Example Address Line 3",
        "city": "Chicago",
        "state": "Illinois",
        "country": "US",
        "postalCode": "60056"
      }
    },
    "contactMethods": [
      {
        "type": "email",
        "value": "sarah.hopper@example.com"
      }
    ],
    "notificationLanguage": "en"
  },
  "customFields": [
    {
      "name": "yourCustomField",
      "value": "abc123"
    }
  ]
}
```