> **Local snapshot — authoritative for this skill.** Source: https://docs.payroc.com/essentials/payment-links/create-and-share-a-payment-link.md
> Last synced: 2026-06-01. Verbatim copy of the Payroc narrative guide. To refresh, re-fetch the source and regenerate this file (see _sources.md).

# Create and share a payment link

Use our Payment Links feature to create a payment link that the merchant can email to customers to pay for goods and services. The request to create a payment link contains the following settings for the payment link:

* **type** - Indicates whether the link can be used only once or if it can be used multiple times.
* **authType** - Indicates whether the transaction is a sale or a pre-authorization.
* **paymentMethod** - Indicates the payment methods that the merchant accepts.
* **charge** - Indicates whether the merchant or customer enters the amount for the transaction.

When the gateway creates the link, it returns the paymentLinkId that you use in the request to share the payment link.

## Integration steps

**Step 1.** Create a payment link. <br />
**Step 2.** Share a payment link.

## Before you begin

### Bearer tokens

Use our Identity Service to generate a Bearer token to include in the header of your requests. To generate your Bearer token, complete the following steps:

1. Include your API key in the x-api-key parameter in the header of a POST request.
2. Send your request to [https://identity.payroc.com/authorize](https://identity.payroc.com/authorize).

> **Note (skill annotation, not part of the source page):** The URL above is the **production** identity host. For **UAT/test**, use `https://identity.uat.payroc.com/authorize` — the UAT host carries the `.uat` segment, production does not. Use the UAT host while testing and swap to production at go-live.

**Note:** You need to generate a new Bearer token before the previous Bearer token expires.

#### Example request

```sh
curl --location --request POST  'https://identity.payroc.com/authorize' --header 'x-api-key: <api key>'
```

#### Example response

If your request is successful, we return a response that contains your Bearer token, information about its scope, and when it expires.

```json
{
  "access_token": "eyJhbGc....adQssw5c",
  "expires_in": 3600,
  "scope": "service_a service_b",
  "token_type": "Bearer"
}
```

### Headers

To create the header of each GET request, you must include the following parameters:

* **Content-Type:** Include application/json as the value for this parameter.
* **Authorization:** Include your Bearer token in this parameter.

```sh
curl
  -H "Content-Type: application/json"
  -H "Authorization: <Bearer token>"
```

To create the header of each POST request, you must include the following parameters:

* **Content-Type:** Include application/json as the value for this parameter.
* **Authorization:** Include your Bearer token in this parameter.
* **Idempotency-Key:** Include a UUID v4 to make the request idempotent.

```sh
curl
  -H "Content-Type: application/json"
  -H "Authorization: <Bearer token>"
  -H "Idempotency-Key: <UUID v4>"
```

### Errors

If your request is unsuccessful, we return an error. For more information about errors, see [Errors](/api/errors).

## Step 1. Create a payment link

To create a payment link, send a POST request to our Processing Terminals endpoint.

| Endpoint   | Prefix     | URL                                                                                                                                                                                  |
| :--------- | :--------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Test       | `api.uat.` | [https://api.uat.payroc.com/v1/processing-terminals/\{processingTerminalId}/payment-links](https://api.uat.payroc.com/v1/processing-terminals/\{processingTerminalId}/payment-links) |
| Production | `api.`     | [https://api.payroc.com/v1/processing-terminals/\{processingTerminalId}/payment-links](https://api.payroc.com/v1/processing-terminals/\{processingTerminalId}/payment-links)         |

### Request parameters

To create the body of your request, use the following parameters:

\<### Schema (`request.body`)

```yaml
openapi: 3.1.0
info:
  title: API
  version: 1.0.0
paths:
  /processing-terminals/{processingTerminalId}/payment-links:
    post:
      operationId: create
      summary: Create payment link
      description: >
        Use this method to create a payment link that a customer can use to make
        a payment for goods or services.  


        The request includes the following settings:

        - **type** - Indicates whether the link can be used only once or if it
        can be used multiple times.

        - **authType** - Indicates whether the transaction is a sale or a
        pre-authorization.

        - **paymentMethod** - Indicates the payment methods that the merchant
        accepts.

        - **charge** - Indicates whether the merchant or the customer enters the
        amount for the transaction.  


        If your request is successful, our gateway returns a paymentLinkId,
        which you can use to perform follow-on actions.  


        **Note:** To share the payment link with a customer, use our [Share
        Payment
        Link](https://docs.payroc.com/api/schema/payment-links/sharing-events/share)
        method.
      tags:
        - subpackage_paymentLinks
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
          description: "Successful request. We return a polymorphic object that contains payment link information.\nThe value of the type parameter determines which variant you should use:\n-\t`multiUse` - Create a link that the merchant can use to take multiple payments.\n-\t`singleUse` - Create a link that the merchant can use for only one payment.\n"
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/paymentLinks_create_Response_201'
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
        description: "Polymorphic object that contains payment link information.  \n\nThe value of the type parameter determines which variant you should use:\n-\t`multiUse` - Create a link that the merchant can use to take multiple payments.\n-\t`singleUse` - Create a link that the merchant can use for only one payment.\n"
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/paymentLinks_create_Request'
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
    MultiUsePaymentLinkType:
      type: string
      enum:
        - multiUse
      description: >
        Type of link. The merchant can use a multi-use link to take multiple
        payments.
      title: MultiUsePaymentLinkType
    PromptPaymentLinkChargeType:
      type: string
      enum:
        - prompt
      title: PromptPaymentLinkChargeType
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
    promptPaymentLinkCharge:
      type: object
      properties:
        type:
          $ref: '#/components/schemas/PromptPaymentLinkChargeType'
        currency:
          $ref: '#/components/schemas/currency'
      required:
        - type
        - currency
      description: >-
        Object that contains information about the charge when the customer
        enters the amount of the transaction.
      title: promptPaymentLinkCharge
    PresetPaymentLinkChargeType:
      type: string
      enum:
        - preset
      title: PresetPaymentLinkChargeType
    presetPaymentLinkCharge:
      type: object
      properties:
        type:
          $ref: '#/components/schemas/PresetPaymentLinkChargeType'
        amount:
          type: integer
          format: int64
          description: >-
            Total amount of the transaction. The value is in the currency's
            lowest denomination, for example, cents.
        currency:
          $ref: '#/components/schemas/currency'
      required:
        - type
        - amount
        - currency
      description: >-
        Object that contains information about the charge when the merchant
        enters the amount of the transaction.
      title: presetPaymentLinkCharge
    MultiUsePaymentLinkOrderCharge:
      oneOf:
        - $ref: '#/components/schemas/promptPaymentLinkCharge'
        - $ref: '#/components/schemas/presetPaymentLinkCharge'
      description: "Polymorphic object that indicates who enters the amount for the payment link.  \n\nThe value of the type parameter determines which variant you should use:  \n-\t`prompt` - Customer enters the amount.\n-\t`preset` - Merchant sets the amount. \n"
      title: MultiUsePaymentLinkOrderCharge
    multiUsePaymentLinkOrder:
      type: object
      properties:
        description:
          type: string
          description: A brief description of the transaction.
        charge:
          $ref: '#/components/schemas/MultiUsePaymentLinkOrderCharge'
          description: "Polymorphic object that indicates who enters the amount for the payment link.  \n\nThe value of the type parameter determines which variant you should use:  \n-\t`prompt` - Customer enters the amount.\n-\t`preset` - Merchant sets the amount. \n"
      required:
        - charge
      description: Object that contains information about the order.
      title: multiUsePaymentLinkOrder
    MultiUsePaymentLinkAuthType:
      type: string
      enum:
        - sale
        - preAuthorization
      description: Type of transaction.
      title: MultiUsePaymentLinkAuthType
    MultiUsePaymentLinkPaymentMethodsItems:
      type: string
      enum:
        - card
        - bankTransfer
      title: MultiUsePaymentLinkPaymentMethodsItems
    CustomLabelElement:
      type: string
      enum:
        - paymentButton
      description: Element that you want to provide a custom label for.
      title: CustomLabelElement
    customLabel:
      type: object
      properties:
        element:
          $ref: '#/components/schemas/CustomLabelElement'
          description: Element that you want to provide a custom label for.
        label:
          type: string
          description: Custom label to display on the element.
      description: Object that contains the information for the custom label.
      title: customLabel
    paymentLinkAssets:
      type: object
      properties:
        paymentUrl:
          type: string
          description: URL of the payment link.
        paymentButton:
          type: string
          format: html
          description: >-
            HTML code for the payment link. You can embed the HTML code in the
            merchant's website.
      required:
        - paymentUrl
        - paymentButton
      description: Object that contains shareable assets for the payment link.
      title: paymentLinkAssets
    MultiUsePaymentLinkStatus:
      type: string
      enum:
        - active
        - completed
        - deactivated
        - expired
      description: |
        Status of the payment link. The value is one of the following:
        - `active` - Payment link is active.
        - `completed` - Customer has paid.
        - `deactivated` - Merchant has deactivated the link.
        - `expired` - Payment link has expired.
      title: MultiUsePaymentLinkStatus
    CredentialOnFileMitAgreement:
      type: string
      enum:
        - unscheduled
        - recurring
        - installment
      default: unscheduled
      description: >
        Indicates how the merchant can use the customer’s card details, as
        agreed by the customer:  


        - `unscheduled` - Transactions for a fixed or variable amount that are
        run at a certain pre-defined event.  

        - `recurring` - Transactions for a fixed amount that are run at regular
        intervals, for example, monthly. Recurring transactions don’t have a
        fixed duration and run until the customer cancels the agreement.  

        - `installment` - Transactions for a fixed amount that are run at
        regular intervals, for example, monthly. Installment transactions have a
        fixed duration.  
          
        **Note:** If you send a value for **mitAgreement**, you must send the
        **standingInstructions** object in the **paymentOrder** object.
      title: CredentialOnFileMitAgreement
    credentialOnFile:
      type: object
      properties:
        tokenize:
          type: boolean
          description: >-
            Indicates if our gateway should tokenize the customer’s payment
            details as part of the transaction.
        mitAgreement:
          $ref: '#/components/schemas/CredentialOnFileMitAgreement'
          default: unscheduled
          description: >
            Indicates how the merchant can use the customer’s card details, as
            agreed by the customer:  


            - `unscheduled` - Transactions for a fixed or variable amount that
            are run at a certain pre-defined event.  

            - `recurring` - Transactions for a fixed amount that are run at
            regular intervals, for example, monthly. Recurring transactions
            don’t have a fixed duration and run until the customer cancels the
            agreement.  

            - `installment` - Transactions for a fixed amount that are run at
            regular intervals, for example, monthly. Installment transactions
            have a fixed duration.  
              
            **Note:** If you send a value for **mitAgreement**, you must send
            the **standingInstructions** object in the **paymentOrder** object.
      description: >-
        Object that contains information about saving the customer’s payment
        details.
      title: credentialOnFile
    multiUsePaymentLink:
      type: object
      properties:
        type:
          $ref: '#/components/schemas/MultiUsePaymentLinkType'
          description: >
            Type of link. The merchant can use a multi-use link to take multiple
            payments.
        paymentLinkId:
          type: string
          description: Unique identifier that we assigned to the payment link.
        merchantReference:
          type: string
          description: Unique identifier that the merchant assigned to the payment.
        order:
          $ref: '#/components/schemas/multiUsePaymentLinkOrder'
        authType:
          $ref: '#/components/schemas/MultiUsePaymentLinkAuthType'
          description: Type of transaction.
        paymentMethods:
          type: array
          items:
            $ref: '#/components/schemas/MultiUsePaymentLinkPaymentMethodsItems'
          description: >
            Payment methods that the merchant accepts.  

            **Note:** If a payment is a pre-authorization, the customer must pay
            by card.
        customLabels:
          type: array
          items:
            $ref: '#/components/schemas/customLabel'
          description: |
            Array of customLabel objects.  
            **Note:** You can change the label of the payment button only.
        assets:
          $ref: '#/components/schemas/paymentLinkAssets'
        status:
          $ref: '#/components/schemas/MultiUsePaymentLinkStatus'
          description: |
            Status of the payment link. The value is one of the following:
            - `active` - Payment link is active.
            - `completed` - Customer has paid.
            - `deactivated` - Merchant has deactivated the link.
            - `expired` - Payment link has expired.
        createdOn:
          type: string
          format: date
          description: >-
            Date that the merchant created the link. The format of this value is
            **YYYY-MM-DD**.
        expiresOn:
          type: string
          format: date
          description: >-
            Last date that the customer can use the payment link. The format of
            this value is **YYYY-MM-DD**.
        credentialOnFile:
          $ref: '#/components/schemas/credentialOnFile'
      required:
        - type
        - merchantReference
        - order
        - authType
        - paymentMethods
      description: Object that contains information about a multi-use payment link.
      title: multiUsePaymentLink
    SingleUsePaymentLinkType:
      type: string
      enum:
        - singleUse
      description: Type of link. The merchant can use this link for only one payment.
      title: SingleUsePaymentLinkType
    SingleUsePaymentLinkOrderCharge:
      oneOf:
        - $ref: '#/components/schemas/promptPaymentLinkCharge'
        - $ref: '#/components/schemas/presetPaymentLinkCharge'
      description: "Polymorphic object that indicates who enters the amount for the payment link.  \n\nThe value of the type parameter determines which variant you should use:  \n-\t`prompt` - Customer enters the amount.\n-\t`preset` - Merchant sets the amount. \n"
      title: SingleUsePaymentLinkOrderCharge
    singleUsePaymentLinkOrder:
      type: object
      properties:
        orderId:
          type: string
          description: Unique identifier that the merchant assigned to the order.
        description:
          type: string
          description: A brief description of the transaction.
        charge:
          $ref: '#/components/schemas/SingleUsePaymentLinkOrderCharge'
          description: "Polymorphic object that indicates who enters the amount for the payment link.  \n\nThe value of the type parameter determines which variant you should use:  \n-\t`prompt` - Customer enters the amount.\n-\t`preset` - Merchant sets the amount. \n"
      required:
        - orderId
        - charge
      description: Object that contains information about the order.
      title: singleUsePaymentLinkOrder
    SingleUsePaymentLinkAuthType:
      type: string
      enum:
        - sale
        - preAuthorization
      description: Type of transaction.
      title: SingleUsePaymentLinkAuthType
    SingleUsePaymentLinkPaymentMethodsItems:
      type: string
      enum:
        - card
        - bankTransfer
      title: SingleUsePaymentLinkPaymentMethodsItems
    SingleUsePaymentLinkStatus:
      type: string
      enum:
        - active
        - completed
        - deactivated
        - expired
      description: |
        Status of the payment link. The value is one of the following:
        - `active` - Payment link is active.
        - `completed` - Customer has paid.
        - `deactivated` - Merchant has deactivated the link.
        - `expired` - Payment link has expired.
      title: SingleUsePaymentLinkStatus
    singleUsePaymentLink:
      type: object
      properties:
        type:
          $ref: '#/components/schemas/SingleUsePaymentLinkType'
          description: Type of link. The merchant can use this link for only one payment.
        paymentLinkId:
          type: string
          description: Unique identifier that we assigned to the payment link.
        merchantReference:
          type: string
          description: Unique identifier that the merchant assigned to the payment.
        order:
          $ref: '#/components/schemas/singleUsePaymentLinkOrder'
        authType:
          $ref: '#/components/schemas/SingleUsePaymentLinkAuthType'
          description: Type of transaction.
        paymentMethods:
          type: array
          items:
            $ref: '#/components/schemas/SingleUsePaymentLinkPaymentMethodsItems'
          description: >
            Payment methods that the merchant accepts.  

            **Note:** If the payment is a pre-authorization, the customer must
            pay by card.
        customLabels:
          type: array
          items:
            $ref: '#/components/schemas/customLabel'
          description: |
            Array of customLabel objects.  
            **Note:** You can change the label of the payment button only.
        assets:
          $ref: '#/components/schemas/paymentLinkAssets'
        status:
          $ref: '#/components/schemas/SingleUsePaymentLinkStatus'
          description: |
            Status of the payment link. The value is one of the following:
            - `active` - Payment link is active.
            - `completed` - Customer has paid.
            - `deactivated` - Merchant has deactivated the link.
            - `expired` - Payment link has expired.
        createdOn:
          type: string
          format: date
          description: >-
            Date that the merchant created the link. The format of this value is
            **YYYY-MM-DD**.
        expiresOn:
          type: string
          format: date
          description: >-
            Last date that the customer can use the payment link. The format of
            this value is **YYYY-MM-DD**.
        credentialOnFile:
          $ref: '#/components/schemas/credentialOnFile'
      required:
        - type
        - merchantReference
        - order
        - authType
        - paymentMethods
        - expiresOn
      description: Object that contains information about a single-use payment link.
      title: singleUsePaymentLink
    paymentLinks_create_Request:
      oneOf:
        - $ref: '#/components/schemas/multiUsePaymentLink'
        - $ref: '#/components/schemas/singleUsePaymentLink'
      title: paymentLinks_create_Request
    paymentLinks_create_Response_201:
      oneOf:
        - $ref: '#/components/schemas/multiUsePaymentLink'
        - $ref: '#/components/schemas/singleUsePaymentLink'
      title: paymentLinks_create_Response_201
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

\<### Request

POST [https://api.payroc.com/v1/processing-terminals/\{processingTerminalId}/payment-links](https://api.payroc.com/v1/processing-terminals/\{processingTerminalId}/payment-links)

```curl Payment Link
curl -X POST https://api.payroc.com/v1/processing-terminals/1234001/payment-links \
     -H "Idempotency-Key: 8e03978e-40d5-43e8-bc93-6894a57f9324" \
     -H "Authorization: Bearer <token>" \
     -H "Content-Type: application/json"
```

```python Payment Link
import requests

url = "https://api.payroc.com/v1/processing-terminals/1234001/payment-links"

headers = {
    "Idempotency-Key": "8e03978e-40d5-43e8-bc93-6894a57f9324",
    "Authorization": "Bearer <token>",
    "Content-Type": "application/json"
}

response = requests.post(url, headers=headers)

print(response.json())
```

```javascript Payment Link
const url = 'https://api.payroc.com/v1/processing-terminals/1234001/payment-links';
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

```go Payment Link
package main

import (
	"fmt"
	"net/http"
	"io"
)

func main() {

	url := "https://api.payroc.com/v1/processing-terminals/1234001/payment-links"

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

```ruby Payment Link
require 'uri'
require 'net/http'

url = URI("https://api.payroc.com/v1/processing-terminals/1234001/payment-links")

http = Net::HTTP.new(url.host, url.port)
http.use_ssl = true

request = Net::HTTP::Post.new(url)
request["Idempotency-Key"] = '8e03978e-40d5-43e8-bc93-6894a57f9324'
request["Authorization"] = 'Bearer <token>'
request["Content-Type"] = 'application/json'

response = http.request(request)
puts response.read_body
```

```java Payment Link
import com.mashape.unirest.http.HttpResponse;
import com.mashape.unirest.http.Unirest;

HttpResponse<String> response = Unirest.post("https://api.payroc.com/v1/processing-terminals/1234001/payment-links")
  .header("Idempotency-Key", "8e03978e-40d5-43e8-bc93-6894a57f9324")
  .header("Authorization", "Bearer <token>")
  .header("Content-Type", "application/json")
  .asString();
```

```php Payment Link
<?php
require_once('vendor/autoload.php');

$client = new \GuzzleHttp\Client();

$response = $client->request('POST', 'https://api.payroc.com/v1/processing-terminals/1234001/payment-links', [
  'headers' => [
    'Authorization' => 'Bearer <token>',
    'Content-Type' => 'application/json',
    'Idempotency-Key' => '8e03978e-40d5-43e8-bc93-6894a57f9324',
  ],
]);

echo $response->getBody();
```

```csharp Payment Link
using RestSharp;

var client = new RestClient("https://api.payroc.com/v1/processing-terminals/1234001/payment-links");
var request = new RestRequest(Method.POST);
request.AddHeader("Idempotency-Key", "8e03978e-40d5-43e8-bc93-6894a57f9324");
request.AddHeader("Authorization", "Bearer <token>");
request.AddHeader("Content-Type", "application/json");
IRestResponse response = client.Execute(request);
```

```swift Payment Link
import Foundation

let headers = [
  "Idempotency-Key": "8e03978e-40d5-43e8-bc93-6894a57f9324",
  "Authorization": "Bearer <token>",
  "Content-Type": "application/json"
]

let request = NSMutableURLRequest(url: NSURL(string: "https://api.payroc.com/v1/processing-terminals/1234001/payment-links")! as URL,
                                        cachePolicy: .useProtocolCachePolicy,
                                    timeoutInterval: 10.0)
request.httpMethod = "POST"
request.allHTTPHeaderFields = headers

let session = URLSession.shared
let dataTask = session.dataTask(with: request as URLRequest, completionHandler: \{ (data, response, error) -> Void in
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

If your request is successful, our gateway returns a paymentLinkId. Save the paymentLinkId so that you can include it in the request to share the link.
The response contains the following fields:

\<### Schema (`response.body`)

```yaml
openapi: 3.1.0
info:
  title: API
  version: 1.0.0
paths:
  /processing-terminals/{processingTerminalId}/payment-links:
    post:
      operationId: create
      summary: Create payment link
      description: >
        Use this method to create a payment link that a customer can use to make
        a payment for goods or services.  


        The request includes the following settings:

        - **type** - Indicates whether the link can be used only once or if it
        can be used multiple times.

        - **authType** - Indicates whether the transaction is a sale or a
        pre-authorization.

        - **paymentMethod** - Indicates the payment methods that the merchant
        accepts.

        - **charge** - Indicates whether the merchant or the customer enters the
        amount for the transaction.  


        If your request is successful, our gateway returns a paymentLinkId,
        which you can use to perform follow-on actions.  


        **Note:** To share the payment link with a customer, use our [Share
        Payment
        Link](https://docs.payroc.com/api/schema/payment-links/sharing-events/share)
        method.
      tags:
        - subpackage_paymentLinks
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
          description: "Successful request. We return a polymorphic object that contains payment link information.\nThe value of the type parameter determines which variant you should use:\n-\t`multiUse` - Create a link that the merchant can use to take multiple payments.\n-\t`singleUse` - Create a link that the merchant can use for only one payment.\n"
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/paymentLinks_create_Response_201'
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
        description: "Polymorphic object that contains payment link information.  \n\nThe value of the type parameter determines which variant you should use:\n-\t`multiUse` - Create a link that the merchant can use to take multiple payments.\n-\t`singleUse` - Create a link that the merchant can use for only one payment.\n"
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/paymentLinks_create_Request'
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
    MultiUsePaymentLinkType:
      type: string
      enum:
        - multiUse
      description: >
        Type of link. The merchant can use a multi-use link to take multiple
        payments.
      title: MultiUsePaymentLinkType
    PromptPaymentLinkChargeType:
      type: string
      enum:
        - prompt
      title: PromptPaymentLinkChargeType
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
    promptPaymentLinkCharge:
      type: object
      properties:
        type:
          $ref: '#/components/schemas/PromptPaymentLinkChargeType'
        currency:
          $ref: '#/components/schemas/currency'
      required:
        - type
        - currency
      description: >-
        Object that contains information about the charge when the customer
        enters the amount of the transaction.
      title: promptPaymentLinkCharge
    PresetPaymentLinkChargeType:
      type: string
      enum:
        - preset
      title: PresetPaymentLinkChargeType
    presetPaymentLinkCharge:
      type: object
      properties:
        type:
          $ref: '#/components/schemas/PresetPaymentLinkChargeType'
        amount:
          type: integer
          format: int64
          description: >-
            Total amount of the transaction. The value is in the currency's
            lowest denomination, for example, cents.
        currency:
          $ref: '#/components/schemas/currency'
      required:
        - type
        - amount
        - currency
      description: >-
        Object that contains information about the charge when the merchant
        enters the amount of the transaction.
      title: presetPaymentLinkCharge
    MultiUsePaymentLinkOrderCharge:
      oneOf:
        - $ref: '#/components/schemas/promptPaymentLinkCharge'
        - $ref: '#/components/schemas/presetPaymentLinkCharge'
      description: "Polymorphic object that indicates who enters the amount for the payment link.  \n\nThe value of the type parameter determines which variant you should use:  \n-\t`prompt` - Customer enters the amount.\n-\t`preset` - Merchant sets the amount. \n"
      title: MultiUsePaymentLinkOrderCharge
    multiUsePaymentLinkOrder:
      type: object
      properties:
        description:
          type: string
          description: A brief description of the transaction.
        charge:
          $ref: '#/components/schemas/MultiUsePaymentLinkOrderCharge'
          description: "Polymorphic object that indicates who enters the amount for the payment link.  \n\nThe value of the type parameter determines which variant you should use:  \n-\t`prompt` - Customer enters the amount.\n-\t`preset` - Merchant sets the amount. \n"
      required:
        - charge
      description: Object that contains information about the order.
      title: multiUsePaymentLinkOrder
    MultiUsePaymentLinkAuthType:
      type: string
      enum:
        - sale
        - preAuthorization
      description: Type of transaction.
      title: MultiUsePaymentLinkAuthType
    MultiUsePaymentLinkPaymentMethodsItems:
      type: string
      enum:
        - card
        - bankTransfer
      title: MultiUsePaymentLinkPaymentMethodsItems
    CustomLabelElement:
      type: string
      enum:
        - paymentButton
      description: Element that you want to provide a custom label for.
      title: CustomLabelElement
    customLabel:
      type: object
      properties:
        element:
          $ref: '#/components/schemas/CustomLabelElement'
          description: Element that you want to provide a custom label for.
        label:
          type: string
          description: Custom label to display on the element.
      description: Object that contains the information for the custom label.
      title: customLabel
    paymentLinkAssets:
      type: object
      properties:
        paymentUrl:
          type: string
          description: URL of the payment link.
        paymentButton:
          type: string
          format: html
          description: >-
            HTML code for the payment link. You can embed the HTML code in the
            merchant's website.
      required:
        - paymentUrl
        - paymentButton
      description: Object that contains shareable assets for the payment link.
      title: paymentLinkAssets
    MultiUsePaymentLinkStatus:
      type: string
      enum:
        - active
        - completed
        - deactivated
        - expired
      description: |
        Status of the payment link. The value is one of the following:
        - `active` - Payment link is active.
        - `completed` - Customer has paid.
        - `deactivated` - Merchant has deactivated the link.
        - `expired` - Payment link has expired.
      title: MultiUsePaymentLinkStatus
    CredentialOnFileMitAgreement:
      type: string
      enum:
        - unscheduled
        - recurring
        - installment
      default: unscheduled
      description: >
        Indicates how the merchant can use the customer’s card details, as
        agreed by the customer:  


        - `unscheduled` - Transactions for a fixed or variable amount that are
        run at a certain pre-defined event.  

        - `recurring` - Transactions for a fixed amount that are run at regular
        intervals, for example, monthly. Recurring transactions don’t have a
        fixed duration and run until the customer cancels the agreement.  

        - `installment` - Transactions for a fixed amount that are run at
        regular intervals, for example, monthly. Installment transactions have a
        fixed duration.  
          
        **Note:** If you send a value for **mitAgreement**, you must send the
        **standingInstructions** object in the **paymentOrder** object.
      title: CredentialOnFileMitAgreement
    credentialOnFile:
      type: object
      properties:
        tokenize:
          type: boolean
          description: >-
            Indicates if our gateway should tokenize the customer’s payment
            details as part of the transaction.
        mitAgreement:
          $ref: '#/components/schemas/CredentialOnFileMitAgreement'
          default: unscheduled
          description: >
            Indicates how the merchant can use the customer’s card details, as
            agreed by the customer:  


            - `unscheduled` - Transactions for a fixed or variable amount that
            are run at a certain pre-defined event.  

            - `recurring` - Transactions for a fixed amount that are run at
            regular intervals, for example, monthly. Recurring transactions
            don’t have a fixed duration and run until the customer cancels the
            agreement.  

            - `installment` - Transactions for a fixed amount that are run at
            regular intervals, for example, monthly. Installment transactions
            have a fixed duration.  
              
            **Note:** If you send a value for **mitAgreement**, you must send
            the **standingInstructions** object in the **paymentOrder** object.
      description: >-
        Object that contains information about saving the customer’s payment
        details.
      title: credentialOnFile
    multiUsePaymentLink:
      type: object
      properties:
        type:
          $ref: '#/components/schemas/MultiUsePaymentLinkType'
          description: >
            Type of link. The merchant can use a multi-use link to take multiple
            payments.
        paymentLinkId:
          type: string
          description: Unique identifier that we assigned to the payment link.
        merchantReference:
          type: string
          description: Unique identifier that the merchant assigned to the payment.
        order:
          $ref: '#/components/schemas/multiUsePaymentLinkOrder'
        authType:
          $ref: '#/components/schemas/MultiUsePaymentLinkAuthType'
          description: Type of transaction.
        paymentMethods:
          type: array
          items:
            $ref: '#/components/schemas/MultiUsePaymentLinkPaymentMethodsItems'
          description: >
            Payment methods that the merchant accepts.  

            **Note:** If a payment is a pre-authorization, the customer must pay
            by card.
        customLabels:
          type: array
          items:
            $ref: '#/components/schemas/customLabel'
          description: |
            Array of customLabel objects.  
            **Note:** You can change the label of the payment button only.
        assets:
          $ref: '#/components/schemas/paymentLinkAssets'
        status:
          $ref: '#/components/schemas/MultiUsePaymentLinkStatus'
          description: |
            Status of the payment link. The value is one of the following:
            - `active` - Payment link is active.
            - `completed` - Customer has paid.
            - `deactivated` - Merchant has deactivated the link.
            - `expired` - Payment link has expired.
        createdOn:
          type: string
          format: date
          description: >-
            Date that the merchant created the link. The format of this value is
            **YYYY-MM-DD**.
        expiresOn:
          type: string
          format: date
          description: >-
            Last date that the customer can use the payment link. The format of
            this value is **YYYY-MM-DD**.
        credentialOnFile:
          $ref: '#/components/schemas/credentialOnFile'
      required:
        - type
        - merchantReference
        - order
        - authType
        - paymentMethods
      description: Object that contains information about a multi-use payment link.
      title: multiUsePaymentLink
    SingleUsePaymentLinkType:
      type: string
      enum:
        - singleUse
      description: Type of link. The merchant can use this link for only one payment.
      title: SingleUsePaymentLinkType
    SingleUsePaymentLinkOrderCharge:
      oneOf:
        - $ref: '#/components/schemas/promptPaymentLinkCharge'
        - $ref: '#/components/schemas/presetPaymentLinkCharge'
      description: "Polymorphic object that indicates who enters the amount for the payment link.  \n\nThe value of the type parameter determines which variant you should use:  \n-\t`prompt` - Customer enters the amount.\n-\t`preset` - Merchant sets the amount. \n"
      title: SingleUsePaymentLinkOrderCharge
    singleUsePaymentLinkOrder:
      type: object
      properties:
        orderId:
          type: string
          description: Unique identifier that the merchant assigned to the order.
        description:
          type: string
          description: A brief description of the transaction.
        charge:
          $ref: '#/components/schemas/SingleUsePaymentLinkOrderCharge'
          description: "Polymorphic object that indicates who enters the amount for the payment link.  \n\nThe value of the type parameter determines which variant you should use:  \n-\t`prompt` - Customer enters the amount.\n-\t`preset` - Merchant sets the amount. \n"
      required:
        - orderId
        - charge
      description: Object that contains information about the order.
      title: singleUsePaymentLinkOrder
    SingleUsePaymentLinkAuthType:
      type: string
      enum:
        - sale
        - preAuthorization
      description: Type of transaction.
      title: SingleUsePaymentLinkAuthType
    SingleUsePaymentLinkPaymentMethodsItems:
      type: string
      enum:
        - card
        - bankTransfer
      title: SingleUsePaymentLinkPaymentMethodsItems
    SingleUsePaymentLinkStatus:
      type: string
      enum:
        - active
        - completed
        - deactivated
        - expired
      description: |
        Status of the payment link. The value is one of the following:
        - `active` - Payment link is active.
        - `completed` - Customer has paid.
        - `deactivated` - Merchant has deactivated the link.
        - `expired` - Payment link has expired.
      title: SingleUsePaymentLinkStatus
    singleUsePaymentLink:
      type: object
      properties:
        type:
          $ref: '#/components/schemas/SingleUsePaymentLinkType'
          description: Type of link. The merchant can use this link for only one payment.
        paymentLinkId:
          type: string
          description: Unique identifier that we assigned to the payment link.
        merchantReference:
          type: string
          description: Unique identifier that the merchant assigned to the payment.
        order:
          $ref: '#/components/schemas/singleUsePaymentLinkOrder'
        authType:
          $ref: '#/components/schemas/SingleUsePaymentLinkAuthType'
          description: Type of transaction.
        paymentMethods:
          type: array
          items:
            $ref: '#/components/schemas/SingleUsePaymentLinkPaymentMethodsItems'
          description: >
            Payment methods that the merchant accepts.  

            **Note:** If the payment is a pre-authorization, the customer must
            pay by card.
        customLabels:
          type: array
          items:
            $ref: '#/components/schemas/customLabel'
          description: |
            Array of customLabel objects.  
            **Note:** You can change the label of the payment button only.
        assets:
          $ref: '#/components/schemas/paymentLinkAssets'
        status:
          $ref: '#/components/schemas/SingleUsePaymentLinkStatus'
          description: |
            Status of the payment link. The value is one of the following:
            - `active` - Payment link is active.
            - `completed` - Customer has paid.
            - `deactivated` - Merchant has deactivated the link.
            - `expired` - Payment link has expired.
        createdOn:
          type: string
          format: date
          description: >-
            Date that the merchant created the link. The format of this value is
            **YYYY-MM-DD**.
        expiresOn:
          type: string
          format: date
          description: >-
            Last date that the customer can use the payment link. The format of
            this value is **YYYY-MM-DD**.
        credentialOnFile:
          $ref: '#/components/schemas/credentialOnFile'
      required:
        - type
        - merchantReference
        - order
        - authType
        - paymentMethods
        - expiresOn
      description: Object that contains information about a single-use payment link.
      title: singleUsePaymentLink
    paymentLinks_create_Request:
      oneOf:
        - $ref: '#/components/schemas/multiUsePaymentLink'
        - $ref: '#/components/schemas/singleUsePaymentLink'
      title: paymentLinks_create_Request
    paymentLinks_create_Response_201:
      oneOf:
        - $ref: '#/components/schemas/multiUsePaymentLink'
        - $ref: '#/components/schemas/singleUsePaymentLink'
      title: paymentLinks_create_Response_201
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

\<### Response (201)

```json
{
  "type": "multiUse",
  "paymentLinkId": "JZURRJBUPS",
  "merchantReference": "LinkRef6543",
  "order": {
    "description": "Pie It Forward charitable trust donation",
    "charge": {
      "type": "prompt",
      "currency": "USD"
    }
  },
  "authType": "sale",
  "paymentMethods": [
    "card",
    "bankTransfer"
  ],
  "customLabels": [
    {
      "element": "paymentButton",
      "label": "SUPPORT US"
    }
  ],
  "assets": {
    "paymentUrl": "https://payments.payroc.com/merchant/pay-by-link?token=02ada211-ff51-4845-b0b5-e685aeb4b19d",
    "paymentButton": "<a href=\"https://payments.payroc.com/merchant/pay-by-link?token=02ada211-ff51-4845-b0b5-e685aeb4b19d\" \ntarget=\"_blank\" style=\"color: #ffffff; background-color: #6C7A89; font-size: 18px; font-family: Helvetica, Arial, sans-serif; \ntext-decoration: none; border-radius: 30px; padding: 14px 28px; display: inline-block;\">SUPPORT US</a>\n"
  },
  "status": "active",
  "createdOn": "2024-09-24"
}
```

## Step 2. Share a payment link

To share a payment link, send a POST request to our Payment Links endpoint that includes the paymentLinkId of the link you want to share.

| Endpoint   | Prefix     | URL                                                                                                                                                        |
| :--------- | :--------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Test       | `api.uat.` | [https://api.uat.payroc.com/v1/payment-links/\{paymentLinkId}/sharing-events](https://api.uat.payroc.com/v1/payment-links/\{paymentLinkId}/sharing-events) |
| Production | `api.`     | [https://api.payroc.com/v1/payment-links/\{paymentLinkId}/sharing-events](https://api.payroc.com/v1/payment-links/\{paymentLinkId}/sharing-events)         |

### Request parameters

To create the body of your request, use the following parameters:

\<### Schema (`request.body`)

```yaml
openapi: 3.1.0
info:
  title: API
  version: 1.0.0
paths:
  /payment-links/{paymentLinkId}/sharing-events:
    post:
      operationId: share
      summary: Share payment link
      description: >
        Use this method to email a payment link to a customer.  


        To email a payment link, you need its paymentLinkId. Our gateway
        returned the paymentLinkId in the response of the [Create Payment
        Link](https://docs.payroc.com/api/schema/payment-links/create) method.  


        **Note:** If you don't have the paymentLinkId, use our [List Payment
        Links](https://docs.payroc.com/api/schema/payment-links/list) method to
        search for the payment link.  


        In the request, you must provide the recipient's name and email
        address.  


        In the response, our gateway returns a sharingEventId, which you can use
        to [List Payment Link Sharing
        Events](https://docs.payroc.com/api/schema/payment-links/sharing-events/list).  
      tags:
        - subpackage_paymentLinks.subpackage_paymentLinks/sharingEvents
      parameters:
        - name: paymentLinkId
          in: path
          description: Unique identifier that we assigned to the payment link.
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
            Successful request. We return a polymorphic object that contains
            information about how the merchant shared a payment link.
          content:
            application/json:
              schema:
                $ref: >-
                  #/components/schemas/paymentLinks_sharingEvents_share_Response_201
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
              $ref: '#/components/schemas/paymentLinks_sharingEvents_share_Request'
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
    PaymentLinkEmailShareEventSharingMethod:
      type: string
      enum:
        - email
      description: Method that the merchant uses to share the payment link.
      title: PaymentLinkEmailShareEventSharingMethod
    paymentLinkEmailRecipient:
      type: object
      properties:
        name:
          type: string
          description: Recipient's name.
        email:
          type: string
          description: Recipient's email address.
      required:
        - name
        - email
      description: Object that contains the contact details of the recipient.
      title: paymentLinkEmailRecipient
    paymentLinkEmailShareEvent:
      type: object
      properties:
        sharingMethod:
          $ref: '#/components/schemas/PaymentLinkEmailShareEventSharingMethod'
          description: Method that the merchant uses to share the payment link.
        sharingEventId:
          type: string
          description: Unique identifier that we assigned to the sharing event.
        dateTime:
          type: string
          format: date-time
          description: >-
            Date and time that the merchant shared the link. Our gateway returns
            this value in the [ISO
            8601](https://www.iso.org/iso-8601-date-and-time-format.html)
            format.
        merchantCopy:
          type: boolean
          default: false
          description: >-
            Indicates if we send a copy of the email to the merchant. By
            default, we don't send a copy to the merchant.
        message:
          type: string
          description: Message that the merchant sends with the payment link.
        recipients:
          type: array
          items:
            $ref: '#/components/schemas/paymentLinkEmailRecipient'
          description: Array that contains the recipients of the payment link.
      required:
        - sharingMethod
        - recipients
      description: >-
        Object that contains the information about a sharing event that the
        merchant sent by email.
      title: paymentLinkEmailShareEvent
    paymentLinks_sharingEvents_share_Request:
      oneOf:
        - $ref: '#/components/schemas/paymentLinkEmailShareEvent'
      description: >-
        Polymorphic object that contains information about how to share a
        payment link.
      title: paymentLinks_sharingEvents_share_Request
    paymentLinks_sharingEvents_share_Response_201:
      oneOf:
        - $ref: '#/components/schemas/paymentLinkEmailShareEvent'
      title: paymentLinks_sharingEvents_share_Response_201
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

\<### Request

POST [https://api.payroc.com/v1/payment-links/\{paymentLinkId}/sharing-events](https://api.payroc.com/v1/payment-links/\{paymentLinkId}/sharing-events)

```curl Payment link sharing event.
curl -X POST https://api.payroc.com/v1/payment-links/JZURRJBUPS/sharing-events \
     -H "Idempotency-Key: 8e03978e-40d5-43e8-bc93-6894a57f9324" \
     -H "Authorization: Bearer <token>" \
     -H "Content-Type: application/json"
```

```typescript Payment link sharing event.
import { PayrocClient } from "payroc";

async function main() {
    const client = new PayrocClient();
    await client.paymentLinks.sharingEvents.share("JZURRJBUPS", {
        idempotencyKey: "8e03978e-40d5-43e8-bc93-6894a57f9324",
    });
}
main();

```

```python Payment link sharing event.
from payroc import Payroc

client = Payroc()

client.payment_links.sharing_events.share(
    payment_link_id="JZURRJBUPS",
    idempotency_key="8e03978e-40d5-43e8-bc93-6894a57f9324",
)

```

```java Payment link sharing event.
package com.example.usage;

import com.payroc.api.PayrocApiClient;
import com.payroc.api.resources.paymentlinks.sharingevents.requests.ShareSharingEventsRequest;

public class Example {
    public static void main(String[] args) {
        PayrocApiClient client = PayrocApiClient
            .builder()
            .build();

        client.paymentLinks().sharingEvents().share(
            "JZURRJBUPS",
            ShareSharingEventsRequest
                .builder()
                .idempotencyKey("8e03978e-40d5-43e8-bc93-6894a57f9324")
                .build()
        );
    }
}
```

```ruby Payment link sharing event.
require "payroc"

client = Payroc::Client.new

client.payment_links.sharing_events.share(
  payment_link_id: "JZURRJBUPS",
  idempotency_key: "8e03978e-40d5-43e8-bc93-6894a57f9324"
)

```

```csharp Payment link sharing event.
using Payroc;
using System.Threading.Tasks;
using Payroc.PaymentLinks.SharingEvents;

namespace Usage;

public class Example
{
    public async Task Do() {
        var client = new PayrocClient();

        await client.PaymentLinks.SharingEvents.ShareAsync(
            new ShareSharingEventsRequest {
                PaymentLinkId = "JZURRJBUPS",
                IdempotencyKey = "8e03978e-40d5-43e8-bc93-6894a57f9324",
                Body = new PaymentLinkEmailShareEvent {
                    SharingMethod = PaymentLinkEmailShareEventSharingMethod.Email
                }
            }
        );
    }

}

```

```go Payment link sharing event.
package main

import (
	"fmt"
	"net/http"
	"io"
)

func main() {

	url := "https://api.payroc.com/v1/payment-links/JZURRJBUPS/sharing-events"

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

```php Payment link sharing event.
<?php
require_once('vendor/autoload.php');

$client = new \GuzzleHttp\Client();

$response = $client->request('POST', 'https://api.payroc.com/v1/payment-links/JZURRJBUPS/sharing-events', [
  'headers' => [
    'Authorization' => 'Bearer <token>',
    'Content-Type' => 'application/json',
    'Idempotency-Key' => '8e03978e-40d5-43e8-bc93-6894a57f9324',
  ],
]);

echo $response->getBody();
```

```swift Payment link sharing event.
import Foundation

let headers = [
  "Idempotency-Key": "8e03978e-40d5-43e8-bc93-6894a57f9324",
  "Authorization": "Bearer <token>",
  "Content-Type": "application/json"
]

let request = NSMutableURLRequest(url: NSURL(string: "https://api.payroc.com/v1/payment-links/JZURRJBUPS/sharing-events")! as URL,
                                        cachePolicy: .useProtocolCachePolicy,
                                    timeoutInterval: 10.0)
request.httpMethod = "POST"
request.allHTTPHeaderFields = headers

let session = URLSession.shared
let dataTask = session.dataTask(with: request as URLRequest, completionHandler: \{ (data, response, error) -> Void in
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

If your request is successful, our gateway shares the payment link with the recipients.
The response contains the following fields:

\<### Schema (`response.body`)

```yaml
openapi: 3.1.0
info:
  title: API
  version: 1.0.0
paths:
  /payment-links/{paymentLinkId}/sharing-events:
    post:
      operationId: share
      summary: Share payment link
      description: >
        Use this method to email a payment link to a customer.  


        To email a payment link, you need its paymentLinkId. Our gateway
        returned the paymentLinkId in the response of the [Create Payment
        Link](https://docs.payroc.com/api/schema/payment-links/create) method.  


        **Note:** If you don't have the paymentLinkId, use our [List Payment
        Links](https://docs.payroc.com/api/schema/payment-links/list) method to
        search for the payment link.  


        In the request, you must provide the recipient's name and email
        address.  


        In the response, our gateway returns a sharingEventId, which you can use
        to [List Payment Link Sharing
        Events](https://docs.payroc.com/api/schema/payment-links/sharing-events/list).  
      tags:
        - subpackage_paymentLinks.subpackage_paymentLinks/sharingEvents
      parameters:
        - name: paymentLinkId
          in: path
          description: Unique identifier that we assigned to the payment link.
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
            Successful request. We return a polymorphic object that contains
            information about how the merchant shared a payment link.
          content:
            application/json:
              schema:
                $ref: >-
                  #/components/schemas/paymentLinks_sharingEvents_share_Response_201
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
              $ref: '#/components/schemas/paymentLinks_sharingEvents_share_Request'
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
    PaymentLinkEmailShareEventSharingMethod:
      type: string
      enum:
        - email
      description: Method that the merchant uses to share the payment link.
      title: PaymentLinkEmailShareEventSharingMethod
    paymentLinkEmailRecipient:
      type: object
      properties:
        name:
          type: string
          description: Recipient's name.
        email:
          type: string
          description: Recipient's email address.
      required:
        - name
        - email
      description: Object that contains the contact details of the recipient.
      title: paymentLinkEmailRecipient
    paymentLinkEmailShareEvent:
      type: object
      properties:
        sharingMethod:
          $ref: '#/components/schemas/PaymentLinkEmailShareEventSharingMethod'
          description: Method that the merchant uses to share the payment link.
        sharingEventId:
          type: string
          description: Unique identifier that we assigned to the sharing event.
        dateTime:
          type: string
          format: date-time
          description: >-
            Date and time that the merchant shared the link. Our gateway returns
            this value in the [ISO
            8601](https://www.iso.org/iso-8601-date-and-time-format.html)
            format.
        merchantCopy:
          type: boolean
          default: false
          description: >-
            Indicates if we send a copy of the email to the merchant. By
            default, we don't send a copy to the merchant.
        message:
          type: string
          description: Message that the merchant sends with the payment link.
        recipients:
          type: array
          items:
            $ref: '#/components/schemas/paymentLinkEmailRecipient'
          description: Array that contains the recipients of the payment link.
      required:
        - sharingMethod
        - recipients
      description: >-
        Object that contains the information about a sharing event that the
        merchant sent by email.
      title: paymentLinkEmailShareEvent
    paymentLinks_sharingEvents_share_Request:
      oneOf:
        - $ref: '#/components/schemas/paymentLinkEmailShareEvent'
      description: >-
        Polymorphic object that contains information about how to share a
        payment link.
      title: paymentLinks_sharingEvents_share_Request
    paymentLinks_sharingEvents_share_Response_201:
      oneOf:
        - $ref: '#/components/schemas/paymentLinkEmailShareEvent'
      title: paymentLinks_sharingEvents_share_Response_201
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

\<### Response (201)

```json
{
  "sharingMethod": "email",
  "sharingEventId": "GTZH5WVXK9",
  "dateTime": "2024-07-02T15:30:00Z",
  "message": "Dear Sarah,\n\nYou can pay for your order via the link below.\n",
  "recipients": [
    {
      "name": "Sarah Hazel Hopper",
      "email": "sarah.hopper@example.com"
    }
  ]
}
```