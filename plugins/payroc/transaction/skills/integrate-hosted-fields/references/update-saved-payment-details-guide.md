> **Local snapshot — authoritative for this skill.** Source: https://docs.payroc.com/guides/take-payments/update-saved-payment-details
> Last synced: 2026-07-02. Verbatim copy of the Payroc narrative guide. To refresh, re-fetch the source and regenerate this file (see _sources.md).

# Update saved payment details

> Update a customer's saved payment details by sending a PATCH request to the Update Secure Token endpoint or a POST request to the Update Account Details endpoint using a single-use token.

Integrate with our API to update a customer’s saved payment details. Our API has two endpoints to update payment details represented by a secure token:

* [Update saved payment details](#update-a-secure-token)  – Use our Update Secure Token endpoint if you are sending the raw payment details, for example, if you are updating a card’s expiry date or a billing address.
* [Update saved payment details with a single-use token](#update-saved-payment-details-with-a-single-use-token)  – Use our Update Account Details endpoint if you have a single-use token that represents updated payment details, for example, if you have a single-use token from Hosted Fields.

**Note:** To update saved payment details, you need the ID of the secure token that represents the payment details. If you don’t know the ID, go to List Secure Tokens.

## Before you begin

Authenticate your requests before making API calls. If your request fails, see Errors.

## Update saved payment details

Use the Update Secure Token method if you have the raw information that a customer wants to update. You can update the following payment details:

* Sensitive payment details, including:
  * **Card** - Cardholder name and expiry date
  * **ACH** - Accountholder name and account type
  * **PAD** - Accountholder name and institution number
* MIT agreement
* Customer’s contact details
* Customer’s address details

## Integration steps

* Update a secure token

## Update a secure token

To update the payment details represented by a secure token, send a PATCH request to our Update Secure Token endpoint.

| Environment | URL                                                                                                                                                                                                                    |
| :---------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Test        | [https://api.uat.payroc.com/v1/processing-terminals/\{processingTerminalId}/secure-tokens/\{secureTokenId}](https://api.uat.payroc.com/v1/processing-terminals/\{processingTerminalId}/secure-tokens/\{secureTokenId}) |
| Production  | [https://api.payroc.com/v1/processing-terminals/\{processingTerminalId}/secure-tokens/\{secureTokenId}](https://api.payroc.com/v1/processing-terminals/\{processingTerminalId}/secure-tokens/\{secureTokenId})         |

**Note:** The request format follows the RFC 6902 standard.

### Request parameters

To create the body of your request, use the following parameters:

### Schema (`request.body`)

```yaml
openapi: 3.1.0
info:
  title: API
  version: 1.0.0
paths:
  /processing-terminals/{processingTerminalId}/secure-tokens/{secureTokenId}:
    patch:
      operationId: partially-update
      summary: Partially update secure token
      description: >
        Use this method to partially update a secure token. Structure your
        request to follow the [RFC
        6902](https://datatracker.ietf.org/doc/html/rfc6902) standard.  


        To update a secure token, you need its secureTokenId, which you sent in
        the request of the [Create Secure Token](./secure-tokens-api-schema.md)
        method.  


        **Note:** If you don't have the secureTokenId, use our [List Secure Tokens](./secure-tokens-api-schema.md)
        method to search  for the payment.  


        You can update all of the properties of the secure token, except the
        following:  

        - processingTerminalId  

        - type  

        - token  

        - status  

        - source/Card  
          - type  
          - cardNumber  
          - cardType  
          - currency  
          - debit  
          - surcharging  
        - source/ACH account  
          - accountNumber  
          - routingNumber  
        - source/PAD account  
          - type  
          - accountNumber  
          - transitNumber  
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
            [Idempotency](./idempotency.md).
          required: true
          schema:
            type: string
            format: uuid
      responses:
        '200':
          description: Successful request. We updated the customer's payment details.
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/secureToken'
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
              $ref: '#/components/schemas/patchRequest'
servers:
  - url: https://api.payroc.com/v1
    description: Production
  - url: https://api.uat.payroc.com/v1
    description: UAT
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
    patchDocument:
      oneOf:
        - type: object
          properties:
            op:
              type: string
              enum:
                - add
              description: 'Discriminator value: add'
            path:
              type: string
              description: |
                Location where you want to add the value.
                The format for this value is JSON Pointer.
            value:
              description: Value that you want to add to the resource.
          required:
            - op
            - path
            - value
          description: A Patch Add Operation.
        - type: object
          properties:
            op:
              type: string
              enum:
                - remove
              description: 'Discriminator value: remove'
            path:
              type: string
              description: |
                Location of the value that you want to remove.
                The format for this value is JSON Pointer.
          required:
            - op
            - path
          description: A Patch Remove Operation.
        - type: object
          properties:
            op:
              type: string
              enum:
                - replace
              description: 'Discriminator value: replace'
            path:
              type: string
              description: |
                Location of the value that you want to replace.
                The format for this value is JSON Pointer.
            value:
              description: Value that you want to use as the replacement.
          required:
            - op
            - path
            - value
          description: A Patch Replace Operation.
        - type: object
          properties:
            op:
              type: string
              enum:
                - move
              description: 'Discriminator value: move'
            from:
              type: string
              description: |
                Location of the value that you want to move.
                The format for this value is JSON Pointer.
            path:
              type: string
              description: |
                Location where you want to move the value to.
                The format for this value is JSON Pointer.
          required:
            - op
            - from
            - path
          description: A Patch Move Operation.
        - type: object
          properties:
            op:
              type: string
              enum:
                - copy
              description: 'Discriminator value: copy'
            from:
              type: string
              description: |
                Location of the value that you want to copy.
                The format for this value is JSON Pointer.
            path:
              type: string
              description: |
                Location where you want to copy the value to.
                The format for this value is JSON Pointer.
          required:
            - op
            - from
            - path
          description: A Patch Copy Operation.
        - type: object
          properties:
            op:
              type: string
              enum:
                - test
              description: 'Discriminator value: test'
            path:
              type: string
              description: |
                Location of the value that you want to test.
                The format for this value is JSON Pointer.
            value:
              description: >-
                Value that you want to compare with the current value at the
                path.
          required:
            - op
            - path
            - value
          description: A Patch Test Operation.
      discriminator:
        propertyName: op
      description: A JSON Patch operation as defined by RFC 6902.
      title: patchDocument
    patchRequest:
      type: array
      items:
        $ref: '#/components/schemas/patchDocument'
      description: A JSON Patch document as defined by RFC 6902.
      title: patchRequest
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

PATCH [https://api.payroc.com/v1/processing-terminals/\{processingTerminalId}/secure-tokens/\{secureTokenId}](https://api.payroc.com/v1/processing-terminals/\{processingTerminalId}/secure-tokens/\{secureTokenId})

```curl Secure Token
curl -X PATCH https://api.payroc.com/v1/processing-terminals/1234001/secure-tokens/MREF_abc1de23-f4a5-6789-bcd0-12e345678901fa \
     -H "Idempotency-Key: 8e03978e-40d5-43e8-bc93-6894a57f9324" \
     -H "Authorization: Bearer <token>" \
     -H "Content-Type: application/json"
```

```python Secure Token
import requests

url = "https://api.payroc.com/v1/processing-terminals/1234001/secure-tokens/MREF_abc1de23-f4a5-6789-bcd0-12e345678901fa"

headers = {
    "Idempotency-Key": "8e03978e-40d5-43e8-bc93-6894a57f9324",
    "Authorization": "Bearer <token>",
    "Content-Type": "application/json"
}

response = requests.patch(url, headers=headers)

print(response.json())
```

```javascript Secure Token
const url = 'https://api.payroc.com/v1/processing-terminals/1234001/secure-tokens/MREF_abc1de23-f4a5-6789-bcd0-12e345678901fa';
const options = {
  method: 'PATCH',
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

```go Secure Token
package main

import (
	"fmt"
	"net/http"
	"io"
)

func main() {

	url := "https://api.payroc.com/v1/processing-terminals/1234001/secure-tokens/MREF_abc1de23-f4a5-6789-bcd0-12e345678901fa"

	req, _ := http.NewRequest("PATCH", url, nil)

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

```ruby Secure Token
require 'uri'
require 'net/http'

url = URI("https://api.payroc.com/v1/processing-terminals/1234001/secure-tokens/MREF_abc1de23-f4a5-6789-bcd0-12e345678901fa")

http = Net::HTTP.new(url.host, url.port)
http.use_ssl = true

request = Net::HTTP::Patch.new(url)
request["Idempotency-Key"] = '8e03978e-40d5-43e8-bc93-6894a57f9324'
request["Authorization"] = 'Bearer <token>'
request["Content-Type"] = 'application/json'

response = http.request(request)
puts response.read_body
```

```java Secure Token
import com.mashape.unirest.http.HttpResponse;
import com.mashape.unirest.http.Unirest;

HttpResponse<String> response = Unirest.patch("https://api.payroc.com/v1/processing-terminals/1234001/secure-tokens/MREF_abc1de23-f4a5-6789-bcd0-12e345678901fa")
  .header("Idempotency-Key", "8e03978e-40d5-43e8-bc93-6894a57f9324")
  .header("Authorization", "Bearer <token>")
  .header("Content-Type", "application/json")
  .asString();
```

```php Secure Token
<?php
require_once('vendor/autoload.php');

$client = new \GuzzleHttp\Client();

$response = $client->request('PATCH', 'https://api.payroc.com/v1/processing-terminals/1234001/secure-tokens/MREF_abc1de23-f4a5-6789-bcd0-12e345678901fa', [
  'headers' => [
    'Authorization' => 'Bearer <token>',
    'Content-Type' => 'application/json',
    'Idempotency-Key' => '8e03978e-40d5-43e8-bc93-6894a57f9324',
  ],
]);

echo $response->getBody();
```

```csharp Secure Token
using RestSharp;

var client = new RestClient("https://api.payroc.com/v1/processing-terminals/1234001/secure-tokens/MREF_abc1de23-f4a5-6789-bcd0-12e345678901fa");
var request = new RestRequest(Method.PATCH);
request.AddHeader("Idempotency-Key", "8e03978e-40d5-43e8-bc93-6894a57f9324");
request.AddHeader("Authorization", "Bearer <token>");
request.AddHeader("Content-Type", "application/json");
IRestResponse response = client.Execute(request);
```

```swift Secure Token
import Foundation

let headers = [
  "Idempotency-Key": "8e03978e-40d5-43e8-bc93-6894a57f9324",
  "Authorization": "Bearer <token>",
  "Content-Type": "application/json"
]

let request = NSMutableURLRequest(url: NSURL(string: "https://api.payroc.com/v1/processing-terminals/1234001/secure-tokens/MREF_abc1de23-f4a5-6789-bcd0-12e345678901fa")! as URL,
                                        cachePolicy: .useProtocolCachePolicy,
                                    timeoutInterval: 10.0)
request.httpMethod = "PATCH"
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

If your request is successful, we update the secure token and return the details represented by the secure token.

### Schema (`response.body`)

```yaml
openapi: 3.1.0
info:
  title: API
  version: 1.0.0
paths:
  /processing-terminals/{processingTerminalId}/secure-tokens/{secureTokenId}:
    patch:
      operationId: partially-update
      summary: Partially update secure token
      description: >
        Use this method to partially update a secure token. Structure your
        request to follow the [RFC
        6902](https://datatracker.ietf.org/doc/html/rfc6902) standard.  


        To update a secure token, you need its secureTokenId, which you sent in
        the request of the [Create Secure Token](./secure-tokens-api-schema.md)
        method.  


        **Note:** If you don't have the secureTokenId, use our [List Secure Tokens](./secure-tokens-api-schema.md)
        method to search  for the payment.  


        You can update all of the properties of the secure token, except the
        following:  

        - processingTerminalId  

        - type  

        - token  

        - status  

        - source/Card  
          - type  
          - cardNumber  
          - cardType  
          - currency  
          - debit  
          - surcharging  
        - source/ACH account  
          - accountNumber  
          - routingNumber  
        - source/PAD account  
          - type  
          - accountNumber  
          - transitNumber  
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
            [Idempotency](./idempotency.md).
          required: true
          schema:
            type: string
            format: uuid
      responses:
        '200':
          description: Successful request. We updated the customer's payment details.
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/secureToken'
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
              $ref: '#/components/schemas/patchRequest'
servers:
  - url: https://api.payroc.com/v1
    description: Production
  - url: https://api.uat.payroc.com/v1
    description: UAT
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
    patchDocument:
      oneOf:
        - type: object
          properties:
            op:
              type: string
              enum:
                - add
              description: 'Discriminator value: add'
            path:
              type: string
              description: |
                Location where you want to add the value.
                The format for this value is JSON Pointer.
            value:
              description: Value that you want to add to the resource.
          required:
            - op
            - path
            - value
          description: A Patch Add Operation.
        - type: object
          properties:
            op:
              type: string
              enum:
                - remove
              description: 'Discriminator value: remove'
            path:
              type: string
              description: |
                Location of the value that you want to remove.
                The format for this value is JSON Pointer.
          required:
            - op
            - path
          description: A Patch Remove Operation.
        - type: object
          properties:
            op:
              type: string
              enum:
                - replace
              description: 'Discriminator value: replace'
            path:
              type: string
              description: |
                Location of the value that you want to replace.
                The format for this value is JSON Pointer.
            value:
              description: Value that you want to use as the replacement.
          required:
            - op
            - path
            - value
          description: A Patch Replace Operation.
        - type: object
          properties:
            op:
              type: string
              enum:
                - move
              description: 'Discriminator value: move'
            from:
              type: string
              description: |
                Location of the value that you want to move.
                The format for this value is JSON Pointer.
            path:
              type: string
              description: |
                Location where you want to move the value to.
                The format for this value is JSON Pointer.
          required:
            - op
            - from
            - path
          description: A Patch Move Operation.
        - type: object
          properties:
            op:
              type: string
              enum:
                - copy
              description: 'Discriminator value: copy'
            from:
              type: string
              description: |
                Location of the value that you want to copy.
                The format for this value is JSON Pointer.
            path:
              type: string
              description: |
                Location where you want to copy the value to.
                The format for this value is JSON Pointer.
          required:
            - op
            - from
            - path
          description: A Patch Copy Operation.
        - type: object
          properties:
            op:
              type: string
              enum:
                - test
              description: 'Discriminator value: test'
            path:
              type: string
              description: |
                Location of the value that you want to test.
                The format for this value is JSON Pointer.
            value:
              description: >-
                Value that you want to compare with the current value at the
                path.
          required:
            - op
            - path
            - value
          description: A Patch Test Operation.
      discriminator:
        propertyName: op
      description: A JSON Patch operation as defined by RFC 6902.
      title: patchDocument
    patchRequest:
      type: array
      items:
        $ref: '#/components/schemas/patchDocument'
      description: A JSON Patch document as defined by RFC 6902.
      title: patchRequest
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

## Update saved payment details with a single-use token

If you use our Hosted Fields solution, our gateway creates a single-use token to represent the customer’s updates to their card, ACH, or PAD details. Send the single-use token to our gateway so that we can update the details represented by the secure token.

You can also send a secondary request to our gateway to update other details that the single-use token doesn’t change:

* MIT agreement
* Customer’s contact details
* Customer’s address details

## Integration steps

**Step 1.** Update saved payment details with a single-use token\
**Step 2.** (Optional) Update a secure token

## Step 1. Update saved payment details with a single-use token

To update saved payment details with a single-use token, send a POST request to our Update Account Details endpoint.

| Environment | URL                                                                                                                                                                                                                                                  |
| :---------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Test        | [https://api.uat.payroc.com/v1/processing-terminals/\{processingTerminalId}/secure-tokens/\{secureTokenId}/update-account](https://api.uat.payroc.com/v1/processing-terminals/\{processingTerminalId}/secure-tokens/\{secureTokenId}/update-account) |
| Production  | [https://api.payroc.com/v1/processing-terminals/\{processingTerminalId}/secure-tokens/\{secureTokenId}/update-account](https://api.payroc.com/v1/processing-terminals/\{processingTerminalId}/secure-tokens/\{secureTokenId}/update-account)         |

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
        payment details with our [Update Secure Token](./secure-tokens-api-schema.md) method.
        For more information about our two options to update a secure token, go
        to Update saved payment details.  
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
            [Idempotency](./idempotency.md).
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
    description: Production
  - url: https://api.uat.payroc.com/v1
    description: UAT
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

```python Secure Token
import requests

url = "https://api.payroc.com/v1/processing-terminals/1234001/secure-tokens/MREF_abc1de23-f4a5-6789-bcd0-12e345678901fa/update-account"

headers = {
    "Idempotency-Key": "8e03978e-40d5-43e8-bc93-6894a57f9324",
    "Authorization": "Bearer <token>",
    "Content-Type": "application/json"
}

response = requests.post(url, headers=headers)

print(response.json())
```

```javascript Secure Token
const url = 'https://api.payroc.com/v1/processing-terminals/1234001/secure-tokens/MREF_abc1de23-f4a5-6789-bcd0-12e345678901fa/update-account';
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

```ruby Secure Token
require 'uri'
require 'net/http'

url = URI("https://api.payroc.com/v1/processing-terminals/1234001/secure-tokens/MREF_abc1de23-f4a5-6789-bcd0-12e345678901fa/update-account")

http = Net::HTTP.new(url.host, url.port)
http.use_ssl = true

request = Net::HTTP::Post.new(url)
request["Idempotency-Key"] = '8e03978e-40d5-43e8-bc93-6894a57f9324'
request["Authorization"] = 'Bearer <token>'
request["Content-Type"] = 'application/json'

response = http.request(request)
puts response.read_body
```

```java Secure Token
import com.mashape.unirest.http.HttpResponse;
import com.mashape.unirest.http.Unirest;

HttpResponse<String> response = Unirest.post("https://api.payroc.com/v1/processing-terminals/1234001/secure-tokens/MREF_abc1de23-f4a5-6789-bcd0-12e345678901fa/update-account")
  .header("Idempotency-Key", "8e03978e-40d5-43e8-bc93-6894a57f9324")
  .header("Authorization", "Bearer <token>")
  .header("Content-Type", "application/json")
  .asString();
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

```csharp Secure Token
using RestSharp;

var client = new RestClient("https://api.payroc.com/v1/processing-terminals/1234001/secure-tokens/MREF_abc1de23-f4a5-6789-bcd0-12e345678901fa/update-account");
var request = new RestRequest(Method.POST);
request.AddHeader("Idempotency-Key", "8e03978e-40d5-43e8-bc93-6894a57f9324");
request.AddHeader("Authorization", "Bearer <token>");
request.AddHeader("Content-Type", "application/json");
IRestResponse response = client.Execute(request);
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

If your request is successful, we update the secure token and return the details represented by the secure token.

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
        payment details with our [Update Secure Token](./secure-tokens-api-schema.md) method.
        For more information about our two options to update a secure token, go
        to Update saved payment details.  
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
            [Idempotency](./idempotency.md).
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
    description: Production
  - url: https://api.uat.payroc.com/v1
    description: UAT
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

## Step 2. (Optional) Update a secure token

To update the payment details represented by a secure token, send a PATCH request to our Update Secure Token endpoint.

| Environment | URL                                                                                                                                                                                                                    |
| :---------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Test        | [https://api.uat.payroc.com/v1/processing-terminals/\{processingTerminalId}/secure-tokens/\{secureTokenId}](https://api.uat.payroc.com/v1/processing-terminals/\{processingTerminalId}/secure-tokens/\{secureTokenId}) |
| Production  | [https://api.payroc.com/v1/processing-terminals/\{processingTerminalId}/secure-tokens/\{secureTokenId}](https://api.payroc.com/v1/processing-terminals/\{processingTerminalId}/secure-tokens/\{secureTokenId})         |

**Note:** The request format follows the RFC 6902 standard.

### Request parameters

To create the body of your request, use the following parameters:

### Schema (`request.body`)

```yaml
openapi: 3.1.0
info:
  title: API
  version: 1.0.0
paths:
  /processing-terminals/{processingTerminalId}/secure-tokens/{secureTokenId}:
    patch:
      operationId: partially-update
      summary: Partially update secure token
      description: >
        Use this method to partially update a secure token. Structure your
        request to follow the [RFC
        6902](https://datatracker.ietf.org/doc/html/rfc6902) standard.  


        To update a secure token, you need its secureTokenId, which you sent in
        the request of the [Create Secure Token](./secure-tokens-api-schema.md)
        method.  


        **Note:** If you don't have the secureTokenId, use our [List Secure Tokens](./secure-tokens-api-schema.md)
        method to search  for the payment.  


        You can update all of the properties of the secure token, except the
        following:  

        - processingTerminalId  

        - type  

        - token  

        - status  

        - source/Card  
          - type  
          - cardNumber  
          - cardType  
          - currency  
          - debit  
          - surcharging  
        - source/ACH account  
          - accountNumber  
          - routingNumber  
        - source/PAD account  
          - type  
          - accountNumber  
          - transitNumber  
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
            [Idempotency](./idempotency.md).
          required: true
          schema:
            type: string
            format: uuid
      responses:
        '200':
          description: Successful request. We updated the customer's payment details.
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/secureToken'
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
              $ref: '#/components/schemas/patchRequest'
servers:
  - url: https://api.payroc.com/v1
    description: Production
  - url: https://api.uat.payroc.com/v1
    description: UAT
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
    patchDocument:
      oneOf:
        - type: object
          properties:
            op:
              type: string
              enum:
                - add
              description: 'Discriminator value: add'
            path:
              type: string
              description: |
                Location where you want to add the value.
                The format for this value is JSON Pointer.
            value:
              description: Value that you want to add to the resource.
          required:
            - op
            - path
            - value
          description: A Patch Add Operation.
        - type: object
          properties:
            op:
              type: string
              enum:
                - remove
              description: 'Discriminator value: remove'
            path:
              type: string
              description: |
                Location of the value that you want to remove.
                The format for this value is JSON Pointer.
          required:
            - op
            - path
          description: A Patch Remove Operation.
        - type: object
          properties:
            op:
              type: string
              enum:
                - replace
              description: 'Discriminator value: replace'
            path:
              type: string
              description: |
                Location of the value that you want to replace.
                The format for this value is JSON Pointer.
            value:
              description: Value that you want to use as the replacement.
          required:
            - op
            - path
            - value
          description: A Patch Replace Operation.
        - type: object
          properties:
            op:
              type: string
              enum:
                - move
              description: 'Discriminator value: move'
            from:
              type: string
              description: |
                Location of the value that you want to move.
                The format for this value is JSON Pointer.
            path:
              type: string
              description: |
                Location where you want to move the value to.
                The format for this value is JSON Pointer.
          required:
            - op
            - from
            - path
          description: A Patch Move Operation.
        - type: object
          properties:
            op:
              type: string
              enum:
                - copy
              description: 'Discriminator value: copy'
            from:
              type: string
              description: |
                Location of the value that you want to copy.
                The format for this value is JSON Pointer.
            path:
              type: string
              description: |
                Location where you want to copy the value to.
                The format for this value is JSON Pointer.
          required:
            - op
            - from
            - path
          description: A Patch Copy Operation.
        - type: object
          properties:
            op:
              type: string
              enum:
                - test
              description: 'Discriminator value: test'
            path:
              type: string
              description: |
                Location of the value that you want to test.
                The format for this value is JSON Pointer.
            value:
              description: >-
                Value that you want to compare with the current value at the
                path.
          required:
            - op
            - path
            - value
          description: A Patch Test Operation.
      discriminator:
        propertyName: op
      description: A JSON Patch operation as defined by RFC 6902.
      title: patchDocument
    patchRequest:
      type: array
      items:
        $ref: '#/components/schemas/patchDocument'
      description: A JSON Patch document as defined by RFC 6902.
      title: patchRequest
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

PATCH [https://api.payroc.com/v1/processing-terminals/\{processingTerminalId}/secure-tokens/\{secureTokenId}](https://api.payroc.com/v1/processing-terminals/\{processingTerminalId}/secure-tokens/\{secureTokenId})

```curl Secure Token
curl -X PATCH https://api.payroc.com/v1/processing-terminals/1234001/secure-tokens/MREF_abc1de23-f4a5-6789-bcd0-12e345678901fa \
     -H "Idempotency-Key: 8e03978e-40d5-43e8-bc93-6894a57f9324" \
     -H "Authorization: Bearer <token>" \
     -H "Content-Type: application/json"
```

```python Secure Token
import requests

url = "https://api.payroc.com/v1/processing-terminals/1234001/secure-tokens/MREF_abc1de23-f4a5-6789-bcd0-12e345678901fa"

headers = {
    "Idempotency-Key": "8e03978e-40d5-43e8-bc93-6894a57f9324",
    "Authorization": "Bearer <token>",
    "Content-Type": "application/json"
}

response = requests.patch(url, headers=headers)

print(response.json())
```

```javascript Secure Token
const url = 'https://api.payroc.com/v1/processing-terminals/1234001/secure-tokens/MREF_abc1de23-f4a5-6789-bcd0-12e345678901fa';
const options = {
  method: 'PATCH',
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

```go Secure Token
package main

import (
	"fmt"
	"net/http"
	"io"
)

func main() {

	url := "https://api.payroc.com/v1/processing-terminals/1234001/secure-tokens/MREF_abc1de23-f4a5-6789-bcd0-12e345678901fa"

	req, _ := http.NewRequest("PATCH", url, nil)

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

```ruby Secure Token
require 'uri'
require 'net/http'

url = URI("https://api.payroc.com/v1/processing-terminals/1234001/secure-tokens/MREF_abc1de23-f4a5-6789-bcd0-12e345678901fa")

http = Net::HTTP.new(url.host, url.port)
http.use_ssl = true

request = Net::HTTP::Patch.new(url)
request["Idempotency-Key"] = '8e03978e-40d5-43e8-bc93-6894a57f9324'
request["Authorization"] = 'Bearer <token>'
request["Content-Type"] = 'application/json'

response = http.request(request)
puts response.read_body
```

```java Secure Token
import com.mashape.unirest.http.HttpResponse;
import com.mashape.unirest.http.Unirest;

HttpResponse<String> response = Unirest.patch("https://api.payroc.com/v1/processing-terminals/1234001/secure-tokens/MREF_abc1de23-f4a5-6789-bcd0-12e345678901fa")
  .header("Idempotency-Key", "8e03978e-40d5-43e8-bc93-6894a57f9324")
  .header("Authorization", "Bearer <token>")
  .header("Content-Type", "application/json")
  .asString();
```

```php Secure Token
<?php
require_once('vendor/autoload.php');

$client = new \GuzzleHttp\Client();

$response = $client->request('PATCH', 'https://api.payroc.com/v1/processing-terminals/1234001/secure-tokens/MREF_abc1de23-f4a5-6789-bcd0-12e345678901fa', [
  'headers' => [
    'Authorization' => 'Bearer <token>',
    'Content-Type' => 'application/json',
    'Idempotency-Key' => '8e03978e-40d5-43e8-bc93-6894a57f9324',
  ],
]);

echo $response->getBody();
```

```csharp Secure Token
using RestSharp;

var client = new RestClient("https://api.payroc.com/v1/processing-terminals/1234001/secure-tokens/MREF_abc1de23-f4a5-6789-bcd0-12e345678901fa");
var request = new RestRequest(Method.PATCH);
request.AddHeader("Idempotency-Key", "8e03978e-40d5-43e8-bc93-6894a57f9324");
request.AddHeader("Authorization", "Bearer <token>");
request.AddHeader("Content-Type", "application/json");
IRestResponse response = client.Execute(request);
```

```swift Secure Token
import Foundation

let headers = [
  "Idempotency-Key": "8e03978e-40d5-43e8-bc93-6894a57f9324",
  "Authorization": "Bearer <token>",
  "Content-Type": "application/json"
]

let request = NSMutableURLRequest(url: NSURL(string: "https://api.payroc.com/v1/processing-terminals/1234001/secure-tokens/MREF_abc1de23-f4a5-6789-bcd0-12e345678901fa")! as URL,
                                        cachePolicy: .useProtocolCachePolicy,
                                    timeoutInterval: 10.0)
request.httpMethod = "PATCH"
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

If your request is successful, we update the secure token and return the details represented by the secure token.

### Schema (`response.body`)

```yaml
openapi: 3.1.0
info:
  title: API
  version: 1.0.0
paths:
  /processing-terminals/{processingTerminalId}/secure-tokens/{secureTokenId}:
    patch:
      operationId: partially-update
      summary: Partially update secure token
      description: >
        Use this method to partially update a secure token. Structure your
        request to follow the [RFC
        6902](https://datatracker.ietf.org/doc/html/rfc6902) standard.  


        To update a secure token, you need its secureTokenId, which you sent in
        the request of the [Create Secure Token](./secure-tokens-api-schema.md)
        method.  


        **Note:** If you don't have the secureTokenId, use our [List Secure Tokens](./secure-tokens-api-schema.md)
        method to search  for the payment.  


        You can update all of the properties of the secure token, except the
        following:  

        - processingTerminalId  

        - type  

        - token  

        - status  

        - source/Card  
          - type  
          - cardNumber  
          - cardType  
          - currency  
          - debit  
          - surcharging  
        - source/ACH account  
          - accountNumber  
          - routingNumber  
        - source/PAD account  
          - type  
          - accountNumber  
          - transitNumber  
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
            [Idempotency](./idempotency.md).
          required: true
          schema:
            type: string
            format: uuid
      responses:
        '200':
          description: Successful request. We updated the customer's payment details.
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/secureToken'
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
              $ref: '#/components/schemas/patchRequest'
servers:
  - url: https://api.payroc.com/v1
    description: Production
  - url: https://api.uat.payroc.com/v1
    description: UAT
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
    patchDocument:
      oneOf:
        - type: object
          properties:
            op:
              type: string
              enum:
                - add
              description: 'Discriminator value: add'
            path:
              type: string
              description: |
                Location where you want to add the value.
                The format for this value is JSON Pointer.
            value:
              description: Value that you want to add to the resource.
          required:
            - op
            - path
            - value
          description: A Patch Add Operation.
        - type: object
          properties:
            op:
              type: string
              enum:
                - remove
              description: 'Discriminator value: remove'
            path:
              type: string
              description: |
                Location of the value that you want to remove.
                The format for this value is JSON Pointer.
          required:
            - op
            - path
          description: A Patch Remove Operation.
        - type: object
          properties:
            op:
              type: string
              enum:
                - replace
              description: 'Discriminator value: replace'
            path:
              type: string
              description: |
                Location of the value that you want to replace.
                The format for this value is JSON Pointer.
            value:
              description: Value that you want to use as the replacement.
          required:
            - op
            - path
            - value
          description: A Patch Replace Operation.
        - type: object
          properties:
            op:
              type: string
              enum:
                - move
              description: 'Discriminator value: move'
            from:
              type: string
              description: |
                Location of the value that you want to move.
                The format for this value is JSON Pointer.
            path:
              type: string
              description: |
                Location where you want to move the value to.
                The format for this value is JSON Pointer.
          required:
            - op
            - from
            - path
          description: A Patch Move Operation.
        - type: object
          properties:
            op:
              type: string
              enum:
                - copy
              description: 'Discriminator value: copy'
            from:
              type: string
              description: |
                Location of the value that you want to copy.
                The format for this value is JSON Pointer.
            path:
              type: string
              description: |
                Location where you want to copy the value to.
                The format for this value is JSON Pointer.
          required:
            - op
            - from
            - path
          description: A Patch Copy Operation.
        - type: object
          properties:
            op:
              type: string
              enum:
                - test
              description: 'Discriminator value: test'
            path:
              type: string
              description: |
                Location of the value that you want to test.
                The format for this value is JSON Pointer.
            value:
              description: >-
                Value that you want to compare with the current value at the
                path.
          required:
            - op
            - path
            - value
          description: A Patch Test Operation.
      discriminator:
        propertyName: op
      description: A JSON Patch operation as defined by RFC 6902.
      title: patchDocument
    patchRequest:
      type: array
      items:
        $ref: '#/components/schemas/patchDocument'
      description: A JSON Patch document as defined by RFC 6902.
      title: patchRequest
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