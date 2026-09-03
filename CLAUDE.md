# Serden — AI Assistant Instructions

This file is the first thing an AI assistant should read before touching any code in this project. It answers "what is this, how is it structured, and what must I not break."

---

## What This App Is

**Serden** is a contractor/freelancer business management mobile app. The core workflow is:
1. User creates a **Client**
2. User creates an **Estimate** for that client (with line items, markup, tax, deposit)
3. Client approves → User converts to an **Invoice**
4. Client pays → User records a **Payment**

It is Flutter only — **iOS and Android, mobile portrait only**. There is no web target.

---

## Current State

- **Architecture scaffolded** — all core layers (theme, router, network, storage, DI, BLoC) are in place and compile clean.
- **UI implemented (July 2026 rebrand)** — all screens are built to match the HTML mockups in "SERDEN APP FINAL DESIGN" (dark green + orange, Manrope). Screens currently render mock data defined in each feature's `models/` file.
- **API does not exist yet** — the .NET backend is still being built. Screens use in-file mock lists (`mockEstimates`, `mockInvoices`, `mockClients`, `mockLeads`); swap these for repository calls when the API lands.
- **Auth flow built** — onboarding carousel, Sign In / Sign Up sheets wired to AuthBloc.

---

## Architecture Rules

### 1. Feature folder structure — never deviate from this

Every feature lives in `lib/features/<feature>/` with these sub-folders:

```
<feature>/
├── bloc/
│   ├── <feature>_bloc.dart    # part files for event + state
│   ├── <feature>_event.dart   # part of '<feature>_bloc.dart'
│   └── <feature>_state.dart   # part of '<feature>_bloc.dart'
├── models/
│   └── <feature>_model.dart   # Equatable data class with fromJson/toJson
├── repository/
│   └── <feature>_repository.dart  # abstract + impl, returns Either<Failure, T>
└── screens/
    ├── <feature>_screen.dart      # main screen widget
    └── widgets/                   # screen-specific sub-widgets
```

For simple screens (settings, about), use **Cubit** instead of full BLoC — only use BLoC when there are distinct events with complex transitions.

### 2. Data flow — one direction only

```
Screen → dispatches Event → BLoC → calls Repository → calls ApiClient → .NET API
                                  ↓
Screen ← rebuilds on State ← BLoC ← Repository returns Either<Failure, T>
```

Never call ApiClient directly from a screen. Never put business logic in a widget.

### 3. Error handling — always use Either

Repository methods return `Either<Failure, T>` from `package:dartz`. The BLoC calls `.fold()` on the result — never use try/catch in a BLoC.

```dart
// Correct pattern
final result = await _repository.getEstimates();
result.fold(
  (failure) => emit(EstimatesError(failure.message)),
  (estimates) => emit(EstimatesLoaded(estimates)),
);
```

Failure types are in `lib/core/errors/failures.dart`. Use the most specific type.

### 4. Routing — go_router only, no Navigator.push

All navigation goes through `go_router`. Route path constants are in `AppRoutes` inside `lib/core/router/app_router.dart`.

```dart
context.go(AppRoutes.estimates);           // replace
context.push(AppRoutes.newEstimate);       // push onto stack
context.pop();                             // back
```

Never use `Navigator.push` or `Navigator.of(context).pushNamed`.

### 5. Theme — never hardcode colors or text styles

Always use:
- `AppColors.green800` / `AppColors.primary` not `Color(0xFF153A2B)`
- `AppTextStyles.rowTitle` not `TextStyle(fontSize: 15, fontWeight: FontWeight.w700)`
- `Theme.of(context).colorScheme.primary` is also acceptable

### 6. Shared widgets — use them, don't re-implement them

| Widget | Location | Use for |
|---|---|---|
| `AppHeader` | `core/widgets/main_shell.dart` | Dark green top section on list screens |
| `HeaderSearchBar` / `HeaderIconButton` | `core/widgets/main_shell.dart` | Search bar / icon buttons inside AppHeader |
| `DetailHeader` | `core/widgets/main_shell.dart` | Compact green header with back label |
| `StatusChip` | `core/widgets/status_badge.dart` | Viewed / Sent / Draft / Paid / Overdue chips |
| `PillTabs` | `core/widgets/pill_tabs.dart` | Underline tab strip (Pending/Approved/Declined, Active/Overdue/Paid, …) |
| `AppCard` / `CardRow` | `core/widgets/app_card.dart` | White cards and menu rows |
| `AppFab` | `core/widgets/app_fab.dart` | Orange extended FAB |
| `FormNavBar` | `core/widgets/form_nav_bar.dart` | Cancel · title · Save form top bar |
| `TipBanner` | `core/widgets/tip_banner.dart` | Orange info banners |
| `AvatarWidget` | `core/widgets/avatar_widget.dart` | Initials circles for clients |
| `EmptyState` | `core/widgets/loading_overlay.dart` | No-data empty screens |
| `SectionHeader` | `core/widgets/loading_overlay.dart` | Uppercase grey section labels |
| `LoadingOverlay` | `core/widgets/loading_overlay.dart` | Full-screen loading indicator |
| `DocumentForm` | `shared/widgets/document_form.dart` | New estimate / new invoice form |
| Paper document widgets | `shared/widgets/paper_document.dart` | Estimate/invoice preview pages |

### 7. Dependency injection — register in Injection, provide via BlocProvider

New repositories and BLoCs are wired in `lib/core/di/injection.dart`. BLoCs are provided at the screen level using `BlocProvider`, not at app root (except AuthBloc which is app-wide).

### 8. Mock data while API is pending

Until the .NET API is ready, repository `impl` classes should return hardcoded `Right(mockData)` rather than calling `_apiClient`. Structure the mock data to match the expected JSON shape so swapping to real API calls is a one-line change.

---

## Design System Summary (July 2026 rebrand)

**Font:** Manrope (bundled, weights 500–800)  
**Header / primary:** `#153A2B` (dark green, `AppColors.green800`)  
**CTA accent:** `#E2793A` (orange, `AppColors.orange500`) — all CTAs and FABs  
**Background:** `#F7F7F5` · **Surface (cards):** `#FFFFFF` with `#ECEEEC` hairline borders

**Screen pattern:** Dark green header (title 26/800, subtitle, translucent icon buttons, translucent search) → white pill tabs → grouped list rows with tinted status chips → orange extended FAB.

**Auth screens:** dark green hero with "S" logo; off-white sheet slides up from bottom.

**Bottom nav tabs (in order):** Estimates · Invoices · Clients · Leads · More
(Payments tab removed — payments are recorded from an invoice.)

Full design token reference: [docs/DESIGN_SYSTEM.md](docs/DESIGN_SYSTEM.md)

---

## What Not To Do

- Do not add a web platform — this is mobile only
- Do not switch state management away from BLoC/Cubit
- Do not use `Navigator.push` — use `context.go()` / `context.push()`
- Do not hardcode colors — use `AppColors`
- Do not call `ApiClient` from a screen widget
- Do not commit without the user reviewing first
- Do not add new top-level packages without confirming with the user

---

## Design Reference

The design source is the HTML mockup folder **"SERDEN APP FINAL DESIGN"**
(one self-contained HTML file per screen). Screen → implementation map:

| Mockup | Implementation |
|---|---|
| serden-onboarding.html | `auth/screens/onboarding_screen.dart` |
| serden-auth.html | `auth/screens/sign_up_screen.dart` + `sign_in_screen.dart` |
| serden-welcome.html | Estimates first-run state in `estimate_list_screen.dart` |
| serden-estimates.html | `estimates/screens/estimate_list_screen.dart` |
| serden-new-estimate.html | `shared/widgets/document_form.dart` (isInvoice: false) |
| serden-estimate-detail (5).html | `estimates/screens/estimate_detail_screen.dart` |
| serden-invoices.html / -empty.html | `invoices/screens/invoice_list_screen.dart` |
| serden-new-invoice-v2.html | `shared/widgets/document_form.dart` (isInvoice: true) |
| serden-invoice-detail.html | `invoices/screens/invoice_detail_screen.dart` |
| serden-record-payment.html | `invoices/screens/record_payment_screen.dart` |
| serden-clients.html (+ copy w/ add sheet) | `clients/screens/client_list_screen.dart` |
| serden-client-details.html | `clients/screens/client_detail_screen.dart` |
| serden-new-client.html | `clients/screens/add_client_screen.dart` |
| serden-leads.html | `leads/screens/leads_screen.dart` |
| serden-more.html | `more/screens/more_screen.dart` |
| serden-items.html | `more/screens/items_screen.dart` |
| serden-account.html | `more/screens/my_account_screen.dart` |
| serden-account-view.html | `more/screens/account_view_screen.dart` |
| serden-company-profile.html | `more/screens/company_profile_screen.dart` |
| serden-reviews.html | `more/screens/reviews_screen.dart` |
| Serden Plans.html | `plans/screens/choose_plan_screen.dart` |
