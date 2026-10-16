# VS Code Mock Backend Hot Reload Design

## Goal

Provide a VS Code debug workflow that runs the Flutter web frontend against its in-memory fake backend and hot reloads compatible Dart changes whenever a file is saved.

## Configuration

Keep the existing real-backend Flutter launch profile and add a separate `Flutter (Mock Backend)` profile. The mock profile will:

- launch Chrome through the Dart/Flutter VS Code extension;
- target `lib/main_fake_backend.dart`;
- serve the app on `localhost:62299`;
- define `API_BASE_URL=http://localhost:8888`;
- enable Flutter web semantics.

The workspace settings will set `dart.flutterHotReloadOnSave` to `all` while preserving the existing CMake source-directory setting.

## Runtime Behavior

Developers select `Flutter (Mock Backend)` from VS Code's Run and Debug panel and start debugging. Saving a compatible Dart change asks the Dart extension to hot reload the running app. The in-memory fake backend remains the only HTTP adapter used by that launch profile, so the real API does not need to be running.

Flutter limitations still apply: changes to initialization, native code, dependencies, build configuration, or other unsupported state require a hot restart or full relaunch.

## Validation

- Confirm both VS Code configuration files are valid JSON with comments.
- Confirm both real-backend and mock-backend launch profiles remain available.
- Launch the mock configuration's equivalent Flutter command and confirm `http://localhost:62299` returns HTTP 200.
- Confirm the mock profile targets `lib/main_fake_backend.dart` and that hot reload on save is enabled for all files.

No application tests are required because this change only affects development tooling.
