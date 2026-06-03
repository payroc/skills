> **Local snapshot — authoritative for this skill.** Source: https://docs.payroc.com/essentials/hosted-fields/extend-your-integration/save-a-customers-payment-details.md
> Last synced: 2026-06-01. Verbatim copy of the Payroc narrative guide. To refresh, re-fetch the source and regenerate this file (see _sources.md).

# Save a customer's payment details

When you use Hosted Fields to capture a customer's payment details, we return a single-use token. You can use the single-use token only once, and it expires 30 minutes after we return it.

If you want to run a sale later or run multiple sales, you need to convert the single-use token into a secure token. You can use the secure token multiple times, and it doesn't expire.

## Before you begin

Make sure you have set up your integration to [run a sale](../run-a-sale).

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

### Errors

Make sure that your integration can handle errors. If a request is unsuccessful, we return an error that follows the [RFC 7807 format](https://www.rfc-editor.org/rfc/rfc7807). For more information about errors, go to [Errors](/api/errors).

## Integration steps

1. Update the JavaScript configuration
2. Convert the single-use token into a secure token.
3. (Optional) Run a sale with the secure token.

## Step 1. Update the JavaScript configuration

* In the JavaScript configuration, change the value for the mode parameter from payment to `tokenization`.

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
  padForm.initialize();
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

## Step 2. Convert the single-use token into a secure token

To convert the single-use token into a secure token, send a POST request to our Secure Tokens endpoint.

| Endpoint   | Prefix     | URL                                                                                                                                                                                  |
| :--------- | :--------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Test       | `api.uat.` | [https://api.uat.payroc.com/v1/processing-terminals/\{processingTerminalId}/secure-tokens](https://api.uat.payroc.com/v1/processing-terminals/\{processingTerminalId}/secure-tokens) |
| Production | `api.`     | [https://api.payroc.com/v1/processing-terminals/\{processingTerminalId}/secure-tokens](https://api.payroc.com/v1/processing-terminals/\{processingTerminalId}/secure-tokens)         |

### Request parameters

To create the body of your request, send the single-use token in the source object.

**Note:** If the single-use token represents card details, you also need to send a value for the mitAgreement parameter.

### Schema (`request.body`)

```yaml
openapi: 3.1.0
info:
  title: API
  version: 1.0.0
paths:
  /processing-terminals/{processingTerminalId}/secure-tokens:
    post:
      operationId: create
      summary: Create secure token
      description: >
        Use this method to create a secure token that represents a customer's
        payment details.  


        When you create a secure token, you need to generate and provide a
        secureTokenId that you use to run follow-on actions:  

        - [Retrieve Secure
        Token](https://docs.payroc.com/api/schema/tokenization/secure-tokens/retrieve)
        – View the details of the secure token.  

        - [Delete Secure
        Token](https://docs.payroc.com/api/schema/tokenization/secure-tokens/delete)
        – Delete the secure token.  

        - [Update Secure
        Token](https://docs.payroc.com/api/schema/tokenization/secure-tokens/partially-update)
        – Update the details of the secure token.  

        - [Update Account
        Details](https://docs.payroc.com/api/schema/tokenization/secure-tokens/update-account)
        – Update the secure token with the details from a single-use token.  


        **Note:** If you don't generate a secureTokenId to identify the token,
        our gateway generates a unique identifier and returns it in the
        response.  


        If the request is successful, our gateway returns a token that the
        merchant can use in transactions instead of the customer's sensitive
        payment details, for example, when they [run a
        sale](https://docs.payroc.com/api/schema/card-payments/payments/create).
      tags:
        - subpackage_tokenization.subpackage_tokenization/secureTokens
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
            Successful request. We created a secure token that represents your
            customer's payment details.
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
              $ref: '#/components/schemas/tokenizationRequest'
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
    TokenizationRequestMitAgreement:
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
      title: TokenizationRequestMitAgreement
    address:
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
      required:
        - address1
        - city
        - state
        - country
        - postalCode
      description: Object that contains information about the address.
      title: address
    shipping:
      type: object
      properties:
        recipientName:
          type: string
          description: Recipient's name.
        address:
          $ref: '#/components/schemas/address'
      description: >-
        Object that contains information about the customer and their shipping
        address.
      title: shipping
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
    CustomerNotificationLanguage:
      type: string
      enum:
        - en
        - fr
      description: >
        Language that the customer uses for notifications. This code follows the
        [ISO 639-1](https://www.iso.org/iso-639-language-code) alpha-2
        standard. 
      title: CustomerNotificationLanguage
    customer:
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
          $ref: '#/components/schemas/address'
          description: >-
            Object that contains information about the address that the card is
            registered to.
        shippingAddress:
          $ref: '#/components/schemas/shipping'
        contactMethods:
          type: array
          items:
            $ref: '#/components/schemas/contactMethod'
          description: "Array of polymorphic objects, which contain contact information.  \n\nThe value of the type parameter determines which variant you should use:  \n-\t`email` - Email address \n-\t`phone` - Phone number\n-\t`mobile` - Mobile number\n-\t`fax` - Fax number\n"
        notificationLanguage:
          $ref: '#/components/schemas/CustomerNotificationLanguage'
          description: >
            Language that the customer uses for notifications. This code follows
            the [ISO 639-1](https://www.iso.org/iso-639-language-code) alpha-2
            standard. 
      description: >-
        Object that contains the customer's contact details and address
        information.
      title: customer
    IpAddressType:
      type: string
      enum:
        - ipv4
        - ipv6
      description: Internet protocol version of the IP address.
      title: IpAddressType
    ipAddress:
      type: object
      properties:
        type:
          $ref: '#/components/schemas/IpAddressType'
          description: Internet protocol version of the IP address.
        value:
          type: string
          description: IP address of the device.
      required:
        - type
        - value
      description: Object that contains the IP address of the device that sent the request.
      title: ipAddress
    BankAccountVerificationRequestBankAccountDiscriminatorMappingAchAccountType:
      type: string
      enum:
        - checking
        - savings
      description: |
        Indicates the customer’s account type.  

        **Note:** For bank account details, send a value for accountType.
      title: >-
        BankAccountVerificationRequestBankAccountDiscriminatorMappingAchAccountType
    BankAccountVerificationRequestBankAccountDiscriminatorMappingAchSecCode:
      type: string
      enum:
        - web
        - tel
        - ccd
        - ppd
      description: >
        Indicates how the customer authorized the ACH transaction. Send one of
        the following values:


        - `web` – Online transaction.

        - `tel` – Telephone transaction.

        - `ccd` – Corporate credit card or debit card transaction.

        - `ppd` – Pre-arranged transaction.


        **Note:** This field is mandatory for ACH payments and unreferenced
        refunds.
      title: BankAccountVerificationRequestBankAccountDiscriminatorMappingAchSecCode
    BankAccountVerificationRequestBankAccountDiscriminatorMappingPadAccountType:
      type: string
      enum:
        - checking
        - savings
      description: |
        Indicates the customer’s account type.  
        **Note:** For bank account details, send a value for accountType.
      title: >-
        BankAccountVerificationRequestBankAccountDiscriminatorMappingPadAccountType
    FxRateInquiryPaymentMethodDiscriminatorMappingCardAccountType:
      type: string
      enum:
        - checking
        - savings
      description: |
        Indicates the customer’s account type.  

        **Note:** Send a value for accountType only for bank account details.
      title: FxRateInquiryPaymentMethodDiscriminatorMappingCardAccountType
    FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingRawDowngradeTo:
      type: string
      enum:
        - keyed
        - swiped
      description: >
        If an offline transaction is not approved using the initial entry
        method, reprocess the transaction using a downgraded entry method.

        For example, an Integrated Circuit Card (ICC) transaction can be
        downgraded to a swiped transaction or to a keyed transaction.
      title: >-
        FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingRawDowngradeTo
    DeviceModel:
      type: string
      enum:
        - bbposChp
        - bbposChp2x
        - bbposChp3x
        - bbposRambler
        - bbposWp
        - bbposWp2
        - bbposWp3
        - genericCtlsMsr
        - genericMsr
        - idtechAugusta
        - idtechMinismart
        - idtechSredkey
        - idtechVp3300
        - idtechVp5300
        - idtechVp6300
        - idtechVp6800
        - ingenicoAxiumDx4000
        - ingenicoAxiumDx8000
        - ingenicoAxiumEx8000
        - ingenicoIct220
        - ingenicoIpp320
        - ingenicoIpp350
        - ingenicoIuc285
        - ingenicoL3000
        - ingenicoL7000
        - ingenicoS2000
        - ingenicoS3000
        - ingenicoS4000
        - ingenicoS5000
        - ingenicoS7000
        - paxA80
        - paxA920
        - paxA920Pro
        - paxA920Max
        - paxE500
        - paxE700
        - paxE800
        - paxIm30
        - uic680
        - uicBezel8
      description: Model of the device that the merchant used to process the transaction.
      title: DeviceModel
    DeviceCategory:
      type: string
      enum:
        - attended
        - unattended
      default: attended
      description: Indicates if the device is attended or unattended.
      title: DeviceCategory
    deviceConfig:
      type: object
      properties:
        quickChip:
          type: boolean
          default: false
          description: Indicates if Quick Chip mode is active on a merchant’s POS terminal.
      required:
        - quickChip
      description: >-
        Object that contains information about the configuration of the POS
        terminal.
      title: deviceConfig
    device:
      type: object
      properties:
        model:
          $ref: '#/components/schemas/DeviceModel'
          description: >-
            Model of the device that the merchant used to process the
            transaction.
        category:
          $ref: '#/components/schemas/DeviceCategory'
          default: attended
          description: Indicates if the device is attended or unattended.
        serialNumber:
          type: string
          description: Serial number of the physical device.
        firmwareVersion:
          type: string
          description: Firmware version of the physical device.
        config:
          $ref: '#/components/schemas/deviceConfig'
      required:
        - model
        - serialNumber
      description: >-
        Object that contains information about the physical device the merchant
        used to capture the customer’s card details.
      title: device
    FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingIccDowngradeTo:
      type: string
      enum:
        - keyed
        - swiped
      description: >
        If an offline transaction is not approved using the initial entry
        method, reprocess the transaction using a downgraded entry method. 

        For example, an Integrated Circuit Card (ICC) transaction can be
        downgraded to a swiped transaction or a keyed transaction.
      title: >-
        FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingIccDowngradeTo
    EncryptionCapableDeviceModel:
      type: string
      enum:
        - bbposChp
        - bbposChp2x
        - bbposChp3x
        - bbposRambler
        - bbposWp
        - bbposWp2
        - bbposWp3
        - genericCtlsMsr
        - genericMsr
        - idtechAugusta
        - idtechMinismart
        - idtechSredkey
        - idtechVp3300
        - idtechVp5300
        - idtechVp6300
        - idtechVp6800
        - ingenicoAxiumDx4000
        - ingenicoAxiumDx8000
        - ingenicoAxiumEx8000
        - ingenicoIct220
        - ingenicoIpp320
        - ingenicoIpp350
        - ingenicoIuc285
        - ingenicoL3000
        - ingenicoL7000
        - ingenicoS2000
        - ingenicoS3000
        - ingenicoS4000
        - ingenicoS5000
        - ingenicoS7000
        - paxA80
        - paxA920
        - paxA920Pro
        - paxA920Max
        - paxE500
        - paxE700
        - paxE800
        - paxIm30
        - uic680
        - uicBezel8
      description: Model of the device that the merchant used to process the transaction.
      title: EncryptionCapableDeviceModel
    EncryptionCapableDeviceCategory:
      type: string
      enum:
        - attended
        - unattended
      default: attended
      description: Indicates if the device is attended or unattended.
      title: EncryptionCapableDeviceCategory
    encryptionCapableDevice:
      type: object
      properties:
        model:
          $ref: '#/components/schemas/EncryptionCapableDeviceModel'
          description: >-
            Model of the device that the merchant used to process the
            transaction.
        category:
          $ref: '#/components/schemas/EncryptionCapableDeviceCategory'
          default: attended
          description: Indicates if the device is attended or unattended.
        serialNumber:
          type: string
          description: Serial number of the physical device.
        firmwareVersion:
          type: string
          description: Firmware version of the physical device.
        config:
          $ref: '#/components/schemas/deviceConfig'
        dataKsn:
          type: string
          format: hexadecimal
          description: Key serial number.
      required:
        - model
        - serialNumber
        - dataKsn
      description: >-
        Object that contains information about the encryption details of the POS
        terminal.
      title: encryptionCapableDevice
    EbtDetailsWithVoucherBenefitCategory:
      type: string
      enum:
        - cash
        - foodStamp
      description: >
        Indicates if the balance relates to an EBT Cash account or an EBT SNAP
        account.  
         - `cash` – EBT Cash  
         - `foodStamp` – EBT SNAP
      title: EbtDetailsWithVoucherBenefitCategory
    voucher:
      type: object
      properties:
        approvalCode:
          type: string
          description: Authorization code that the processor issued for the transaction.
        serialNumber:
          type: string
          description: Serial number of the voucher.
      required:
        - approvalCode
        - serialNumber
      description: |
        Object that contains information about the EBT voucher.  

        **Note:** Vouchers are available only for EBT SNAP payments.
      title: voucher
    ebtDetailsWithVoucher:
      type: object
      properties:
        benefitCategory:
          $ref: '#/components/schemas/EbtDetailsWithVoucherBenefitCategory'
          description: >
            Indicates if the balance relates to an EBT Cash account or an EBT
            SNAP account.  
             - `cash` – EBT Cash  
             - `foodStamp` – EBT SNAP
        withdrawal:
          type: boolean
          description: >
            Indicates whether the customer wants to withdraw cash.  


            **Note:** Cash withdrawals are available only from EBT Cash
            accounts.
        voucher:
          $ref: '#/components/schemas/voucher'
      required:
        - benefitCategory
      description: >-
        Object that contains information about the Electronic Benefit Transfer
        (EBT) transaction.
      title: ebtDetailsWithVoucher
    FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingKeyedKeyedData:
      oneOf:
        - type: object
          properties:
            dataFormat:
              type: string
              enum:
                - fullyEncrypted
              description: 'Discriminator value: fullyEncrypted'
            device:
              $ref: '#/components/schemas/encryptionCapableDevice'
            encryptedData:
              type: string
              format: hexadecimal
              description: Encrypted card data.
            firstDigitOfPan:
              type: string
              description: First digit of the customer’s card number.
          required:
            - dataFormat
            - device
            - encryptedData
          description: >-
            Object that contains information about the encrypted card data for
            keyed transactions.
        - type: object
          properties:
            dataFormat:
              type: string
              enum:
                - partiallyEncrypted
              description: 'Discriminator value: partiallyEncrypted'
            device:
              $ref: '#/components/schemas/encryptionCapableDevice'
            encryptedPan:
              type: string
              format: hexadecimal
              description: Encrypted card number.
            maskedPan:
              type: string
              description: >
                Masked card number. 

                The gateway shows only the first six digits and the last four
                digits of the account number. For example, `453985******7062`.
            expiryDate:
              type: string
              description: Expiry date of the customer’s card.
            cvv:
              type: string
              description: Security code of the customer’s card.
            cvvEncrypted:
              type: string
              format: hexadecimal
              description: Encrypted security code data.
            issueNumber:
              type: string
              description: Issue number of the customer’s card.
          required:
            - dataFormat
            - device
            - encryptedPan
            - maskedPan
            - expiryDate
          description: >-
            Object that contains information about the partially-encrypted card
            data for keyed transactions.
        - type: object
          properties:
            dataFormat:
              type: string
              enum:
                - plainText
              description: 'Discriminator value: plainText'
            device:
              $ref: '#/components/schemas/device'
            cardNumber:
              type: string
              description: Customer’s card number.
            expiryDate:
              type: string
              description: >
                Expiry date of the customer’s card.  

                **Note:** We require you to send an expiry date for most BIN
                lookups and electronic voucher transactions.
            cvv:
              type: string
              description: Security code of the customer’s card.
            issueNumber:
              type: string
              description: Issue number of the customer’s card.
          required:
            - dataFormat
            - cardNumber
          description: >-
            Object that contains information about the plain-text card data for
            keyed transactions.
      discriminator:
        propertyName: dataFormat
      description: "Polymorphic object that contains payment card details that the merchant manually entered into the device.  \n\nThe value of the dataFormat parameter determines which variant you should use:  \n-\t`fullyEncrypted` - All payment card details are encrypted.\n-\t`partiallyEncrypted` - Some payment card details are encrypted.\n-\t`plainText` - Payment card details are in plain text.\n"
      title: >-
        FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingKeyedKeyedData
    FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingKeyedPinDetails:
      oneOf:
        - type: object
          properties:
            dataFormat:
              type: string
              enum:
                - dukpt
              description: 'Discriminator value: dukpt'
            pin:
              type: string
              format: hexadecimal
              description: |
                Encrypted PIN.  
                **Note:** PIN is encrypted using the DUKPT scheme.
            pinKsn:
              type: string
              format: hexadecimal
              description: Key serial number.
          required:
            - dataFormat
            - pin
            - pinKsn
          description: Object that contains information about encrypted PIN details.
      discriminator:
        propertyName: dataFormat
      description: Polymorphic object that contains information about the customer's PIN.
      title: >-
        FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingKeyedPinDetails
    FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedDowngradeTo:
      type: string
      enum:
        - keyed
        - swiped
      description: >
        If an offline transaction is not approved using the initial entry
        method, reprocess the transaction using a downgraded entry method. 

        For example, a swiped transaction can be downgraded to a keyed
        transaction.
      title: >-
        FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedDowngradeTo
    FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedSwipedDataDiscriminatorMappingEncryptedFallbackReason:
      type: string
      enum:
        - technical
        - repeatFallback
        - emptyCandidateList
      description: Reason for the fallback.
      title: >-
        FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedSwipedDataDiscriminatorMappingEncryptedFallbackReason
    FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedSwipedDataDiscriminatorMappingPlainTextFallbackReason:
      type: string
      enum:
        - technical
        - repeatFallback
        - emptyCandidateList
      description: Reason for the fallback.
      title: >-
        FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedSwipedDataDiscriminatorMappingPlainTextFallbackReason
    FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedSwipedData:
      oneOf:
        - type: object
          properties:
            dataFormat:
              type: string
              enum:
                - encrypted
              description: 'Discriminator value: encrypted'
            device:
              $ref: '#/components/schemas/encryptionCapableDevice'
            encryptedData:
              type: string
              format: hexadecimal
              description: Encrypted data received from the magnetic stripe reader.
            firstDigitOfPan:
              type: string
              description: First digit of the of the card number.
            fallback:
              type: boolean
              description: >-
                Indicates that this is a fallback transaction. For example, if
                there was a technical issue with the chip on the customer's card
                and the merchant then swiped the card.
            fallbackReason:
              $ref: >-
                #/components/schemas/FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedSwipedDataDiscriminatorMappingEncryptedFallbackReason
              description: Reason for the fallback.
          required:
            - dataFormat
            - device
            - encryptedData
          description: >-
            Object that contains information about the encrypted swiped card
            data.
        - type: object
          properties:
            dataFormat:
              type: string
              enum:
                - plainText
              description: 'Discriminator value: plainText'
            device:
              $ref: '#/components/schemas/device'
            trackData:
              type: string
              description: Customer’s card data from the swiped transaction.
            fallback:
              type: boolean
              description: >-
                Indicates that this is a fallback transaction. For example, if
                there was a technical issue with the chip on the customer's card
                and the merchant then swiped the card.
            fallbackReason:
              $ref: >-
                #/components/schemas/FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedSwipedDataDiscriminatorMappingPlainTextFallbackReason
              description: Reason for the fallback.
          required:
            - dataFormat
            - device
            - trackData
          description: Object that contains information about plain-text swiped card data.
      discriminator:
        propertyName: dataFormat
      description: "Polymorphic object that contains payment card details that a device captured from the magnetic strip.  \n\nThe value of the dataFormat parameter determines which variant you should use:  \n-\t`encrypted` - Payment card details are encrypted.\n-\t`plainText` - Payment card details are in plain text.\n"
      title: >-
        FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedSwipedData
    FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedPinDetails:
      oneOf:
        - type: object
          properties:
            dataFormat:
              type: string
              enum:
                - dukpt
              description: 'Discriminator value: dukpt'
            pin:
              type: string
              format: hexadecimal
              description: |
                Encrypted PIN.  
                **Note:** PIN is encrypted using the DUKPT scheme.
            pinKsn:
              type: string
              format: hexadecimal
              description: Key serial number.
          required:
            - dataFormat
            - pin
            - pinKsn
          description: Object that contains information about encrypted PIN details.
      discriminator:
        propertyName: dataFormat
      description: Polymorphic object that contains information about the customer's PIN.
      title: >-
        FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedPinDetails
    FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetails:
      oneOf:
        - type: object
          properties:
            entryMethod:
              type: string
              enum:
                - raw
              description: 'Discriminator value: raw'
            downgradeTo:
              $ref: >-
                #/components/schemas/FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingRawDowngradeTo
              description: >
                If an offline transaction is not approved using the initial
                entry method, reprocess the transaction using a downgraded entry
                method.

                For example, an Integrated Circuit Card (ICC) transaction can be
                downgraded to a swiped transaction or to a keyed transaction.
            device:
              $ref: '#/components/schemas/device'
            rawData:
              type: string
              format: hexadecimal
              description: Unencrypted data from the POS terminal.
            cardholderSignature:
              type: string
              description: >-
                Cardholder's signature. For more information about how to format
                the signature, go to [How to send a signature to our
                gateway](https://docs.payroc.com/knowledge/basic-concepts/signature-capture).
          required:
            - entryMethod
            - device
            - rawData
          description: Object that contains information about the unencrypted card details.
        - type: object
          properties:
            entryMethod:
              type: string
              enum:
                - icc
              description: 'Discriminator value: icc'
            downgradeTo:
              $ref: >-
                #/components/schemas/FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingIccDowngradeTo
              description: >
                If an offline transaction is not approved using the initial
                entry method, reprocess the transaction using a downgraded entry
                method. 

                For example, an Integrated Circuit Card (ICC) transaction can be
                downgraded to a swiped transaction or a keyed transaction.
            device:
              $ref: '#/components/schemas/encryptionCapableDevice'
            iccData:
              type: string
              format: hexadecimal
              description: >-
                Cardholder data from the ICC. The data consists of EMV tags in
                Tag-Length-Value (TLV) format.
            firstDigitOfPan:
              type: string
              description: First digit of the card number.
            cardholderSignature:
              type: string
              description: >-
                Cardholder's signature. For more information about how to format
                the signature, go to [How to send a signature to our
                gateway](https://docs.payroc.com/knowledge/basic-concepts/signature-capture).
            ebtDetails:
              $ref: '#/components/schemas/ebtDetailsWithVoucher'
          required:
            - entryMethod
            - device
            - iccData
          description: >-
            Object that contains information about the Integrated Circuit Card
            (ICC).
        - type: object
          properties:
            entryMethod:
              type: string
              enum:
                - keyed
              description: 'Discriminator value: keyed'
            keyedData:
              $ref: >-
                #/components/schemas/FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingKeyedKeyedData
              description: "Polymorphic object that contains payment card details that the merchant manually entered into the device.  \n\nThe value of the dataFormat parameter determines which variant you should use:  \n-\t`fullyEncrypted` - All payment card details are encrypted.\n-\t`partiallyEncrypted` - Some payment card details are encrypted.\n-\t`plainText` - Payment card details are in plain text.\n"
            cardholderName:
              type: string
              description: Cardholder’s name.
            cardholderSignature:
              type: string
              description: >-
                Cardholder's signature. For more information about how to format
                the signature, go to [How to send a signature to our
                gateway](https://docs.payroc.com/knowledge/basic-concepts/signature-capture).
            pinDetails:
              $ref: >-
                #/components/schemas/FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingKeyedPinDetails
              description: >-
                Polymorphic object that contains information about the
                customer's PIN.
            ebtDetails:
              $ref: '#/components/schemas/ebtDetailsWithVoucher'
          required:
            - entryMethod
            - keyedData
          description: Object that contains information about the keyed card details.
        - type: object
          properties:
            entryMethod:
              type: string
              enum:
                - swiped
              description: 'Discriminator value: swiped'
            downgradeTo:
              $ref: >-
                #/components/schemas/FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedDowngradeTo
              description: >
                If an offline transaction is not approved using the initial
                entry method, reprocess the transaction using a downgraded entry
                method. 

                For example, a swiped transaction can be downgraded to a keyed
                transaction.
            swipedData:
              $ref: >-
                #/components/schemas/FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedSwipedData
              description: "Polymorphic object that contains payment card details that a device captured from the magnetic strip.  \n\nThe value of the dataFormat parameter determines which variant you should use:  \n-\t`encrypted` - Payment card details are encrypted.\n-\t`plainText` - Payment card details are in plain text.\n"
            cardholderName:
              type: string
              description: Cardholder’s name.
            cardholderSignature:
              type: string
              description: >-
                Cardholder's signature. For more information about how to format
                the signature, go to [How to send a signature to our
                gateway](https://docs.payroc.com/knowledge/basic-concepts/signature-capture).
            pinDetails:
              $ref: >-
                #/components/schemas/FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedPinDetails
              description: >-
                Polymorphic object that contains information about the
                customer's PIN.
            ebtDetails:
              $ref: '#/components/schemas/ebtDetailsWithVoucher'
          required:
            - entryMethod
            - swipedData
          description: >-
            Object that contains information about the customer’s card details
            for swiped transactions.
      discriminator:
        propertyName: entryMethod
      description: >
        Polymorphic object that contains payment card information.  


        The value of the entryMethod parameter determines which variant you
        should use:  

        - `raw` - Unencrypted payment data directly from the device.

        - `icc` - Payment data that the device captured from the chip.

        - `keyed` - Payment data that the merchant entered manually.

        - `swiped` - Payment data that the device captured from the magnetic
        strip.
      title: FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetails
    BankTransferPaymentRequestPaymentMethodDiscriminatorMappingSingleUseTokenAccountType:
      type: string
      enum:
        - checking
        - savings
      description: >
        Indicates the customer’s account type.  


        **Note:** Send a value for accountType only if the single-use token
        represents bank account details.
      title: >-
        BankTransferPaymentRequestPaymentMethodDiscriminatorMappingSingleUseTokenAccountType
    BankTransferPaymentRequestPaymentMethodDiscriminatorMappingSingleUseTokenPinDetails:
      oneOf:
        - type: object
          properties:
            dataFormat:
              type: string
              enum:
                - dukpt
              description: 'Discriminator value: dukpt'
            pin:
              type: string
              format: hexadecimal
              description: |
                Encrypted PIN.  
                **Note:** PIN is encrypted using the DUKPT scheme.
            pinKsn:
              type: string
              format: hexadecimal
              description: Key serial number.
          required:
            - dataFormat
            - pin
            - pinKsn
          description: Object that contains information about encrypted PIN details.
        - type: object
          properties:
            dataFormat:
              type: string
              enum:
                - raw
              description: 'Discriminator value: raw'
            pin:
              type: string
              description: Customer’s unencrypted PIN.
          required:
            - dataFormat
            - pin
          description: Object that contains information about the unencrypted PIN details.
      discriminator:
        propertyName: dataFormat
      description: >
        Polymorphic object that contains information about a customer's PIN.  


        The value of the dataFormat parameter determines which variant you
        should use:  

        - `dukpt` - PIN information is encrypted.

        - `raw` - PIN information is unencrypted.
      title: >-
        BankTransferPaymentRequestPaymentMethodDiscriminatorMappingSingleUseTokenPinDetails
    BankTransferPaymentRequestPaymentMethodDiscriminatorMappingSingleUseTokenSecCode:
      type: string
      enum:
        - web
        - tel
        - ccd
        - ppd
      description: >
        Indicates how the customer authorized the ACH transaction. Send one of
        the following values:


        - `web` – Online transaction.

        - `tel` – Telephone transaction.

        - `ccd` – Corporate credit card or debit card transaction.

        - `ppd` – Pre-arranged transaction.


        **Note:** This field is mandatory when the single-use token represents
        ACH bank account details.
      title: >-
        BankTransferPaymentRequestPaymentMethodDiscriminatorMappingSingleUseTokenSecCode
    TokenizationRequestSource:
      oneOf:
        - type: object
          properties:
            type:
              type: string
              enum:
                - ach
              description: 'Discriminator value: ach'
            accountType:
              $ref: >-
                #/components/schemas/BankAccountVerificationRequestBankAccountDiscriminatorMappingAchAccountType
              description: >
                Indicates the customer’s account type.  


                **Note:** For bank account details, send a value for
                accountType.
            secCode:
              $ref: >-
                #/components/schemas/BankAccountVerificationRequestBankAccountDiscriminatorMappingAchSecCode
              description: >
                Indicates how the customer authorized the ACH transaction. Send
                one of the following values:


                - `web` – Online transaction.

                - `tel` – Telephone transaction.

                - `ccd` – Corporate credit card or debit card transaction.

                - `ppd` – Pre-arranged transaction.


                **Note:** This field is mandatory for ACH payments and
                unreferenced refunds.
            nameOnAccount:
              type: string
              description: Customer's name.
            accountNumber:
              type: string
              description: >
                Customer’s bank account number.  

                **Note:** In responses, our gateway shows only the last four
                digits of the account number, for example, `*****5929`.
            routingNumber:
              type: string
              description: Nine-digit number that identifies the customer's bank.
          required:
            - type
            - nameOnAccount
            - accountNumber
            - routingNumber
          description: >-
            Object that contains information about the payment details for the
            customer’s automated clearing house (ACH) transactions.
        - type: object
          properties:
            type:
              type: string
              enum:
                - pad
              description: 'Discriminator value: pad'
            accountType:
              $ref: >-
                #/components/schemas/BankAccountVerificationRequestBankAccountDiscriminatorMappingPadAccountType
              description: >
                Indicates the customer’s account type.  

                **Note:** For bank account details, send a value for
                accountType.
            nameOnAccount:
              type: string
              description: Customer's name.
            accountNumber:
              type: string
              description: >
                Customer's account number.  

                **Note:** In responses, our gateway shows only the last four
                digits of the account number, for example, `*****5929`.
            transitNumber:
              type: string
              description: Five-digit number that identifies the customer's bank branch.
            institutionNumber:
              type: string
              description: Three-digit number that identifies the customer's bank.
          required:
            - type
            - nameOnAccount
            - accountNumber
            - transitNumber
            - institutionNumber
          description: >-
            Object that contains information about the payment details for the
            customer’s preauthorized electronic debit (PAD) transactions.
        - type: object
          properties:
            type:
              type: string
              enum:
                - card
              description: 'Discriminator value: card'
            accountType:
              $ref: >-
                #/components/schemas/FxRateInquiryPaymentMethodDiscriminatorMappingCardAccountType
              description: >
                Indicates the customer’s account type.  


                **Note:** Send a value for accountType only for bank account
                details.
            cardDetails:
              $ref: >-
                #/components/schemas/FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetails
              description: >
                Polymorphic object that contains payment card information.  


                The value of the entryMethod parameter determines which variant
                you should use:  

                - `raw` - Unencrypted payment data directly from the device.

                - `icc` - Payment data that the device captured from the chip.

                - `keyed` - Payment data that the merchant entered manually.

                - `swiped` - Payment data that the device captured from the
                magnetic strip.
          required:
            - type
            - cardDetails
          description: Object that contains information about the customer’s payment card.
        - type: object
          properties:
            type:
              type: string
              enum:
                - singleUseToken
              description: 'Discriminator value: singleUseToken'
            accountType:
              $ref: >-
                #/components/schemas/BankTransferPaymentRequestPaymentMethodDiscriminatorMappingSingleUseTokenAccountType
              description: >
                Indicates the customer’s account type.  


                **Note:** Send a value for accountType only if the single-use
                token represents bank account details.
            token:
              type: string
              description: Unique token that the gateway assigned to the payment details.
            pinDetails:
              $ref: >-
                #/components/schemas/BankTransferPaymentRequestPaymentMethodDiscriminatorMappingSingleUseTokenPinDetails
              description: >
                Polymorphic object that contains information about a customer's
                PIN.  


                The value of the dataFormat parameter determines which variant
                you should use:  

                - `dukpt` - PIN information is encrypted.

                - `raw` - PIN information is unencrypted.
            ebtDetails:
              $ref: '#/components/schemas/ebtDetailsWithVoucher'
            secCode:
              $ref: >-
                #/components/schemas/BankTransferPaymentRequestPaymentMethodDiscriminatorMappingSingleUseTokenSecCode
              description: >
                Indicates how the customer authorized the ACH transaction. Send
                one of the following values:


                - `web` – Online transaction.

                - `tel` – Telephone transaction.

                - `ccd` – Corporate credit card or debit card transaction.

                - `ppd` – Pre-arranged transaction.


                **Note:** This field is mandatory when the single-use token
                represents ACH bank account details.
          required:
            - type
            - token
          description: >-
            Object that contains information about the single-use token, which
            represents the customer’s payment details.
      discriminator:
        propertyName: type
      description: "Polymorphic object that contains the payment method to tokenize.  \n\nThe value of the type parameter determines which variant you should use:  \n-\t`ach` - Automated Clearing House (ACH) details\n-\t`pad` - Pre-authorized debit (PAD) details\n-\t`card` - Payment card details\n-\t`singleUseToken` - Single-use token details\n"
      title: TokenizationRequestSource
    PaymentRequestThreeDSecureDiscriminatorMappingThirdPartyEci:
      type: string
      enum:
        - fullyAuthenticated
        - attemptedAuthentication
      description: E-commerce indicator (ECI) result of a the 3-D Secure check.
      title: PaymentRequestThreeDSecureDiscriminatorMappingThirdPartyEci
    TokenizationRequestThreeDSecure:
      oneOf:
        - type: object
          properties:
            type:
              type: string
              enum:
                - gatewayThreeDSecure
              description: 'Discriminator value: gatewayThreeDSecure'
            mpiReference:
              type: string
              description: >-
                Reference that our gateway assigned to the 3-D Secure
                authentication response.
          required:
            - type
            - mpiReference
          description: Object that contains the 3-D Secure information from our gateway.
        - type: object
          properties:
            type:
              type: string
              enum:
                - thirdPartyThreeDSecure
              description: 'Discriminator value: thirdPartyThreeDSecure'
            eci:
              $ref: >-
                #/components/schemas/PaymentRequestThreeDSecureDiscriminatorMappingThirdPartyEci
              description: E-commerce indicator (ECI) result of a the 3-D Secure check.
            xid:
              type: string
              description: >-
                Unique transaction identifier that the merchant assigned to the
                transaction and sent in the authentication request.
            cavv:
              type: string
              description: >-
                Cardholder Authentication Verification Value (CAVV) that the
                card issuer provided to prove that they authorized the online
                payment.
            dsTransactionId:
              type: string
              description: >-
                Directory Server Transaction ID that the processor assigned to
                the request.
          required:
            - type
            - eci
          description: Object that contains the 3-D Secure information from a third party.
      discriminator:
        propertyName: type
      description: "Polymorphic object that contains authentication information from 3-D Secure.  \n\nThe value of the type parameter determines which variant you should use:  \n-\t`gatewayThreeDSecure` - Use our gateway to run a 3-D Secure check.\n-\t`thirdPartyThreeDSecure` - Use a third party to run a 3-D Secure check.\n"
      title: TokenizationRequestThreeDSecure
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
    tokenizationRequest:
      type: object
      properties:
        secureTokenId:
          type: string
          description: >
            Unique identifier that the merchant created for the secure token
            that represents the customer's payment details. 

            If the merchant doesn't create a secureTokenId, the gateway
            generates one and returns it in the response.
        operator:
          type: string
          description: Operator who saved the customer's payment details.
        mitAgreement:
          $ref: '#/components/schemas/TokenizationRequestMitAgreement'
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
          $ref: '#/components/schemas/customer'
        ipAddress:
          $ref: '#/components/schemas/ipAddress'
        source:
          $ref: '#/components/schemas/TokenizationRequestSource'
          description: "Polymorphic object that contains the payment method to tokenize.  \n\nThe value of the type parameter determines which variant you should use:  \n-\t`ach` - Automated Clearing House (ACH) details\n-\t`pad` - Pre-authorized debit (PAD) details\n-\t`card` - Payment card details\n-\t`singleUseToken` - Single-use token details\n"
        threeDSecure:
          $ref: '#/components/schemas/TokenizationRequestThreeDSecure'
          description: "Polymorphic object that contains authentication information from 3-D Secure.  \n\nThe value of the type parameter determines which variant you should use:  \n-\t`gatewayThreeDSecure` - Use our gateway to run a 3-D Secure check.\n-\t`thirdPartyThreeDSecure` - Use a third party to run a 3-D Secure check.\n"
        customFields:
          type: array
          items:
            $ref: '#/components/schemas/customField'
          description: |
            Array of customField objects.
      required:
        - source
      title: tokenizationRequest
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

POST [https://api.payroc.com/v1/processing-terminals/\{processingTerminalId}/secure-tokens](https://api.payroc.com/v1/processing-terminals/\{processingTerminalId}/secure-tokens)

```curl Secure Token
curl -X POST https://api.payroc.com/v1/processing-terminals/1234001/secure-tokens \
     -H "Idempotency-Key: 8e03978e-40d5-43e8-bc93-6894a57f9324" \
     -H "Authorization: Bearer <token>" \
     -H "Content-Type: application/json" \
     -d '{
  "source": {
    "type": "card",
    "cardDetails": {
      "entryMethod": "keyed",
      "keyedData": {
        "dataFormat": "plainText",
        "cardNumber": "4539858876047062",
        "cvv": "234",
        "expiryDate": "1230"
      },
      "cardholderName": "Sarah Hazel Hopper"
    }
  },
  "operator": "Jane",
  "mitAgreement": "unscheduled",
  "customer": {
    "firstName": "Sarah",
    "lastName": "Hopper",
    "dateOfBirth": "1990-07-15",
    "referenceNumber": "Customer-12",
    "billingAddress": {
      "address1": "1 Example Ave.",
      "city": "Chicago",
      "state": "Illinois",
      "country": "US",
      "postalCode": "60056",
      "address2": "Example Address Line 2",
      "address3": "Example Address Line 3"
    },
    "shippingAddress": {
      "recipientName": "Sarah Hopper",
      "address": {
        "address1": "1 Example Ave.",
        "city": "Chicago",
        "state": "Illinois",
        "country": "US",
        "postalCode": "60056",
        "address2": "Example Address Line 2",
        "address3": "Example Address Line 3"
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
  "ipAddress": {
    "type": "ipv4",
    "value": "104.18.24.203"
  },
  "customFields": [
    {
      "name": "yourCustomField",
      "value": "abc123"
    }
  ]
}'
```

```typescript Secure Token
import { PayrocClient } from "payroc";

async function main() {
    const client = new PayrocClient();
    await client.tokenization.secureTokens.create("1234001", {
        idempotencyKey: "8e03978e-40d5-43e8-bc93-6894a57f9324",
        source: {
            type: "card",
            cardDetails: {
                entryMethod: "keyed",
                keyedData: {
                    dataFormat: "plainText",
                    cardNumber: "4539858876047062",
                    cvv: "234",
                    expiryDate: "1230",
                },
                cardholderName: "Sarah Hazel Hopper",
            },
        },
        operator: "Jane",
        mitAgreement: "unscheduled",
        customer: {
            firstName: "Sarah",
            lastName: "Hopper",
            dateOfBirth: "1990-07-15",
            referenceNumber: "Customer-12",
            billingAddress: {
                address1: "1 Example Ave.",
                city: "Chicago",
                state: "Illinois",
                country: "US",
                postalCode: "60056",
                address2: "Example Address Line 2",
                address3: "Example Address Line 3",
            },
            shippingAddress: {
                recipientName: "Sarah Hopper",
                address: {
                    address1: "1 Example Ave.",
                    city: "Chicago",
                    state: "Illinois",
                    country: "US",
                    postalCode: "60056",
                    address2: "Example Address Line 2",
                    address3: "Example Address Line 3",
                },
            },
            contactMethods: [
                {
                    type: "email",
                    value: "sarah.hopper@example.com",
                },
            ],
            notificationLanguage: "en",
        },
        ipAddress: {
            type: "ipv4",
            value: "104.18.24.203",
        },
        customFields: [
            {
                name: "yourCustomField",
                value: "abc123",
            },
        ],
    });
}
main();

```

```python Secure Token
from payroc import Payroc, CardPayloadCardDetails_Keyed, KeyedCardDetailsKeyedData_PlainText, Customer, Address, Shipping, ContactMethod_Email, IpAddress, CustomField
from payroc.tokenization.secure_tokens import TokenizationRequestSource_Card
import datetime

client = Payroc()

client.tokenization.secure_tokens.create(
    processing_terminal_id="1234001",
    idempotency_key="8e03978e-40d5-43e8-bc93-6894a57f9324",
    source=TokenizationRequestSource_Card(
        card_details=CardPayloadCardDetails_Keyed(
            keyed_data=KeyedCardDetailsKeyedData_PlainText(
                card_number="4539858876047062",
                cvv="234",
                expiry_date="1230",
            ),
            cardholder_name="Sarah Hazel Hopper",
        ),
    ),
    operator="Jane",
    mit_agreement="unscheduled",
    customer=Customer(
        first_name="Sarah",
        last_name="Hopper",
        date_of_birth=datetime.date.fromisoformat("1990-07-15"),
        reference_number="Customer-12",
        billing_address=Address(
            address_1="1 Example Ave.",
            city="Chicago",
            state="Illinois",
            country="US",
            postal_code="60056",
            address_2="Example Address Line 2",
            address_3="Example Address Line 3",
        ),
        shipping_address=Shipping(
            recipient_name="Sarah Hopper",
            address=Address(
                address_1="1 Example Ave.",
                city="Chicago",
                state="Illinois",
                country="US",
                postal_code="60056",
                address_2="Example Address Line 2",
                address_3="Example Address Line 3",
            ),
        ),
        contact_methods=[
            ContactMethod_Email(
                value="sarah.hopper@example.com",
            )
        ],
        notification_language="en",
    ),
    ip_address=IpAddress(
        type="ipv4",
        value="104.18.24.203",
    ),
    custom_fields=[
        CustomField(
            name="yourCustomField",
            value="abc123",
        )
    ],
)

```

```java Secure Token
package com.example.usage;

import com.payroc.api.PayrocApiClient;
import com.payroc.api.resources.tokenization.securetokens.requests.TokenizationRequest;
import com.payroc.api.resources.tokenization.securetokens.types.TokenizationRequestMitAgreement;
import com.payroc.api.resources.tokenization.securetokens.types.TokenizationRequestSource;
import com.payroc.api.types.Address;
import com.payroc.api.types.CardPayload;
import com.payroc.api.types.CardPayloadCardDetails;
import com.payroc.api.types.ContactMethod;
import com.payroc.api.types.ContactMethodEmail;
import com.payroc.api.types.CustomField;
import com.payroc.api.types.Customer;
import com.payroc.api.types.CustomerNotificationLanguage;
import com.payroc.api.types.IpAddress;
import com.payroc.api.types.IpAddressType;
import com.payroc.api.types.KeyedCardDetails;
import com.payroc.api.types.KeyedCardDetailsKeyedData;
import com.payroc.api.types.PlainTextKeyedDataFormat;
import com.payroc.api.types.Shipping;
import java.time.LocalDate;
import java.util.Arrays;
import java.util.Optional;

public class Example {
    public static void main(String[] args) {
        PayrocApiClient client = PayrocApiClient
            .builder()
            .build();

        client.tokenization().secureTokens().create(
            "1234001",
            TokenizationRequest
                .builder()
                .idempotencyKey("8e03978e-40d5-43e8-bc93-6894a57f9324")
                .source(
                    TokenizationRequestSource.card(
                        CardPayload
                            .builder()
                            .cardDetails(
                                CardPayloadCardDetails.keyed(
                                    KeyedCardDetails
                                        .builder()
                                        .keyedData(
                                            KeyedCardDetailsKeyedData.plainText(
                                                PlainTextKeyedDataFormat
                                                    .builder()
                                                    .cardNumber("4539858876047062")
                                                    .expiryDate("1230")
                                                    .cvv("234")
                                                    .build()
                                            )
                                        )
                                        .cardholderName("Sarah Hazel Hopper")
                                        .build()
                                )
                            )
                            .build()
                    )
                )
                .operator("Jane")
                .mitAgreement(TokenizationRequestMitAgreement.UNSCHEDULED)
                .customer(
                    Customer
                        .builder()
                        .firstName("Sarah")
                        .lastName("Hopper")
                        .dateOfBirth(LocalDate.parse("1990-07-15"))
                        .referenceNumber("Customer-12")
                        .billingAddress(
                            Address
                                .builder()
                                .address1("1 Example Ave.")
                                .city("Chicago")
                                .state("Illinois")
                                .country("US")
                                .postalCode("60056")
                                .address2("Example Address Line 2")
                                .address3("Example Address Line 3")
                                .build()
                        )
                        .shippingAddress(
                            Shipping
                                .builder()
                                .recipientName("Sarah Hopper")
                                .address(
                                    Address
                                        .builder()
                                        .address1("1 Example Ave.")
                                        .city("Chicago")
                                        .state("Illinois")
                                        .country("US")
                                        .postalCode("60056")
                                        .address2("Example Address Line 2")
                                        .address3("Example Address Line 3")
                                        .build()
                                )
                                .build()
                        )
                        .contactMethods(
                            Optional.of(
                                Arrays.asList(
                                    ContactMethod.email(
                                        ContactMethodEmail
                                            .builder()
                                            .value("sarah.hopper@example.com")
                                            .build()
                                    )
                                )
                            )
                        )
                        .notificationLanguage(CustomerNotificationLanguage.EN)
                        .build()
                )
                .ipAddress(
                    IpAddress
                        .builder()
                        .type(IpAddressType.IPV_4)
                        .value("104.18.24.203")
                        .build()
                )
                .customFields(
                    Optional.of(
                        Arrays.asList(
                            CustomField
                                .builder()
                                .name("yourCustomField")
                                .value("abc123")
                                .build()
                        )
                    )
                )
                .build()
        );
    }
}
```

```ruby Secure Token
require "payroc"

client = Payroc::Client.new

client.tokenization.secure_tokens.create(
  processing_terminal_id: "1234001",
  idempotency_key: "8e03978e-40d5-43e8-bc93-6894a57f9324",
  operator: "Jane",
  mit_agreement: "unscheduled",
  customer: {
    first_name: "Sarah",
    last_name: "Hopper",
    date_of_birth: "1990-07-15",
    reference_number: "Customer-12",
    billing_address: {
      address_1: "1 Example Ave.",
      city: "Chicago",
      state: "Illinois",
      country: "US",
      postal_code: "60056",
      address_2: "Example Address Line 2",
      address_3: "Example Address Line 3"
    },
    shipping_address: {
      recipient_name: "Sarah Hopper",
      address: {
        address_1: "1 Example Ave.",
        city: "Chicago",
        state: "Illinois",
        country: "US",
        postal_code: "60056",
        address_2: "Example Address Line 2",
        address_3: "Example Address Line 3"
      }
    },
    contact_methods: [],
    notification_language: "en"
  },
  ip_address: {
    type: "ipv4",
    value: "104.18.24.203"
  },
  custom_fields: [{
    name: "yourCustomField",
    value: "abc123"
  }]
)

```

```csharp Secure Token
using Payroc;
using System.Threading.Tasks;
using Payroc.Tokenization.SecureTokens;
using System;
using System.Collections.Generic;

namespace Usage;

public class Example
{
    public async Task Do() {
        var client = new PayrocClient();

        await client.Tokenization.SecureTokens.CreateAsync(
            new TokenizationRequest {
                ProcessingTerminalId = "1234001",
                IdempotencyKey = "8e03978e-40d5-43e8-bc93-6894a57f9324",
                Source = new TokenizationRequestSource(
                    new CardPayload {
                        CardDetails = new CardPayloadCardDetails(
                            new KeyedCardDetails {
                                KeyedData = new KeyedCardDetailsKeyedData(
                                    new PlainTextKeyedDataFormat {
                                        CardNumber = "4539858876047062",
                                        Cvv = "234",
                                        ExpiryDate = "1230"
                                    }
                                ),
                                CardholderName = "Sarah Hazel Hopper"
                            }
                        )
                    }
                ),
                Operator = "Jane",
                MitAgreement = TokenizationRequestMitAgreement.Unscheduled,
                Customer = new Customer {
                    FirstName = "Sarah",
                    LastName = "Hopper",
                    DateOfBirth = DateOnly.Parse("1990-07-15"),
                    ReferenceNumber = "Customer-12",
                    BillingAddress = new Address {
                        Address1 = "1 Example Ave.",
                        City = "Chicago",
                        State = "Illinois",
                        Country = "US",
                        PostalCode = "60056",
                        Address2 = "Example Address Line 2",
                        Address3 = "Example Address Line 3"
                    },
                    ShippingAddress = new Shipping {
                        RecipientName = "Sarah Hopper",
                        Address = new Address {
                            Address1 = "1 Example Ave.",
                            City = "Chicago",
                            State = "Illinois",
                            Country = "US",
                            PostalCode = "60056",
                            Address2 = "Example Address Line 2",
                            Address3 = "Example Address Line 3"
                        }
                    },
                    ContactMethods = new List<ContactMethod>(){
                        new ContactMethod(
                            new ContactMethodEmail {
                                Value = "sarah.hopper@example.com"
                            }
                        ),
                    }
                    ,
                    NotificationLanguage = CustomerNotificationLanguage.En
                },
                IpAddress = new IpAddress {
                    Type = IpAddressType.Ipv4,
                    Value = "104.18.24.203"
                },
                CustomFields = new List<CustomField>(){
                    new CustomField {
                        Name = "yourCustomField",
                        Value = "abc123"
                    },
                }

            }
        );
    }

}

```

```go Secure Token
package main

import (
	"fmt"
	"strings"
	"net/http"
	"io"
)

func main() {

	url := "https://api.payroc.com/v1/processing-terminals/1234001/secure-tokens"

	payload := strings.NewReader("{\n  \"source\": {\n    \"type\": \"card\",\n    \"cardDetails\": {\n      \"entryMethod\": \"keyed\",\n      \"keyedData\": {\n        \"dataFormat\": \"plainText\",\n        \"cardNumber\": \"4539858876047062\",\n        \"cvv\": \"234\",\n        \"expiryDate\": \"1230\"\n      },\n      \"cardholderName\": \"Sarah Hazel Hopper\"\n    }\n  },\n  \"operator\": \"Jane\",\n  \"mitAgreement\": \"unscheduled\",\n  \"customer\": {\n    \"firstName\": \"Sarah\",\n    \"lastName\": \"Hopper\",\n    \"dateOfBirth\": \"1990-07-15\",\n    \"referenceNumber\": \"Customer-12\",\n    \"billingAddress\": {\n      \"address1\": \"1 Example Ave.\",\n      \"city\": \"Chicago\",\n      \"state\": \"Illinois\",\n      \"country\": \"US\",\n      \"postalCode\": \"60056\",\n      \"address2\": \"Example Address Line 2\",\n      \"address3\": \"Example Address Line 3\"\n    },\n    \"shippingAddress\": {\n      \"recipientName\": \"Sarah Hopper\",\n      \"address\": {\n        \"address1\": \"1 Example Ave.\",\n        \"city\": \"Chicago\",\n        \"state\": \"Illinois\",\n        \"country\": \"US\",\n        \"postalCode\": \"60056\",\n        \"address2\": \"Example Address Line 2\",\n        \"address3\": \"Example Address Line 3\"\n      }\n    },\n    \"contactMethods\": [\n      {\n        \"type\": \"email\",\n        \"value\": \"sarah.hopper@example.com\"\n      }\n    ],\n    \"notificationLanguage\": \"en\"\n  },\n  \"ipAddress\": {\n    \"type\": \"ipv4\",\n    \"value\": \"104.18.24.203\"\n  },\n  \"customFields\": [\n    {\n      \"name\": \"yourCustomField\",\n      \"value\": \"abc123\"\n    }\n  ]\n}")

	req, _ := http.NewRequest("POST", url, payload)

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

$response = $client->request('POST', 'https://api.payroc.com/v1/processing-terminals/1234001/secure-tokens', [
  'body' => '{
  "source": {
    "type": "card",
    "cardDetails": {
      "entryMethod": "keyed",
      "keyedData": {
        "dataFormat": "plainText",
        "cardNumber": "4539858876047062",
        "cvv": "234",
        "expiryDate": "1230"
      },
      "cardholderName": "Sarah Hazel Hopper"
    }
  },
  "operator": "Jane",
  "mitAgreement": "unscheduled",
  "customer": {
    "firstName": "Sarah",
    "lastName": "Hopper",
    "dateOfBirth": "1990-07-15",
    "referenceNumber": "Customer-12",
    "billingAddress": {
      "address1": "1 Example Ave.",
      "city": "Chicago",
      "state": "Illinois",
      "country": "US",
      "postalCode": "60056",
      "address2": "Example Address Line 2",
      "address3": "Example Address Line 3"
    },
    "shippingAddress": {
      "recipientName": "Sarah Hopper",
      "address": {
        "address1": "1 Example Ave.",
        "city": "Chicago",
        "state": "Illinois",
        "country": "US",
        "postalCode": "60056",
        "address2": "Example Address Line 2",
        "address3": "Example Address Line 3"
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
  "ipAddress": {
    "type": "ipv4",
    "value": "104.18.24.203"
  },
  "customFields": [
    {
      "name": "yourCustomField",
      "value": "abc123"
    }
  ]
}',
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
let parameters = [
  "source": [
    "type": "card",
    "cardDetails": [
      "entryMethod": "keyed",
      "keyedData": [
        "dataFormat": "plainText",
        "cardNumber": "4539858876047062",
        "cvv": "234",
        "expiryDate": "1230"
      ],
      "cardholderName": "Sarah Hazel Hopper"
    ]
  ],
  "operator": "Jane",
  "mitAgreement": "unscheduled",
  "customer": [
    "firstName": "Sarah",
    "lastName": "Hopper",
    "dateOfBirth": "1990-07-15",
    "referenceNumber": "Customer-12",
    "billingAddress": [
      "address1": "1 Example Ave.",
      "city": "Chicago",
      "state": "Illinois",
      "country": "US",
      "postalCode": "60056",
      "address2": "Example Address Line 2",
      "address3": "Example Address Line 3"
    ],
    "shippingAddress": [
      "recipientName": "Sarah Hopper",
      "address": [
        "address1": "1 Example Ave.",
        "city": "Chicago",
        "state": "Illinois",
        "country": "US",
        "postalCode": "60056",
        "address2": "Example Address Line 2",
        "address3": "Example Address Line 3"
      ]
    ],
    "contactMethods": [
      [
        "type": "email",
        "value": "sarah.hopper@example.com"
      ]
    ],
    "notificationLanguage": "en"
  ],
  "ipAddress": [
    "type": "ipv4",
    "value": "104.18.24.203"
  ],
  "customFields": [
    [
      "name": "yourCustomField",
      "value": "abc123"
    ]
  ]
] as [String : Any]

let postData = JSONSerialization.data(withJSONObject: parameters, options: [])

let request = NSMutableURLRequest(url: NSURL(string: "https://api.payroc.com/v1/processing-terminals/1234001/secure-tokens")! as URL,
                                        cachePolicy: .useProtocolCachePolicy,
                                    timeoutInterval: 10.0)
request.httpMethod = "POST"
request.allHTTPHeaderFields = headers
request.httpBody = postData as Data

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

If your request is successful, our gateway converts the single-use token into a secure token. Our gateway returns the secure token in the token field. The response also contains the following fields:

### Schema (`response.body`)

```yaml
openapi: 3.1.0
info:
  title: API
  version: 1.0.0
paths:
  /processing-terminals/{processingTerminalId}/secure-tokens:
    post:
      operationId: create
      summary: Create secure token
      description: >
        Use this method to create a secure token that represents a customer's
        payment details.  


        When you create a secure token, you need to generate and provide a
        secureTokenId that you use to run follow-on actions:  

        - [Retrieve Secure
        Token](https://docs.payroc.com/api/schema/tokenization/secure-tokens/retrieve)
        – View the details of the secure token.  

        - [Delete Secure
        Token](https://docs.payroc.com/api/schema/tokenization/secure-tokens/delete)
        – Delete the secure token.  

        - [Update Secure
        Token](https://docs.payroc.com/api/schema/tokenization/secure-tokens/partially-update)
        – Update the details of the secure token.  

        - [Update Account
        Details](https://docs.payroc.com/api/schema/tokenization/secure-tokens/update-account)
        – Update the secure token with the details from a single-use token.  


        **Note:** If you don't generate a secureTokenId to identify the token,
        our gateway generates a unique identifier and returns it in the
        response.  


        If the request is successful, our gateway returns a token that the
        merchant can use in transactions instead of the customer's sensitive
        payment details, for example, when they [run a
        sale](https://docs.payroc.com/api/schema/card-payments/payments/create).
      tags:
        - subpackage_tokenization.subpackage_tokenization/secureTokens
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
            Successful request. We created a secure token that represents your
            customer's payment details.
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
              $ref: '#/components/schemas/tokenizationRequest'
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
    TokenizationRequestMitAgreement:
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
      title: TokenizationRequestMitAgreement
    address:
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
      required:
        - address1
        - city
        - state
        - country
        - postalCode
      description: Object that contains information about the address.
      title: address
    shipping:
      type: object
      properties:
        recipientName:
          type: string
          description: Recipient's name.
        address:
          $ref: '#/components/schemas/address'
      description: >-
        Object that contains information about the customer and their shipping
        address.
      title: shipping
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
    CustomerNotificationLanguage:
      type: string
      enum:
        - en
        - fr
      description: >
        Language that the customer uses for notifications. This code follows the
        [ISO 639-1](https://www.iso.org/iso-639-language-code) alpha-2
        standard. 
      title: CustomerNotificationLanguage
    customer:
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
          $ref: '#/components/schemas/address'
          description: >-
            Object that contains information about the address that the card is
            registered to.
        shippingAddress:
          $ref: '#/components/schemas/shipping'
        contactMethods:
          type: array
          items:
            $ref: '#/components/schemas/contactMethod'
          description: "Array of polymorphic objects, which contain contact information.  \n\nThe value of the type parameter determines which variant you should use:  \n-\t`email` - Email address \n-\t`phone` - Phone number\n-\t`mobile` - Mobile number\n-\t`fax` - Fax number\n"
        notificationLanguage:
          $ref: '#/components/schemas/CustomerNotificationLanguage'
          description: >
            Language that the customer uses for notifications. This code follows
            the [ISO 639-1](https://www.iso.org/iso-639-language-code) alpha-2
            standard. 
      description: >-
        Object that contains the customer's contact details and address
        information.
      title: customer
    IpAddressType:
      type: string
      enum:
        - ipv4
        - ipv6
      description: Internet protocol version of the IP address.
      title: IpAddressType
    ipAddress:
      type: object
      properties:
        type:
          $ref: '#/components/schemas/IpAddressType'
          description: Internet protocol version of the IP address.
        value:
          type: string
          description: IP address of the device.
      required:
        - type
        - value
      description: Object that contains the IP address of the device that sent the request.
      title: ipAddress
    BankAccountVerificationRequestBankAccountDiscriminatorMappingAchAccountType:
      type: string
      enum:
        - checking
        - savings
      description: |
        Indicates the customer’s account type.  

        **Note:** For bank account details, send a value for accountType.
      title: >-
        BankAccountVerificationRequestBankAccountDiscriminatorMappingAchAccountType
    BankAccountVerificationRequestBankAccountDiscriminatorMappingAchSecCode:
      type: string
      enum:
        - web
        - tel
        - ccd
        - ppd
      description: >
        Indicates how the customer authorized the ACH transaction. Send one of
        the following values:


        - `web` – Online transaction.

        - `tel` – Telephone transaction.

        - `ccd` – Corporate credit card or debit card transaction.

        - `ppd` – Pre-arranged transaction.


        **Note:** This field is mandatory for ACH payments and unreferenced
        refunds.
      title: BankAccountVerificationRequestBankAccountDiscriminatorMappingAchSecCode
    BankAccountVerificationRequestBankAccountDiscriminatorMappingPadAccountType:
      type: string
      enum:
        - checking
        - savings
      description: |
        Indicates the customer’s account type.  
        **Note:** For bank account details, send a value for accountType.
      title: >-
        BankAccountVerificationRequestBankAccountDiscriminatorMappingPadAccountType
    FxRateInquiryPaymentMethodDiscriminatorMappingCardAccountType:
      type: string
      enum:
        - checking
        - savings
      description: |
        Indicates the customer’s account type.  

        **Note:** Send a value for accountType only for bank account details.
      title: FxRateInquiryPaymentMethodDiscriminatorMappingCardAccountType
    FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingRawDowngradeTo:
      type: string
      enum:
        - keyed
        - swiped
      description: >
        If an offline transaction is not approved using the initial entry
        method, reprocess the transaction using a downgraded entry method.

        For example, an Integrated Circuit Card (ICC) transaction can be
        downgraded to a swiped transaction or to a keyed transaction.
      title: >-
        FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingRawDowngradeTo
    DeviceModel:
      type: string
      enum:
        - bbposChp
        - bbposChp2x
        - bbposChp3x
        - bbposRambler
        - bbposWp
        - bbposWp2
        - bbposWp3
        - genericCtlsMsr
        - genericMsr
        - idtechAugusta
        - idtechMinismart
        - idtechSredkey
        - idtechVp3300
        - idtechVp5300
        - idtechVp6300
        - idtechVp6800
        - ingenicoAxiumDx4000
        - ingenicoAxiumDx8000
        - ingenicoAxiumEx8000
        - ingenicoIct220
        - ingenicoIpp320
        - ingenicoIpp350
        - ingenicoIuc285
        - ingenicoL3000
        - ingenicoL7000
        - ingenicoS2000
        - ingenicoS3000
        - ingenicoS4000
        - ingenicoS5000
        - ingenicoS7000
        - paxA80
        - paxA920
        - paxA920Pro
        - paxA920Max
        - paxE500
        - paxE700
        - paxE800
        - paxIm30
        - uic680
        - uicBezel8
      description: Model of the device that the merchant used to process the transaction.
      title: DeviceModel
    DeviceCategory:
      type: string
      enum:
        - attended
        - unattended
      default: attended
      description: Indicates if the device is attended or unattended.
      title: DeviceCategory
    deviceConfig:
      type: object
      properties:
        quickChip:
          type: boolean
          default: false
          description: Indicates if Quick Chip mode is active on a merchant’s POS terminal.
      required:
        - quickChip
      description: >-
        Object that contains information about the configuration of the POS
        terminal.
      title: deviceConfig
    device:
      type: object
      properties:
        model:
          $ref: '#/components/schemas/DeviceModel'
          description: >-
            Model of the device that the merchant used to process the
            transaction.
        category:
          $ref: '#/components/schemas/DeviceCategory'
          default: attended
          description: Indicates if the device is attended or unattended.
        serialNumber:
          type: string
          description: Serial number of the physical device.
        firmwareVersion:
          type: string
          description: Firmware version of the physical device.
        config:
          $ref: '#/components/schemas/deviceConfig'
      required:
        - model
        - serialNumber
      description: >-
        Object that contains information about the physical device the merchant
        used to capture the customer’s card details.
      title: device
    FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingIccDowngradeTo:
      type: string
      enum:
        - keyed
        - swiped
      description: >
        If an offline transaction is not approved using the initial entry
        method, reprocess the transaction using a downgraded entry method. 

        For example, an Integrated Circuit Card (ICC) transaction can be
        downgraded to a swiped transaction or a keyed transaction.
      title: >-
        FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingIccDowngradeTo
    EncryptionCapableDeviceModel:
      type: string
      enum:
        - bbposChp
        - bbposChp2x
        - bbposChp3x
        - bbposRambler
        - bbposWp
        - bbposWp2
        - bbposWp3
        - genericCtlsMsr
        - genericMsr
        - idtechAugusta
        - idtechMinismart
        - idtechSredkey
        - idtechVp3300
        - idtechVp5300
        - idtechVp6300
        - idtechVp6800
        - ingenicoAxiumDx4000
        - ingenicoAxiumDx8000
        - ingenicoAxiumEx8000
        - ingenicoIct220
        - ingenicoIpp320
        - ingenicoIpp350
        - ingenicoIuc285
        - ingenicoL3000
        - ingenicoL7000
        - ingenicoS2000
        - ingenicoS3000
        - ingenicoS4000
        - ingenicoS5000
        - ingenicoS7000
        - paxA80
        - paxA920
        - paxA920Pro
        - paxA920Max
        - paxE500
        - paxE700
        - paxE800
        - paxIm30
        - uic680
        - uicBezel8
      description: Model of the device that the merchant used to process the transaction.
      title: EncryptionCapableDeviceModel
    EncryptionCapableDeviceCategory:
      type: string
      enum:
        - attended
        - unattended
      default: attended
      description: Indicates if the device is attended or unattended.
      title: EncryptionCapableDeviceCategory
    encryptionCapableDevice:
      type: object
      properties:
        model:
          $ref: '#/components/schemas/EncryptionCapableDeviceModel'
          description: >-
            Model of the device that the merchant used to process the
            transaction.
        category:
          $ref: '#/components/schemas/EncryptionCapableDeviceCategory'
          default: attended
          description: Indicates if the device is attended or unattended.
        serialNumber:
          type: string
          description: Serial number of the physical device.
        firmwareVersion:
          type: string
          description: Firmware version of the physical device.
        config:
          $ref: '#/components/schemas/deviceConfig'
        dataKsn:
          type: string
          format: hexadecimal
          description: Key serial number.
      required:
        - model
        - serialNumber
        - dataKsn
      description: >-
        Object that contains information about the encryption details of the POS
        terminal.
      title: encryptionCapableDevice
    EbtDetailsWithVoucherBenefitCategory:
      type: string
      enum:
        - cash
        - foodStamp
      description: >
        Indicates if the balance relates to an EBT Cash account or an EBT SNAP
        account.  
         - `cash` – EBT Cash  
         - `foodStamp` – EBT SNAP
      title: EbtDetailsWithVoucherBenefitCategory
    voucher:
      type: object
      properties:
        approvalCode:
          type: string
          description: Authorization code that the processor issued for the transaction.
        serialNumber:
          type: string
          description: Serial number of the voucher.
      required:
        - approvalCode
        - serialNumber
      description: |
        Object that contains information about the EBT voucher.  

        **Note:** Vouchers are available only for EBT SNAP payments.
      title: voucher
    ebtDetailsWithVoucher:
      type: object
      properties:
        benefitCategory:
          $ref: '#/components/schemas/EbtDetailsWithVoucherBenefitCategory'
          description: >
            Indicates if the balance relates to an EBT Cash account or an EBT
            SNAP account.  
             - `cash` – EBT Cash  
             - `foodStamp` – EBT SNAP
        withdrawal:
          type: boolean
          description: >
            Indicates whether the customer wants to withdraw cash.  


            **Note:** Cash withdrawals are available only from EBT Cash
            accounts.
        voucher:
          $ref: '#/components/schemas/voucher'
      required:
        - benefitCategory
      description: >-
        Object that contains information about the Electronic Benefit Transfer
        (EBT) transaction.
      title: ebtDetailsWithVoucher
    FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingKeyedKeyedData:
      oneOf:
        - type: object
          properties:
            dataFormat:
              type: string
              enum:
                - fullyEncrypted
              description: 'Discriminator value: fullyEncrypted'
            device:
              $ref: '#/components/schemas/encryptionCapableDevice'
            encryptedData:
              type: string
              format: hexadecimal
              description: Encrypted card data.
            firstDigitOfPan:
              type: string
              description: First digit of the customer’s card number.
          required:
            - dataFormat
            - device
            - encryptedData
          description: >-
            Object that contains information about the encrypted card data for
            keyed transactions.
        - type: object
          properties:
            dataFormat:
              type: string
              enum:
                - partiallyEncrypted
              description: 'Discriminator value: partiallyEncrypted'
            device:
              $ref: '#/components/schemas/encryptionCapableDevice'
            encryptedPan:
              type: string
              format: hexadecimal
              description: Encrypted card number.
            maskedPan:
              type: string
              description: >
                Masked card number. 

                The gateway shows only the first six digits and the last four
                digits of the account number. For example, `453985******7062`.
            expiryDate:
              type: string
              description: Expiry date of the customer’s card.
            cvv:
              type: string
              description: Security code of the customer’s card.
            cvvEncrypted:
              type: string
              format: hexadecimal
              description: Encrypted security code data.
            issueNumber:
              type: string
              description: Issue number of the customer’s card.
          required:
            - dataFormat
            - device
            - encryptedPan
            - maskedPan
            - expiryDate
          description: >-
            Object that contains information about the partially-encrypted card
            data for keyed transactions.
        - type: object
          properties:
            dataFormat:
              type: string
              enum:
                - plainText
              description: 'Discriminator value: plainText'
            device:
              $ref: '#/components/schemas/device'
            cardNumber:
              type: string
              description: Customer’s card number.
            expiryDate:
              type: string
              description: >
                Expiry date of the customer’s card.  

                **Note:** We require you to send an expiry date for most BIN
                lookups and electronic voucher transactions.
            cvv:
              type: string
              description: Security code of the customer’s card.
            issueNumber:
              type: string
              description: Issue number of the customer’s card.
          required:
            - dataFormat
            - cardNumber
          description: >-
            Object that contains information about the plain-text card data for
            keyed transactions.
      discriminator:
        propertyName: dataFormat
      description: "Polymorphic object that contains payment card details that the merchant manually entered into the device.  \n\nThe value of the dataFormat parameter determines which variant you should use:  \n-\t`fullyEncrypted` - All payment card details are encrypted.\n-\t`partiallyEncrypted` - Some payment card details are encrypted.\n-\t`plainText` - Payment card details are in plain text.\n"
      title: >-
        FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingKeyedKeyedData
    FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingKeyedPinDetails:
      oneOf:
        - type: object
          properties:
            dataFormat:
              type: string
              enum:
                - dukpt
              description: 'Discriminator value: dukpt'
            pin:
              type: string
              format: hexadecimal
              description: |
                Encrypted PIN.  
                **Note:** PIN is encrypted using the DUKPT scheme.
            pinKsn:
              type: string
              format: hexadecimal
              description: Key serial number.
          required:
            - dataFormat
            - pin
            - pinKsn
          description: Object that contains information about encrypted PIN details.
      discriminator:
        propertyName: dataFormat
      description: Polymorphic object that contains information about the customer's PIN.
      title: >-
        FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingKeyedPinDetails
    FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedDowngradeTo:
      type: string
      enum:
        - keyed
        - swiped
      description: >
        If an offline transaction is not approved using the initial entry
        method, reprocess the transaction using a downgraded entry method. 

        For example, a swiped transaction can be downgraded to a keyed
        transaction.
      title: >-
        FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedDowngradeTo
    FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedSwipedDataDiscriminatorMappingEncryptedFallbackReason:
      type: string
      enum:
        - technical
        - repeatFallback
        - emptyCandidateList
      description: Reason for the fallback.
      title: >-
        FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedSwipedDataDiscriminatorMappingEncryptedFallbackReason
    FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedSwipedDataDiscriminatorMappingPlainTextFallbackReason:
      type: string
      enum:
        - technical
        - repeatFallback
        - emptyCandidateList
      description: Reason for the fallback.
      title: >-
        FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedSwipedDataDiscriminatorMappingPlainTextFallbackReason
    FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedSwipedData:
      oneOf:
        - type: object
          properties:
            dataFormat:
              type: string
              enum:
                - encrypted
              description: 'Discriminator value: encrypted'
            device:
              $ref: '#/components/schemas/encryptionCapableDevice'
            encryptedData:
              type: string
              format: hexadecimal
              description: Encrypted data received from the magnetic stripe reader.
            firstDigitOfPan:
              type: string
              description: First digit of the of the card number.
            fallback:
              type: boolean
              description: >-
                Indicates that this is a fallback transaction. For example, if
                there was a technical issue with the chip on the customer's card
                and the merchant then swiped the card.
            fallbackReason:
              $ref: >-
                #/components/schemas/FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedSwipedDataDiscriminatorMappingEncryptedFallbackReason
              description: Reason for the fallback.
          required:
            - dataFormat
            - device
            - encryptedData
          description: >-
            Object that contains information about the encrypted swiped card
            data.
        - type: object
          properties:
            dataFormat:
              type: string
              enum:
                - plainText
              description: 'Discriminator value: plainText'
            device:
              $ref: '#/components/schemas/device'
            trackData:
              type: string
              description: Customer’s card data from the swiped transaction.
            fallback:
              type: boolean
              description: >-
                Indicates that this is a fallback transaction. For example, if
                there was a technical issue with the chip on the customer's card
                and the merchant then swiped the card.
            fallbackReason:
              $ref: >-
                #/components/schemas/FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedSwipedDataDiscriminatorMappingPlainTextFallbackReason
              description: Reason for the fallback.
          required:
            - dataFormat
            - device
            - trackData
          description: Object that contains information about plain-text swiped card data.
      discriminator:
        propertyName: dataFormat
      description: "Polymorphic object that contains payment card details that a device captured from the magnetic strip.  \n\nThe value of the dataFormat parameter determines which variant you should use:  \n-\t`encrypted` - Payment card details are encrypted.\n-\t`plainText` - Payment card details are in plain text.\n"
      title: >-
        FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedSwipedData
    FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedPinDetails:
      oneOf:
        - type: object
          properties:
            dataFormat:
              type: string
              enum:
                - dukpt
              description: 'Discriminator value: dukpt'
            pin:
              type: string
              format: hexadecimal
              description: |
                Encrypted PIN.  
                **Note:** PIN is encrypted using the DUKPT scheme.
            pinKsn:
              type: string
              format: hexadecimal
              description: Key serial number.
          required:
            - dataFormat
            - pin
            - pinKsn
          description: Object that contains information about encrypted PIN details.
      discriminator:
        propertyName: dataFormat
      description: Polymorphic object that contains information about the customer's PIN.
      title: >-
        FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedPinDetails
    FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetails:
      oneOf:
        - type: object
          properties:
            entryMethod:
              type: string
              enum:
                - raw
              description: 'Discriminator value: raw'
            downgradeTo:
              $ref: >-
                #/components/schemas/FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingRawDowngradeTo
              description: >
                If an offline transaction is not approved using the initial
                entry method, reprocess the transaction using a downgraded entry
                method.

                For example, an Integrated Circuit Card (ICC) transaction can be
                downgraded to a swiped transaction or to a keyed transaction.
            device:
              $ref: '#/components/schemas/device'
            rawData:
              type: string
              format: hexadecimal
              description: Unencrypted data from the POS terminal.
            cardholderSignature:
              type: string
              description: >-
                Cardholder's signature. For more information about how to format
                the signature, go to [How to send a signature to our
                gateway](https://docs.payroc.com/knowledge/basic-concepts/signature-capture).
          required:
            - entryMethod
            - device
            - rawData
          description: Object that contains information about the unencrypted card details.
        - type: object
          properties:
            entryMethod:
              type: string
              enum:
                - icc
              description: 'Discriminator value: icc'
            downgradeTo:
              $ref: >-
                #/components/schemas/FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingIccDowngradeTo
              description: >
                If an offline transaction is not approved using the initial
                entry method, reprocess the transaction using a downgraded entry
                method. 

                For example, an Integrated Circuit Card (ICC) transaction can be
                downgraded to a swiped transaction or a keyed transaction.
            device:
              $ref: '#/components/schemas/encryptionCapableDevice'
            iccData:
              type: string
              format: hexadecimal
              description: >-
                Cardholder data from the ICC. The data consists of EMV tags in
                Tag-Length-Value (TLV) format.
            firstDigitOfPan:
              type: string
              description: First digit of the card number.
            cardholderSignature:
              type: string
              description: >-
                Cardholder's signature. For more information about how to format
                the signature, go to [How to send a signature to our
                gateway](https://docs.payroc.com/knowledge/basic-concepts/signature-capture).
            ebtDetails:
              $ref: '#/components/schemas/ebtDetailsWithVoucher'
          required:
            - entryMethod
            - device
            - iccData
          description: >-
            Object that contains information about the Integrated Circuit Card
            (ICC).
        - type: object
          properties:
            entryMethod:
              type: string
              enum:
                - keyed
              description: 'Discriminator value: keyed'
            keyedData:
              $ref: >-
                #/components/schemas/FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingKeyedKeyedData
              description: "Polymorphic object that contains payment card details that the merchant manually entered into the device.  \n\nThe value of the dataFormat parameter determines which variant you should use:  \n-\t`fullyEncrypted` - All payment card details are encrypted.\n-\t`partiallyEncrypted` - Some payment card details are encrypted.\n-\t`plainText` - Payment card details are in plain text.\n"
            cardholderName:
              type: string
              description: Cardholder’s name.
            cardholderSignature:
              type: string
              description: >-
                Cardholder's signature. For more information about how to format
                the signature, go to [How to send a signature to our
                gateway](https://docs.payroc.com/knowledge/basic-concepts/signature-capture).
            pinDetails:
              $ref: >-
                #/components/schemas/FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingKeyedPinDetails
              description: >-
                Polymorphic object that contains information about the
                customer's PIN.
            ebtDetails:
              $ref: '#/components/schemas/ebtDetailsWithVoucher'
          required:
            - entryMethod
            - keyedData
          description: Object that contains information about the keyed card details.
        - type: object
          properties:
            entryMethod:
              type: string
              enum:
                - swiped
              description: 'Discriminator value: swiped'
            downgradeTo:
              $ref: >-
                #/components/schemas/FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedDowngradeTo
              description: >
                If an offline transaction is not approved using the initial
                entry method, reprocess the transaction using a downgraded entry
                method. 

                For example, a swiped transaction can be downgraded to a keyed
                transaction.
            swipedData:
              $ref: >-
                #/components/schemas/FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedSwipedData
              description: "Polymorphic object that contains payment card details that a device captured from the magnetic strip.  \n\nThe value of the dataFormat parameter determines which variant you should use:  \n-\t`encrypted` - Payment card details are encrypted.\n-\t`plainText` - Payment card details are in plain text.\n"
            cardholderName:
              type: string
              description: Cardholder’s name.
            cardholderSignature:
              type: string
              description: >-
                Cardholder's signature. For more information about how to format
                the signature, go to [How to send a signature to our
                gateway](https://docs.payroc.com/knowledge/basic-concepts/signature-capture).
            pinDetails:
              $ref: >-
                #/components/schemas/FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetailsDiscriminatorMappingSwipedPinDetails
              description: >-
                Polymorphic object that contains information about the
                customer's PIN.
            ebtDetails:
              $ref: '#/components/schemas/ebtDetailsWithVoucher'
          required:
            - entryMethod
            - swipedData
          description: >-
            Object that contains information about the customer’s card details
            for swiped transactions.
      discriminator:
        propertyName: entryMethod
      description: >
        Polymorphic object that contains payment card information.  


        The value of the entryMethod parameter determines which variant you
        should use:  

        - `raw` - Unencrypted payment data directly from the device.

        - `icc` - Payment data that the device captured from the chip.

        - `keyed` - Payment data that the merchant entered manually.

        - `swiped` - Payment data that the device captured from the magnetic
        strip.
      title: FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetails
    BankTransferPaymentRequestPaymentMethodDiscriminatorMappingSingleUseTokenAccountType:
      type: string
      enum:
        - checking
        - savings
      description: >
        Indicates the customer’s account type.  


        **Note:** Send a value for accountType only if the single-use token
        represents bank account details.
      title: >-
        BankTransferPaymentRequestPaymentMethodDiscriminatorMappingSingleUseTokenAccountType
    BankTransferPaymentRequestPaymentMethodDiscriminatorMappingSingleUseTokenPinDetails:
      oneOf:
        - type: object
          properties:
            dataFormat:
              type: string
              enum:
                - dukpt
              description: 'Discriminator value: dukpt'
            pin:
              type: string
              format: hexadecimal
              description: |
                Encrypted PIN.  
                **Note:** PIN is encrypted using the DUKPT scheme.
            pinKsn:
              type: string
              format: hexadecimal
              description: Key serial number.
          required:
            - dataFormat
            - pin
            - pinKsn
          description: Object that contains information about encrypted PIN details.
        - type: object
          properties:
            dataFormat:
              type: string
              enum:
                - raw
              description: 'Discriminator value: raw'
            pin:
              type: string
              description: Customer’s unencrypted PIN.
          required:
            - dataFormat
            - pin
          description: Object that contains information about the unencrypted PIN details.
      discriminator:
        propertyName: dataFormat
      description: >
        Polymorphic object that contains information about a customer's PIN.  


        The value of the dataFormat parameter determines which variant you
        should use:  

        - `dukpt` - PIN information is encrypted.

        - `raw` - PIN information is unencrypted.
      title: >-
        BankTransferPaymentRequestPaymentMethodDiscriminatorMappingSingleUseTokenPinDetails
    BankTransferPaymentRequestPaymentMethodDiscriminatorMappingSingleUseTokenSecCode:
      type: string
      enum:
        - web
        - tel
        - ccd
        - ppd
      description: >
        Indicates how the customer authorized the ACH transaction. Send one of
        the following values:


        - `web` – Online transaction.

        - `tel` – Telephone transaction.

        - `ccd` – Corporate credit card or debit card transaction.

        - `ppd` – Pre-arranged transaction.


        **Note:** This field is mandatory when the single-use token represents
        ACH bank account details.
      title: >-
        BankTransferPaymentRequestPaymentMethodDiscriminatorMappingSingleUseTokenSecCode
    TokenizationRequestSource:
      oneOf:
        - type: object
          properties:
            type:
              type: string
              enum:
                - ach
              description: 'Discriminator value: ach'
            accountType:
              $ref: >-
                #/components/schemas/BankAccountVerificationRequestBankAccountDiscriminatorMappingAchAccountType
              description: >
                Indicates the customer’s account type.  


                **Note:** For bank account details, send a value for
                accountType.
            secCode:
              $ref: >-
                #/components/schemas/BankAccountVerificationRequestBankAccountDiscriminatorMappingAchSecCode
              description: >
                Indicates how the customer authorized the ACH transaction. Send
                one of the following values:


                - `web` – Online transaction.

                - `tel` – Telephone transaction.

                - `ccd` – Corporate credit card or debit card transaction.

                - `ppd` – Pre-arranged transaction.


                **Note:** This field is mandatory for ACH payments and
                unreferenced refunds.
            nameOnAccount:
              type: string
              description: Customer's name.
            accountNumber:
              type: string
              description: >
                Customer’s bank account number.  

                **Note:** In responses, our gateway shows only the last four
                digits of the account number, for example, `*****5929`.
            routingNumber:
              type: string
              description: Nine-digit number that identifies the customer's bank.
          required:
            - type
            - nameOnAccount
            - accountNumber
            - routingNumber
          description: >-
            Object that contains information about the payment details for the
            customer’s automated clearing house (ACH) transactions.
        - type: object
          properties:
            type:
              type: string
              enum:
                - pad
              description: 'Discriminator value: pad'
            accountType:
              $ref: >-
                #/components/schemas/BankAccountVerificationRequestBankAccountDiscriminatorMappingPadAccountType
              description: >
                Indicates the customer’s account type.  

                **Note:** For bank account details, send a value for
                accountType.
            nameOnAccount:
              type: string
              description: Customer's name.
            accountNumber:
              type: string
              description: >
                Customer's account number.  

                **Note:** In responses, our gateway shows only the last four
                digits of the account number, for example, `*****5929`.
            transitNumber:
              type: string
              description: Five-digit number that identifies the customer's bank branch.
            institutionNumber:
              type: string
              description: Three-digit number that identifies the customer's bank.
          required:
            - type
            - nameOnAccount
            - accountNumber
            - transitNumber
            - institutionNumber
          description: >-
            Object that contains information about the payment details for the
            customer’s preauthorized electronic debit (PAD) transactions.
        - type: object
          properties:
            type:
              type: string
              enum:
                - card
              description: 'Discriminator value: card'
            accountType:
              $ref: >-
                #/components/schemas/FxRateInquiryPaymentMethodDiscriminatorMappingCardAccountType
              description: >
                Indicates the customer’s account type.  


                **Note:** Send a value for accountType only for bank account
                details.
            cardDetails:
              $ref: >-
                #/components/schemas/FxRateInquiryPaymentMethodDiscriminatorMappingCardCardDetails
              description: >
                Polymorphic object that contains payment card information.  


                The value of the entryMethod parameter determines which variant
                you should use:  

                - `raw` - Unencrypted payment data directly from the device.

                - `icc` - Payment data that the device captured from the chip.

                - `keyed` - Payment data that the merchant entered manually.

                - `swiped` - Payment data that the device captured from the
                magnetic strip.
          required:
            - type
            - cardDetails
          description: Object that contains information about the customer’s payment card.
        - type: object
          properties:
            type:
              type: string
              enum:
                - singleUseToken
              description: 'Discriminator value: singleUseToken'
            accountType:
              $ref: >-
                #/components/schemas/BankTransferPaymentRequestPaymentMethodDiscriminatorMappingSingleUseTokenAccountType
              description: >
                Indicates the customer’s account type.  


                **Note:** Send a value for accountType only if the single-use
                token represents bank account details.
            token:
              type: string
              description: Unique token that the gateway assigned to the payment details.
            pinDetails:
              $ref: >-
                #/components/schemas/BankTransferPaymentRequestPaymentMethodDiscriminatorMappingSingleUseTokenPinDetails
              description: >
                Polymorphic object that contains information about a customer's
                PIN.  


                The value of the dataFormat parameter determines which variant
                you should use:  

                - `dukpt` - PIN information is encrypted.

                - `raw` - PIN information is unencrypted.
            ebtDetails:
              $ref: '#/components/schemas/ebtDetailsWithVoucher'
            secCode:
              $ref: >-
                #/components/schemas/BankTransferPaymentRequestPaymentMethodDiscriminatorMappingSingleUseTokenSecCode
              description: >
                Indicates how the customer authorized the ACH transaction. Send
                one of the following values:


                - `web` – Online transaction.

                - `tel` – Telephone transaction.

                - `ccd` – Corporate credit card or debit card transaction.

                - `ppd` – Pre-arranged transaction.


                **Note:** This field is mandatory when the single-use token
                represents ACH bank account details.
          required:
            - type
            - token
          description: >-
            Object that contains information about the single-use token, which
            represents the customer’s payment details.
      discriminator:
        propertyName: type
      description: "Polymorphic object that contains the payment method to tokenize.  \n\nThe value of the type parameter determines which variant you should use:  \n-\t`ach` - Automated Clearing House (ACH) details\n-\t`pad` - Pre-authorized debit (PAD) details\n-\t`card` - Payment card details\n-\t`singleUseToken` - Single-use token details\n"
      title: TokenizationRequestSource
    PaymentRequestThreeDSecureDiscriminatorMappingThirdPartyEci:
      type: string
      enum:
        - fullyAuthenticated
        - attemptedAuthentication
      description: E-commerce indicator (ECI) result of a the 3-D Secure check.
      title: PaymentRequestThreeDSecureDiscriminatorMappingThirdPartyEci
    TokenizationRequestThreeDSecure:
      oneOf:
        - type: object
          properties:
            type:
              type: string
              enum:
                - gatewayThreeDSecure
              description: 'Discriminator value: gatewayThreeDSecure'
            mpiReference:
              type: string
              description: >-
                Reference that our gateway assigned to the 3-D Secure
                authentication response.
          required:
            - type
            - mpiReference
          description: Object that contains the 3-D Secure information from our gateway.
        - type: object
          properties:
            type:
              type: string
              enum:
                - thirdPartyThreeDSecure
              description: 'Discriminator value: thirdPartyThreeDSecure'
            eci:
              $ref: >-
                #/components/schemas/PaymentRequestThreeDSecureDiscriminatorMappingThirdPartyEci
              description: E-commerce indicator (ECI) result of a the 3-D Secure check.
            xid:
              type: string
              description: >-
                Unique transaction identifier that the merchant assigned to the
                transaction and sent in the authentication request.
            cavv:
              type: string
              description: >-
                Cardholder Authentication Verification Value (CAVV) that the
                card issuer provided to prove that they authorized the online
                payment.
            dsTransactionId:
              type: string
              description: >-
                Directory Server Transaction ID that the processor assigned to
                the request.
          required:
            - type
            - eci
          description: Object that contains the 3-D Secure information from a third party.
      discriminator:
        propertyName: type
      description: "Polymorphic object that contains authentication information from 3-D Secure.  \n\nThe value of the type parameter determines which variant you should use:  \n-\t`gatewayThreeDSecure` - Use our gateway to run a 3-D Secure check.\n-\t`thirdPartyThreeDSecure` - Use a third party to run a 3-D Secure check.\n"
      title: TokenizationRequestThreeDSecure
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
    tokenizationRequest:
      type: object
      properties:
        secureTokenId:
          type: string
          description: >
            Unique identifier that the merchant created for the secure token
            that represents the customer's payment details. 

            If the merchant doesn't create a secureTokenId, the gateway
            generates one and returns it in the response.
        operator:
          type: string
          description: Operator who saved the customer's payment details.
        mitAgreement:
          $ref: '#/components/schemas/TokenizationRequestMitAgreement'
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
          $ref: '#/components/schemas/customer'
        ipAddress:
          $ref: '#/components/schemas/ipAddress'
        source:
          $ref: '#/components/schemas/TokenizationRequestSource'
          description: "Polymorphic object that contains the payment method to tokenize.  \n\nThe value of the type parameter determines which variant you should use:  \n-\t`ach` - Automated Clearing House (ACH) details\n-\t`pad` - Pre-authorized debit (PAD) details\n-\t`card` - Payment card details\n-\t`singleUseToken` - Single-use token details\n"
        threeDSecure:
          $ref: '#/components/schemas/TokenizationRequestThreeDSecure'
          description: "Polymorphic object that contains authentication information from 3-D Secure.  \n\nThe value of the type parameter determines which variant you should use:  \n-\t`gatewayThreeDSecure` - Use our gateway to run a 3-D Secure check.\n-\t`thirdPartyThreeDSecure` - Use a third party to run a 3-D Secure check.\n"
        customFields:
          type: array
          items:
            $ref: '#/components/schemas/customField'
          description: |
            Array of customField objects.
      required:
        - source
      title: tokenizationRequest
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

### Response example

### Response (201)

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

## Step 3. (Optional) Run a sale with the secure token

To run a sale with the secure token, the method that you need to follow depends on whether the secure token represents card details or bank account details.

Use the same methods that you used in [Run a Sale](../run-a-sale), but update the following parameters in the paymentMethod object:

* **type** - Change the value to `secureToken`.
* **token** -  Include the secure token that you received in Step 2.