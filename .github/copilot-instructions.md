# Doormer — Project Instructions

Doormer is a Flutter **web-first** application for candidate onboarding (auth, registration, learning tools).  
**Flutter 3.27.1 / Dart SDK ^3.5.3** · Primary target: **web** (localStorage, `flutter_web_plugins`).

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
├── core/       # DI, routing, theme, errors, HTTP client, config, utils
├── features/<feature>/
│   ├── di/            # GetIt module for this feature
│   ├── data/          # datasource/ (Remote + Local), model/ (DTOs), repository/ (impl)
│   ├── domain/        # entity/, repository/ (abstract), usecase/
│   └── presentation/  # bloc/, pages/, widget/, utils/
└── shared/     # GlobalSessionBloc, User model, reusable widgets
```

### Layer rules — enforce these

- **Domain layer is pure Dart** — no Flutter or package imports. Repositories are abstract interfaces here.
- **BLoCs depend on UseCases only** — never on repositories or datasources directly.
- **Features never import each other.** Cross-feature state goes through `shared/` (e.g., `GlobalSessionBloc`).
- **Model ↔ Entity conversion**: response models expose `toEntity()`, request models use `factory fromEntity()`.

## Key Patterns

### BLoC (event-driven, not Cubit)

- Events and states extend **Equatable** (not Freezed).
- Use `part` directives to split event/state files from the BLoC file.
- Handler naming: `on<EventName>(_onEventName)` — private async methods.
- State flow: emit `Loading` → `Success` or `Failure(error)`.
- Cross-BLoC: inject the target BLoC, call `.add(Event)`.
- See `lib/src/features/auth/presentation/bloc/` for the reference pattern.

### Dependency Injection (GetIt)

- Central setup: `core/di/service_locator.dart` → calls each feature's `init<Feature>Module()`.
- **factory** for BLoCs, **lazySingleton** for repos/usecases/services.
- Access: `serviceLocator<T>()`.

### HTTP (Dio)

- Client: `core/connection/dio_client.dart` — 15s timeouts.
- `SessionInterceptor` attaches Bearer tokens; 401 → auto session expiry.
- Skip auth: `Options(extra: {'skipAuth': true})`.
- Catch `DioException` in datasources, throw domain exceptions.

### Models & Serialization

- **Manual JSON** — no codegen. Response: `factory fromJson(Map<String, dynamic>)`. Request: `toJson()`.
- Models in `data/model/`, entities in `domain/entity/`.

### Error Handling

- Failure hierarchy in `core/errors/failure.dart`: `NetworkFailure`, `ServerFailure`, `ApiFailure(statusCode)`, `AuthFailure`, `DatabaseFailure`, `UnknownFailure`.
- BLoCs catch exceptions and emit `Failure` states. dartz `Either` is not used — stick with try/catch.

### Routing (GoRouter)

- Routes: `core/routes/app_router.dart` + `web_router.dart`. Uses `PathUrlStrategy` (no hash).
- Session expiry → redirect to `/auth` via `BlocListener<GlobalSessionBloc>` in `main.dart`.

## Conventions

- **File naming**: `snake_case.dart`. Web-specific widgets use `_web` suffix.
- **Theming**: use `AppColors` and `AppTextStyles` constants — no raw hex. Use ScreenUtil extensions (`.sp`, `.w`, `.h`).
- **Logging**: use `AppLogger` (`core/utils/app_logger.dart`) — never `print()`.
- **Widgets**: pages in `pages/`, small reusables in `widget/`, helpers in `utils/`.

## Adding a New Feature

1. Create `lib/src/features/<name>/` with `di/`, `data/`, `domain/`, `presentation/` subdirs.
2. Define abstract repository in `domain/repository/`.
3. Create entities (`domain/entity/`) and models (`data/model/`) with conversion methods.
4. Implement datasources (`data/datasource/` — remote for API, local for cache).
5. Implement repository in `data/repository/`.
6. Create use cases in `domain/usecase/`.
7. Create BLoC with events/states in `presentation/bloc/`.
8. Add DI module in `di/<name>_module.dart`, register in `service_locator.dart`.
9. Add routes in `core/routes/`.
