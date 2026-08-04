# Serden API Reference

**Base URL:** `https://apiservice.lemonglacier-62b8e153.westus2.azurecontainerapps.io/api`  
**Total operations:** 267

> Field notation: type *(null)* = nullable, **req** = required in body

## Table of Contents

- [Categories](#categories)
- [Clients](#clients)
- [ContactUs](#contactus)
- [Discussions](#discussions)
- [EmailSignups](#emailsignups)
- [EstimateFiles](#estimatefiles)
- [EstimateLineItemPhotos](#estimatelineitemphotos)
- [EstimatePhotos](#estimatephotos)
- [Estimates](#estimates)
- [Insights](#insights)
- [InvoiceFiles](#invoicefiles)
- [InvoiceLineItemPhotos](#invoicelineitemphotos)
- [InvoicePhotos](#invoicephotos)
- [Invoices](#invoices)
- [LineItems](#lineitems)
- [LoginHistory](#loginhistory)
- [Notifications](#notifications)
- [Pages](#pages)
- [PasswordResetTokens](#passwordresettokens)
- [ProCategories](#procategories)
- [ProProjectPhotos](#proprojectphotos)
- [ProReviews](#proreviews)
- [ProSearch](#prosearch)
- [Pros](#pros)
- [Replies](#replies)
- [RequestQuotes](#requestquotes)
- [SellYourProperty](#sellyourproperty)
- [ServiceTags](#servicetags)
- [SmsCampaigns](#smscampaigns)
- [States](#states)
- [Stripe](#stripe)
- [Subcategories](#subcategories)
- [SubscriptionUsage](#subscriptionusage)
- [Taxes](#taxes)
- [UserSubscriptions](#usersubscriptions)
- [Users](#users)
- [ZipCodes](#zipcodes)

---

## Categories

### `GET /api/Categories`

**Responses:**
- `200`: OK → array of `Category`
  - `categoryId`: integer/int32
  - `categoryName`: string *(null)*
  - `description`: string *(null)*
  - `slug`: string *(null)*
  - `displayAtHomePage`: boolean
  - `sortNo`: integer/int32
  - `backgroundImage`: string *(null)*
  - `publicId`: string/uuid
  - `isActive`: boolean
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time
  - `subcategories`: array of `Subcategory` *(null)*

---

### `POST /api/Categories`

**Request body:**
Schema: `CategoryViewModel`
  - `categoryId`: integer/int32
  - `categoryName`: string **req**
  - `slug`: string *(null)*
  - `sortNo`: integer/int32
  - `displayAtHomePage`: boolean
  - `backgroundImage`: string *(null)*
  - `isActive`: boolean
  - `publicId`: string/uuid

**Responses:**
- `200`: OK → `Category`
  - `categoryId`: integer/int32
  - `categoryName`: string *(null)*
  - `description`: string *(null)*
  - `slug`: string *(null)*
  - `displayAtHomePage`: boolean
  - `sortNo`: integer/int32
  - `backgroundImage`: string *(null)*
  - `publicId`: string/uuid
  - `isActive`: boolean
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time
  - `subcategories`: array of `Subcategory` *(null)*

---

### `GET /api/Categories/home`

**Responses:**
- `200`: OK → array of `CategoryViewModel`
  - `categoryId`: integer/int32
  - `categoryName`: string **req**
  - `slug`: string *(null)*
  - `sortNo`: integer/int32
  - `displayAtHomePage`: boolean
  - `backgroundImage`: string *(null)*
  - `isActive`: boolean
  - `publicId`: string/uuid

---

### `GET /api/Categories/slug`

**Parameters:**
- `slug` (query): string

**Responses:**
- `200`: OK → `CategoryViewModel`
  - `categoryId`: integer/int32
  - `categoryName`: string **req**
  - `slug`: string *(null)*
  - `sortNo`: integer/int32
  - `displayAtHomePage`: boolean
  - `backgroundImage`: string *(null)*
  - `isActive`: boolean
  - `publicId`: string/uuid

---

### `DELETE /api/Categories/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Responses:**
- `200`: OK

---

### `GET /api/Categories/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Responses:**
- `200`: OK → `Category`
  - `categoryId`: integer/int32
  - `categoryName`: string *(null)*
  - `description`: string *(null)*
  - `slug`: string *(null)*
  - `displayAtHomePage`: boolean
  - `sortNo`: integer/int32
  - `backgroundImage`: string *(null)*
  - `publicId`: string/uuid
  - `isActive`: boolean
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time
  - `subcategories`: array of `Subcategory` *(null)*

---

### `PUT /api/Categories/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Request body:**
Schema: `CategoryViewModel`
  - `categoryId`: integer/int32
  - `categoryName`: string **req**
  - `slug`: string *(null)*
  - `sortNo`: integer/int32
  - `displayAtHomePage`: boolean
  - `backgroundImage`: string *(null)*
  - `isActive`: boolean
  - `publicId`: string/uuid

**Responses:**
- `200`: OK

---

### `DELETE /api/Categories/{id}/delete-image`

**Parameters:**
- `id` (path): integer/int32 **req**

**Responses:**
- `200`: OK

---

### `POST /api/Categories/{id}/upload-image`

**Parameters:**
- `id` (path): integer/int32 **req**

**Request body:**
  - `file`: string/binary

**Responses:**
- `200`: OK → `ImageUploadResponse`
  - `imageUrl`: string *(null)*

---

## Clients

### `POST /api/Clients`

**Request body:**
Schema: `ClientViewModel`
  - `clientId`: integer/int32
  - `proId`: integer/int32
  - `publicId`: string *(null)*
  - `name`: string *(null)*
  - `email`: string *(null)*
  - `phoneMobile`: string *(null)*
  - `phoneOther`: string *(null)*
  - `address`: string *(null)*
  - `address2`: string *(null)*
  - `city`: string *(null)*
  - `state`: string *(null)*
  - `zipCode`: string *(null)*
  - `privateNotes`: string *(null)*
  - `isActive`: boolean
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time *(null)*

**Responses:**
- `200`: OK → `ClientViewModel`
  - `clientId`: integer/int32
  - `proId`: integer/int32
  - `publicId`: string *(null)*
  - `name`: string *(null)*
  - `email`: string *(null)*
  - `phoneMobile`: string *(null)*
  - `phoneOther`: string *(null)*
  - `address`: string *(null)*
  - `address2`: string *(null)*
  - `city`: string *(null)*
  - `state`: string *(null)*
  - `zipCode`: string *(null)*
  - `privateNotes`: string *(null)*
  - `isActive`: boolean
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time *(null)*

---

### `GET /api/Clients/pro/{proId}`

**Parameters:**
- `proId` (path): integer/int32 **req**
- `searchTerm` (query): string
- `sortBy` (query): string default=`name`
- `sortDirection` (query): string default=`asc`
- `pageIndex` (query): integer/int32 default=`1`
- `pageSize` (query): integer/int32 default=`20`

**Responses:**
- `200`: OK → array of `ClientListViewModel`
  - `clientId`: integer/int32
  - `name`: string *(null)*
  - `email`: string *(null)*
  - `phoneMobile`: string *(null)*
  - `city`: string *(null)*
  - `state`: string *(null)*
  - `createdDate`: string/date-time

---

### `GET /api/Clients/pro/{proId}/count`

**Parameters:**
- `proId` (path): integer/int32 **req**

**Responses:**
- `200`: OK → integer/int32

---

### `DELETE /api/Clients/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Responses:**
- `200`: OK

---

### `GET /api/Clients/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Responses:**
- `200`: OK → `ClientViewModel`
  - `clientId`: integer/int32
  - `proId`: integer/int32
  - `publicId`: string *(null)*
  - `name`: string *(null)*
  - `email`: string *(null)*
  - `phoneMobile`: string *(null)*
  - `phoneOther`: string *(null)*
  - `address`: string *(null)*
  - `address2`: string *(null)*
  - `city`: string *(null)*
  - `state`: string *(null)*
  - `zipCode`: string *(null)*
  - `privateNotes`: string *(null)*
  - `isActive`: boolean
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time *(null)*

---

### `PUT /api/Clients/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Request body:**
Schema: `ClientViewModel`
  - `clientId`: integer/int32
  - `proId`: integer/int32
  - `publicId`: string *(null)*
  - `name`: string *(null)*
  - `email`: string *(null)*
  - `phoneMobile`: string *(null)*
  - `phoneOther`: string *(null)*
  - `address`: string *(null)*
  - `address2`: string *(null)*
  - `city`: string *(null)*
  - `state`: string *(null)*
  - `zipCode`: string *(null)*
  - `privateNotes`: string *(null)*
  - `isActive`: boolean
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time *(null)*

**Responses:**
- `200`: OK

---

## ContactUs

### `POST /api/ContactUs`

**Request body:**
Schema: `ContactViewModel`
  - `name`: string **req**
  - `company`: string *(null)*
  - `email`: string/email **req**
  - `phone`: string/tel **req**
  - `subject`: string **req**
  - `description`: string *(null)*
  - `turnstileToken`: string **req**

**Responses:**
- `200`: OK → boolean

---

## Discussions

### `GET /api/Discussions`

**Parameters:**
- `subcategoryslug` (query): string
- `questionsearch` (query): string default=``
- `pageNumber` (query): integer/int32 default=`1`
- `pageSize` (query): integer/int32 default=`10`

**Responses:**
- `200`: OK → array of `DiscussionDto`
  - `discussionID`: integer/int32
  - `question`: string *(null)*
  - `description`: string *(null)*
  - `slug`: string *(null)*
  - `createdByName`: string *(null)*
  - `createdByUserId`: integer/int32
  - `replyCount`: integer/int32
  - `lastReplyDate`: string/date-time *(null)*
  - `discussionCreatedDate`: string/date-time *(null)*

---

### `POST /api/Discussions`

**Request body:**
Schema: `DiscussionViewModel`
  - `discussionId`: integer/int32
  - `question`: string *(null)*
  - `description`: string *(null)*
  - `slug`: string *(null)*
  - `subcategoryId`: integer/int32
  - `userId`: integer/int32

**Responses:**
- `200`: OK → `Discussion`
  - `discussionId`: integer/int32
  - `question`: string *(null)*
  - `description`: string *(null)*
  - `slug`: string *(null)*
  - `subcategoryId`: integer/int32
  - `publicId`: string/uuid
  - `isActive`: boolean
  - `createdBy`: integer/int32
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time
  - `createdByNavigation`: `User`
  - `replies`: array of `Reply` *(null)*
  - `subcategory`: `Subcategory`

---

### `GET /api/Discussions/description/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Responses:**
- `200`: OK → string

---

### `GET /api/Discussions/replies/{slug}`

**Parameters:**
- `slug` (path): string **req**

**Responses:**
- `200`: OK → array of `DiscussionReplyDto`
  - `discussionReplyID`: integer/int32
  - `discussionID`: integer/int32
  - `reply`: string *(null)*
  - `createdByUserID`: integer/int32
  - `createdByUserName`: string *(null)*
  - `replyCreatedDate`: string/date-time *(null)*

---

### `POST /api/Discussions/reply`

**Request body:**
Schema: `DiscussionReplyDto`
  - `discussionReplyID`: integer/int32
  - `discussionID`: integer/int32
  - `reply`: string *(null)*
  - `createdByUserID`: integer/int32
  - `createdByUserName`: string *(null)*
  - `replyCreatedDate`: string/date-time *(null)*

**Responses:**
- `200`: OK

---

### `GET /api/Discussions/slug/{slug}`

**Parameters:**
- `slug` (path): string **req**

**Responses:**
- `200`: OK → `DiscussionDto`
  - `discussionID`: integer/int32
  - `question`: string *(null)*
  - `description`: string *(null)*
  - `slug`: string *(null)*
  - `createdByName`: string *(null)*
  - `createdByUserId`: integer/int32
  - `replyCount`: integer/int32
  - `lastReplyDate`: string/date-time *(null)*
  - `discussionCreatedDate`: string/date-time *(null)*

---

### `DELETE /api/Discussions/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Responses:**
- `200`: OK

---

### `GET /api/Discussions/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Responses:**
- `200`: OK → `Discussion`
  - `discussionId`: integer/int32
  - `question`: string *(null)*
  - `description`: string *(null)*
  - `slug`: string *(null)*
  - `subcategoryId`: integer/int32
  - `publicId`: string/uuid
  - `isActive`: boolean
  - `createdBy`: integer/int32
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time
  - `createdByNavigation`: `User`
  - `replies`: array of `Reply` *(null)*
  - `subcategory`: `Subcategory`

---

### `PUT /api/Discussions/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Request body:**
Schema: `Discussion`
  - `discussionId`: integer/int32
  - `question`: string *(null)*
  - `description`: string *(null)*
  - `slug`: string *(null)*
  - `subcategoryId`: integer/int32
  - `publicId`: string/uuid
  - `isActive`: boolean
  - `createdBy`: integer/int32
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time
  - `createdByNavigation`: `User`
  - `replies`: array of `Reply` *(null)*
  - `subcategory`: `Subcategory`

**Responses:**
- `200`: OK

---

## EmailSignups

### `GET /api/EmailSignups`

**Parameters:**
- `pageIndex` (query): integer/int32 default=`1`
- `pageSize` (query): integer/int32 default=`10`

**Responses:**
- `200`: OK → array of `EmailSignup`
  - `signupId`: integer/int32
  - `email`: string *(null)*
  - `subscriptionDate`: string/date-time *(null)*
  - `status`: string *(null)*
  - `publicId`: string/uuid
  - `createdDate`: string/date-time *(null)*
  - `modifiedDate`: string/date-time *(null)*
  - `clientIpaddress`: string *(null)*

---

### `POST /api/EmailSignups`

**Request body:**
Schema: `EmailSignupRequest`
  - `email`: string *(null)*
  - `turnstileToken`: string *(null)*
  - `clientIpaddress`: string *(null)*

**Responses:**
- `200`: OK → boolean

---

### `DELETE /api/EmailSignups/unsubscribe/{publicId}`

**Parameters:**
- `publicId` (path): string/uuid **req**

**Responses:**
- `200`: OK → boolean

---

### `DELETE /api/EmailSignups/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Responses:**
- `200`: OK

---

### `GET /api/EmailSignups/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Responses:**
- `200`: OK → `EmailSignup`
  - `signupId`: integer/int32
  - `email`: string *(null)*
  - `subscriptionDate`: string/date-time *(null)*
  - `status`: string *(null)*
  - `publicId`: string/uuid
  - `createdDate`: string/date-time *(null)*
  - `modifiedDate`: string/date-time *(null)*
  - `clientIpaddress`: string *(null)*

---

### `PUT /api/EmailSignups/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Request body:**
Schema: `EmailSignup`
  - `signupId`: integer/int32
  - `email`: string *(null)*
  - `subscriptionDate`: string/date-time *(null)*
  - `status`: string *(null)*
  - `publicId`: string/uuid
  - `createdDate`: string/date-time *(null)*
  - `modifiedDate`: string/date-time *(null)*
  - `clientIpaddress`: string *(null)*

**Responses:**
- `200`: OK

---

## EstimateFiles

### `GET /api/estimates/{estimatePublicId}/files`

**Parameters:**
- `estimatePublicId` (path): string/uuid **req**

**Responses:**
- `200`: OK → array of `EstimateAttachmentViewModel`
  - `attachmentId`: integer/int32
  - `publicId`: string/uuid
  - `estimateId`: integer/int32
  - `fileName`: string *(null)*
  - `fileUrl`: string *(null)*
  - `fileSize`: integer/int64 *(null)*
  - `contentType`: string *(null)*
  - `sortOrder`: integer/int32
  - `isActive`: boolean

---

### `POST /api/estimates/{estimatePublicId}/files`

**Parameters:**
- `estimatePublicId` (path): string/uuid **req**

**Request body:**
  - `file`: string/binary

**Responses:**
- `200`: OK → `EstimateAttachmentViewModel`
  - `attachmentId`: integer/int32
  - `publicId`: string/uuid
  - `estimateId`: integer/int32
  - `fileName`: string *(null)*
  - `fileUrl`: string *(null)*
  - `fileSize`: integer/int64 *(null)*
  - `contentType`: string *(null)*
  - `sortOrder`: integer/int32
  - `isActive`: boolean

---

### `DELETE /api/estimates/{estimatePublicId}/files/{attachmentId}`

**Parameters:**
- `estimatePublicId` (path): string/uuid **req**
- `attachmentId` (path): integer/int32 **req**

**Responses:**
- `200`: OK

---

## EstimateLineItemPhotos

### `GET /api/estimates/{estimatePublicId}/lineitems/{lineItemId}/photos`

**Parameters:**
- `estimatePublicId` (path): string/uuid **req**
- `lineItemId` (path): integer/int32 **req**

**Responses:**
- `200`: OK → array of `EstimateLineItemPhotoViewModel`
  - `photoId`: integer/int32
  - `publicId`: string/uuid
  - `lineItemId`: integer/int32
  - `fileName`: string *(null)*
  - `fileUrl`: string *(null)*
  - `sortOrder`: integer/int32
  - `isActive`: boolean

---

### `POST /api/estimates/{estimatePublicId}/lineitems/{lineItemId}/photos`

**Parameters:**
- `estimatePublicId` (path): string/uuid **req**
- `lineItemId` (path): integer/int32 **req**

**Request body:**
  - `file`: string/binary

**Responses:**
- `200`: OK → `EstimateLineItemPhotoViewModel`
  - `photoId`: integer/int32
  - `publicId`: string/uuid
  - `lineItemId`: integer/int32
  - `fileName`: string *(null)*
  - `fileUrl`: string *(null)*
  - `sortOrder`: integer/int32
  - `isActive`: boolean

---

### `DELETE /api/estimates/{estimatePublicId}/lineitems/{lineItemId}/photos/{photoId}`

**Parameters:**
- `estimatePublicId` (path): string/uuid **req**
- `lineItemId` (path): integer/int32 **req**
- `photoId` (path): integer/int32 **req**

**Responses:**
- `200`: OK

---

## EstimatePhotos

### `GET /api/estimates/{estimatePublicId}/photos`

**Parameters:**
- `estimatePublicId` (path): string/uuid **req**

**Responses:**
- `200`: OK → array of `EstimatePhotoViewModel`
  - `photoId`: integer/int32
  - `publicId`: string/uuid
  - `estimateId`: integer/int32
  - `fileName`: string *(null)*
  - `fileUrl`: string *(null)*
  - `caption`: string *(null)*
  - `sortOrder`: integer/int32
  - `isActive`: boolean

---

### `POST /api/estimates/{estimatePublicId}/photos`

**Parameters:**
- `estimatePublicId` (path): string/uuid **req**

**Request body:**
  - `file`: string/binary
  - `caption`: string

**Responses:**
- `200`: OK → `EstimatePhotoViewModel`
  - `photoId`: integer/int32
  - `publicId`: string/uuid
  - `estimateId`: integer/int32
  - `fileName`: string *(null)*
  - `fileUrl`: string *(null)*
  - `caption`: string *(null)*
  - `sortOrder`: integer/int32
  - `isActive`: boolean

---

### `DELETE /api/estimates/{estimatePublicId}/photos/{photoId}`

**Parameters:**
- `estimatePublicId` (path): string/uuid **req**
- `photoId` (path): integer/int32 **req**

**Responses:**
- `200`: OK

---

## Estimates

### `POST /api/Estimates`

**Request body:**
Schema: `CreateEstimateRequest`
  - `proId`: integer/int32
  - `clientId`: integer/int32 *(null)*
  - `estimateDate`: string/date-time
  - `expirationDate`: string/date-time *(null)*
  - `poNumber`: string *(null)*
  - `description`: string *(null)*
  - `groupItemsIntoSections`: boolean
  - `subtotal`: number/double
  - `markupType`: string *(null)*
  - `markupValue`: number/double *(null)*
  - `discountType`: string *(null)*
  - `discountValue`: number/double *(null)*
  - `depositType`: string *(null)*
  - `depositValue`: number/double *(null)*
  - `taxName`: string *(null)*
  - `taxRate`: number/double *(null)*
  - `total`: number/double
  - `showClientSignature`: boolean
  - `showMySignature`: boolean
  - `notes`: string *(null)*
  - `privateNotes`: string *(null)*
  - `sections`: array of `EstimateSectionViewModel` *(null)*
  - `lineItems`: array of `EstimateLineItemViewModel` *(null)*

**Responses:**
- `200`: OK → `EstimateViewModel`
  - `estimateId`: integer/int32
  - `publicId`: string/uuid
  - `proId`: integer/int32
  - `clientId`: integer/int32 *(null)*
  - `clientName`: string *(null)*
  - `estimateNumber`: string *(null)*
  - `estimateDate`: string/date-time
  - `expirationDate`: string/date-time *(null)*
  - `poNumber`: string *(null)*
  - `groupItemsIntoSections`: boolean
  - `subtotal`: number/double
  - `markupType`: string *(null)*
  - `markupValue`: number/double *(null)*
  - `discountType`: string *(null)*
  - `discountValue`: number/double *(null)*
  - `depositType`: string *(null)*
  - `depositValue`: number/double *(null)*
  - `taxName`: string *(null)*
  - `taxRate`: number/double *(null)*
  - `total`: number/double
  - `showClientSignature`: boolean
  - `showMySignature`: boolean
  - `clientSignatureData`: string *(null)*
  - `mySignatureData`: string *(null)*
  - `clientSignedDate`: string/date-time *(null)*
  - `mySignedDate`: string/date-time *(null)*
  - `notes`: string *(null)*
  - `privateNotes`: string *(null)*
  - `showDisplayOptionsRate`: boolean
  - `showDisplayOptionsQuantity`: boolean
  - `showDisplayOptionsItemTotals`: boolean
  - `showDisplayOptionsSectionTotals`: boolean
  - `status`: string *(null)*
  - `isApproved`: boolean *(null)*
  - `sentDate`: string/date-time *(null)*
  - `viewedDate`: string/date-time *(null)*
  - `acceptedDate`: string/date-time *(null)*
  - `declinedDate`: string/date-time *(null)*
  - `isActive`: boolean
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time
  - `sections`: array of `EstimateSectionViewModel` *(null)*
  - `lineItems`: array of `EstimateLineItemViewModel` *(null)*
  - `photos`: array of `EstimatePhotoViewModel` *(null)*
  - `attachments`: array of `EstimateAttachmentViewModel` *(null)*
  - `proName`: string *(null)*
  - `proLogo`: string *(null)*
  - `proAddress`: string *(null)*
  - `proCity`: string *(null)*
  - `proState`: string *(null)*
  - `proZipCode`: string *(null)*
  - `proEmail`: string *(null)*

---

### `DELETE /api/Estimates/lineitems/{lineItemId}`

**Parameters:**
- `lineItemId` (path): integer/int32 **req**

**Responses:**
- `200`: OK

---

### `GET /api/Estimates/pro/{proId}`

**Parameters:**
- `proId` (path): integer/int32 **req**
- `searchTerm` (query): string
- `status` (query): string
- `sortBy` (query): string default=`date`
- `sortDirection` (query): string default=`desc`
- `pageIndex` (query): integer/int32 default=`1`
- `pageSize` (query): integer/int32 default=`20`

**Responses:**
- `200`: OK → array of `EstimateListViewModel`
  - `estimateId`: integer/int32
  - `publicId`: string/uuid
  - `estimateNumber`: string *(null)*
  - `clientName`: string *(null)*
  - `estimateDate`: string/date-time
  - `expirationDate`: string/date-time *(null)*
  - `total`: number/double
  - `status`: string *(null)*
  - `isApproved`: boolean *(null)*
  - `createdDate`: string/date-time
  - `clientAddress`: string *(null)*
  - `clientCity`: string *(null)*
  - `clientState`: string *(null)*
  - `clientZipCode`: string *(null)*
  - `clientPhone`: string *(null)*
  - `emailOpened`: boolean
  - `emailOpenedDate`: string/date-time *(null)*
  - `clientSignedDate`: string/date-time *(null)*

---

### `GET /api/Estimates/pro/{proId}/monthly-totals`

**Parameters:**
- `proId` (path): integer/int32 **req**
- `searchTerm` (query): string
- `status` (query): string

**Responses:**
- `200`: OK → array of `EstimateMonthlyTotalDto`
  - `monthKey`: string *(null)*
  - `total`: number/double

---

### `GET /api/Estimates/pro/{proId}/next-number`

**Parameters:**
- `proId` (path): integer/int32 **req**

**Responses:**
- `200`: OK → string

---

### `GET /api/Estimates/public-view/{publicId}`

**Parameters:**
- `publicId` (path): string/uuid **req**

**Responses:**
- `200`: OK → `EstimatePublicViewResponse`
  - `estimate`: `EstimateViewModel`
  - `pro`: `ProViewModel`
  - `client`: `ClientViewModel`

---

### `GET /api/Estimates/public/{publicId}`

**Parameters:**
- `publicId` (path): string/uuid **req**

**Responses:**
- `200`: OK → `EstimateViewModel`
  - `estimateId`: integer/int32
  - `publicId`: string/uuid
  - `proId`: integer/int32
  - `clientId`: integer/int32 *(null)*
  - `clientName`: string *(null)*
  - `estimateNumber`: string *(null)*
  - `estimateDate`: string/date-time
  - `expirationDate`: string/date-time *(null)*
  - `poNumber`: string *(null)*
  - `groupItemsIntoSections`: boolean
  - `subtotal`: number/double
  - `markupType`: string *(null)*
  - `markupValue`: number/double *(null)*
  - `discountType`: string *(null)*
  - `discountValue`: number/double *(null)*
  - `depositType`: string *(null)*
  - `depositValue`: number/double *(null)*
  - `taxName`: string *(null)*
  - `taxRate`: number/double *(null)*
  - `total`: number/double
  - `showClientSignature`: boolean
  - `showMySignature`: boolean
  - `clientSignatureData`: string *(null)*
  - `mySignatureData`: string *(null)*
  - `clientSignedDate`: string/date-time *(null)*
  - `mySignedDate`: string/date-time *(null)*
  - `notes`: string *(null)*
  - `privateNotes`: string *(null)*
  - `showDisplayOptionsRate`: boolean
  - `showDisplayOptionsQuantity`: boolean
  - `showDisplayOptionsItemTotals`: boolean
  - `showDisplayOptionsSectionTotals`: boolean
  - `status`: string *(null)*
  - `isApproved`: boolean *(null)*
  - `sentDate`: string/date-time *(null)*
  - `viewedDate`: string/date-time *(null)*
  - `acceptedDate`: string/date-time *(null)*
  - `declinedDate`: string/date-time *(null)*
  - `isActive`: boolean
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time
  - `sections`: array of `EstimateSectionViewModel` *(null)*
  - `lineItems`: array of `EstimateLineItemViewModel` *(null)*
  - `photos`: array of `EstimatePhotoViewModel` *(null)*
  - `attachments`: array of `EstimateAttachmentViewModel` *(null)*
  - `proName`: string *(null)*
  - `proLogo`: string *(null)*
  - `proAddress`: string *(null)*
  - `proCity`: string *(null)*
  - `proState`: string *(null)*
  - `proZipCode`: string *(null)*
  - `proEmail`: string *(null)*

---

### `DELETE /api/Estimates/sections/{sectionId}`

**Parameters:**
- `sectionId` (path): integer/int32 **req**

**Responses:**
- `200`: OK

---

### `DELETE /api/Estimates/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Responses:**
- `200`: OK

---

### `GET /api/Estimates/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Responses:**
- `200`: OK → `EstimateViewModel`
  - `estimateId`: integer/int32
  - `publicId`: string/uuid
  - `proId`: integer/int32
  - `clientId`: integer/int32 *(null)*
  - `clientName`: string *(null)*
  - `estimateNumber`: string *(null)*
  - `estimateDate`: string/date-time
  - `expirationDate`: string/date-time *(null)*
  - `poNumber`: string *(null)*
  - `groupItemsIntoSections`: boolean
  - `subtotal`: number/double
  - `markupType`: string *(null)*
  - `markupValue`: number/double *(null)*
  - `discountType`: string *(null)*
  - `discountValue`: number/double *(null)*
  - `depositType`: string *(null)*
  - `depositValue`: number/double *(null)*
  - `taxName`: string *(null)*
  - `taxRate`: number/double *(null)*
  - `total`: number/double
  - `showClientSignature`: boolean
  - `showMySignature`: boolean
  - `clientSignatureData`: string *(null)*
  - `mySignatureData`: string *(null)*
  - `clientSignedDate`: string/date-time *(null)*
  - `mySignedDate`: string/date-time *(null)*
  - `notes`: string *(null)*
  - `privateNotes`: string *(null)*
  - `showDisplayOptionsRate`: boolean
  - `showDisplayOptionsQuantity`: boolean
  - `showDisplayOptionsItemTotals`: boolean
  - `showDisplayOptionsSectionTotals`: boolean
  - `status`: string *(null)*
  - `isApproved`: boolean *(null)*
  - `sentDate`: string/date-time *(null)*
  - `viewedDate`: string/date-time *(null)*
  - `acceptedDate`: string/date-time *(null)*
  - `declinedDate`: string/date-time *(null)*
  - `isActive`: boolean
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time
  - `sections`: array of `EstimateSectionViewModel` *(null)*
  - `lineItems`: array of `EstimateLineItemViewModel` *(null)*
  - `photos`: array of `EstimatePhotoViewModel` *(null)*
  - `attachments`: array of `EstimateAttachmentViewModel` *(null)*
  - `proName`: string *(null)*
  - `proLogo`: string *(null)*
  - `proAddress`: string *(null)*
  - `proCity`: string *(null)*
  - `proState`: string *(null)*
  - `proZipCode`: string *(null)*
  - `proEmail`: string *(null)*

---

### `PUT /api/Estimates/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Request body:**
Schema: `EstimateViewModel`
  - `estimateId`: integer/int32
  - `publicId`: string/uuid
  - `proId`: integer/int32
  - `clientId`: integer/int32 *(null)*
  - `clientName`: string *(null)*
  - `estimateNumber`: string *(null)*
  - `estimateDate`: string/date-time
  - `expirationDate`: string/date-time *(null)*
  - `poNumber`: string *(null)*
  - `groupItemsIntoSections`: boolean
  - `subtotal`: number/double
  - `markupType`: string *(null)*
  - `markupValue`: number/double *(null)*
  - `discountType`: string *(null)*
  - `discountValue`: number/double *(null)*
  - `depositType`: string *(null)*
  - `depositValue`: number/double *(null)*
  - `taxName`: string *(null)*
  - `taxRate`: number/double *(null)*
  - `total`: number/double
  - `showClientSignature`: boolean
  - `showMySignature`: boolean
  - `clientSignatureData`: string *(null)*
  - `mySignatureData`: string *(null)*
  - `clientSignedDate`: string/date-time *(null)*
  - `mySignedDate`: string/date-time *(null)*
  - `notes`: string *(null)*
  - `privateNotes`: string *(null)*
  - `showDisplayOptionsRate`: boolean
  - `showDisplayOptionsQuantity`: boolean
  - `showDisplayOptionsItemTotals`: boolean
  - `showDisplayOptionsSectionTotals`: boolean
  - `status`: string *(null)*
  - `isApproved`: boolean *(null)*
  - `sentDate`: string/date-time *(null)*
  - `viewedDate`: string/date-time *(null)*
  - `acceptedDate`: string/date-time *(null)*
  - `declinedDate`: string/date-time *(null)*
  - `isActive`: boolean
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time
  - `sections`: array of `EstimateSectionViewModel` *(null)*
  - `lineItems`: array of `EstimateLineItemViewModel` *(null)*
  - `photos`: array of `EstimatePhotoViewModel` *(null)*
  - `attachments`: array of `EstimateAttachmentViewModel` *(null)*
  - `proName`: string *(null)*
  - `proLogo`: string *(null)*
  - `proAddress`: string *(null)*
  - `proCity`: string *(null)*
  - `proState`: string *(null)*
  - `proZipCode`: string *(null)*
  - `proEmail`: string *(null)*

**Responses:**
- `200`: OK → `EstimateViewModel`
  - `estimateId`: integer/int32
  - `publicId`: string/uuid
  - `proId`: integer/int32
  - `clientId`: integer/int32 *(null)*
  - `clientName`: string *(null)*
  - `estimateNumber`: string *(null)*
  - `estimateDate`: string/date-time
  - `expirationDate`: string/date-time *(null)*
  - `poNumber`: string *(null)*
  - `groupItemsIntoSections`: boolean
  - `subtotal`: number/double
  - `markupType`: string *(null)*
  - `markupValue`: number/double *(null)*
  - `discountType`: string *(null)*
  - `discountValue`: number/double *(null)*
  - `depositType`: string *(null)*
  - `depositValue`: number/double *(null)*
  - `taxName`: string *(null)*
  - `taxRate`: number/double *(null)*
  - `total`: number/double
  - `showClientSignature`: boolean
  - `showMySignature`: boolean
  - `clientSignatureData`: string *(null)*
  - `mySignatureData`: string *(null)*
  - `clientSignedDate`: string/date-time *(null)*
  - `mySignedDate`: string/date-time *(null)*
  - `notes`: string *(null)*
  - `privateNotes`: string *(null)*
  - `showDisplayOptionsRate`: boolean
  - `showDisplayOptionsQuantity`: boolean
  - `showDisplayOptionsItemTotals`: boolean
  - `showDisplayOptionsSectionTotals`: boolean
  - `status`: string *(null)*
  - `isApproved`: boolean *(null)*
  - `sentDate`: string/date-time *(null)*
  - `viewedDate`: string/date-time *(null)*
  - `acceptedDate`: string/date-time *(null)*
  - `declinedDate`: string/date-time *(null)*
  - `isActive`: boolean
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time
  - `sections`: array of `EstimateSectionViewModel` *(null)*
  - `lineItems`: array of `EstimateLineItemViewModel` *(null)*
  - `photos`: array of `EstimatePhotoViewModel` *(null)*
  - `attachments`: array of `EstimateAttachmentViewModel` *(null)*
  - `proName`: string *(null)*
  - `proLogo`: string *(null)*
  - `proAddress`: string *(null)*
  - `proCity`: string *(null)*
  - `proState`: string *(null)*
  - `proZipCode`: string *(null)*
  - `proEmail`: string *(null)*

---

### `POST /api/Estimates/{id}/lineitems`

**Parameters:**
- `id` (path): integer/int32 **req**

**Request body:**
Schema: `EstimateLineItemViewModel`
  - `lineItemId`: integer/int32
  - `publicId`: string/uuid
  - `estimateId`: integer/int32
  - `sectionId`: integer/int32 *(null)*
  - `catalogLineItemId`: integer/int32 *(null)*
  - `description`: string *(null)*
  - `notes`: string *(null)*
  - `unitPrice`: number/double
  - `quantity`: integer/int32
  - `markupType`: string *(null)*
  - `markupValue`: number/double *(null)*
  - `isTaxable`: boolean
  - `taxRate`: number/double *(null)*
  - `taxAmount`: number/double
  - `total`: number/double
  - `sortOrder`: integer/int32
  - `isActive`: boolean
  - `photos`: array of `EstimateLineItemPhotoViewModel` *(null)*

**Responses:**
- `200`: OK → `EstimateLineItemViewModel`
  - `lineItemId`: integer/int32
  - `publicId`: string/uuid
  - `estimateId`: integer/int32
  - `sectionId`: integer/int32 *(null)*
  - `catalogLineItemId`: integer/int32 *(null)*
  - `description`: string *(null)*
  - `notes`: string *(null)*
  - `unitPrice`: number/double
  - `quantity`: integer/int32
  - `markupType`: string *(null)*
  - `markupValue`: number/double *(null)*
  - `isTaxable`: boolean
  - `taxRate`: number/double *(null)*
  - `taxAmount`: number/double
  - `total`: number/double
  - `sortOrder`: integer/int32
  - `isActive`: boolean
  - `photos`: array of `EstimateLineItemPhotoViewModel` *(null)*

---

### `POST /api/Estimates/{id}/sections`

**Parameters:**
- `id` (path): integer/int32 **req**

**Request body:**
Schema: `EstimateSectionViewModel`
  - `sectionId`: integer/int32
  - `publicId`: string/uuid
  - `estimateId`: integer/int32
  - `name`: string *(null)*
  - `sortOrder`: integer/int32
  - `subtotal`: number/double
  - `isExpanded`: boolean
  - `isActive`: boolean
  - `lineItems`: array of `EstimateLineItemViewModel` *(null)*

**Responses:**
- `200`: OK → `EstimateSectionViewModel`
  - `sectionId`: integer/int32
  - `publicId`: string/uuid
  - `estimateId`: integer/int32
  - `name`: string *(null)*
  - `sortOrder`: integer/int32
  - `subtotal`: number/double
  - `isExpanded`: boolean
  - `isActive`: boolean
  - `lineItems`: array of `EstimateLineItemViewModel` *(null)*

---

### `POST /api/Estimates/{id}/send`

**Parameters:**
- `id` (path): integer/int32 **req**

**Responses:**
- `200`: OK

---

### `DELETE /api/Estimates/{publicId}/hard-delete`

**Parameters:**
- `publicId` (path): string/uuid **req**

**Responses:**
- `200`: OK

---

### `POST /api/Estimates/{publicId}/send-email`

**Parameters:**
- `publicId` (path): string/uuid **req**

**Request body:**
Schema: `SendEstimateEmailRequest`
  - `toEmail`: string *(null)*
  - `subject`: string *(null)*
  - `message`: string *(null)*
  - `sendMeACopy`: boolean

**Responses:**
- `200`: OK

---

### `POST /api/Estimates/{publicId}/sign`

**Parameters:**
- `publicId` (path): string/uuid **req**

**Request body:**
Schema: `SignEstimateRequest`
  - `signatureName`: string *(null)*

**Responses:**
- `200`: OK

---

### `POST /api/Estimates/{publicId}/track-view`

**Parameters:**
- `publicId` (path): string/uuid **req**

**Responses:**
- `200`: OK

---

## Insights

### `GET /api/Insights`

**Parameters:**
- `pageIndex` (query): integer/int32 default=`1`
- `pageSize` (query): integer/int32 default=`9`
- `isHomePage` (query): boolean
- `isTopInsight` (query): boolean

**Responses:**
- `200`: OK → array of `InsightViewModel`
  - `insightId`: integer/int32
  - `title`: string **req**
  - `slug`: string **req**
  - `insightImage`: string *(null)*
  - `insightImageAltText`: string *(null)*
  - `insightContent`: string *(null)*
  - `metaDesc`: string *(null)*
  - `publishDate`: string/date-time *(null)*
  - `isHomePage`: boolean *(null)*
  - `isTopInsight`: boolean *(null)*

---

### `POST /api/Insights`

**Request body:**
Schema: `InsightViewModel`
  - `insightId`: integer/int32
  - `title`: string **req**
  - `slug`: string **req**
  - `insightImage`: string *(null)*
  - `insightImageAltText`: string *(null)*
  - `insightContent`: string *(null)*
  - `metaDesc`: string *(null)*
  - `publishDate`: string/date-time *(null)*
  - `isHomePage`: boolean *(null)*
  - `isTopInsight`: boolean *(null)*

**Responses:**
- `200`: OK → `Insight`
  - `insightId`: integer/int32
  - `title`: string *(null)*
  - `slug`: string *(null)*
  - `insightImage`: string *(null)*
  - `insightImageAltText`: string *(null)*
  - `insightContent`: string *(null)*
  - `metaDesc`: string *(null)*
  - `publishDate`: string/date-time *(null)*
  - `isHomePage`: boolean *(null)*
  - `isTopInsight`: boolean *(null)*
  - `publicId`: string/uuid
  - `createdDate`: string/date-time *(null)*
  - `modifiedDate`: string/date-time *(null)*

---

### `GET /api/Insights/home`

**Parameters:**
- `count` (query): integer/int32 default=`6`

**Responses:**
- `200`: OK → array of `InsightViewModel`
  - `insightId`: integer/int32
  - `title`: string **req**
  - `slug`: string **req**
  - `insightImage`: string *(null)*
  - `insightImageAltText`: string *(null)*
  - `insightContent`: string *(null)*
  - `metaDesc`: string *(null)*
  - `publishDate`: string/date-time *(null)*
  - `isHomePage`: boolean *(null)*
  - `isTopInsight`: boolean *(null)*

---

### `GET /api/Insights/latest`

**Parameters:**
- `count` (query): integer/int32 default=`3`

**Responses:**
- `200`: OK → array of `InsightViewModel`
  - `insightId`: integer/int32
  - `title`: string **req**
  - `slug`: string **req**
  - `insightImage`: string *(null)*
  - `insightImageAltText`: string *(null)*
  - `insightContent`: string *(null)*
  - `metaDesc`: string *(null)*
  - `publishDate`: string/date-time *(null)*
  - `isHomePage`: boolean *(null)*
  - `isTopInsight`: boolean *(null)*

---

### `GET /api/Insights/slug/{slug}`

**Parameters:**
- `slug` (path): string **req**

**Responses:**
- `200`: OK → `InsightViewModel`
  - `insightId`: integer/int32
  - `title`: string **req**
  - `slug`: string **req**
  - `insightImage`: string *(null)*
  - `insightImageAltText`: string *(null)*
  - `insightContent`: string *(null)*
  - `metaDesc`: string *(null)*
  - `publishDate`: string/date-time *(null)*
  - `isHomePage`: boolean *(null)*
  - `isTopInsight`: boolean *(null)*

---

### `GET /api/Insights/top`

**Parameters:**
- `count` (query): integer/int32 default=`3`

**Responses:**
- `200`: OK → array of `InsightViewModel`
  - `insightId`: integer/int32
  - `title`: string **req**
  - `slug`: string **req**
  - `insightImage`: string *(null)*
  - `insightImageAltText`: string *(null)*
  - `insightContent`: string *(null)*
  - `metaDesc`: string *(null)*
  - `publishDate`: string/date-time *(null)*
  - `isHomePage`: boolean *(null)*
  - `isTopInsight`: boolean *(null)*

---

### `DELETE /api/Insights/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Responses:**
- `200`: OK

---

### `GET /api/Insights/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Responses:**
- `200`: OK → `InsightViewModel`
  - `insightId`: integer/int32
  - `title`: string **req**
  - `slug`: string **req**
  - `insightImage`: string *(null)*
  - `insightImageAltText`: string *(null)*
  - `insightContent`: string *(null)*
  - `metaDesc`: string *(null)*
  - `publishDate`: string/date-time *(null)*
  - `isHomePage`: boolean *(null)*
  - `isTopInsight`: boolean *(null)*

---

### `PUT /api/Insights/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Request body:**
Schema: `InsightViewModel`
  - `insightId`: integer/int32
  - `title`: string **req**
  - `slug`: string **req**
  - `insightImage`: string *(null)*
  - `insightImageAltText`: string *(null)*
  - `insightContent`: string *(null)*
  - `metaDesc`: string *(null)*
  - `publishDate`: string/date-time *(null)*
  - `isHomePage`: boolean *(null)*
  - `isTopInsight`: boolean *(null)*

**Responses:**
- `200`: OK

---

### `DELETE /api/Insights/{id}/delete-image`

**Parameters:**
- `id` (path): integer/int32 **req**

**Responses:**
- `200`: OK

---

### `POST /api/Insights/{id}/upload-image`

**Parameters:**
- `id` (path): integer/int32 **req**

**Request body:**
  - `file`: string/binary

**Responses:**
- `200`: OK → `ImageUploadResponse`
  - `imageUrl`: string *(null)*

---

## InvoiceFiles

### `GET /api/invoices/{invoicePublicId}/files`

**Parameters:**
- `invoicePublicId` (path): string/uuid **req**

**Responses:**
- `200`: OK → array of `InvoiceAttachmentViewModel`
  - `attachmentId`: integer/int32
  - `publicId`: string/uuid
  - `invoiceId`: integer/int32
  - `fileName`: string *(null)*
  - `fileUrl`: string *(null)*
  - `fileSize`: integer/int64 *(null)*
  - `contentType`: string *(null)*
  - `sortOrder`: integer/int32
  - `isActive`: boolean

---

### `POST /api/invoices/{invoicePublicId}/files`

**Parameters:**
- `invoicePublicId` (path): string/uuid **req**

**Request body:**
  - `file`: string/binary

**Responses:**
- `200`: OK → `InvoiceAttachmentViewModel`
  - `attachmentId`: integer/int32
  - `publicId`: string/uuid
  - `invoiceId`: integer/int32
  - `fileName`: string *(null)*
  - `fileUrl`: string *(null)*
  - `fileSize`: integer/int64 *(null)*
  - `contentType`: string *(null)*
  - `sortOrder`: integer/int32
  - `isActive`: boolean

---

### `DELETE /api/invoices/{invoicePublicId}/files/{attachmentId}`

**Parameters:**
- `invoicePublicId` (path): string/uuid **req**
- `attachmentId` (path): integer/int32 **req**

**Responses:**
- `200`: OK

---

## InvoiceLineItemPhotos

### `GET /api/invoices/{invoicePublicId}/lineitems/{lineItemId}/photos`

**Parameters:**
- `invoicePublicId` (path): string/uuid **req**
- `lineItemId` (path): integer/int32 **req**

**Responses:**
- `200`: OK → array of `InvoiceLineItemPhotoViewModel`
  - `photoId`: integer/int32
  - `publicId`: string/uuid
  - `lineItemId`: integer/int32
  - `fileName`: string *(null)*
  - `fileUrl`: string *(null)*
  - `sortOrder`: integer/int32
  - `isActive`: boolean

---

### `POST /api/invoices/{invoicePublicId}/lineitems/{lineItemId}/photos`

**Parameters:**
- `invoicePublicId` (path): string/uuid **req**
- `lineItemId` (path): integer/int32 **req**

**Request body:**
  - `file`: string/binary

**Responses:**
- `200`: OK → `InvoiceLineItemPhotoViewModel`
  - `photoId`: integer/int32
  - `publicId`: string/uuid
  - `lineItemId`: integer/int32
  - `fileName`: string *(null)*
  - `fileUrl`: string *(null)*
  - `sortOrder`: integer/int32
  - `isActive`: boolean

---

### `DELETE /api/invoices/{invoicePublicId}/lineitems/{lineItemId}/photos/{photoId}`

**Parameters:**
- `invoicePublicId` (path): string/uuid **req**
- `lineItemId` (path): integer/int32 **req**
- `photoId` (path): integer/int32 **req**

**Responses:**
- `200`: OK

---

## InvoicePhotos

### `GET /api/invoices/{invoicePublicId}/photos`

**Parameters:**
- `invoicePublicId` (path): string/uuid **req**

**Responses:**
- `200`: OK → array of `InvoicePhotoViewModel`
  - `photoId`: integer/int32
  - `publicId`: string/uuid
  - `invoiceId`: integer/int32
  - `fileName`: string *(null)*
  - `fileUrl`: string *(null)*
  - `caption`: string *(null)*
  - `sortOrder`: integer/int32
  - `isActive`: boolean

---

### `POST /api/invoices/{invoicePublicId}/photos`

**Parameters:**
- `invoicePublicId` (path): string/uuid **req**

**Request body:**
  - `file`: string/binary
  - `caption`: string

**Responses:**
- `200`: OK → `InvoicePhotoViewModel`
  - `photoId`: integer/int32
  - `publicId`: string/uuid
  - `invoiceId`: integer/int32
  - `fileName`: string *(null)*
  - `fileUrl`: string *(null)*
  - `caption`: string *(null)*
  - `sortOrder`: integer/int32
  - `isActive`: boolean

---

### `DELETE /api/invoices/{invoicePublicId}/photos/{photoId}`

**Parameters:**
- `invoicePublicId` (path): string/uuid **req**
- `photoId` (path): integer/int32 **req**

**Responses:**
- `200`: OK

---

## Invoices

### `POST /api/Invoices`

**Request body:**
Schema: `CreateInvoiceRequest`
  - `proId`: integer/int32
  - `clientId`: integer/int32 *(null)*
  - `invoiceDate`: string/date-time
  - `daysToPay`: integer/int32 *(null)*
  - `poNumber`: string *(null)*
  - `groupItemsIntoSections`: boolean
  - `subtotal`: number/double
  - `markupType`: string *(null)*
  - `markupValue`: number/double *(null)*
  - `discountType`: string *(null)*
  - `discountValue`: number/double *(null)*
  - `depositType`: string *(null)*
  - `depositValue`: number/double *(null)*
  - `taxName`: string *(null)*
  - `taxRate`: number/double *(null)*
  - `total`: number/double
  - `showClientSignature`: boolean
  - `showMySignature`: boolean
  - `notes`: string *(null)*
  - `privateNotes`: string *(null)*
  - `sections`: array of `InvoiceSectionViewModel` *(null)*
  - `lineItems`: array of `InvoiceLineItemViewModel` *(null)*

**Responses:**
- `200`: OK → `InvoiceViewModel`
  - `invoiceId`: integer/int32
  - `publicId`: string/uuid
  - `proId`: integer/int32
  - `clientId`: integer/int32 *(null)*
  - `clientName`: string *(null)*
  - `invoiceNumber`: string *(null)*
  - `invoiceDate`: string/date-time
  - `daysToPay`: integer/int32 *(null)*
  - `dueDate`: string/date-time *(null)*
  - `poNumber`: string *(null)*
  - `groupItemsIntoSections`: boolean
  - `subtotal`: number/double
  - `markupType`: string *(null)*
  - `markupValue`: number/double *(null)*
  - `discountType`: string *(null)*
  - `discountValue`: number/double *(null)*
  - `depositType`: string *(null)*
  - `depositValue`: number/double *(null)*
  - `taxName`: string *(null)*
  - `taxRate`: number/double *(null)*
  - `total`: number/double
  - `showClientSignature`: boolean
  - `showMySignature`: boolean
  - `clientSignatureData`: string *(null)*
  - `mySignatureData`: string *(null)*
  - `clientSignedDate`: string/date-time *(null)*
  - `mySignedDate`: string/date-time *(null)*
  - `notes`: string *(null)*
  - `privateNotes`: string *(null)*
  - `showDisplayOptionsRate`: boolean
  - `showDisplayOptionsQuantity`: boolean
  - `showDisplayOptionsItemTotals`: boolean
  - `showDisplayOptionsSectionTotals`: boolean
  - `status`: string *(null)*
  - `sentDate`: string/date-time *(null)*
  - `viewedDate`: string/date-time *(null)*
  - `acceptedDate`: string/date-time *(null)*
  - `declinedDate`: string/date-time *(null)*
  - `paidDate`: string/date-time *(null)*
  - `isActive`: boolean
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time
  - `sections`: array of `InvoiceSectionViewModel` *(null)*
  - `lineItems`: array of `InvoiceLineItemViewModel` *(null)*
  - `photos`: array of `InvoicePhotoViewModel` *(null)*
  - `attachments`: array of `InvoiceAttachmentViewModel` *(null)*
  - `proName`: string *(null)*
  - `proLogo`: string *(null)*
  - `proAddress`: string *(null)*
  - `proCity`: string *(null)*
  - `proState`: string *(null)*
  - `proZipCode`: string *(null)*
  - `proEmail`: string *(null)*

---

### `DELETE /api/Invoices/lineitems/{lineItemId}`

**Parameters:**
- `lineItemId` (path): integer/int32 **req**

**Responses:**
- `200`: OK

---

### `GET /api/Invoices/pro/{proId}`

**Parameters:**
- `proId` (path): integer/int32 **req**
- `searchTerm` (query): string
- `status` (query): string
- `sortBy` (query): string default=`date`
- `sortDirection` (query): string default=`desc`
- `pageIndex` (query): integer/int32 default=`1`
- `pageSize` (query): integer/int32 default=`20`

**Responses:**
- `200`: OK → array of `InvoiceListViewModel`
  - `invoiceId`: integer/int32
  - `publicId`: string/uuid
  - `invoiceNumber`: string *(null)*
  - `clientName`: string *(null)*
  - `invoiceDate`: string/date-time
  - `daysToPay`: integer/int32 *(null)*
  - `dueDate`: string/date-time *(null)*
  - `total`: number/double
  - `paidAmount`: number/double
  - `status`: string *(null)*
  - `createdDate`: string/date-time
  - `clientAddress`: string *(null)*
  - `clientCity`: string *(null)*
  - `clientState`: string *(null)*
  - `clientZipCode`: string *(null)*
  - `clientPhone`: string *(null)*
  - `sentDate`: string/date-time *(null)*
  - `emailOpened`: boolean
  - `emailOpenedDate`: string/date-time *(null)*
  - `clientSignedDate`: string/date-time *(null)*

---

### `GET /api/Invoices/pro/{proId}/next-number`

**Parameters:**
- `proId` (path): integer/int32 **req**

**Responses:**
- `200`: OK → string

---

### `GET /api/Invoices/pro/{proId}/payment-stats`

**Parameters:**
- `proId` (path): integer/int32 **req**

**Responses:**
- `200`: OK → `ProPaymentStatsViewModel`
  - `paidThisMonth`: number/double
  - `paidLastMonth`: number/double

---

### `GET /api/Invoices/public-view/{publicId}`

**Parameters:**
- `publicId` (path): string/uuid **req**

**Responses:**
- `200`: OK → `InvoicePublicViewResponse`
  - `invoice`: `InvoiceViewModel`
  - `pro`: `ProViewModel`
  - `client`: `ClientViewModel`

---

### `GET /api/Invoices/public/{publicId}`

**Parameters:**
- `publicId` (path): string/uuid **req**

**Responses:**
- `200`: OK → `InvoiceViewModel`
  - `invoiceId`: integer/int32
  - `publicId`: string/uuid
  - `proId`: integer/int32
  - `clientId`: integer/int32 *(null)*
  - `clientName`: string *(null)*
  - `invoiceNumber`: string *(null)*
  - `invoiceDate`: string/date-time
  - `daysToPay`: integer/int32 *(null)*
  - `dueDate`: string/date-time *(null)*
  - `poNumber`: string *(null)*
  - `groupItemsIntoSections`: boolean
  - `subtotal`: number/double
  - `markupType`: string *(null)*
  - `markupValue`: number/double *(null)*
  - `discountType`: string *(null)*
  - `discountValue`: number/double *(null)*
  - `depositType`: string *(null)*
  - `depositValue`: number/double *(null)*
  - `taxName`: string *(null)*
  - `taxRate`: number/double *(null)*
  - `total`: number/double
  - `showClientSignature`: boolean
  - `showMySignature`: boolean
  - `clientSignatureData`: string *(null)*
  - `mySignatureData`: string *(null)*
  - `clientSignedDate`: string/date-time *(null)*
  - `mySignedDate`: string/date-time *(null)*
  - `notes`: string *(null)*
  - `privateNotes`: string *(null)*
  - `showDisplayOptionsRate`: boolean
  - `showDisplayOptionsQuantity`: boolean
  - `showDisplayOptionsItemTotals`: boolean
  - `showDisplayOptionsSectionTotals`: boolean
  - `status`: string *(null)*
  - `sentDate`: string/date-time *(null)*
  - `viewedDate`: string/date-time *(null)*
  - `acceptedDate`: string/date-time *(null)*
  - `declinedDate`: string/date-time *(null)*
  - `paidDate`: string/date-time *(null)*
  - `isActive`: boolean
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time
  - `sections`: array of `InvoiceSectionViewModel` *(null)*
  - `lineItems`: array of `InvoiceLineItemViewModel` *(null)*
  - `photos`: array of `InvoicePhotoViewModel` *(null)*
  - `attachments`: array of `InvoiceAttachmentViewModel` *(null)*
  - `proName`: string *(null)*
  - `proLogo`: string *(null)*
  - `proAddress`: string *(null)*
  - `proCity`: string *(null)*
  - `proState`: string *(null)*
  - `proZipCode`: string *(null)*
  - `proEmail`: string *(null)*

---

### `DELETE /api/Invoices/sections/{sectionId}`

**Parameters:**
- `sectionId` (path): integer/int32 **req**

**Responses:**
- `200`: OK

---

### `DELETE /api/Invoices/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Responses:**
- `200`: OK

---

### `GET /api/Invoices/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Responses:**
- `200`: OK → `InvoiceViewModel`
  - `invoiceId`: integer/int32
  - `publicId`: string/uuid
  - `proId`: integer/int32
  - `clientId`: integer/int32 *(null)*
  - `clientName`: string *(null)*
  - `invoiceNumber`: string *(null)*
  - `invoiceDate`: string/date-time
  - `daysToPay`: integer/int32 *(null)*
  - `dueDate`: string/date-time *(null)*
  - `poNumber`: string *(null)*
  - `groupItemsIntoSections`: boolean
  - `subtotal`: number/double
  - `markupType`: string *(null)*
  - `markupValue`: number/double *(null)*
  - `discountType`: string *(null)*
  - `discountValue`: number/double *(null)*
  - `depositType`: string *(null)*
  - `depositValue`: number/double *(null)*
  - `taxName`: string *(null)*
  - `taxRate`: number/double *(null)*
  - `total`: number/double
  - `showClientSignature`: boolean
  - `showMySignature`: boolean
  - `clientSignatureData`: string *(null)*
  - `mySignatureData`: string *(null)*
  - `clientSignedDate`: string/date-time *(null)*
  - `mySignedDate`: string/date-time *(null)*
  - `notes`: string *(null)*
  - `privateNotes`: string *(null)*
  - `showDisplayOptionsRate`: boolean
  - `showDisplayOptionsQuantity`: boolean
  - `showDisplayOptionsItemTotals`: boolean
  - `showDisplayOptionsSectionTotals`: boolean
  - `status`: string *(null)*
  - `sentDate`: string/date-time *(null)*
  - `viewedDate`: string/date-time *(null)*
  - `acceptedDate`: string/date-time *(null)*
  - `declinedDate`: string/date-time *(null)*
  - `paidDate`: string/date-time *(null)*
  - `isActive`: boolean
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time
  - `sections`: array of `InvoiceSectionViewModel` *(null)*
  - `lineItems`: array of `InvoiceLineItemViewModel` *(null)*
  - `photos`: array of `InvoicePhotoViewModel` *(null)*
  - `attachments`: array of `InvoiceAttachmentViewModel` *(null)*
  - `proName`: string *(null)*
  - `proLogo`: string *(null)*
  - `proAddress`: string *(null)*
  - `proCity`: string *(null)*
  - `proState`: string *(null)*
  - `proZipCode`: string *(null)*
  - `proEmail`: string *(null)*

---

### `PUT /api/Invoices/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Request body:**
Schema: `InvoiceViewModel`
  - `invoiceId`: integer/int32
  - `publicId`: string/uuid
  - `proId`: integer/int32
  - `clientId`: integer/int32 *(null)*
  - `clientName`: string *(null)*
  - `invoiceNumber`: string *(null)*
  - `invoiceDate`: string/date-time
  - `daysToPay`: integer/int32 *(null)*
  - `dueDate`: string/date-time *(null)*
  - `poNumber`: string *(null)*
  - `groupItemsIntoSections`: boolean
  - `subtotal`: number/double
  - `markupType`: string *(null)*
  - `markupValue`: number/double *(null)*
  - `discountType`: string *(null)*
  - `discountValue`: number/double *(null)*
  - `depositType`: string *(null)*
  - `depositValue`: number/double *(null)*
  - `taxName`: string *(null)*
  - `taxRate`: number/double *(null)*
  - `total`: number/double
  - `showClientSignature`: boolean
  - `showMySignature`: boolean
  - `clientSignatureData`: string *(null)*
  - `mySignatureData`: string *(null)*
  - `clientSignedDate`: string/date-time *(null)*
  - `mySignedDate`: string/date-time *(null)*
  - `notes`: string *(null)*
  - `privateNotes`: string *(null)*
  - `showDisplayOptionsRate`: boolean
  - `showDisplayOptionsQuantity`: boolean
  - `showDisplayOptionsItemTotals`: boolean
  - `showDisplayOptionsSectionTotals`: boolean
  - `status`: string *(null)*
  - `sentDate`: string/date-time *(null)*
  - `viewedDate`: string/date-time *(null)*
  - `acceptedDate`: string/date-time *(null)*
  - `declinedDate`: string/date-time *(null)*
  - `paidDate`: string/date-time *(null)*
  - `isActive`: boolean
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time
  - `sections`: array of `InvoiceSectionViewModel` *(null)*
  - `lineItems`: array of `InvoiceLineItemViewModel` *(null)*
  - `photos`: array of `InvoicePhotoViewModel` *(null)*
  - `attachments`: array of `InvoiceAttachmentViewModel` *(null)*
  - `proName`: string *(null)*
  - `proLogo`: string *(null)*
  - `proAddress`: string *(null)*
  - `proCity`: string *(null)*
  - `proState`: string *(null)*
  - `proZipCode`: string *(null)*
  - `proEmail`: string *(null)*

**Responses:**
- `200`: OK → `InvoiceViewModel`
  - `invoiceId`: integer/int32
  - `publicId`: string/uuid
  - `proId`: integer/int32
  - `clientId`: integer/int32 *(null)*
  - `clientName`: string *(null)*
  - `invoiceNumber`: string *(null)*
  - `invoiceDate`: string/date-time
  - `daysToPay`: integer/int32 *(null)*
  - `dueDate`: string/date-time *(null)*
  - `poNumber`: string *(null)*
  - `groupItemsIntoSections`: boolean
  - `subtotal`: number/double
  - `markupType`: string *(null)*
  - `markupValue`: number/double *(null)*
  - `discountType`: string *(null)*
  - `discountValue`: number/double *(null)*
  - `depositType`: string *(null)*
  - `depositValue`: number/double *(null)*
  - `taxName`: string *(null)*
  - `taxRate`: number/double *(null)*
  - `total`: number/double
  - `showClientSignature`: boolean
  - `showMySignature`: boolean
  - `clientSignatureData`: string *(null)*
  - `mySignatureData`: string *(null)*
  - `clientSignedDate`: string/date-time *(null)*
  - `mySignedDate`: string/date-time *(null)*
  - `notes`: string *(null)*
  - `privateNotes`: string *(null)*
  - `showDisplayOptionsRate`: boolean
  - `showDisplayOptionsQuantity`: boolean
  - `showDisplayOptionsItemTotals`: boolean
  - `showDisplayOptionsSectionTotals`: boolean
  - `status`: string *(null)*
  - `sentDate`: string/date-time *(null)*
  - `viewedDate`: string/date-time *(null)*
  - `acceptedDate`: string/date-time *(null)*
  - `declinedDate`: string/date-time *(null)*
  - `paidDate`: string/date-time *(null)*
  - `isActive`: boolean
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time
  - `sections`: array of `InvoiceSectionViewModel` *(null)*
  - `lineItems`: array of `InvoiceLineItemViewModel` *(null)*
  - `photos`: array of `InvoicePhotoViewModel` *(null)*
  - `attachments`: array of `InvoiceAttachmentViewModel` *(null)*
  - `proName`: string *(null)*
  - `proLogo`: string *(null)*
  - `proAddress`: string *(null)*
  - `proCity`: string *(null)*
  - `proState`: string *(null)*
  - `proZipCode`: string *(null)*
  - `proEmail`: string *(null)*

---

### `POST /api/Invoices/{id}/lineitems`

**Parameters:**
- `id` (path): integer/int32 **req**

**Request body:**
Schema: `InvoiceLineItemViewModel`
  - `lineItemId`: integer/int32
  - `publicId`: string/uuid
  - `invoiceId`: integer/int32
  - `sectionId`: integer/int32 *(null)*
  - `description`: string *(null)*
  - `notes`: string *(null)*
  - `unitPrice`: number/double
  - `quantity`: integer/int32
  - `markupType`: string *(null)*
  - `markupValue`: number/double *(null)*
  - `isTaxable`: boolean
  - `taxRate`: number/double *(null)*
  - `taxAmount`: number/double
  - `total`: number/double
  - `sortOrder`: integer/int32
  - `isActive`: boolean
  - `photos`: array of `InvoiceLineItemPhotoViewModel` *(null)*

**Responses:**
- `200`: OK → `InvoiceLineItemViewModel`
  - `lineItemId`: integer/int32
  - `publicId`: string/uuid
  - `invoiceId`: integer/int32
  - `sectionId`: integer/int32 *(null)*
  - `description`: string *(null)*
  - `notes`: string *(null)*
  - `unitPrice`: number/double
  - `quantity`: integer/int32
  - `markupType`: string *(null)*
  - `markupValue`: number/double *(null)*
  - `isTaxable`: boolean
  - `taxRate`: number/double *(null)*
  - `taxAmount`: number/double
  - `total`: number/double
  - `sortOrder`: integer/int32
  - `isActive`: boolean
  - `photos`: array of `InvoiceLineItemPhotoViewModel` *(null)*

---

### `POST /api/Invoices/{id}/sections`

**Parameters:**
- `id` (path): integer/int32 **req**

**Request body:**
Schema: `InvoiceSectionViewModel`
  - `sectionId`: integer/int32
  - `publicId`: string/uuid
  - `invoiceId`: integer/int32
  - `name`: string *(null)*
  - `sortOrder`: integer/int32
  - `subtotal`: number/double
  - `isExpanded`: boolean
  - `isActive`: boolean
  - `lineItems`: array of `InvoiceLineItemViewModel` *(null)*

**Responses:**
- `200`: OK → `InvoiceSectionViewModel`
  - `sectionId`: integer/int32
  - `publicId`: string/uuid
  - `invoiceId`: integer/int32
  - `name`: string *(null)*
  - `sortOrder`: integer/int32
  - `subtotal`: number/double
  - `isExpanded`: boolean
  - `isActive`: boolean
  - `lineItems`: array of `InvoiceLineItemViewModel` *(null)*

---

### `POST /api/Invoices/{id}/send`

**Parameters:**
- `id` (path): integer/int32 **req**

**Responses:**
- `200`: OK

---

### `POST /api/Invoices/{publicId}/mark-paid`

**Parameters:**
- `publicId` (path): string/uuid **req**

**Responses:**
- `200`: OK

---

### `GET /api/Invoices/{publicId}/payments`

**Parameters:**
- `publicId` (path): string/uuid **req**

**Responses:**
- `200`: OK → array of `InvoicePaymentViewModel`
  - `invoicePaymentId`: integer/int32
  - `publicId`: string/uuid
  - `invoiceId`: integer/int32
  - `paymentDate`: string/date-time
  - `amount`: number/double
  - `paymentMethod`: string *(null)*
  - `referenceNumber`: string *(null)*
  - `notes`: string *(null)*
  - `isActive`: boolean
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time *(null)*

---

### `POST /api/Invoices/{publicId}/record-payment`

**Parameters:**
- `publicId` (path): string/uuid **req**

**Request body:**
Schema: `RecordPaymentRequest`
  - `paymentDate`: string/date-time
  - `amount`: number/double
  - `paymentMethod`: string *(null)*
  - `referenceNumber`: string *(null)*
  - `notes`: string *(null)*

**Responses:**
- `200`: OK → `InvoicePaymentViewModel`
  - `invoicePaymentId`: integer/int32
  - `publicId`: string/uuid
  - `invoiceId`: integer/int32
  - `paymentDate`: string/date-time
  - `amount`: number/double
  - `paymentMethod`: string *(null)*
  - `referenceNumber`: string *(null)*
  - `notes`: string *(null)*
  - `isActive`: boolean
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time *(null)*

---

### `POST /api/Invoices/{publicId}/refund`

**Parameters:**
- `publicId` (path): string/uuid **req**

**Request body:**
Schema: `IssueRefundRequest`
  - `paymentPublicId`: string/uuid
  - `amount`: number/double
  - `notes`: string *(null)*

**Responses:**
- `200`: OK → `InvoicePaymentViewModel`
  - `invoicePaymentId`: integer/int32
  - `publicId`: string/uuid
  - `invoiceId`: integer/int32
  - `paymentDate`: string/date-time
  - `amount`: number/double
  - `paymentMethod`: string *(null)*
  - `referenceNumber`: string *(null)*
  - `notes`: string *(null)*
  - `isActive`: boolean
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time *(null)*

---

### `POST /api/Invoices/{publicId}/send-email`

**Parameters:**
- `publicId` (path): string/uuid **req**

**Request body:**
Schema: `SendInvoiceEmailRequest`
  - `toEmail`: string *(null)*
  - `subject`: string *(null)*
  - `message`: string *(null)*
  - `sendMeACopy`: boolean

**Responses:**
- `200`: OK

---

### `POST /api/Invoices/{publicId}/sign`

**Parameters:**
- `publicId` (path): string/uuid **req**

**Request body:**
Schema: `SignInvoiceRequest`
  - `signatureName`: string *(null)*

**Responses:**
- `200`: OK

---

### `POST /api/Invoices/{publicId}/track-view`

**Parameters:**
- `publicId` (path): string/uuid **req**

**Responses:**
- `200`: OK

---

## LineItems

### `POST /api/LineItems`

**Request body:**
Schema: `LineItemViewModel`
  - `lineItemId`: integer/int32
  - `proId`: integer/int32
  - `publicId`: string *(null)*
  - `itemName`: string *(null)*
  - `rate`: number/double *(null)*
  - `lineItemMarkupId`: integer/int32 *(null)*
  - `markupName`: string *(null)*
  - `markupType`: string *(null)*
  - `markupRate`: number/double *(null)*
  - `description`: string *(null)*
  - `privateNote`: string *(null)*
  - `isActive`: boolean
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time *(null)*

**Responses:**
- `200`: OK → `LineItemViewModel`
  - `lineItemId`: integer/int32
  - `proId`: integer/int32
  - `publicId`: string *(null)*
  - `itemName`: string *(null)*
  - `rate`: number/double *(null)*
  - `lineItemMarkupId`: integer/int32 *(null)*
  - `markupName`: string *(null)*
  - `markupType`: string *(null)*
  - `markupRate`: number/double *(null)*
  - `description`: string *(null)*
  - `privateNote`: string *(null)*
  - `isActive`: boolean
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time *(null)*

---

### `POST /api/LineItems/markups`

**Request body:**
Schema: `LineItemMarkupViewModel`
  - `lineItemMarkupId`: integer/int32
  - `proId`: integer/int32
  - `markupName`: string *(null)*
  - `markupType`: string *(null)*
  - `markupRate`: number/double
  - `isActive`: boolean
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time *(null)*

**Responses:**
- `200`: OK → `LineItemMarkupViewModel`
  - `lineItemMarkupId`: integer/int32
  - `proId`: integer/int32
  - `markupName`: string *(null)*
  - `markupType`: string *(null)*
  - `markupRate`: number/double
  - `isActive`: boolean
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time *(null)*

---

### `GET /api/LineItems/markups/pro/{proId}`

**Parameters:**
- `proId` (path): integer/int32 **req**

**Responses:**
- `200`: OK → array of `LineItemMarkupViewModel`
  - `lineItemMarkupId`: integer/int32
  - `proId`: integer/int32
  - `markupName`: string *(null)*
  - `markupType`: string *(null)*
  - `markupRate`: number/double
  - `isActive`: boolean
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time *(null)*

---

### `DELETE /api/LineItems/markups/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Responses:**
- `200`: OK

---

### `PUT /api/LineItems/markups/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Request body:**
Schema: `LineItemMarkupViewModel`
  - `lineItemMarkupId`: integer/int32
  - `proId`: integer/int32
  - `markupName`: string *(null)*
  - `markupType`: string *(null)*
  - `markupRate`: number/double
  - `isActive`: boolean
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time *(null)*

**Responses:**
- `200`: OK

---

### `GET /api/LineItems/pro/{proId}`

**Parameters:**
- `proId` (path): integer/int32 **req**
- `searchTerm` (query): string
- `sortBy` (query): string default=`name`
- `sortDirection` (query): string default=`asc`
- `pageIndex` (query): integer/int32 default=`1`
- `pageSize` (query): integer/int32 default=`20`

**Responses:**
- `200`: OK → array of `LineItemListViewModel`
  - `lineItemId`: integer/int32
  - `itemName`: string *(null)*
  - `rate`: number/double *(null)*
  - `markupName`: string *(null)*
  - `markupType`: string *(null)*
  - `markupRate`: number/double *(null)*
  - `description`: string *(null)*
  - `createdDate`: string/date-time

---

### `GET /api/LineItems/pro/{proId}/count`

**Parameters:**
- `proId` (path): integer/int32 **req**

**Responses:**
- `200`: OK → integer/int32

---

### `DELETE /api/LineItems/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Responses:**
- `200`: OK

---

### `GET /api/LineItems/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Responses:**
- `200`: OK → `LineItemViewModel`
  - `lineItemId`: integer/int32
  - `proId`: integer/int32
  - `publicId`: string *(null)*
  - `itemName`: string *(null)*
  - `rate`: number/double *(null)*
  - `lineItemMarkupId`: integer/int32 *(null)*
  - `markupName`: string *(null)*
  - `markupType`: string *(null)*
  - `markupRate`: number/double *(null)*
  - `description`: string *(null)*
  - `privateNote`: string *(null)*
  - `isActive`: boolean
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time *(null)*

---

### `PUT /api/LineItems/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Request body:**
Schema: `LineItemViewModel`
  - `lineItemId`: integer/int32
  - `proId`: integer/int32
  - `publicId`: string *(null)*
  - `itemName`: string *(null)*
  - `rate`: number/double *(null)*
  - `lineItemMarkupId`: integer/int32 *(null)*
  - `markupName`: string *(null)*
  - `markupType`: string *(null)*
  - `markupRate`: number/double *(null)*
  - `description`: string *(null)*
  - `privateNote`: string *(null)*
  - `isActive`: boolean
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time *(null)*

**Responses:**
- `200`: OK

---

## LoginHistory

### `GET /api/LoginHistory`

**Parameters:**
- `todayOnly` (query): boolean default=`False`
- `fromDate` (query): string/date-time
- `toDate` (query): string/date-time
- `username` (query): string
- `email` (query): string
- `ipAddress` (query): string
- `isSuccessful` (query): boolean
- `pageIndex` (query): integer/int32 default=`1`
- `pageSize` (query): integer/int32 default=`10`

**Responses:**
- `200`: OK → array of `LoginHistoryDto`
  - `loginHistoryId`: integer/int32
  - `userId`: integer/int32 *(null)*
  - `username`: string *(null)*
  - `email`: string *(null)*
  - `loginAttemptTime`: string/date-time
  - `isSuccessful`: boolean
  - `ipAddress`: string *(null)*
  - `userAgent`: string *(null)*
  - `failureReason`: string *(null)*
  - `fullName`: string *(null)*

---

### `DELETE /api/LoginHistory/cleanup`

**Parameters:**
- `olderThanDays` (query): integer/int32 default=`90`

**Responses:**
- `200`: OK

---

### `GET /api/LoginHistory/stats`

**Responses:**
- `200`: OK → `LoginStatsDto`
  - `totalAttempts`: integer/int32
  - `totalSuccessful`: integer/int32
  - `totalFailed`: integer/int32
  - `todayAttempts`: integer/int32
  - `todaySuccessful`: integer/int32
  - `todayFailed`: integer/int32
  - `weekAttempts`: integer/int32
  - `monthAttempts`: integer/int32
  - `uniqueUsers`: integer/int32

---

### `GET /api/LoginHistory/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Responses:**
- `200`: OK → `LoginHistoryDto`
  - `loginHistoryId`: integer/int32
  - `userId`: integer/int32 *(null)*
  - `username`: string *(null)*
  - `email`: string *(null)*
  - `loginAttemptTime`: string/date-time
  - `isSuccessful`: boolean
  - `ipAddress`: string *(null)*
  - `userAgent`: string *(null)*
  - `failureReason`: string *(null)*
  - `fullName`: string *(null)*

---

## Notifications

### `POST /api/Notifications`

**Request body:**
Schema: `RecordNotificationRequest`
  - `proId`: integer/int32
  - `title`: string *(null)*
  - `entityType`: string *(null)*
  - `entityId`: integer/int32 *(null)*
  - `entityGuid`: string/uuid *(null)*

**Responses:**
- `200`: OK

---

### `GET /api/Notifications/pro/{proId}`

**Parameters:**
- `proId` (path): integer/int32 **req**
- `searchTerm` (query): string
- `sortBy` (query): string default=`date`
- `sortDirection` (query): string default=`desc`
- `pageIndex` (query): integer/int32 default=`1`
- `pageSize` (query): integer/int32 default=`20`

**Responses:**
- `200`: OK → array of `NotificationListViewModel`
  - `notificationId`: integer/int32
  - `title`: string *(null)*
  - `createdOnUtc`: string/date-time
  - `entityType`: string *(null)*
  - `entityId`: integer/int32 *(null)*
  - `entityGuid`: string/uuid *(null)*

---

### `POST /api/Notifications/pro/{proId}/mark-read`

**Parameters:**
- `proId` (path): integer/int32 **req**

**Responses:**
- `200`: OK

---

## Pages

### `GET /api/Pages`

**Parameters:**
- `pageIndex` (query): integer/int32 default=`1`
- `pageSize` (query): integer/int32 default=`10`

**Responses:**
- `200`: OK → array of `Page`
  - `pageId`: integer/int32
  - `title`: string *(null)*
  - `slug`: string *(null)*
  - `pageContent`: string *(null)*
  - `publicId`: string/uuid
  - `metaDesc`: string *(null)*
  - `createdDate`: string/date-time *(null)*
  - `modifiedDate`: string/date-time *(null)*

---

### `POST /api/Pages`

**Request body:**
Schema: `Page`
  - `pageId`: integer/int32
  - `title`: string *(null)*
  - `slug`: string *(null)*
  - `pageContent`: string *(null)*
  - `publicId`: string/uuid
  - `metaDesc`: string *(null)*
  - `createdDate`: string/date-time *(null)*
  - `modifiedDate`: string/date-time *(null)*

**Responses:**
- `200`: OK → `Page`
  - `pageId`: integer/int32
  - `title`: string *(null)*
  - `slug`: string *(null)*
  - `pageContent`: string *(null)*
  - `publicId`: string/uuid
  - `metaDesc`: string *(null)*
  - `createdDate`: string/date-time *(null)*
  - `modifiedDate`: string/date-time *(null)*

---

### `GET /api/Pages/slug/{slug}`

**Parameters:**
- `slug` (path): string **req**

**Responses:**
- `200`: OK → `InsightViewModel`
  - `insightId`: integer/int32
  - `title`: string **req**
  - `slug`: string **req**
  - `insightImage`: string *(null)*
  - `insightImageAltText`: string *(null)*
  - `insightContent`: string *(null)*
  - `metaDesc`: string *(null)*
  - `publishDate`: string/date-time *(null)*
  - `isHomePage`: boolean *(null)*
  - `isTopInsight`: boolean *(null)*

---

### `DELETE /api/Pages/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Responses:**
- `200`: OK

---

### `GET /api/Pages/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Responses:**
- `200`: OK → `Page`
  - `pageId`: integer/int32
  - `title`: string *(null)*
  - `slug`: string *(null)*
  - `pageContent`: string *(null)*
  - `publicId`: string/uuid
  - `metaDesc`: string *(null)*
  - `createdDate`: string/date-time *(null)*
  - `modifiedDate`: string/date-time *(null)*

---

### `PUT /api/Pages/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Request body:**
Schema: `Page`
  - `pageId`: integer/int32
  - `title`: string *(null)*
  - `slug`: string *(null)*
  - `pageContent`: string *(null)*
  - `publicId`: string/uuid
  - `metaDesc`: string *(null)*
  - `createdDate`: string/date-time *(null)*
  - `modifiedDate`: string/date-time *(null)*

**Responses:**
- `200`: OK

---

## PasswordResetTokens

### `GET /api/PasswordResetTokens`

**Responses:**
- `200`: OK → array of `PasswordResetToken`
  - `tokenId`: integer/int32
  - `userId`: integer/int32
  - `resetToken`: string *(null)*
  - `publicId`: string/uuid
  - `expirationDate`: string/date-time
  - `isUsed`: boolean
  - `createdDate`: string/date-time
  - `user`: `User`

---

### `POST /api/PasswordResetTokens`

**Request body:**
Schema: `PasswordResetToken`
  - `tokenId`: integer/int32
  - `userId`: integer/int32
  - `resetToken`: string *(null)*
  - `publicId`: string/uuid
  - `expirationDate`: string/date-time
  - `isUsed`: boolean
  - `createdDate`: string/date-time
  - `user`: `User`

**Responses:**
- `200`: OK → `PasswordResetToken`
  - `tokenId`: integer/int32
  - `userId`: integer/int32
  - `resetToken`: string *(null)*
  - `publicId`: string/uuid
  - `expirationDate`: string/date-time
  - `isUsed`: boolean
  - `createdDate`: string/date-time
  - `user`: `User`

---

### `DELETE /api/PasswordResetTokens/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Responses:**
- `200`: OK

---

### `GET /api/PasswordResetTokens/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Responses:**
- `200`: OK → `PasswordResetToken`
  - `tokenId`: integer/int32
  - `userId`: integer/int32
  - `resetToken`: string *(null)*
  - `publicId`: string/uuid
  - `expirationDate`: string/date-time
  - `isUsed`: boolean
  - `createdDate`: string/date-time
  - `user`: `User`

---

### `PUT /api/PasswordResetTokens/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Request body:**
Schema: `PasswordResetToken`
  - `tokenId`: integer/int32
  - `userId`: integer/int32
  - `resetToken`: string *(null)*
  - `publicId`: string/uuid
  - `expirationDate`: string/date-time
  - `isUsed`: boolean
  - `createdDate`: string/date-time
  - `user`: `User`

**Responses:**
- `200`: OK

---

## ProCategories

### `GET /api/ProCategories`

**Parameters:**
- `isActive` (query): boolean

**Responses:**
- `200`: OK → array of `ProCategoryViewModel`
  - `proCategoryId`: integer/int32
  - `categoryName`: string **req**
  - `description`: string *(null)*
  - `slug`: string *(null)*
  - `sortNo`: integer/int32
  - `isActive`: boolean
  - `publicId`: string/uuid

---

### `POST /api/ProCategories`

**Request body:**
Schema: `ProCategoryViewModel`
  - `proCategoryId`: integer/int32
  - `categoryName`: string **req**
  - `description`: string *(null)*
  - `slug`: string *(null)*
  - `sortNo`: integer/int32
  - `isActive`: boolean
  - `publicId`: string/uuid

**Responses:**
- `200`: OK → `ProCategoryViewModel`
  - `proCategoryId`: integer/int32
  - `categoryName`: string **req**
  - `description`: string *(null)*
  - `slug`: string *(null)*
  - `sortNo`: integer/int32
  - `isActive`: boolean
  - `publicId`: string/uuid

---

### `POST /api/ProCategories/match-problem`

**Request body:**
Schema: `CategoryMatchRequest`
  - `problemDescription`: string **req**

**Responses:**
- `200`: OK → `CategoryMatchResponse`
  - `matched`: boolean
  - `proCategoryId`: integer/int32 *(null)*
  - `categoryName`: string *(null)*
  - `slug`: string *(null)*

---

### `DELETE /api/ProCategories/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Responses:**
- `200`: OK

---

### `GET /api/ProCategories/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Responses:**
- `200`: OK → `ProCategoryViewModel`
  - `proCategoryId`: integer/int32
  - `categoryName`: string **req**
  - `description`: string *(null)*
  - `slug`: string *(null)*
  - `sortNo`: integer/int32
  - `isActive`: boolean
  - `publicId`: string/uuid

---

### `PUT /api/ProCategories/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Request body:**
Schema: `ProCategoryViewModel`
  - `proCategoryId`: integer/int32
  - `categoryName`: string **req**
  - `description`: string *(null)*
  - `slug`: string *(null)*
  - `sortNo`: integer/int32
  - `isActive`: boolean
  - `publicId`: string/uuid

**Responses:**
- `200`: OK

---

## ProProjectPhotos

### `GET /api/pros/{proId}/project-photos`

**Parameters:**
- `proId` (path): integer/int32 **req**

**Responses:**
- `200`: OK → array of `ProProjectPhotoDto`
  - `photoId`: integer/int32
  - `proId`: integer/int32
  - `fileName`: string *(null)*
  - `caption`: string *(null)*
  - `uploadedDate`: string/date-time
  - `isActive`: boolean

---

### `POST /api/pros/{proId}/project-photos`

**Parameters:**
- `proId` (path): integer/int32 **req**

**Request body:**
  - `file`: string/binary
  - `caption`: string

**Responses:**
- `200`: OK → `ProProjectPhotoDto`
  - `photoId`: integer/int32
  - `proId`: integer/int32
  - `fileName`: string *(null)*
  - `caption`: string *(null)*
  - `uploadedDate`: string/date-time
  - `isActive`: boolean

---

### `DELETE /api/pros/{proId}/project-photos/{photoId}`

**Parameters:**
- `proId` (path): integer/int32 **req**
- `photoId` (path): integer/int32 **req**

**Responses:**
- `200`: OK

---

## ProReviews

### `POST /api/ProReviews`

**Request body:**
Schema: `CreateProReviewViewModel`
  - `proId`: integer/int32 **req**
  - `userId`: integer/int32
  - `rating`: integer/int32 **req**
  - `reviewText`: string *(null)*
  - `reviewerName`: string **req**
  - `reviewerEmail`: string/email *(null)*

**Responses:**
- `200`: OK → `ProReviewViewModel`
  - `reviewId`: integer/int32
  - `proId`: integer/int32
  - `userId`: integer/int32
  - `rating`: integer/int32 **req**
  - `reviewText`: string *(null)*
  - `reviewerName`: string **req**
  - `reviewerEmail`: string/email *(null)*
  - `isVerified`: boolean
  - `isApproved`: boolean
  - `isActive`: boolean
  - `publicId`: string/uuid
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time
  - `companyResponseText`: string *(null)*
  - `companyResponseDate`: string/date-time *(null)*
  - `companyResponseByUserId`: integer/int32 *(null)*
  - `proName`: string *(null)*
  - `userName`: string *(null)*
  - `userEmail`: string *(null)*

---

### `GET /api/ProReviews/admin/pending`

**Parameters:**
- `pageIndex` (query): integer/int32 default=`1`
- `pageSize` (query): integer/int32 default=`10`

**Responses:**
- `200`: OK → array of `ProReviewViewModel`
  - `reviewId`: integer/int32
  - `proId`: integer/int32
  - `userId`: integer/int32
  - `rating`: integer/int32 **req**
  - `reviewText`: string *(null)*
  - `reviewerName`: string **req**
  - `reviewerEmail`: string/email *(null)*
  - `isVerified`: boolean
  - `isApproved`: boolean
  - `isActive`: boolean
  - `publicId`: string/uuid
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time
  - `companyResponseText`: string *(null)*
  - `companyResponseDate`: string/date-time *(null)*
  - `companyResponseByUserId`: integer/int32 *(null)*
  - `proName`: string *(null)*
  - `userName`: string *(null)*
  - `userEmail`: string *(null)*

---

### `GET /api/ProReviews/pro/{proId}`

**Parameters:**
- `proId` (path): integer/int32 **req**
- `pageIndex` (query): integer/int32 default=`1`
- `pageSize` (query): integer/int32 default=`10`

**Responses:**
- `200`: OK → `ProReviewSummaryViewModel`
  - `proId`: integer/int32
  - `averageRating`: number/double
  - `totalReviews`: integer/int32
  - `ratingDistribution`: object *(null)*
  - `recentReviews`: array of `ProReviewViewModel` *(null)*

---

### `GET /api/ProReviews/pro/{proId}/all`

**Parameters:**
- `proId` (path): integer/int32 **req**

**Responses:**
- `200`: OK → array of `ProReviewViewModel`
  - `reviewId`: integer/int32
  - `proId`: integer/int32
  - `userId`: integer/int32
  - `rating`: integer/int32 **req**
  - `reviewText`: string *(null)*
  - `reviewerName`: string **req**
  - `reviewerEmail`: string/email *(null)*
  - `isVerified`: boolean
  - `isApproved`: boolean
  - `isActive`: boolean
  - `publicId`: string/uuid
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time
  - `companyResponseText`: string *(null)*
  - `companyResponseDate`: string/date-time *(null)*
  - `companyResponseByUserId`: integer/int32 *(null)*
  - `proName`: string *(null)*
  - `userName`: string *(null)*
  - `userEmail`: string *(null)*

---

### `DELETE /api/ProReviews/{reviewId}`

**Parameters:**
- `reviewId` (path): integer/int32 **req**

**Responses:**
- `200`: OK

---

### `GET /api/ProReviews/{reviewId}`

**Parameters:**
- `reviewId` (path): integer/int32 **req**

**Responses:**
- `200`: OK → `ProReviewViewModel`
  - `reviewId`: integer/int32
  - `proId`: integer/int32
  - `userId`: integer/int32
  - `rating`: integer/int32 **req**
  - `reviewText`: string *(null)*
  - `reviewerName`: string **req**
  - `reviewerEmail`: string/email *(null)*
  - `isVerified`: boolean
  - `isApproved`: boolean
  - `isActive`: boolean
  - `publicId`: string/uuid
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time
  - `companyResponseText`: string *(null)*
  - `companyResponseDate`: string/date-time *(null)*
  - `companyResponseByUserId`: integer/int32 *(null)*
  - `proName`: string *(null)*
  - `userName`: string *(null)*
  - `userEmail`: string *(null)*

---

### `PUT /api/ProReviews/{reviewId}`

**Parameters:**
- `reviewId` (path): integer/int32 **req**

**Request body:**
Schema: `ProReviewViewModel`
  - `reviewId`: integer/int32
  - `proId`: integer/int32
  - `userId`: integer/int32
  - `rating`: integer/int32 **req**
  - `reviewText`: string *(null)*
  - `reviewerName`: string **req**
  - `reviewerEmail`: string/email *(null)*
  - `isVerified`: boolean
  - `isApproved`: boolean
  - `isActive`: boolean
  - `publicId`: string/uuid
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time
  - `companyResponseText`: string *(null)*
  - `companyResponseDate`: string/date-time *(null)*
  - `companyResponseByUserId`: integer/int32 *(null)*
  - `proName`: string *(null)*
  - `userName`: string *(null)*
  - `userEmail`: string *(null)*

**Responses:**
- `200`: OK

---

### `PUT /api/ProReviews/{reviewId}/approve`

**Parameters:**
- `reviewId` (path): integer/int32 **req**

**Responses:**
- `200`: OK

---

### `PUT /api/ProReviews/{reviewId}/reject`

**Parameters:**
- `reviewId` (path): integer/int32 **req**

**Responses:**
- `200`: OK

---

### `PUT /api/ProReviews/{reviewId}/respond`

**Parameters:**
- `reviewId` (path): integer/int32 **req**

**Request body:**
Schema: `RespondToProReviewViewModel`
  - `companyResponseText`: string **req**
  - `currentUserId`: integer/int32 **req**

**Responses:**
- `200`: OK

---

## ProSearch

### `GET /api/ProSearch/top-cities`

**Parameters:**
- `page` (query): integer/int32 default=`1`
- `pageSize` (query): integer/int32 default=`10`

**Responses:**
- `200`: OK → array of `ProSearchTopCity`
  - `cityId`: integer/int32
  - `cityName`: string *(null)*
  - `stateName`: string *(null)*
  - `scrapped`: boolean *(null)*

---

### `PUT /api/ProSearch/top-cities/{cityId}/scrapped`

**Parameters:**
- `cityId` (path): integer/int32 **req**
- `scrapped` (query): boolean

**Responses:**
- `200`: OK

---

## Pros

### `GET /api/Pros`

**Responses:**
- `200`: OK → array of `Pro`
  - `proId`: integer/int32
  - `serdenProId`: string *(null)*
  - `proName`: string *(null)*
  - `slug`: string *(null)*
  - `proLogo`: string *(null)*
  - `phone`: string *(null)*
  - `website`: string *(null)*
  - `aboutCompany`: string *(null)*
  - `streetAddress`: string *(null)*
  - `addressLine2`: string *(null)*
  - `city`: string *(null)*
  - `state`: string *(null)*
  - `zipCode`: string *(null)*
  - `latitude`: number/double *(null)*
  - `longitude`: number/double *(null)*
  - `userId`: integer/int32 *(null)*
  - `publicId`: string/uuid
  - `isActive`: boolean
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time *(null)*
  - `licenseNumber`: string *(null)*
  - `insuranceNumber`: string *(null)*
  - `yearFounded`: integer/int32 *(null)*
  - `facebookUrl`: string *(null)*
  - `instagramUrl`: string *(null)*
  - `linkedInUrl`: string *(null)*
  - `twitterUrl`: string *(null)*
  - `youTubeUrl`: string *(null)*
  - `businessHours`: string *(null)*
  - `email`: string *(null)*
  - `isInDirectory`: boolean
  - `hasUnreadNotifications`: boolean
  - `clients`: array of `Client` *(null)*
  - `estimateNumberSequence`: `EstimateNumberSequence`
  - `estimates`: array of `Estimate` *(null)*
  - `invoices`: array of `Invoice` *(null)*
  - `lineItemMarkups`: array of `LineItemMarkup` *(null)*
  - `lineItems`: array of `LineItem` *(null)*
  - `notifications`: array of `Notification` *(null)*
  - `proEmailLogs`: array of `ProEmailLog` *(null)*
  - `proInternalMessageLogs`: array of `ProInternalMessageLog` *(null)*
  - `proProjectPhotos`: array of `ProProjectPhoto` *(null)*
  - `proReviews`: array of `ProReview` *(null)*
  - `prosToAreaServeds`: array of `ProsToAreaServed` *(null)*
  - `prosToCategories`: array of `ProsToCategory` *(null)*
  - `prosToServiceTags`: array of `ProsToServiceTag` *(null)*
  - `requestQuotes`: array of `RequestQuote` *(null)*
  - `taxes`: array of `Taxis` *(null)*
  - `user`: `User`

---

### `POST /api/Pros`

**Request body:**
Schema: `ProViewModel`
  - `proId`: integer/int32
  - `serdenProId`: string *(null)*
  - `slug`: string *(null)*
  - `proName`: string *(null)*
  - `proLogo`: string *(null)*
  - `phone`: string *(null)*
  - `website`: string *(null)*
  - `aboutCompany`: string *(null)*
  - `streetAddress`: string *(null)*
  - `addressLine2`: string *(null)*
  - `city`: string *(null)*
  - `state`: string *(null)*
  - `zipCode`: string *(null)*
  - `latitude`: number/double *(null)*
  - `longitude`: number/double *(null)*
  - `isActive`: boolean
  - `publicId`: string *(null)*
  - `userId`: integer/int32 *(null)*
  - `roleId`: integer/int32 *(null)*
  - `serviceTags`: array of `ServiceTagViewModel` *(null)*
  - `categories`: array of `CategoryViewModel` *(null)*
  - `licenseNumber`: string *(null)*
  - `insuranceNumber`: string *(null)*
  - `yearFounded`: integer/int32 *(null)*
  - `facebookUrl`: string *(null)*
  - `instagramUrl`: string *(null)*
  - `linkedInUrl`: string *(null)*
  - `twitterUrl`: string *(null)*
  - `youTubeUrl`: string *(null)*
  - `businessHours`: string *(null)*
  - `email`: string *(null)*
  - `projectPhotos`: array of `ProProjectPhotoDto` *(null)*
  - `areasServed`: array of `ProsToAreaServedDto` *(null)*
  - `reviewSummary`: `ProReviewSummaryViewModel`
  - `isInDirectory`: boolean
  - `hasUnreadNotifications`: boolean

**Responses:**
- `200`: OK → `ProViewModel`
  - `proId`: integer/int32
  - `serdenProId`: string *(null)*
  - `slug`: string *(null)*
  - `proName`: string *(null)*
  - `proLogo`: string *(null)*
  - `phone`: string *(null)*
  - `website`: string *(null)*
  - `aboutCompany`: string *(null)*
  - `streetAddress`: string *(null)*
  - `addressLine2`: string *(null)*
  - `city`: string *(null)*
  - `state`: string *(null)*
  - `zipCode`: string *(null)*
  - `latitude`: number/double *(null)*
  - `longitude`: number/double *(null)*
  - `isActive`: boolean
  - `publicId`: string *(null)*
  - `userId`: integer/int32 *(null)*
  - `roleId`: integer/int32 *(null)*
  - `serviceTags`: array of `ServiceTagViewModel` *(null)*
  - `categories`: array of `CategoryViewModel` *(null)*
  - `licenseNumber`: string *(null)*
  - `insuranceNumber`: string *(null)*
  - `yearFounded`: integer/int32 *(null)*
  - `facebookUrl`: string *(null)*
  - `instagramUrl`: string *(null)*
  - `linkedInUrl`: string *(null)*
  - `twitterUrl`: string *(null)*
  - `youTubeUrl`: string *(null)*
  - `businessHours`: string *(null)*
  - `email`: string *(null)*
  - `projectPhotos`: array of `ProProjectPhotoDto` *(null)*
  - `areasServed`: array of `ProsToAreaServedDto` *(null)*
  - `reviewSummary`: `ProReviewSummaryViewModel`
  - `isInDirectory`: boolean
  - `hasUnreadNotifications`: boolean

---

### `GET /api/Pros/ProSearch`

**Parameters:**
- `page` (query): integer/int32 default=`1`
- `pageSize` (query): integer/int32 default=`10`
- `filter` (query): string default=`all`

**Responses:**
- `200`: OK → array of `ProSearchScrapperResult`
  - `id`: integer/int32
  - `proName`: string *(null)*
  - `proLogo`: string *(null)*
  - `phone`: string *(null)*
  - `website`: string *(null)*
  - `aboutCompany`: string *(null)*
  - `streetAddress`: string *(null)*
  - `addressLine2`: string *(null)*
  - `city`: string *(null)*
  - `state`: string *(null)*
  - `zipcode`: string *(null)*
  - `latitude`: number/double *(null)*
  - `longitude`: number/double *(null)*
  - `isAdded`: boolean *(null)*
  - `createdDate`: string/date-time *(null)*
  - `modifiedDate`: string/date-time *(null)*
  - `proSearchScrapperResultProsToCategories`: array of `ProSearchScrapperResultProsToCategory` *(null)*

---

### `DELETE /api/Pros/ProSearch/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Responses:**
- `200`: OK

---

### `PUT /api/Pros/ProSearch/{id}/status`

**Parameters:**
- `id` (path): integer/int32 **req**
- `isAdded` (query): boolean

**Responses:**
- `200`: OK

---

### `GET /api/Pros/directory`

**Parameters:**
- `roleId` (query): integer/int32
- `searchSerdenId` (query): string
- `searchTerm` (query): string
- `sortBy` (query): string
- `sortDirection` (query): string default=`desc`
- `aboutUsFilter` (query): string
- `emailFilter` (query): string
- `stateFilter` (query): string
- `cityFilter` (query): string
- `duplicateFilter` (query): string
- `categoryFilter` (query): integer/int32
- `pageIndex` (query): integer/int32 default=`1`
- `pageSize` (query): integer/int32 default=`10`

**Responses:**
- `200`: OK → array of `ProLiteViewModel`
  - `proId`: integer/int32
  - `serdenProId`: string *(null)*
  - `slug`: string *(null)*
  - `proName`: string *(null)*
  - `proLogo`: string *(null)*
  - `streetAddress`: string *(null)*
  - `addressLine2`: string *(null)*
  - `city`: string *(null)*
  - `state`: string *(null)*
  - `zipCode`: string *(null)*
  - `email`: string *(null)*
  - `publicId`: string *(null)*
  - `roleId`: integer/int32
  - `categories`: array of string *(null)*
  - `services`: array of string *(null)*
  - `areasServed`: array of string *(null)*
  - `businessHours`: string *(null)*
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time *(null)*
  - `aboutCompany`: string *(null)*

---

### `GET /api/Pros/internal-message-log-counts`

**Parameters:**
- `proIds` (query): string

**Responses:**
- `200`: OK → object

---

### `POST /api/Pros/save-search-results`

**Request body:**
Schema: array of `BusinessResult`

**Responses:**
- `200`: OK → array of integer/int32

---

### `GET /api/Pros/search`

**Parameters:**
- `categoryIds` (query): array of integer/int32
- `serviceTagIds` (query): array of integer/int32
- `city` (query): string
- `state` (query): string
- `zipCode` (query): string
- `searchTerm` (query): string
- `radiusMiles` (query): number/float default=`25`
- `pageNumber` (query): integer/int32 default=`1`
- `pageSize` (query): integer/int32 default=`10`

**Responses:**
- `200`: OK → array of `ProViewModel`
  - `proId`: integer/int32
  - `serdenProId`: string *(null)*
  - `slug`: string *(null)*
  - `proName`: string *(null)*
  - `proLogo`: string *(null)*
  - `phone`: string *(null)*
  - `website`: string *(null)*
  - `aboutCompany`: string *(null)*
  - `streetAddress`: string *(null)*
  - `addressLine2`: string *(null)*
  - `city`: string *(null)*
  - `state`: string *(null)*
  - `zipCode`: string *(null)*
  - `latitude`: number/double *(null)*
  - `longitude`: number/double *(null)*
  - `isActive`: boolean
  - `publicId`: string *(null)*
  - `userId`: integer/int32 *(null)*
  - `roleId`: integer/int32 *(null)*
  - `serviceTags`: array of `ServiceTagViewModel` *(null)*
  - `categories`: array of `CategoryViewModel` *(null)*
  - `licenseNumber`: string *(null)*
  - `insuranceNumber`: string *(null)*
  - `yearFounded`: integer/int32 *(null)*
  - `facebookUrl`: string *(null)*
  - `instagramUrl`: string *(null)*
  - `linkedInUrl`: string *(null)*
  - `twitterUrl`: string *(null)*
  - `youTubeUrl`: string *(null)*
  - `businessHours`: string *(null)*
  - `email`: string *(null)*
  - `projectPhotos`: array of `ProProjectPhotoDto` *(null)*
  - `areasServed`: array of `ProsToAreaServedDto` *(null)*
  - `reviewSummary`: `ProReviewSummaryViewModel`
  - `isInDirectory`: boolean
  - `hasUnreadNotifications`: boolean

---

### `GET /api/Pros/send-bulk-welcome-email`

**Responses:**
- `200`: OK

---

### `GET /api/Pros/slug/{slug}`

**Parameters:**
- `slug` (path): string **req**

**Responses:**
- `200`: OK → `ProViewModel`
  - `proId`: integer/int32
  - `serdenProId`: string *(null)*
  - `slug`: string *(null)*
  - `proName`: string *(null)*
  - `proLogo`: string *(null)*
  - `phone`: string *(null)*
  - `website`: string *(null)*
  - `aboutCompany`: string *(null)*
  - `streetAddress`: string *(null)*
  - `addressLine2`: string *(null)*
  - `city`: string *(null)*
  - `state`: string *(null)*
  - `zipCode`: string *(null)*
  - `latitude`: number/double *(null)*
  - `longitude`: number/double *(null)*
  - `isActive`: boolean
  - `publicId`: string *(null)*
  - `userId`: integer/int32 *(null)*
  - `roleId`: integer/int32 *(null)*
  - `serviceTags`: array of `ServiceTagViewModel` *(null)*
  - `categories`: array of `CategoryViewModel` *(null)*
  - `licenseNumber`: string *(null)*
  - `insuranceNumber`: string *(null)*
  - `yearFounded`: integer/int32 *(null)*
  - `facebookUrl`: string *(null)*
  - `instagramUrl`: string *(null)*
  - `linkedInUrl`: string *(null)*
  - `twitterUrl`: string *(null)*
  - `youTubeUrl`: string *(null)*
  - `businessHours`: string *(null)*
  - `email`: string *(null)*
  - `projectPhotos`: array of `ProProjectPhotoDto` *(null)*
  - `areasServed`: array of `ProsToAreaServedDto` *(null)*
  - `reviewSummary`: `ProReviewSummaryViewModel`
  - `isInDirectory`: boolean
  - `hasUnreadNotifications`: boolean

---

### `GET /api/Pros/update-all-slugs`

**Responses:**
- `200`: OK → object

---

### `POST /api/Pros/upload-search-image`

**Request body:**
Schema: `SearchImageUploadRequest`
  - `imageUrl`: string *(null)*
  - `businessName`: string *(null)*

**Responses:**
- `200`: OK → string

---

### `GET /api/Pros/user/{userId}`

**Parameters:**
- `userId` (path): integer/int32 **req**

**Responses:**
- `200`: OK → `ProViewModel`
  - `proId`: integer/int32
  - `serdenProId`: string *(null)*
  - `slug`: string *(null)*
  - `proName`: string *(null)*
  - `proLogo`: string *(null)*
  - `phone`: string *(null)*
  - `website`: string *(null)*
  - `aboutCompany`: string *(null)*
  - `streetAddress`: string *(null)*
  - `addressLine2`: string *(null)*
  - `city`: string *(null)*
  - `state`: string *(null)*
  - `zipCode`: string *(null)*
  - `latitude`: number/double *(null)*
  - `longitude`: number/double *(null)*
  - `isActive`: boolean
  - `publicId`: string *(null)*
  - `userId`: integer/int32 *(null)*
  - `roleId`: integer/int32 *(null)*
  - `serviceTags`: array of `ServiceTagViewModel` *(null)*
  - `categories`: array of `CategoryViewModel` *(null)*
  - `licenseNumber`: string *(null)*
  - `insuranceNumber`: string *(null)*
  - `yearFounded`: integer/int32 *(null)*
  - `facebookUrl`: string *(null)*
  - `instagramUrl`: string *(null)*
  - `linkedInUrl`: string *(null)*
  - `twitterUrl`: string *(null)*
  - `youTubeUrl`: string *(null)*
  - `businessHours`: string *(null)*
  - `email`: string *(null)*
  - `projectPhotos`: array of `ProProjectPhotoDto` *(null)*
  - `areasServed`: array of `ProsToAreaServedDto` *(null)*
  - `reviewSummary`: `ProReviewSummaryViewModel`
  - `isInDirectory`: boolean
  - `hasUnreadNotifications`: boolean

---

### `DELETE /api/Pros/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Responses:**
- `200`: OK

---

### `GET /api/Pros/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Responses:**
- `200`: OK → `Pro`
  - `proId`: integer/int32
  - `serdenProId`: string *(null)*
  - `proName`: string *(null)*
  - `slug`: string *(null)*
  - `proLogo`: string *(null)*
  - `phone`: string *(null)*
  - `website`: string *(null)*
  - `aboutCompany`: string *(null)*
  - `streetAddress`: string *(null)*
  - `addressLine2`: string *(null)*
  - `city`: string *(null)*
  - `state`: string *(null)*
  - `zipCode`: string *(null)*
  - `latitude`: number/double *(null)*
  - `longitude`: number/double *(null)*
  - `userId`: integer/int32 *(null)*
  - `publicId`: string/uuid
  - `isActive`: boolean
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time *(null)*
  - `licenseNumber`: string *(null)*
  - `insuranceNumber`: string *(null)*
  - `yearFounded`: integer/int32 *(null)*
  - `facebookUrl`: string *(null)*
  - `instagramUrl`: string *(null)*
  - `linkedInUrl`: string *(null)*
  - `twitterUrl`: string *(null)*
  - `youTubeUrl`: string *(null)*
  - `businessHours`: string *(null)*
  - `email`: string *(null)*
  - `isInDirectory`: boolean
  - `hasUnreadNotifications`: boolean
  - `clients`: array of `Client` *(null)*
  - `estimateNumberSequence`: `EstimateNumberSequence`
  - `estimates`: array of `Estimate` *(null)*
  - `invoices`: array of `Invoice` *(null)*
  - `lineItemMarkups`: array of `LineItemMarkup` *(null)*
  - `lineItems`: array of `LineItem` *(null)*
  - `notifications`: array of `Notification` *(null)*
  - `proEmailLogs`: array of `ProEmailLog` *(null)*
  - `proInternalMessageLogs`: array of `ProInternalMessageLog` *(null)*
  - `proProjectPhotos`: array of `ProProjectPhoto` *(null)*
  - `proReviews`: array of `ProReview` *(null)*
  - `prosToAreaServeds`: array of `ProsToAreaServed` *(null)*
  - `prosToCategories`: array of `ProsToCategory` *(null)*
  - `prosToServiceTags`: array of `ProsToServiceTag` *(null)*
  - `requestQuotes`: array of `RequestQuote` *(null)*
  - `taxes`: array of `Taxis` *(null)*
  - `user`: `User`

---

### `PUT /api/Pros/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Request body:**
Schema: `ProViewModel`
  - `proId`: integer/int32
  - `serdenProId`: string *(null)*
  - `slug`: string *(null)*
  - `proName`: string *(null)*
  - `proLogo`: string *(null)*
  - `phone`: string *(null)*
  - `website`: string *(null)*
  - `aboutCompany`: string *(null)*
  - `streetAddress`: string *(null)*
  - `addressLine2`: string *(null)*
  - `city`: string *(null)*
  - `state`: string *(null)*
  - `zipCode`: string *(null)*
  - `latitude`: number/double *(null)*
  - `longitude`: number/double *(null)*
  - `isActive`: boolean
  - `publicId`: string *(null)*
  - `userId`: integer/int32 *(null)*
  - `roleId`: integer/int32 *(null)*
  - `serviceTags`: array of `ServiceTagViewModel` *(null)*
  - `categories`: array of `CategoryViewModel` *(null)*
  - `licenseNumber`: string *(null)*
  - `insuranceNumber`: string *(null)*
  - `yearFounded`: integer/int32 *(null)*
  - `facebookUrl`: string *(null)*
  - `instagramUrl`: string *(null)*
  - `linkedInUrl`: string *(null)*
  - `twitterUrl`: string *(null)*
  - `youTubeUrl`: string *(null)*
  - `businessHours`: string *(null)*
  - `email`: string *(null)*
  - `projectPhotos`: array of `ProProjectPhotoDto` *(null)*
  - `areasServed`: array of `ProsToAreaServedDto` *(null)*
  - `reviewSummary`: `ProReviewSummaryViewModel`
  - `isInDirectory`: boolean
  - `hasUnreadNotifications`: boolean

**Responses:**
- `200`: OK

---

### `DELETE /api/Pros/{id}/delete-image`

**Parameters:**
- `id` (path): integer/int32 **req**

**Responses:**
- `200`: OK

---

### `POST /api/Pros/{id}/upload-image`

**Parameters:**
- `id` (path): integer/int32 **req**

**Request body:**
  - `file`: string/binary

**Responses:**
- `200`: OK → `ImageUploadResponse`
  - `imageUrl`: string *(null)*

---

### `GET /api/Pros/{proId}/areas-served`

**Parameters:**
- `proId` (path): integer/int32 **req**

**Responses:**
- `200`: OK → array of `ProsToAreaServedDto`
  - `id`: integer/int32
  - `proId`: integer/int32
  - `areaName`: string *(null)*
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time

---

### `POST /api/Pros/{proId}/areas-served`

**Parameters:**
- `proId` (path): integer/int32 **req**

**Request body:**
Schema: array of string

**Responses:**
- `200`: OK

---

### `GET /api/Pros/{proId}/categories`

**Parameters:**
- `proId` (path): integer/int32 **req**

**Responses:**
- `200`: OK → array of integer/int32

---

### `POST /api/Pros/{proId}/categories`

**Parameters:**
- `proId` (path): integer/int32 **req**

**Request body:**
Schema: array of integer/int32

**Responses:**
- `200`: OK

---

### `GET /api/Pros/{proId}/email-history`

**Parameters:**
- `proId` (path): integer/int32 **req**

**Responses:**
- `200`: OK → array of any

---

### `GET /api/Pros/{proId}/internal-message-log`

**Parameters:**
- `proId` (path): integer/int32 **req**
- `pageIndex` (query): integer/int32 default=`1`
- `pageSize` (query): integer/int32 default=`10`

**Responses:**
- `200`: OK → `ProInternalMessageLogPagedResult`
  - `items`: array of `ProInternalMessageLogItemViewModel` *(null)*
  - `totalCount`: integer/int32

---

### `POST /api/Pros/{proId}/internal-message-log`

**Parameters:**
- `proId` (path): integer/int32 **req**

**Request body:**
Schema: `ProInternalMessageLogCreateViewModel`
  - `messageType`: string *(null)*
  - `subject`: string *(null)*
  - `body`: string *(null)*

**Responses:**
- `200`: OK → `ProInternalMessageLogItemViewModel`
  - `id`: integer/int32
  - `proId`: integer/int32
  - `messageType`: string *(null)*
  - `subject`: string *(null)*
  - `body`: string *(null)*
  - `createdByUserId`: integer/int32 *(null)*
  - `createdByDisplayName`: string *(null)*
  - `createdDate`: string/date-time

---

### `POST /api/Pros/{proId}/send-review-request-email`

**Parameters:**
- `proId` (path): integer/int32 **req**

**Request body:**
Schema: `ProReviewRequestEmailViewModel`
  - `toEmail`: string/email **req**
  - `fromEmail`: string/email **req**
  - `subject`: string **req**
  - `message`: string **req**
  - `reviewPageUrl`: string *(null)*

**Responses:**
- `200`: OK

---

### `POST /api/Pros/{proId}/send-welcome-email`

**Parameters:**
- `proId` (path): integer/int32 **req**

**Responses:**
- `200`: OK

---

### `GET /api/Pros/{proId}/servicetags`

**Parameters:**
- `proId` (path): integer/int32 **req**

**Responses:**
- `200`: OK → array of integer/int32

---

### `POST /api/Pros/{proId}/servicetags`

**Parameters:**
- `proId` (path): integer/int32 **req**

**Request body:**
Schema: array of integer/int32

**Responses:**
- `200`: OK

---

## Replies

### `GET /api/Replies`

**Responses:**
- `200`: OK → array of `Reply`
  - `replyId`: integer/int32
  - `discussionId`: integer/int32
  - `replyText`: string *(null)*
  - `publicId`: string/uuid
  - `createdBy`: integer/int32
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time
  - `createdByNavigation`: `User`
  - `discussion`: `Discussion`

---

### `POST /api/Replies`

**Request body:**
Schema: `Reply`
  - `replyId`: integer/int32
  - `discussionId`: integer/int32
  - `replyText`: string *(null)*
  - `publicId`: string/uuid
  - `createdBy`: integer/int32
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time
  - `createdByNavigation`: `User`
  - `discussion`: `Discussion`

**Responses:**
- `200`: OK → `Reply`
  - `replyId`: integer/int32
  - `discussionId`: integer/int32
  - `replyText`: string *(null)*
  - `publicId`: string/uuid
  - `createdBy`: integer/int32
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time
  - `createdByNavigation`: `User`
  - `discussion`: `Discussion`

---

### `DELETE /api/Replies/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Responses:**
- `200`: OK

---

### `GET /api/Replies/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Responses:**
- `200`: OK → `Reply`
  - `replyId`: integer/int32
  - `discussionId`: integer/int32
  - `replyText`: string *(null)*
  - `publicId`: string/uuid
  - `createdBy`: integer/int32
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time
  - `createdByNavigation`: `User`
  - `discussion`: `Discussion`

---

### `PUT /api/Replies/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Request body:**
Schema: `Reply`
  - `replyId`: integer/int32
  - `discussionId`: integer/int32
  - `replyText`: string *(null)*
  - `publicId`: string/uuid
  - `createdBy`: integer/int32
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time
  - `createdByNavigation`: `User`
  - `discussion`: `Discussion`

**Responses:**
- `200`: OK

---

## RequestQuotes

### `GET /api/RequestQuotes`

**Parameters:**
- `pageIndex` (query): integer/int32 default=`0`
- `pageSize` (query): integer/int32 default=`10`

**Responses:**
- `200`: OK → array of `RequestQuote`
  - `requestId`: integer/int32
  - `firstName`: string *(null)*
  - `lastName`: string *(null)*
  - `phone`: string *(null)*
  - `email`: string *(null)*
  - `streetAddress`: string *(null)*
  - `addressLine2`: string *(null)*
  - `city`: string *(null)*
  - `state`: string *(null)*
  - `zipCode`: string *(null)*
  - `requestText`: string *(null)*
  - `proCategoryId`: integer/int32 *(null)*
  - `proId`: integer/int32
  - `publicId`: string/uuid
  - `createdDate`: string/date-time
  - `status`: string *(null)*
  - `notes`: string *(null)*
  - `leadCost`: number/double *(null)*
  - `leadSource`: string *(null)*
  - `leadHistories`: array of `LeadHistory` *(null)*
  - `leadNotes`: array of `LeadNote` *(null)*
  - `pro`: `Pro`
  - `proCategory`: `ProCategory`

---

### `POST /api/RequestQuotes`

**Request body:**
Schema: `QuoteRequestViewModel`
  - `requestID`: integer/int32
  - `proCategoryID`: integer/int32
  - `firstName`: string **req**
  - `lastName`: string **req**
  - `phone`: string/tel **req**
  - `email`: string/email **req**
  - `streetAddress`: string *(null)*
  - `city`: string *(null)*
  - `state`: string *(null)*
  - `zipCode`: string *(null)*
  - `requestText`: string **req**
  - `proID`: integer/int32 *(null)*
  - `createdDate`: string/date-time
  - `turnstileToken`: string **req**

**Responses:**
- `200`: OK

---

### `GET /api/RequestQuotes/my-requests`

**Parameters:**
- `userId` (query): integer/int32
- `pageIndex` (query): integer/int32 default=`0`
- `pageSize` (query): integer/int32 default=`10`
- `search` (query): string
- `statusGroup` (query): string default=`all`
- `dateFilter` (query): string default=`all`
- `startDate` (query): string/date-time
- `endDate` (query): string/date-time

**Responses:**
- `200`: OK → array of `RequestQuote`
  - `requestId`: integer/int32
  - `firstName`: string *(null)*
  - `lastName`: string *(null)*
  - `phone`: string *(null)*
  - `email`: string *(null)*
  - `streetAddress`: string *(null)*
  - `addressLine2`: string *(null)*
  - `city`: string *(null)*
  - `state`: string *(null)*
  - `zipCode`: string *(null)*
  - `requestText`: string *(null)*
  - `proCategoryId`: integer/int32 *(null)*
  - `proId`: integer/int32
  - `publicId`: string/uuid
  - `createdDate`: string/date-time
  - `status`: string *(null)*
  - `notes`: string *(null)*
  - `leadCost`: number/double *(null)*
  - `leadSource`: string *(null)*
  - `leadHistories`: array of `LeadHistory` *(null)*
  - `leadNotes`: array of `LeadNote` *(null)*
  - `pro`: `Pro`
  - `proCategory`: `ProCategory`

---

### `POST /api/RequestQuotes/my-requests`

**Parameters:**
- `userId` (query): integer/int32

**Request body:**
Schema: `CreateMyLeadDto`
  - `firstName`: string *(null)*
  - `lastName`: string *(null)*
  - `phone`: string *(null)*
  - `email`: string *(null)*
  - `streetAddress`: string *(null)*
  - `addressLine2`: string *(null)*
  - `city`: string *(null)*
  - `state`: string *(null)*
  - `zipCode`: string *(null)*
  - `requestText`: string *(null)*
  - `proCategoryId`: integer/int32 *(null)*
  - `createdDate`: string/date-time *(null)*
  - `leadCost`: number/double *(null)*
  - `leadSource`: string *(null)*
  - `status`: string *(null)*

**Responses:**
- `200`: OK → `RequestQuote`
  - `requestId`: integer/int32
  - `firstName`: string *(null)*
  - `lastName`: string *(null)*
  - `phone`: string *(null)*
  - `email`: string *(null)*
  - `streetAddress`: string *(null)*
  - `addressLine2`: string *(null)*
  - `city`: string *(null)*
  - `state`: string *(null)*
  - `zipCode`: string *(null)*
  - `requestText`: string *(null)*
  - `proCategoryId`: integer/int32 *(null)*
  - `proId`: integer/int32
  - `publicId`: string/uuid
  - `createdDate`: string/date-time
  - `status`: string *(null)*
  - `notes`: string *(null)*
  - `leadCost`: number/double *(null)*
  - `leadSource`: string *(null)*
  - `leadHistories`: array of `LeadHistory` *(null)*
  - `leadNotes`: array of `LeadNote` *(null)*
  - `pro`: `Pro`
  - `proCategory`: `ProCategory`

---

### `GET /api/RequestQuotes/my-requests/by-public-id/{publicId}`

**Parameters:**
- `publicId` (path): string/uuid **req**
- `userId` (query): integer/int32

**Responses:**
- `200`: OK → `RequestQuote`
  - `requestId`: integer/int32
  - `firstName`: string *(null)*
  - `lastName`: string *(null)*
  - `phone`: string *(null)*
  - `email`: string *(null)*
  - `streetAddress`: string *(null)*
  - `addressLine2`: string *(null)*
  - `city`: string *(null)*
  - `state`: string *(null)*
  - `zipCode`: string *(null)*
  - `requestText`: string *(null)*
  - `proCategoryId`: integer/int32 *(null)*
  - `proId`: integer/int32
  - `publicId`: string/uuid
  - `createdDate`: string/date-time
  - `status`: string *(null)*
  - `notes`: string *(null)*
  - `leadCost`: number/double *(null)*
  - `leadSource`: string *(null)*
  - `leadHistories`: array of `LeadHistory` *(null)*
  - `leadNotes`: array of `LeadNote` *(null)*
  - `pro`: `Pro`
  - `proCategory`: `ProCategory`

---

### `GET /api/RequestQuotes/my-requests/export`

**Parameters:**
- `userId` (query): integer/int32
- `search` (query): string
- `statusGroup` (query): string default=`all`
- `dateFilter` (query): string default=`all`
- `startDate` (query): string/date-time
- `endDate` (query): string/date-time

**Responses:**
- `200`: OK

---

### `DELETE /api/RequestQuotes/my-requests/{requestId}`

**Parameters:**
- `requestId` (path): integer/int32 **req**
- `userId` (query): integer/int32

**Responses:**
- `200`: OK

---

### `GET /api/RequestQuotes/my-requests/{requestId}`

**Parameters:**
- `requestId` (path): integer/int32 **req**
- `userId` (query): integer/int32

**Responses:**
- `200`: OK → `RequestQuote`
  - `requestId`: integer/int32
  - `firstName`: string *(null)*
  - `lastName`: string *(null)*
  - `phone`: string *(null)*
  - `email`: string *(null)*
  - `streetAddress`: string *(null)*
  - `addressLine2`: string *(null)*
  - `city`: string *(null)*
  - `state`: string *(null)*
  - `zipCode`: string *(null)*
  - `requestText`: string *(null)*
  - `proCategoryId`: integer/int32 *(null)*
  - `proId`: integer/int32
  - `publicId`: string/uuid
  - `createdDate`: string/date-time
  - `status`: string *(null)*
  - `notes`: string *(null)*
  - `leadCost`: number/double *(null)*
  - `leadSource`: string *(null)*
  - `leadHistories`: array of `LeadHistory` *(null)*
  - `leadNotes`: array of `LeadNote` *(null)*
  - `pro`: `Pro`
  - `proCategory`: `ProCategory`

---

### `PATCH /api/RequestQuotes/my-requests/{requestId}`

**Parameters:**
- `requestId` (path): integer/int32 **req**
- `userId` (query): integer/int32

**Request body:**
Schema: `UpdateMyLeadDto`
  - `status`: string *(null)*
  - `notes`: string *(null)*

**Responses:**
- `200`: OK

---

### `PUT /api/RequestQuotes/my-requests/{requestId}`

**Parameters:**
- `requestId` (path): integer/int32 **req**
- `userId` (query): integer/int32

**Request body:**
Schema: `UpdateMyLeadFullDto`
  - `firstName`: string *(null)*
  - `lastName`: string *(null)*
  - `phone`: string *(null)*
  - `email`: string *(null)*
  - `streetAddress`: string *(null)*
  - `addressLine2`: string *(null)*
  - `city`: string *(null)*
  - `state`: string *(null)*
  - `zipCode`: string *(null)*
  - `requestText`: string *(null)*
  - `proCategoryId`: integer/int32 *(null)*
  - `createdDate`: string/date-time *(null)*
  - `leadCost`: number/double *(null)*
  - `leadSource`: string *(null)*
  - `status`: string *(null)*

**Responses:**
- `200`: OK → `RequestQuote`
  - `requestId`: integer/int32
  - `firstName`: string *(null)*
  - `lastName`: string *(null)*
  - `phone`: string *(null)*
  - `email`: string *(null)*
  - `streetAddress`: string *(null)*
  - `addressLine2`: string *(null)*
  - `city`: string *(null)*
  - `state`: string *(null)*
  - `zipCode`: string *(null)*
  - `requestText`: string *(null)*
  - `proCategoryId`: integer/int32 *(null)*
  - `proId`: integer/int32
  - `publicId`: string/uuid
  - `createdDate`: string/date-time
  - `status`: string *(null)*
  - `notes`: string *(null)*
  - `leadCost`: number/double *(null)*
  - `leadSource`: string *(null)*
  - `leadHistories`: array of `LeadHistory` *(null)*
  - `leadNotes`: array of `LeadNote` *(null)*
  - `pro`: `Pro`
  - `proCategory`: `ProCategory`

---

### `POST /api/RequestQuotes/my-requests/{requestId}/create-estimate`

**Parameters:**
- `requestId` (path): integer/int32 **req**
- `userId` (query): integer/int32

**Responses:**
- `200`: OK → `LeadConvertResultDto`
  - `publicId`: string/uuid
  - `clientId`: integer/int32
  - `documentType`: string *(null)*

---

### `POST /api/RequestQuotes/my-requests/{requestId}/create-invoice`

**Parameters:**
- `requestId` (path): integer/int32 **req**
- `userId` (query): integer/int32

**Responses:**
- `200`: OK → `LeadConvertResultDto`
  - `publicId`: string/uuid
  - `clientId`: integer/int32
  - `documentType`: string *(null)*

---

### `GET /api/RequestQuotes/my-requests/{requestId}/history`

**Parameters:**
- `requestId` (path): integer/int32 **req**
- `userId` (query): integer/int32

**Responses:**
- `200`: OK → array of `LeadHistoryDto`
  - `leadHistoryId`: integer/int32
  - `requestId`: integer/int32
  - `eventText`: string *(null)*
  - `createdDateUtc`: string/date-time

---

### `GET /api/RequestQuotes/my-requests/{requestId}/notes`

**Parameters:**
- `requestId` (path): integer/int32 **req**
- `userId` (query): integer/int32

**Responses:**
- `200`: OK → array of `LeadNoteDto`
  - `leadNoteId`: integer/int32
  - `requestId`: integer/int32
  - `noteText`: string *(null)*
  - `createdDateUtc`: string/date-time

---

### `POST /api/RequestQuotes/my-requests/{requestId}/notes`

**Parameters:**
- `requestId` (path): integer/int32 **req**
- `userId` (query): integer/int32

**Request body:**
Schema: `CreateLeadNoteDto`
  - `noteText`: string *(null)*

**Responses:**
- `200`: OK → `LeadNoteDto`
  - `leadNoteId`: integer/int32
  - `requestId`: integer/int32
  - `noteText`: string *(null)*
  - `createdDateUtc`: string/date-time

---

### `DELETE /api/RequestQuotes/my-requests/{requestId}/notes/{noteId}`

**Parameters:**
- `requestId` (path): integer/int32 **req**
- `noteId` (path): integer/int32 **req**
- `userId` (query): integer/int32

**Responses:**
- `200`: OK

---

### `DELETE /api/RequestQuotes/my-requests/{requestId}/photos`

**Parameters:**
- `requestId` (path): integer/int32 **req**
- `userId` (query): integer/int32
- `blobPath` (query): string

**Responses:**
- `200`: OK

---

### `GET /api/RequestQuotes/my-requests/{requestId}/photos`

**Parameters:**
- `requestId` (path): integer/int32 **req**
- `userId` (query): integer/int32

**Responses:**
- `200`: OK → array of `LeadPhotoDto`
  - `fileName`: string *(null)*
  - `blobPath`: string *(null)*
  - `url`: string *(null)*

---

### `POST /api/RequestQuotes/my-requests/{requestId}/photos`

**Parameters:**
- `requestId` (path): integer/int32 **req**
- `userId` (query): integer/int32

**Request body:**
  - `file`: string/binary

**Responses:**
- `200`: OK → `LeadPhotoDto`
  - `fileName`: string *(null)*
  - `blobPath`: string *(null)*
  - `url`: string *(null)*

---

### `DELETE /api/RequestQuotes/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Responses:**
- `200`: OK

---

### `GET /api/RequestQuotes/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Responses:**
- `200`: OK → `RequestQuote`
  - `requestId`: integer/int32
  - `firstName`: string *(null)*
  - `lastName`: string *(null)*
  - `phone`: string *(null)*
  - `email`: string *(null)*
  - `streetAddress`: string *(null)*
  - `addressLine2`: string *(null)*
  - `city`: string *(null)*
  - `state`: string *(null)*
  - `zipCode`: string *(null)*
  - `requestText`: string *(null)*
  - `proCategoryId`: integer/int32 *(null)*
  - `proId`: integer/int32
  - `publicId`: string/uuid
  - `createdDate`: string/date-time
  - `status`: string *(null)*
  - `notes`: string *(null)*
  - `leadCost`: number/double *(null)*
  - `leadSource`: string *(null)*
  - `leadHistories`: array of `LeadHistory` *(null)*
  - `leadNotes`: array of `LeadNote` *(null)*
  - `pro`: `Pro`
  - `proCategory`: `ProCategory`

---

### `PUT /api/RequestQuotes/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Request body:**
Schema: `RequestQuote`
  - `requestId`: integer/int32
  - `firstName`: string *(null)*
  - `lastName`: string *(null)*
  - `phone`: string *(null)*
  - `email`: string *(null)*
  - `streetAddress`: string *(null)*
  - `addressLine2`: string *(null)*
  - `city`: string *(null)*
  - `state`: string *(null)*
  - `zipCode`: string *(null)*
  - `requestText`: string *(null)*
  - `proCategoryId`: integer/int32 *(null)*
  - `proId`: integer/int32
  - `publicId`: string/uuid
  - `createdDate`: string/date-time
  - `status`: string *(null)*
  - `notes`: string *(null)*
  - `leadCost`: number/double *(null)*
  - `leadSource`: string *(null)*
  - `leadHistories`: array of `LeadHistory` *(null)*
  - `leadNotes`: array of `LeadNote` *(null)*
  - `pro`: `Pro`
  - `proCategory`: `ProCategory`

**Responses:**
- `200`: OK

---

## SellYourProperty

### `GET /api/SellYourProperty`

**Parameters:**
- `page` (query): integer/int32 default=`1`
- `pageSize` (query): integer/int32 default=`10`

**Responses:**
- `200`: OK

---

### `POST /api/SellYourProperty`

**Request body:**
Schema: `SellYourPropertyViewModel`
  - `firstName`: string **req**
  - `lastName`: string **req**
  - `email`: string/email **req**
  - `phoneNumber`: string/tel **req**
  - `propertyAddress`: string **req**
  - `propertyType`: string **req**
  - `turnstileToken`: string **req**

**Responses:**
- `200`: OK

---

### `DELETE /api/SellYourProperty/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Responses:**
- `200`: OK

---

## ServiceTags

### `GET /api/ServiceTags`

**Responses:**
- `200`: OK → array of `ServiceTagViewModel`
  - `serviceTagID`: integer/int32
  - `tagName`: string *(null)*

---

### `POST /api/ServiceTags`

**Request body:**
Schema: `ServiceTagViewModel`
  - `serviceTagID`: integer/int32
  - `tagName`: string *(null)*

**Responses:**
- `200`: OK → `ServiceTagViewModel`
  - `serviceTagID`: integer/int32
  - `tagName`: string *(null)*

---

## SmsCampaigns

### `GET /api/sms-campaigns`

**Parameters:**
- `pageIndex` (query): integer/int32 default=`1`
- `pageSize` (query): integer/int32 default=`10`

**Responses:**
- `200`: OK → array of `SmsCampaignListItemDto`
  - `id`: integer/int32
  - `name`: string *(null)*
  - `status`: string *(null)*
  - `scheduledStartUtc`: string/date-time *(null)*
  - `dailySendLimit`: integer/int32
  - `createdDateUtc`: string/date-time
  - `totalRecipients`: integer/int32
  - `sentCount`: integer/int32
  - `pendingCount`: integer/int32
  - `failedCount`: integer/int32

---

### `POST /api/sms-campaigns`

**Request body:**
Schema: `CreateSmsCampaignDto`
  - `name`: string *(null)*
  - `messageBody`: string *(null)*
  - `dailySendLimit`: integer/int32
  - `includeOptOutFooter`: boolean
  - `scheduledStartUtc`: string/date-time *(null)*
  - `createdByUserId`: integer/int32 *(null)*

**Responses:**
- `200`: OK → `SmsCampaignDetailDto`
  - `id`: integer/int32
  - `name`: string *(null)*
  - `messageBody`: string *(null)*
  - `status`: string *(null)*
  - `scheduledStartUtc`: string/date-time *(null)*
  - `dailySendLimit`: integer/int32
  - `includeOptOutFooter`: boolean
  - `confirmedOptInUtc`: string/date-time *(null)*
  - `createdDateUtc`: string/date-time
  - `startedDateUtc`: string/date-time *(null)*
  - `completedDateUtc`: string/date-time *(null)*
  - `totalRecipients`: integer/int32
  - `sentCount`: integer/int32
  - `pendingCount`: integer/int32
  - `failedCount`: integer/int32
  - `skippedCount`: integer/int32

---

### `DELETE /api/sms-campaigns/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Responses:**
- `200`: OK

---

### `GET /api/sms-campaigns/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Responses:**
- `200`: OK → `SmsCampaignDetailDto`
  - `id`: integer/int32
  - `name`: string *(null)*
  - `messageBody`: string *(null)*
  - `status`: string *(null)*
  - `scheduledStartUtc`: string/date-time *(null)*
  - `dailySendLimit`: integer/int32
  - `includeOptOutFooter`: boolean
  - `confirmedOptInUtc`: string/date-time *(null)*
  - `createdDateUtc`: string/date-time
  - `startedDateUtc`: string/date-time *(null)*
  - `completedDateUtc`: string/date-time *(null)*
  - `totalRecipients`: integer/int32
  - `sentCount`: integer/int32
  - `pendingCount`: integer/int32
  - `failedCount`: integer/int32
  - `skippedCount`: integer/int32

---

### `PUT /api/sms-campaigns/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Request body:**
Schema: `UpdateSmsCampaignDto`
  - `name`: string *(null)*
  - `messageBody`: string *(null)*
  - `dailySendLimit`: integer/int32
  - `includeOptOutFooter`: boolean
  - `scheduledStartUtc`: string/date-time *(null)*

**Responses:**
- `200`: OK

---

### `POST /api/sms-campaigns/{id}/cancel`

**Parameters:**
- `id` (path): integer/int32 **req**

**Responses:**
- `200`: OK

---

### `POST /api/sms-campaigns/{id}/pause`

**Parameters:**
- `id` (path): integer/int32 **req**

**Responses:**
- `200`: OK

---

### `GET /api/sms-campaigns/{id}/recipients`

**Parameters:**
- `id` (path): integer/int32 **req**
- `pageIndex` (query): integer/int32 default=`1`
- `pageSize` (query): integer/int32 default=`25`
- `status` (query): string

**Responses:**
- `200`: OK → array of `SmsCampaignRecipientDto`
  - `id`: integer/int32
  - `leadNumber`: string *(null)*
  - `firstName`: string *(null)*
  - `lastName`: string *(null)*
  - `phone`: string *(null)*
  - `phoneNormalized`: string *(null)*
  - `email`: string *(null)*
  - `status`: string *(null)*
  - `errorMessage`: string *(null)*
  - `sentDateUtc`: string/date-time *(null)*

---

### `POST /api/sms-campaigns/{id}/resume`

**Parameters:**
- `id` (path): integer/int32 **req**

**Responses:**
- `200`: OK

---

### `POST /api/sms-campaigns/{id}/retry-failed`

**Parameters:**
- `id` (path): integer/int32 **req**

**Responses:**
- `200`: OK

---

### `POST /api/sms-campaigns/{id}/schedule`

**Parameters:**
- `id` (path): integer/int32 **req**

**Request body:**
Schema: `ScheduleSmsCampaignDto`
  - `confirmOptIn`: boolean

**Responses:**
- `200`: OK

---

### `POST /api/sms-campaigns/{id}/upload`

**Parameters:**
- `id` (path): integer/int32 **req**

**Request body:**
  - `file`: string/binary

**Responses:**
- `200`: OK → `SmsCampaignUploadResultDto`
  - `totalRows`: integer/int32
  - `importedCount`: integer/int32
  - `skippedInvalidPhone`: integer/int32
  - `skippedDuplicate`: integer/int32
  - `skippedOptOut`: integer/int32
  - `preview`: array of `SmsCampaignRecipientPreviewDto` *(null)*

---

## States

### `GET /api/States`

**Responses:**
- `200`: OK → array of `StateViewModel`
  - `stateId`: integer/int32
  - `stateName`: string *(null)*
  - `state`: string *(null)*

---

## Stripe

### `POST /api/Stripe/cancel-subscription`

**Request body:**
Schema: `CartDTo`
  - `id`: integer/int32
  - `userId`: integer/int32 *(null)*
  - `planId`: integer/int32
  - `planName`: string *(null)*
  - `isAnnual`: boolean
  - `email`: string *(null)*
  - `name`: string *(null)*
  - `proIdToClaim`: integer/int32 *(null)*

**Responses:**
- `200`: OK

---

### `GET /api/Stripe/check-payment-status-and-update`

**Parameters:**
- `sessionId` (query): string

**Responses:**
- `200`: OK → `PaymentStatus`
  - `isPaid`: boolean
  - `sessionId`: string *(null)*
  - `customerEmail`: string *(null)*

---

### `POST /api/Stripe/create-billing-portal-session`

**Request body:**
Schema: `BillingPortalRequest`
  - `email`: string *(null)*

**Responses:**
- `200`: OK

---

### `POST /api/Stripe/create-checkout-session`

**Request body:**
Schema: `CartDTo`
  - `id`: integer/int32
  - `userId`: integer/int32 *(null)*
  - `planId`: integer/int32
  - `planName`: string *(null)*
  - `isAnnual`: boolean
  - `email`: string *(null)*
  - `name`: string *(null)*
  - `proIdToClaim`: integer/int32 *(null)*

**Responses:**
- `200`: OK

---

### `GET /api/Stripe/get-current-subscription`

**Parameters:**
- `email` (query): string

**Responses:**
- `200`: OK

---

### `GET /api/Stripe/get-serdenrole-basedon-productid`

**Parameters:**
- `productId` (query): string

**Responses:**
- `200`: OK → `SerdenRole`

---

### `GET /api/Stripe/update-subscription-in-database`

**Parameters:**
- `email` (query): string

**Responses:**
- `200`: OK → boolean

---

### `POST /api/Stripe/upgrade-subscription`

**Request body:**
Schema: `CartDTo`
  - `id`: integer/int32
  - `userId`: integer/int32 *(null)*
  - `planId`: integer/int32
  - `planName`: string *(null)*
  - `isAnnual`: boolean
  - `email`: string *(null)*
  - `name`: string *(null)*
  - `proIdToClaim`: integer/int32 *(null)*

**Responses:**
- `200`: OK

---

## Subcategories

### `GET /api/Subcategories`

**Parameters:**
- `categoryId` (query): integer/int32

**Responses:**
- `200`: OK → array of `Subcategory`
  - `subcategoryId`: integer/int32
  - `subcategoryName`: string *(null)*
  - `description`: string *(null)*
  - `slug`: string *(null)*
  - `categoryId`: integer/int32
  - `sortNo`: integer/int32
  - `isActive`: boolean
  - `publicId`: string/uuid
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time
  - `category`: `Category`
  - `discussions`: array of `Discussion` *(null)*

---

### `POST /api/Subcategories`

**Request body:**
Schema: `SubCategoryViewModel`
  - `subCategoryId`: integer/int32
  - `subcategoryName`: string **req**
  - `slug`: string *(null)*
  - `sortNo`: integer/int32
  - `displayAtHomePage`: boolean
  - `categoryId`: integer/int32
  - `categoryName`: string *(null)*
  - `isActive`: boolean
  - `publicId`: string/uuid

**Responses:**
- `200`: OK → `Subcategory`
  - `subcategoryId`: integer/int32
  - `subcategoryName`: string *(null)*
  - `description`: string *(null)*
  - `slug`: string *(null)*
  - `categoryId`: integer/int32
  - `sortNo`: integer/int32
  - `isActive`: boolean
  - `publicId`: string/uuid
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time
  - `category`: `Category`
  - `discussions`: array of `Discussion` *(null)*

---

### `GET /api/Subcategories/slug`

**Parameters:**
- `slug` (query): string

**Responses:**
- `200`: OK → array of `SubCategoryViewModel`
  - `subCategoryId`: integer/int32
  - `subcategoryName`: string **req**
  - `slug`: string *(null)*
  - `sortNo`: integer/int32
  - `displayAtHomePage`: boolean
  - `categoryId`: integer/int32
  - `categoryName`: string *(null)*
  - `isActive`: boolean
  - `publicId`: string/uuid

---

### `GET /api/Subcategories/subCategorybyslug`

**Parameters:**
- `slug` (query): string

**Responses:**
- `200`: OK → `SubCategoryViewModel`
  - `subCategoryId`: integer/int32
  - `subcategoryName`: string **req**
  - `slug`: string *(null)*
  - `sortNo`: integer/int32
  - `displayAtHomePage`: boolean
  - `categoryId`: integer/int32
  - `categoryName`: string *(null)*
  - `isActive`: boolean
  - `publicId`: string/uuid

---

### `DELETE /api/Subcategories/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Responses:**
- `200`: OK

---

### `GET /api/Subcategories/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Responses:**
- `200`: OK → `SubCategoryViewModel`
  - `subCategoryId`: integer/int32
  - `subcategoryName`: string **req**
  - `slug`: string *(null)*
  - `sortNo`: integer/int32
  - `displayAtHomePage`: boolean
  - `categoryId`: integer/int32
  - `categoryName`: string *(null)*
  - `isActive`: boolean
  - `publicId`: string/uuid

---

### `PUT /api/Subcategories/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Request body:**
Schema: `Subcategory`
  - `subcategoryId`: integer/int32
  - `subcategoryName`: string *(null)*
  - `description`: string *(null)*
  - `slug`: string *(null)*
  - `categoryId`: integer/int32
  - `sortNo`: integer/int32
  - `isActive`: boolean
  - `publicId`: string/uuid
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time
  - `category`: `Category`
  - `discussions`: array of `Discussion` *(null)*

**Responses:**
- `200`: OK

---

## SubscriptionUsage

### `GET /api/SubscriptionUsage/pro/{proId}`

**Parameters:**
- `proId` (path): integer/int32 **req**

**Responses:**
- `200`: OK → `SubscriptionUsageDto`
  - `estimatesUsed`: integer/int32
  - `estimatesLimit`: integer/int32
  - `invoicesUsed`: integer/int32
  - `invoicesLimit`: integer/int32
  - `billingPeriodStart`: string/date-time
  - `billingPeriodEnd`: string/date-time
  - `tier`: string *(null)*
  - `subscriptionStatus`: string *(null)*

---

### `GET /api/SubscriptionUsage/user/{userId}`

**Parameters:**
- `userId` (path): integer/int32 **req**

**Responses:**
- `200`: OK → `SubscriptionUsageDto`
  - `estimatesUsed`: integer/int32
  - `estimatesLimit`: integer/int32
  - `invoicesUsed`: integer/int32
  - `invoicesLimit`: integer/int32
  - `billingPeriodStart`: string/date-time
  - `billingPeriodEnd`: string/date-time
  - `tier`: string *(null)*
  - `subscriptionStatus`: string *(null)*

---

## Taxes

### `POST /api/Taxes`

**Request body:**
Schema: `TaxViewModel`
  - `taxId`: integer/int32
  - `proId`: integer/int32
  - `taxName`: string *(null)*
  - `taxRate`: number/double
  - `isActive`: boolean
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time *(null)*

**Responses:**
- `200`: OK → `TaxViewModel`
  - `taxId`: integer/int32
  - `proId`: integer/int32
  - `taxName`: string *(null)*
  - `taxRate`: number/double
  - `isActive`: boolean
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time *(null)*

---

### `GET /api/Taxes/pro/{proId}`

**Parameters:**
- `proId` (path): integer/int32 **req**

**Responses:**
- `200`: OK → array of `TaxViewModel`
  - `taxId`: integer/int32
  - `proId`: integer/int32
  - `taxName`: string *(null)*
  - `taxRate`: number/double
  - `isActive`: boolean
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time *(null)*

---

### `DELETE /api/Taxes/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Responses:**
- `200`: OK

---

### `GET /api/Taxes/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Responses:**
- `200`: OK → `TaxViewModel`
  - `taxId`: integer/int32
  - `proId`: integer/int32
  - `taxName`: string *(null)*
  - `taxRate`: number/double
  - `isActive`: boolean
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time *(null)*

---

### `PUT /api/Taxes/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Request body:**
Schema: `TaxViewModel`
  - `taxId`: integer/int32
  - `proId`: integer/int32
  - `taxName`: string *(null)*
  - `taxRate`: number/double
  - `isActive`: boolean
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time *(null)*

**Responses:**
- `200`: OK

---

## UserSubscriptions

### `POST /api/UserSubscriptions/UpdateToSerdenBasic`

**Request body:**
Schema: `CartDTo`
  - `id`: integer/int32
  - `userId`: integer/int32 *(null)*
  - `planId`: integer/int32
  - `planName`: string *(null)*
  - `isAnnual`: boolean
  - `email`: string *(null)*
  - `name`: string *(null)*
  - `proIdToClaim`: integer/int32 *(null)*

**Responses:**
- `200`: OK → boolean

---

## Users

### `GET /api/Users`

**Parameters:**
- `pageIndex` (query): integer/int32 default=`1`
- `pageSize` (query): integer/int32 default=`10`
- `roleId` (query): integer/int32 default=`0`
- `sortBy` (query): string default=`createddate`
- `sortDirection` (query): string default=`desc`

**Responses:**
- `200`: OK → array of `UserListViewModel`
  - `userId`: integer/int32
  - `firstName`: string *(null)*
  - `lastName`: string *(null)*
  - `userName`: string *(null)*
  - `email`: string *(null)*
  - `roleId`: integer/int32
  - `subsciptionEndDate`: string/date-time *(null)*
  - `subscriptionStatus`: string *(null)*
  - `proName`: string *(null)*
  - `proSlug`: string *(null)*

---

### `POST /api/Users`

**Request body:**
Schema: `User`
  - `userId`: integer/int32
  - `userName`: string *(null)*
  - `email`: string *(null)*
  - `passwordHash`: string *(null)*
  - `profilePictureUrl`: string *(null)*
  - `publicId`: string/uuid
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time
  - `firstName`: string *(null)*
  - `lastName`: string *(null)*
  - `roleId`: integer/int32
  - `subsciptionEndDate`: string/date-time *(null)*
  - `subscriptionStatus`: string *(null)*
  - `isEmailVerified`: boolean
  - `discussions`: array of `Discussion` *(null)*
  - `emailVerificationTokens`: array of `EmailVerificationToken` *(null)*
  - `loginHistories`: array of `LoginHistory` *(null)*
  - `passwordResetTokens`: array of `PasswordResetToken` *(null)*
  - `proInternalMessageLogs`: array of `ProInternalMessageLog` *(null)*
  - `proReviewCompanyResponseByUsers`: array of `ProReview` *(null)*
  - `proReviewUsers`: array of `ProReview` *(null)*
  - `pros`: array of `Pro` *(null)*
  - `refreshTokens`: array of `RefreshToken` *(null)*
  - `replies`: array of `Reply` *(null)*
  - `role`: `Role`

**Responses:**
- `200`: OK → `User`
  - `userId`: integer/int32
  - `userName`: string *(null)*
  - `email`: string *(null)*
  - `passwordHash`: string *(null)*
  - `profilePictureUrl`: string *(null)*
  - `publicId`: string/uuid
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time
  - `firstName`: string *(null)*
  - `lastName`: string *(null)*
  - `roleId`: integer/int32
  - `subsciptionEndDate`: string/date-time *(null)*
  - `subscriptionStatus`: string *(null)*
  - `isEmailVerified`: boolean
  - `discussions`: array of `Discussion` *(null)*
  - `emailVerificationTokens`: array of `EmailVerificationToken` *(null)*
  - `loginHistories`: array of `LoginHistory` *(null)*
  - `passwordResetTokens`: array of `PasswordResetToken` *(null)*
  - `proInternalMessageLogs`: array of `ProInternalMessageLog` *(null)*
  - `proReviewCompanyResponseByUsers`: array of `ProReview` *(null)*
  - `proReviewUsers`: array of `ProReview` *(null)*
  - `pros`: array of `Pro` *(null)*
  - `refreshTokens`: array of `RefreshToken` *(null)*
  - `replies`: array of `Reply` *(null)*
  - `role`: `Role`

---

### `POST /api/Users/change-password`

**Request body:**
Schema: `ChangePasswordDto`
  - `email`: string *(null)*
  - `currentPassword`: string *(null)*
  - `newPassword`: string *(null)*

**Responses:**
- `200`: OK → boolean

---

### `GET /api/Users/check-email-verification/{username}`

**Parameters:**
- `username` (path): string **req**

**Responses:**
- `200`: OK

---

### `POST /api/Users/forgotpassword`

**Request body:**
Schema: `ForgotPasswordViewModel`
  - `username`: string **req**
  - `email`: string **req**
  - `turnstileToken`: string **req**

**Responses:**
- `200`: OK

---

### `GET /api/Users/istokenexpired`

**Parameters:**
- `token` (query): string

**Responses:**
- `200`: OK → boolean

---

### `POST /api/Users/login`

**Request body:**
Schema: `LoginViewModel`
  - `userName`: string **req**
  - `password`: string **req**
  - `ipAddress`: string *(null)*
  - `userAgent`: string *(null)*

**Responses:**
- `200`: OK → `AuthResponseDto`
  - `user`: `SerdenUser`
  - `accessToken`: string *(null)*
  - `refreshToken`: string *(null)*
  - `expiresAt`: string/date-time

---

### `POST /api/Users/logout`

**Request body:**
Schema: `LogoutRequestDto`
  - `refreshToken`: string *(null)*

**Responses:**
- `200`: OK

---

### `GET /api/Users/publicid`

**Parameters:**
- `publicId` (query): string

**Responses:**
- `200`: OK → `SerdenUser`
  - `userId`: integer/int32
  - `username`: string *(null)*
  - `firstName`: string *(null)*
  - `lastName`: string *(null)*
  - `fullName`: string *(null)*
  - `email`: string *(null)*
  - `role`: string *(null)*
  - `subscriptionEndDate`: string/date-time *(null)*
  - `publicId`: string *(null)*
  - `subscriptionStatus`: string *(null)*

---

### `POST /api/Users/refresh`

**Request body:**
Schema: `RefreshTokenRequestDto`
  - `refreshToken`: string *(null)*

**Responses:**
- `200`: OK → `AuthResponseDto`
  - `user`: `SerdenUser`
  - `accessToken`: string *(null)*
  - `refreshToken`: string *(null)*
  - `expiresAt`: string/date-time

---

### `POST /api/Users/register`

**Request body:**
Schema: `RegistrationViewModel`
  - `username`: string **req**
  - `password`: string **req**
  - `confirmPassword`: string **req**
  - `email`: string/email **req**
  - `firstName`: string **req**
  - `lastName`: string **req**
  - `role`: `SerdenRole`
  - `turnstileToken`: string *(null)*

**Responses:**
- `200`: OK

---

### `POST /api/Users/resend-verification`

**Request body:**

**Responses:**
- `200`: OK

---

### `POST /api/Users/resetpassword`

**Request body:**
Schema: `ResetPasswordDto`
  - `token`: string *(null)*
  - `newPassword`: string *(null)*

**Responses:**
- `200`: OK

---

### `GET /api/Users/username`

**Parameters:**
- `username` (query): string

**Responses:**
- `200`: OK → string

---

### `POST /api/Users/verify-email`

**Request body:**

**Responses:**
- `200`: OK

---

### `DELETE /api/Users/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Responses:**
- `200`: OK

---

### `GET /api/Users/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Responses:**
- `200`: OK → `SerdenUser`
  - `userId`: integer/int32
  - `username`: string *(null)*
  - `firstName`: string *(null)*
  - `lastName`: string *(null)*
  - `fullName`: string *(null)*
  - `email`: string *(null)*
  - `role`: string *(null)*
  - `subscriptionEndDate`: string/date-time *(null)*
  - `publicId`: string *(null)*
  - `subscriptionStatus`: string *(null)*

---

### `PUT /api/Users/{id}`

**Parameters:**
- `id` (path): integer/int32 **req**

**Request body:**
Schema: `User`
  - `userId`: integer/int32
  - `userName`: string *(null)*
  - `email`: string *(null)*
  - `passwordHash`: string *(null)*
  - `profilePictureUrl`: string *(null)*
  - `publicId`: string/uuid
  - `createdDate`: string/date-time
  - `modifiedDate`: string/date-time
  - `firstName`: string *(null)*
  - `lastName`: string *(null)*
  - `roleId`: integer/int32
  - `subsciptionEndDate`: string/date-time *(null)*
  - `subscriptionStatus`: string *(null)*
  - `isEmailVerified`: boolean
  - `discussions`: array of `Discussion` *(null)*
  - `emailVerificationTokens`: array of `EmailVerificationToken` *(null)*
  - `loginHistories`: array of `LoginHistory` *(null)*
  - `passwordResetTokens`: array of `PasswordResetToken` *(null)*
  - `proInternalMessageLogs`: array of `ProInternalMessageLog` *(null)*
  - `proReviewCompanyResponseByUsers`: array of `ProReview` *(null)*
  - `proReviewUsers`: array of `ProReview` *(null)*
  - `pros`: array of `Pro` *(null)*
  - `refreshTokens`: array of `RefreshToken` *(null)*
  - `replies`: array of `Reply` *(null)*
  - `role`: `Role`

**Responses:**
- `200`: OK

---

## ZipCodes

### `GET /api/ZipCodes/search`

**Parameters:**
- `term` (query): string

**Responses:**
- `200`: OK → array of `ZipCodeViewModel`
  - `zipCode`: string *(null)*
  - `city`: string *(null)*
  - `state`: string *(null)*

---

### `GET /api/ZipCodes/searchcities`

**Parameters:**
- `state` (query): string
- `searchTerm` (query): string default=``

**Responses:**
- `200`: OK → array of `ZipCodeViewModel`
  - `zipCode`: string *(null)*
  - `city`: string *(null)*
  - `state`: string *(null)*

---

### `GET /api/ZipCodes/{zipCode}`

**Parameters:**
- `zipCode` (path): string **req**

**Responses:**
- `200`: OK → `ZipCodeViewModel`
  - `zipCode`: string *(null)*
  - `city`: string *(null)*
  - `state`: string *(null)*

---
