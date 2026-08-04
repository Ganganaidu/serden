# Architecture

## Overview

Serden follows **Clean Architecture** split into three layers — Presentation, Domain, and Data — organised by feature rather than by layer. This keeps all code for one feature co-located and makes it easy to work on Estimates without touching Invoices.

```
Presentation  →  Domain  →  Data
(BLoC/Screen)    (Model,     (Repository impl,
                  Failure,    ApiClient,
                  Repository  SecureStorage)
                  abstract)
```

---

## Layer Responsibilities

### Presentation (`screens/`, `bloc/`)
- Widgets render UI based on BLoC state
- Screens dispatch events to BLoC; never call repository directly
- Cubit for simple state (toggle, settings page); BLoC for multi-event flows

### Domain (`models/`, `repository/` abstract, `core/errors/`)
- Pure Dart — no Flutter imports, no Dio imports
- `Either<Failure, T>` is the return type for every repository method
- Models are `Equatable`, have `fromJson`/`toJson`, and a `copyWith`

### Data (`repository/` impl, `core/network/`, `core/storage/`)
- Repository impls translate raw exceptions into typed `Failure`s
- `ApiClient` is the only place `Dio` is used
- `SecureStorage` is the only place `flutter_secure_storage` is used

---

## BLoC Pattern

### When to use BLoC vs Cubit

| Use **BLoC** | Use **Cubit** |
|---|---|
| Multiple distinct events with different logic paths | Simple state that can be toggled or set directly |
| Complex async sequences (e.g. form wizard) | Settings screen, My Account |
| When events carry different payloads | Loading/displaying a single resource |

### File layout

Three files, always using `part of`:

```dart
// auth_bloc.dart — the main file
import ...;
part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> { ... }
```

```dart
// auth_event.dart
part of 'auth_bloc.dart';
abstract class AuthEvent extends Equatable { ... }
class AuthSignInRequested extends AuthEvent { ... }
```

```dart
// auth_state.dart
part of 'auth_bloc.dart';
abstract class AuthState extends Equatable { ... }
class AuthLoading extends AuthState { ... }
class AuthAuthenticated extends AuthState { ... }
```

### State naming convention

Every feature follows the same state naming:

```
<Feature>Initial    — before any action
<Feature>Loading    — async in progress
<Feature>Loaded     — success, carries data
<Feature>Error      — failure, carries message string
```

For list screens add `<Feature>Empty` when the API returns an empty list (triggers EmptyState widget).

---

## Navigation

Router file: `lib/core/router/app_router.dart`

```
/onboarding           (no shell — full screen)
/sign-in              (no shell — full screen)
/sign-up              (no shell — full screen)
/choose-plan          (no shell — full screen)

ShellRoute → MainShell (bottom nav)
  /estimates
  /estimates/new
  /estimates/line-item
  /estimates/:id
  /invoices
  /invoices/new
  /invoices/:id
  /clients
  /clients/add
  /clients/:id
  /payments
  /more
  /more/settings
  /more/account
  /more/items
  /more/expenses
  /more/about
```

**Auth guard** — the `redirect` callback on `GoRouter` checks `AuthBloc` state on every navigation:
- If `AuthUnauthenticated` and not on an auth route → redirect to `/onboarding`
- If `AuthAuthenticated` and on an auth route → redirect to `/estimates`

`GoRouterRefreshStream` bridges the BLoC stream to GoRouter's `Listenable` so redirects fire automatically when auth state changes.

---

## Dependency Injection

File: `lib/core/di/injection.dart`

Manual DI — no `get_it`, no `injectable`. Call `Injection.init()` once in `main()` before `runApp`. The `Injection` class holds static singletons.

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Injection.init();
  runApp(const SerdenApp());
}
```

Adding a new feature:
1. Create `Injection.create<Feature>Repository()` factory
2. Create `Injection.create<Feature>Bloc()` factory
3. Provide the BLoC at screen level with `BlocProvider`

---

## Error Handling

```
ApiClient throws Exception
    ↓
Repository impl catches → maps to Failure
    ↓
BLoC receives Either<Failure, T>
    ↓
.fold( left → emit ErrorState, right → emit SuccessState )
    ↓
Screen shows error UI or success UI
```

Failure hierarchy (`lib/core/errors/failures.dart`):

```
Failure (abstract)
├── NetworkFailure       — no connection / timeout
├── ServerFailure        — 5xx errors
├── UnauthorizedFailure  — 401 (triggers logout)
├── NotFoundFailure      — 404
├── ValidationFailure    — 422 (carries field errors map)
├── CacheFailure         — local storage error
└── UnexpectedFailure    — catch-all
```

---

## API Client

File: `lib/core/network/api_client.dart`

Thin wrapper around `Dio`. All methods return `Response` on success or throw typed exceptions.

`TokenInterceptor` (`lib/core/network/token_interceptor.dart`) reads the JWT from `SecureStorage` and attaches `Authorization: Bearer <token>` to every request. When a 401 is received it propagates the error; the `AuthBloc` listens and fires `AuthSignOutRequested`.

Base URL: `AppConstants.baseUrl` — change this one constant to switch between dev/staging/prod.

---

## Folder Naming Conventions

| Pattern | Example |
|---|---|
| Feature folders | `snake_case` — `estimates`, `line_items` |
| Dart files | `snake_case` — `estimate_list_screen.dart` |
| Classes | `PascalCase` — `EstimateListScreen` |
| BLoC events | `PascalCase` + verb — `EstimatesLoadRequested` |
| BLoC states | `PascalCase` + adjective — `EstimatesLoaded` |
| Route constants | `camelCase` in `AppRoutes` — `AppRoutes.estimates` |
| Color constants | `camelCase` in `AppColors` — `AppColors.primary` |
