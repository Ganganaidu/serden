# Serden

A Flutter mobile app for contractor and freelancer business management. Serden lets tradespeople create professional estimates, send invoices, manage clients, and track payments — all from their phone.

**Platforms:** iOS + Android (mobile only, portrait locked)  
**Backend:** .NET REST API (in development — screens use stub/mock data until API is ready)  
**Figma:** https://www.figma.com/design/K5TdhFBBuj8qbHJFQYKHO6/Serden-screens  
**Flutter:** 3.35+ · Dart 3.9+

---

## Quick Start

```bash
cd serden
flutter pub get
flutter run
```

---

## Project Structure

```
lib/
├── main.dart               # Entry point — DI init, portrait lock, runApp
├── app.dart                # SerdenApp — MaterialApp.router + AuthBloc provider
├── core/                   # Shared framework-level code
│   ├── constants/          # AppConstants (base URL, keys, timeouts, pagination)
│   ├── di/                 # Manual dependency injection (Injection class)
│   ├── errors/             # Failures (domain layer) + Exceptions (data layer)
│   ├── network/            # Dio ApiClient + TokenInterceptor (Bearer auth)
│   ├── router/             # go_router: all routes + auth guard + GoRouterRefreshStream
│   ├── storage/            # SecureStorage (flutter_secure_storage wrapper)
│   ├── theme/              # AppColors, AppTextStyles, AppTheme (Material 3)
│   ├── utils/              # Formatters (currency, dates, initials)
│   └── widgets/            # Shared UI: MainShell, TealHeader, StatusBadge, AvatarWidget, EmptyState
└── features/               # One folder per product feature
    ├── auth/               # Onboarding, Sign In, Sign Up — AuthBloc
    ├── estimates/          # Estimate list, new estimate wizard, detail, line items
    ├── invoices/           # Invoice list, new invoice wizard, detail
    ├── clients/            # Client list, detail, add client
    ├── payments/           # Payments tab
    ├── plans/              # Subscription plan selection (Basics/Pro/Elite)
    └── more/               # Settings, My Account, Items, Expenses, About
```

---

## Documentation Index

| File | Purpose |
|---|---|
| [CLAUDE.md](CLAUDE.md) | **Start here if you are an AI assistant** — conventions, rules, what not to touch |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Full architecture: BLoC pattern, data flow, DI, routing |
| [docs/FEATURES.md](docs/FEATURES.md) | Every screen mapped to its data, BLoC, and API needs |
| [docs/API.md](docs/API.md) | Expected .NET API contract for each feature |
| [docs/DESIGN_SYSTEM.md](docs/DESIGN_SYSTEM.md) | Colors, typography, and shared components from Figma |
| [docs/CONVENTIONS.md](docs/CONVENTIONS.md) | Naming rules, file layout rules, code style |

---

## Key Technology Choices

| Concern | Library | Reason |
|---|---|---|
| State | `flutter_bloc` | BLoC/Cubit — enterprise scale, predictable, testable |
| Navigation | `go_router` | Auth redirect guard, deep linking, ShellRoute bottom nav |
| HTTP | `dio` | Interceptors for JWT injection; works well with .NET APIs |
| Auth storage | `flutter_secure_storage` | Keychain (iOS) + EncryptedSharedPreferences (Android) |
| Error typing | `dartz` | `Either<Failure, T>` — forces callers to handle failures |
| Forms | `flutter_form_builder` | Multi-section wizard forms (New Estimate, New Invoice) |
| DI | Manual `Injection` class | Zero magic — readable by any developer |
