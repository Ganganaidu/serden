# API Contract

The .NET backend is still in development. This document defines the expected API shape that the Flutter repository classes are written against.

**Base URL:** `https://api.serden.com/api/v1`  
**Auth:** `Authorization: Bearer <jwt_access_token>`  
**Content-Type:** `application/json`

> Until the API is live, repository `impl` classes return mock `Right(data)` so screens can be built and tested independently.

---

## Auth

### POST /auth/register
Create a new account.

**Request:**
```json
{ "email": "user@example.com", "password": "Secret123!" }
```

**Response 201:**
```json
{
  "accessToken": "eyJ...",
  "refreshToken": "eyJ...",
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "name": null,
    "businessName": null,
    "phone": null,
    "avatarUrl": null,
    "plan": "basics"
  }
}
```

### POST /auth/login
Sign in with email + password.  
Same request/response shape as `/auth/register`.

### POST /auth/refresh
Exchange a refresh token for a new access token.

**Request:** `{ "refreshToken": "eyJ..." }`  
**Response:** `{ "accessToken": "eyJ...", "refreshToken": "eyJ..." }`

### GET /auth/me
Returns the current authenticated user. Same user shape as above.

### PUT /auth/me
Update profile.

**Request:**
```json
{
  "name": "John Smith",
  "businessName": "Smith Contracting",
  "phone": "+1-503-555-0100"
}
```

---

## Clients

### GET /clients
Returns all clients for the authenticated user.

**Query params:** `search=string` (optional)

**Response:**
```json
[
  {
    "id": "uuid",
    "name": "Avery Atkinson",
    "email": "avery@example.com",
    "phone": "+1-503-555-0100",
    "address": {
      "street": "730 Maple Ct",
      "city": "Hillsboro",
      "state": "OR",
      "zip": "97124",
      "country": "US"
    },
    "createdAt": "2026-01-15T00:00:00Z"
  }
]
```

### GET /clients/:id
Single client. Same shape as above.

### POST /clients
Create a client. Body matches client shape (minus `id`, `createdAt`).

### PUT /clients/:id
Update a client.

### DELETE /clients/:id
Delete a client. Returns `204 No Content`.

### GET /clients/:id/estimates
Returns estimates for a specific client. Same as `/estimates` shape.

### GET /clients/:id/invoices
Returns invoices for a specific client. Same as `/invoices` shape.

---

## Estimates

### GET /estimates
**Query params:** `status=pending|approved|declined|all`, `search=string`, `page=1`, `pageSize=20`

**Response:**
```json
{
  "total": 8,
  "page": 1,
  "pageSize": 20,
  "items": [
    {
      "id": "uuid",
      "number": 1172,
      "status": "issued",
      "clientId": "uuid",
      "clientName": "Joseph Ulrich",
      "issuedDate": "2026-04-04",
      "expiryDate": "2026-05-04",
      "subtotal": 10000.00,
      "markup": 0,
      "discount": 0,
      "tax": 600.00,
      "total": 10600.00,
      "depositAmount": 0,
      "currency": "USD",
      "createdAt": "2026-04-04T10:00:00Z"
    }
  ]
}
```

**Status values:** `draft` | `issued` | `approved` | `declined`

### GET /estimates/:id
Full estimate with line items.

```json
{
  "id": "uuid",
  "number": 1172,
  "status": "issued",
  "clientId": "uuid",
  "clientName": "Joseph Ulrich",
  "issuedDate": "2026-04-04",
  "expiryDate": "2026-05-04",
  "lineItems": [
    {
      "id": "uuid",
      "name": "Labor",
      "description": "Installation work",
      "quantity": 10,
      "unit": "hrs",
      "unitPrice": 150.00,
      "total": 1500.00
    }
  ],
  "groupIntoSections": false,
  "subtotal": 10000.00,
  "markup": 0,
  "discount": 0,
  "tax": 600.00,
  "total": 10600.00,
  "depositAmount": 0,
  "paymentSchedule": null,
  "acceptOnlinePayments": false,
  "notes": null,
  "currency": "USD"
}
```

### POST /estimates
Create estimate. Body is the same shape minus `id`, `number`, `createdAt`.

### PUT /estimates/:id
Update estimate.

### DELETE /estimates/:id
Returns `204`.

### POST /estimates/:id/convert
Convert an estimate to an invoice. Returns the new invoice.

---

## Invoices

### GET /invoices
**Query params:** `status=active|paid|all`, `search=string`, `page=1`, `pageSize=20`

**Response shape:** Same pagination wrapper as estimates.

**Status values:** `draft` | `issued` | `partial` | `paid` | `overdue` | `void`

### GET /invoices/:id
Full invoice with line items + payment history.

```json
{
  "id": "uuid",
  "number": 95,
  "status": "issued",
  "clientId": "uuid",
  "clientName": "Zachary Bosma",
  "issuedDate": "2026-06-03",
  "dueDate": "2026-07-03",
  "lineItems": [...],
  "subtotal": 2500.00,
  "tax": 0,
  "total": 2500.00,
  "amountPaid": 0,
  "amountDue": 2500.00,
  "payments": [],
  "currency": "USD"
}
```

### POST /invoices
Create invoice.

### PUT /invoices/:id
Update invoice.

### POST /invoices/:id/payments
Record a payment against an invoice.

**Request:**
```json
{
  "amount": 1250.00,
  "date": "2026-06-15",
  "method": "check",
  "reference": "Check #1042"
}
```

---

## Items (Products/Services catalogue)

### GET /items
All saved line items for the user. Used in "Add Line Item" search.

```json
[
  {
    "id": "uuid",
    "name": "Electrical Outlet Installation",
    "description": "Standard 15A outlet",
    "unitPrice": 125.00,
    "unit": "each",
    "category": "electrical"
  }
]
```

### POST /items
Create a new item.

### PUT /items/:id
Update an item.

### DELETE /items/:id
Delete an item. Returns `204`.

---

## Expenses

### GET /expenses
**Query params:** `page=1`, `pageSize=20`

```json
{
  "total": 12,
  "items": [
    {
      "id": "uuid",
      "name": "Materials",
      "amount": 450.00,
      "date": "2026-06-10",
      "category": "materials",
      "notes": null
    }
  ]
}
```

### POST /expenses
Create an expense.

---

## Error Responses

All errors follow this shape:

```json
{
  "statusCode": 422,
  "message": "Validation failed",
  "errors": {
    "email": ["Email is already in use"],
    "password": ["Password must be at least 8 characters"]
  }
}
```

| Status | Failure class |
|---|---|
| 400 | `ServerFailure` |
| 401 | `UnauthorizedFailure` |
| 404 | `NotFoundFailure` |
| 422 | `ValidationFailure` (carries `errors` map) |
| 500+ | `ServerFailure` |
| timeout/no connection | `NetworkFailure` |
