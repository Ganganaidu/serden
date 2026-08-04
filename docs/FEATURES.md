# Features

Every screen in Serden, what it does, what data it needs, and its implementation status.

---

## Auth & Onboarding

### Onboarding (4 screens)
**Route:** `/onboarding`  
**Figma nodes:** `30:2310`, `28:438`, `28:577`, `28:640`  
**What it does:** Animated intro slides shown once on first launch. Slides show product illustration + tagline. Last slide has "Get Started" CTA.  
**Data:** None — no API call. Reads `AppConstants.onboardingDoneKey` from SharedPreferences to skip on subsequent launches.  
**Status:** Stub

### Sign Up
**Route:** `/sign-up`  
**Figma node:** `28:706`  
**What it does:** Bottom-sheet style modal over blurred onboarding background. Email + password fields. "Create Free Account" button. Link to Sign In.  
**Data:** `POST /auth/register { email, password }` → returns `{ accessToken, refreshToken, user }`  
**BLoC:** `AuthBloc` → `AuthSignUpRequested`  
**Status:** Stub

### Sign In
**Route:** `/sign-in`  
**Figma node:** `28:824`  
**What it does:** Same bottom-sheet style. Email + password fields. "Sign In" button. "or continue with" (social buttons TBD). Link to Sign Up.  
**Data:** `POST /auth/login { email, password }` → returns `{ accessToken, refreshToken, user }`  
**BLoC:** `AuthBloc` → `AuthSignInRequested`  
**Status:** Stub

---

## Estimates

### Estimate List
**Route:** `/estimates`  
**Figma nodes:** `4:244` (empty state), `65:2` (populated)  
**What it does:** Teal header with count + search bar. Tabs: Pending / Approved / Declined. Items grouped by month. Each row: client name, date, number, amount, status badge. FAB/+ opens New Estimate.  
**Data:** `GET /estimates?status=pending|approved|declined`  
**BLoC:** `EstimatesBloc` — states: Initial / Loading / Loaded / Empty / Error  
**Status:** Stub

### New Estimate (wizard — 3 scroll states)
**Route:** `/estimates/new`  
**Figma nodes:** `76:2`, `82:2`, `85:2`  
**What it does:** Multi-section form. Sections: Client picker, Description (line items + "Group into Sections" toggle), Subtotal/Markup/Discount/Tax/Total summary, Deposit request, Payment Schedule, Online Payments toggle, Notes, Attachments, Expiry date, Estimate number, Issued date.  
**Data:** `POST /estimates { clientId, lineItems[], markup, discount, tax, deposit, ... }`  
**BLoC:** `NewEstimateBloc` (BLoC not Cubit — complex multi-step)  
**Dependencies:** Opens `AddLineItemScreen` as a push route to pick line items  
**Status:** Stub

### Estimate Detail
**Route:** `/estimates/:id`  
**Figma node:** `88:2`  
**What it does:** Shows full estimate: header (client, date, number, status), line items table, totals. Action bar: Send / Convert to Invoice / More.  
**Data:** `GET /estimates/:id`  
**BLoC:** `EstimateDetailBloc`  
**Status:** Stub

### Add Line Item
**Route:** `/estimates/line-item`  
**Figma node:** `97:2`, `229:2`  
**What it does:** Search or create a line item. Fields: Name, Description, Price, Quantity, Unit. Can save as a product for reuse.  
**Data:** `GET /items` (for search), `POST /estimates/:id/line-items`  
**Status:** Stub

---

## Invoices

### Invoice List
**Route:** `/invoices`  
**Figma nodes:** `106:2` (populated), `106:96` (empty)  
**What it does:** Same Teal header pattern as Estimates. Tabs: Active / Paid. Items grouped by month, with running monthly total shown on group header. Status badges: ISSUED / PARTIAL / DRAFT / OVERDUE / PAID.  
**Data:** `GET /invoices?status=active|paid`  
**BLoC:** `InvoicesBloc`  
**Status:** Stub

### New Invoice
**Route:** `/invoices/new`  
**Figma nodes:** `107:2`, `107:93`  
**What it does:** Similar to New Estimate. Sections: Client, Line Items, Totals, Due date, Payment terms, Online Payments toggle, Notes.  
**Data:** `POST /invoices { clientId, lineItems[], dueDate, ... }`  
**BLoC:** `NewInvoiceBloc`  
**Status:** Stub

### Invoice Detail
**Route:** `/invoices/:id`  
**Figma node:** `108:2`  
**What it does:** Full invoice view. Actions: Send / Record Payment / More (void, duplicate, download PDF).  
**Data:** `GET /invoices/:id`  
**BLoC:** `InvoiceDetailBloc`  
**Status:** Stub

### Invoice Bottom Sheet (Record Payment)
**Figma node:** `112:8`  
**What it does:** Bottom sheet modal. Fields: Amount, Payment date, Payment method (cash/check/card/other), Reference note.  
**Data:** `POST /invoices/:id/payments { amount, date, method, reference }`  
**Status:** Stub

---

## Clients

### Client List
**Route:** `/clients`  
**Figma node:** `28:1050`  
**What it does:** Teal header with count + search. Alphabetical sections (A, B, C...) with A–Z scrubber on right edge. Each row: initials avatar, name, address.  
**Data:** `GET /clients`  
**BLoC:** `ClientsBloc`  
**Status:** Stub

### Client Detail
**Route:** `/clients/:id`  
**Figma node:** `28:1625`  
**What it does:** Client info (name, address, email, phone). Tabs: Estimates / Invoices showing that client's documents. Edit button.  
**Data:** `GET /clients/:id`, `GET /clients/:id/estimates`, `GET /clients/:id/invoices`  
**BLoC:** `ClientDetailBloc`  
**Status:** Stub

### Add Client
**Route:** `/clients/add`  
**Figma nodes:** `28:1872`, `28:2241`  
**What it does:** Two-step form. Step 1: Name (first + last or company name). Step 2: Address, email, phone.  
**Data:** `POST /clients { name, address, email, phone }`  
**BLoC:** `AddClientBloc`  
**Status:** Stub

---

## Payments

### Payments Tab
**Route:** `/payments`  
**What it does:** Summary of all payment activity. (Full design TBD — screen not yet in Figma.)  
**Data:** `GET /payments`  
**Status:** Stub (screen not designed yet)

### Record Payment Modal
**Figma node:** `163:233`  
**What it does:** Bottom sheet launched from Invoice Detail or More screen.  
**Note:** Shares implementation with Invoice Bottom Sheet  
**Status:** Stub

---

## Plans / Subscription

### Choose Plan
**Route:** `/choose-plan?plan=basics|pro|elite`  
**Figma nodes:** `101:2`, `101:38`, `101:109`  
**What it does:** Full-screen plan comparison. Three tabs: Basics (free) / Pro / Elite. Each shows feature list and price. CTA: "Get Started" or "Upgrade".  
**Data:** `GET /plans` (or hardcoded — plans rarely change)  
**Status:** Stub

---

## More

### More – Main
**Route:** `/more`  
**Figma node:** `162:2`  
**What it does:** Settings menu list. Items: Settings, Payments Settings (with "Finish setup" badge), Items, Refer & Earn (New), Expenses, Serden Pro (New), Collect Google Reviews (New), Reports (New), Serden Lending (New), Homeowner Financing, QuickBooks Sync.  
**Status:** Stub

### More – Settings
**Route:** `/more/settings`  
**Figma node:** `162:171`  
**What it does:** App settings: notifications, language, etc.  
**Status:** Stub

### More – Items
**Route:** `/more/items`  
**Figma node:** `163:2`  
**What it does:** Product/service catalogue. Items that can be added to estimates and invoices. CRUD operations.  
**Data:** `GET /items`, `POST /items`, `PUT /items/:id`, `DELETE /items/:id`  
**Status:** Stub

### More – Expenses
**Route:** `/more/expenses`  
**Figma node:** `163:113`  
**What it does:** Track business expenses. List + add new expense.  
**Data:** `GET /expenses`, `POST /expenses`  
**Status:** Stub

### More – About
**Route:** `/more/about`  
**Figma node:** `163:166`  
**What it does:** App version, legal links, social links.  
**Status:** Stub

### More – My Account
**Route:** `/more/account`  
**Figma node:** `169:2`  
**What it does:** User profile: name, email, business name, phone, logo upload, plan badge. Logout button.  
**Data:** `GET /auth/me`, `PUT /auth/me`  
**BLoC:** `MyAccountCubit`  
**Status:** Stub

---

## Implementation Order (Recommended)

1. **Auth** — everything else requires a logged-in user
2. **Estimates** — the primary feature, shown on first launch
3. **Clients** — estimates need clients
4. **Invoices** — natural progression from estimates
5. **More / My Account** — settings and profile
6. **Plans** — subscription gate
7. **Payments tab** — pending Figma designs
8. **Items & Expenses** — secondary features
