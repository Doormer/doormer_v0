# Doormer — Project Instructions

Doormer is a Flutter **web-first** application for candidate onboarding (auth, registration, learning tools).  
**Flutter 3.27.1 / Dart SDK ^3.5.3** · Primary target: **web** (cookies via `universal_html`, `flutter_web_plugins` for URL strategy).

## Build & Run

```bash
# Install dependencies
flutter pub get

# Run on web (dev)
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8888

# Production build
flutter build web --dart-define=API_BASE_URL=<prod-url> --dart-define=GOOGLE_CLIENT_ID=<id>

# Static analysis
flutter analyze

# Code generation (freezed / json_serializable — if used)
dart run build_runner build --delete-conflicting-outputs

# Tests (none exist yet — infra is ready: test, bloc_test, mockito)
flutter test
```

### Environment variables (passed via `--dart-define`)

| Variable | Default | Purpose |
|----------|---------|---------|
| `API_BASE_URL` | `http://localhost:8888` | Backend API root |
| `GOOGLE_CLIENT_ID` | hardcoded dev ID | Google OAuth client |

See `lib/src/core/config/app_config.dart` for all config values.

## Architecture — Clean Architecture

Each feature has three layers: **data → domain → presentation**, plus a feature-level DI module.

```
lib/src/
├── core/       # DI, routing, theme, errors, HTTP client, config, services, utils
│   ├── connection/   # dio_client.dart, dio_exception_mapper.dart, interceptors/
│   ├── errors/       # failure.dart (typed Failure hierarchy)
│   ├── services/     # cross-cutting services (e.g. sessions/SessionService)
│   └── utils/        # AppLogger, token storage, helpers
├── features/<feature>/
│   ├── di/            # GetIt module for this feature
│   ├── data/          # datasource/ (Remote + Local), model/ (DTOs), repository/ (impl)
│   ├── domain/        # entity/, repository/ (abstract), usecase/
│   ├── presentation/  # bloc/, pages/, widget/
│   └── utils/         # feature-level helpers and validators
└── shared/     # cross-feature code: user/ (User entity + model), sessions/ (GlobalSessionBloc), widget/
```

### Layer rules — enforce these

- **Domain layer is pure Dart** — no Flutter or third-party package imports. Repositories are abstract interfaces here. `core/errors/failure.dart` is pure Dart and safe to reference from any layer. `dart:` core libraries (e.g. `dart:typed_data` for `Uint8List`) are allowed.
- **BLoCs depend on UseCases only** — never on repositories or datasources directly.
- **Features never import each other.** Cross-feature state and entities go through `shared/` (e.g., `GlobalSessionBloc`, the `User` entity in `shared/user/entity/`). Do not duplicate shared entities inside a feature's `domain/entity/`.
- **Model ↔ Entity conversion**: response models parse with `fromJson()` and expose `toEntity()`; request models build via `factory fromEntity()` and serialize with `toJson()`. A model used in both directions may expose all four.

## Key Patterns

### BLoC (event-driven, not Cubit)

- Events and states extend **Equatable** (not Freezed).
- Use `part` directives to split event/state files from the BLoC file.
- Handler naming: `on<EventName>(_onEventName)` — private async methods.
- State flow: emit `Loading` → `Success` or an **error state**.
- **Error states use the `XxxError` suffix** (e.g., `AuthError`), NOT `XxxFailure`. `XxxFailure` names are reserved for the domain `Failure` types in `core/errors/failure.dart` — using them as state names creates a collision.
- BLoC error handling: catch typed `Failure` first, then a generic fallback. Always log in both branches:
  ```dart
  } on Failure catch (f, stackTrace) {
    emit(AuthError(f.message));
    AppLogger.error('Login failed', error: f, stackTrace: stackTrace);
  } catch (e, stackTrace) {
    emit(AuthError('An unexpected error occurred'));
    AppLogger.error('Login unexpected error', error: e, stackTrace: stackTrace);
  }
  ```
- Cross-BLoC: inject the target BLoC, call `.add(Event)`.
- See `lib/src/features/auth/presentation/bloc/` for the reference pattern.

### Dependency Injection (GetIt)

- Central setup: `core/di/service_locator.dart` → calls each feature's `init<Feature>Module()` (actual names: `initAuthModule()`, `initRegisterModule()` — registration abbreviates to "Register").
- **factory** for BLoCs (each page needs a fresh instance with clean state).
- **lazySingleton** for repos, usecases, datasources, and services (stateless — one instance is enough).
- **singleton** (eager) for app-wide BLoCs (e.g. `GlobalSessionBloc`) and platform services (e.g. `TokenStorage`) that must exist before any lazy resolution occurs.
- Access: `serviceLocator<T>()`.

### HTTP (Dio)

- Client: `core/connection/dio_client.dart` — 15s timeouts.
- `SessionInterceptor` (`core/connection/interceptors/`) attaches Bearer tokens; 401 → auto session expiry.
- Skip auth: `Options(extra: {'skipAuth': true})`.
- In datasources, catch `DioException` and convert it with `dioExceptionToFailure` (see Error Handling).

### Models & Serialization

- **Manual JSON by default.** Response: `factory fromJson(Map<String, dynamic>)`. Request: `toJson()`. The current DTOs are small, so hand-written serialization is preferred — it avoids a `build_runner` step and matches the Equatable-not-Freezed BLoC convention.
- Models in `data/model/`, entities in `domain/entity/` (shared entities in `shared/`).
- **When to reach for Freezed / json_serializable** (already in `pubspec.yaml`): use it only when a *data-layer* model genuinely needs `copyWith`, value equality, immutability, sealed/union variants, or has enough fields/nesting that manual JSON becomes error-prone. Don't convert trivial DTOs just because the tooling exists. When you do: keep it confined to `data/model/` (never import `freezed_annotation` into a domain entity — domain stays pure Dart), preserve exact JSON keys with `@JsonKey(name:)`, retain `toEntity()`/`fromEntity()` via a `const Model._()` private constructor, and run `dart run build_runner build --delete-conflicting-outputs`.

### Error Handling

Typed `Failure` hierarchy in `core/errors/failure.dart` (pure Dart): `NetworkFailure`, `ServerFailure`, `ApiFailure(statusCode, message)`, `AuthFailure`, `ValidationFailure`, `DatabaseFailure`, `UnknownFailure`. `Failure.toString()` returns its `message`.

Rules:

- **Datasources throw typed `Failure`s — never raw `Exception`.** For `DioException`, use the shared mapper `dioExceptionToFailure(e, {required String userFacingMessage})` in `core/connection/dio_exception_mapper.dart`. It maps by type/status: timeout & connection → `NetworkFailure`, 401 → `AuthFailure`, 422 → `ValidationFailure`, 5xx → `ServerFailure`, other 4xx → `ApiFailure`, else → `UnknownFailure`.
- **`userFacingMessage` must be user-friendly** — no server jargon. Server response bodies are NEVER put into `Failure.message`; they only go to logs (pass the raw exception as `error:`).
- **Every `catch` must log before throwing/rethrowing.** Use `AppLogger.error('context', error: e, stackTrace: stackTrace)`.
- **Repositories and UseCases pass `Failure`s through** — don't re-wrap. Use `on Failure { rethrow; }` to let typed failures propagate, only wrapping genuinely new failure sources (e.g., a local save) in their own typed `Failure`.
- **BLoCs catch `Failure` and emit error states** — see BLoC section. `dartz`/`Either` is not used; stick with try/catch.
- **Never log secrets** (tokens, passwords, raw credentials).

Datasource pattern:
```dart
try {
  final response = await dio.post('/login', data: {...});
  return LoginResponseModel.fromJson(response.data);
} on DioException catch (e, stackTrace) {
  AppLogger.error('Login failed', error: e, stackTrace: stackTrace);
  throw dioExceptionToFailure(e,
      userFacingMessage: 'Login failed. Please check your credentials.');
}
```

### Routing (GoRouter)

- Routes: `core/routes/app_router.dart` + `web_router.dart` (`AppRouter` delegates to `WebRouter.router`). `PathUrlStrategy` (no hash) is set in `main.dart` via `setUrlStrategy()`, not in the router files.
- Session expiry → redirect to `/auth` via `BlocListener<GlobalSessionBloc>` in `main.dart`.

## Atomic Design (presentation layer)

Decompose a feature's screens into a layered widget hierarchy instead of one monolithic page. Apply it when a page grows past a simple form/list; don't force it on trivial screens. The `questions` feature is the reference implementation (`features/questions/presentation/`).

### The layers — dependencies point strictly downward

`page → template → organism → molecule → atom`. A layer may only compose layers below it; never sideways or upward.

- **Atoms** — smallest reusable widgets (button, card, icon decoration), no feature knowledge. Generic ones live in `lib/src/shared/design/atomic/atoms/` (e.g. `AppButtonAtom`, `SurfaceCardAtom`); atoms tied to one feature live in `features/<f>/presentation/atoms/`.
- **Molecules** — small compositions of atoms + static layout (`features/<f>/presentation/molecules/`). Receive plain data + callbacks via constructor params. No bloc.
- **Organisms** — larger sections composed of molecules/atoms (`organisms/`). Group their inputs into a **Parameter Object** in `params/` (the `xxxParams` pattern). Params are **plain holders, NOT `Equatable`** — they carry `VoidCallback`s, which compare by reference.
- **Templates** — arrange organisms into the page layout (`Scaffold`, responsive `LayoutBuilder`) in `templates/`. A template owns the screen's single `Scaffold`, including its background color and other page chrome. Receive ready-made param objects / primitives only. **No content derivation, no bloc.**
- **Pages** — the ONLY layer that touches `flutter_bloc` (`pages/`). Own `BlocProvider`/`BlocConsumer`, resolve display copy via a pure presenter in `mapper/`, pack the param objects, and delegate rendering to the template.

### Enforce these

- **No `flutter_bloc` or bloc-state imports below the page** — atoms, molecules, organisms, templates, and params stay bloc-free. The `mapper/` presenter is the only non-page unit allowed to import the bloc, and only for state *types*; its mapping function is **page-invoked only**.
- **Do not nest page and template scaffolds.** A page that delegates to a template returns that template directly; it must not wrap the template in another `Scaffold`.
- **Static chrome copy may be hardcoded** in a molecule/organism (titles, button labels like `Clear`/`Retake`). **State- or data-driven text must flow in** via params / the mapper — never hardcode it below the page.
- **Naming**: suffix classes `XxxAtom` / `XxxMolecule` / `XxxOrganism` / `XxxTemplate` / `XxxParams`; files `snake_case.dart`. Theming and sizing rules (`AppColors`/`AppTextStyles`, ScreenUtil) apply as everywhere else.

## Conventions

- **File naming**: `snake_case.dart`. Web-specific widgets use `_web` suffix.
- **Theming**: use `AppColors` and `AppTextStyles` constants — no raw hex. Use ScreenUtil extensions (`.sp`, `.w`, `.h`).
- **Logging**: use `AppLogger` (`core/utils/app_logger.dart`) — never `print()`. For errors use named args: `AppLogger.error('context', error: e, stackTrace: stackTrace)`. Never log secrets (tokens, passwords).
- **Widgets**: pages in `pages/`, small reusables in `widget/`, helpers in `utils/`.

## Adding a New Feature

1. Create `lib/src/features/<name>/` with `di/`, `data/`, `domain/`, `presentation/` subdirs.
2. Define abstract repository in `domain/repository/`.
3. Create entities (`domain/entity/`) and models (`data/model/`) with conversion methods. Reuse a `shared/` entity instead of creating your own when one fits (e.g. auth reuses the `User` entity from `shared/user/entity/` and has no `domain/entity/` of its own).
4. Implement datasources (`data/datasource/` — remote for API, local for cache).
5. Implement repository in `data/repository/`.
6. Create use cases in `domain/usecase/`.
7. Create BLoC with events/states in `presentation/bloc/`. For non-trivial screens, structure the widgets with **Atomic Design** (see that section) — atoms/molecules/organisms/templates with a thin bloc-aware page.
8. Add DI module in `di/<name>_module.dart`, register in `service_locator.dart`.
9. Add routes in `core/routes/`.
