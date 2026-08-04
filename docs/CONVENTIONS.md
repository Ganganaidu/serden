# Conventions

Rules that every developer (and AI assistant) must follow when adding code to this project.

---

## File & Folder Naming

- All Dart files: `snake_case.dart`
- All folders: `snake_case`
- Feature folder names must be singular: `estimate` not `estimates`, `client` not `clients` — **exception:** the folder at `lib/features/` uses plural because it mirrors the route names (`estimates`, `invoices`, `clients`)

```
lib/features/estimates/screens/estimate_list_screen.dart   ✅
lib/features/estimates/screens/EstimateList.dart           ❌
```

---

## Class Naming

| Type | Convention | Example |
|---|---|---|
| Widgets/screens | `PascalCase` + `Screen` | `EstimateListScreen` |
| BLoC | `PascalCase` + `Bloc` | `EstimatesBloc` |
| Cubit | `PascalCase` + `Cubit` | `MyAccountCubit` |
| Events | `PascalCase` + past tense verb | `EstimatesLoadRequested` |
| States | `PascalCase` + adjective | `EstimatesLoaded`, `EstimatesLoading` |
| Models | `PascalCase` + `Model` | `EstimateModel`, `ClientModel` |
| Repositories | `PascalCase` + `Repository` | `EstimatesRepository` (abstract), `EstimatesRepositoryImpl` (impl) |
| Failures | `PascalCase` + `Failure` | `ServerFailure`, `NetworkFailure` |

---

## BLoC Conventions

### Event naming
Events are named in the form `<Subject><Action>Requested`:

```dart
EstimatesLoadRequested        // load the list
EstimateCreateRequested       // create new
EstimateDeleteRequested       // delete by id
EstimateStatusUpdateRequested // change status
```

### State naming
```dart
EstimatesInitial   // before first load
EstimatesLoading   // async in progress
EstimatesLoaded    // carries List<EstimateModel>
EstimatesEmpty     // API returned empty list
EstimatesError     // carries String message
```

### Handler methods
Name them `_on<EventName>`:

```dart
on<EstimatesLoadRequested>(_onLoadRequested);
on<EstimateCreateRequested>(_onCreateRequested);

Future<void> _onLoadRequested(
  EstimatesLoadRequested event,
  Emitter<EstimatesState> emit,
) async { ... }
```

---

## Repository Conventions

Every public repository method returns `Future<Either<Failure, T>>`:

```dart
abstract class EstimatesRepository {
  Future<Either<Failure, List<EstimateModel>>> getEstimates({String? status});
  Future<Either<Failure, EstimateModel>> getEstimate(String id);
  Future<Either<Failure, EstimateModel>> createEstimate(CreateEstimateInput input);
  Future<Either<Failure, EstimateModel>> updateEstimate(String id, UpdateEstimateInput input);
  Future<Either<Failure, void>> deleteEstimate(String id);
}
```

Always define `Input` classes for create/update payloads — never pass raw `Map<String, dynamic>` between layers.

---

## Model Conventions

All models must:
1. Extend `Equatable`
2. All fields `final`
3. Have `fromJson(Map<String, dynamic>)` factory
4. Have `toJson()` method
5. Have `copyWith(...)` method

```dart
class EstimateModel extends Equatable {
  final String id;
  final String clientName;
  final double total;
  final DocumentStatus status;

  const EstimateModel({
    required this.id,
    required this.clientName,
    required this.total,
    required this.status,
  });

  factory EstimateModel.fromJson(Map<String, dynamic> json) => EstimateModel(
        id: json['id'],
        clientName: json['clientName'],
        total: (json['total'] as num).toDouble(),
        status: DocumentStatus.fromString(json['status']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'clientName': clientName,
        'total': total,
        'status': status.name,
      };

  EstimateModel copyWith({String? clientName, double? total}) =>
      EstimateModel(
        id: id,
        clientName: clientName ?? this.clientName,
        total: total ?? this.total,
        status: status,
      );

  @override
  List<Object?> get props => [id, clientName, total, status];
}
```

---

## Screen Conventions

Every screen widget:
- Is a `StatelessWidget` unless it needs lifecycle callbacks (`initState`, `dispose`) — then `StatefulWidget`
- Gets its BLoC via `BlocProvider` from its route, not from a global provider
- Uses `BlocBuilder` to rebuild on state change, `BlocListener` to react to side effects (show snackbar, navigate)
- Does **not** call any service, repository, or API directly

```dart
class EstimateListScreen extends StatelessWidget {
  const EstimateListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => Injection.createEstimatesBloc(),
      child: BlocListener<EstimatesBloc, EstimatesState>(
        listener: (context, state) {
          if (state is EstimatesError) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: BlocBuilder<EstimatesBloc, EstimatesState>(
          builder: (context, state) {
            return switch (state) {
              EstimatesLoading() => const Center(child: CircularProgressIndicator()),
              EstimatesEmpty() => EmptyState(...),
              EstimatesLoaded(:final estimates) => _EstimateList(estimates: estimates),
              EstimatesError() => const SizedBox.shrink(),
              _ => const SizedBox.shrink(),
            };
          },
        ),
      ),
    );
  }
}
```

---

## Widget Conventions

- Extract sub-widgets into private classes within the same file using `_PrivateWidgetName`
- Only extract to a separate file if the widget is used in more than one screen
- Shared components go in `lib/core/widgets/`
- Feature-specific sub-widgets go in `lib/features/<feature>/screens/widgets/`

```dart
// Good — private class in same file
class _EstimateListItem extends StatelessWidget { ... }

// Good — extracted to shared widgets because used in 3+ places
// lib/core/widgets/status_badge.dart
class StatusBadge extends StatelessWidget { ... }
```

---

## Navigation Conventions

```dart
// Navigate to a tab (replaces current)
context.go(AppRoutes.estimates);

// Push onto stack (can go back)
context.push(AppRoutes.newEstimate);
context.push('/estimates/${estimate.id}');

// Go back
context.pop();

// Pass result back from pushed screen
context.pop(selectedClient);  // in child
final client = await context.push<ClientModel>(AppRoutes.addClient); // in parent
```

Never use `Navigator.push`, `Navigator.pop`, or `Navigator.of(context)`.

---

## Mock Data Convention

While the API is not ready, repository impls return mock data like this:

```dart
@override
Future<Either<Failure, List<EstimateModel>>> getEstimates({String? status}) async {
  // TODO: replace with real API call when backend is ready
  await Future.delayed(const Duration(milliseconds: 400)); // simulate network
  return Right(_mockEstimates);
}

static final _mockEstimates = [
  EstimateModel(id: '1', clientName: 'Joseph Ulrich', total: 10600, status: DocumentStatus.issued),
  EstimateModel(id: '2', clientName: 'Susan Perry', total: 14800, status: DocumentStatus.issued),
];
```

The `Future.delayed` makes the loading state visible during development so you can see the shimmer/loading UI.

---

## Formatting

Run before every commit:
```bash
dart format lib/ test/
flutter analyze
```

There must be **zero `flutter analyze` warnings** before code is committed. The project uses `flutter_lints` — do not disable any lint rules.

---

## Comments

Write comments only when the **why** is non-obvious. Never write comments that restate what the code does.

```dart
// Bad — restates the code
final token = await _storage.read(key); // read token from storage

// Good — explains a non-obvious constraint
// Keychain reads on iOS return null on first app launch after device restart
// until the user unlocks the device. Don't treat null as "not logged in".
final token = await _storage.read(AppConstants.accessTokenKey);
```
