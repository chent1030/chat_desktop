# Repository Guidelines

## Project Structure & Module Organization
- Flutter app: `lib/` (Dart sources), `assets/`, `test/`, platform folders (`windows/`, `macos/`, `linux/`).
- Windows runner: `windows/runner/` (Flutter host app).
- Native floating window (Win10+): `windows/native_floating_ball/` (C++ WIC/D2D, Acrylic bubble, IPC).
- Icons/media: e.g. `assets/static_logo.ico`, `dynamic_logo.gif`, `unread_logo.gif`.

## Build, Test, and Development Commands
- Install deps: `flutter pub get`
- Run (macOS): `flutter run -d macos`
- Run (Windows): `flutter run -d windows`
- Build (Windows): `flutter build windows`
- Tests: `flutter test`
- Native floating window (standalone debug, optional):
  - `cmake -S windows/native_floating_ball -B build -G Ninja`
  - `cmake --build build --config Debug`

## Coding Style & Naming Conventions
- Dart: 2‑space indent; types `UpperCamelCase`, members `lowerCamelCase`, files `snake_case.dart`.
- Prefer domain names over DB-reserved terms (e.g., use `taskId`/`taskUuid` not bare `uuid`).
- Run formatter: `dart format .`; keep imports ordered; avoid one‑letter vars.
- C++: follow existing patterns; classes `PascalCase`, methods `lowerCamelCase`, files `snake_case.cpp/h`.

## Testing Guidelines
- Unit/widget tests live in `test/` mirroring `lib/` paths.
- Name tests `*_test.dart`; keep fast and deterministic.
- Run locally with `flutter test`; add screenshots only to PR description, not to repo.

## Commit & Pull Request Guidelines
- Conventional commits: `feat:`, `fix:`, `refactor:`, `build(windows):`, `chore:`.
- PRs must include: purpose, linked issues, platform(s) affected, reproduction steps, and before/after screenshots or a short clip for UI.
- For Windows issues, attach relevant snippets from `error.log` and the failing MSBuild/CMake lines.

## Security & Configuration Tips
- MQTT credentials via environment variables (do not commit): `MQTT_USERNAME`, `MQTT_PASSWORD`.
- Platform launch helpers should read env at runtime; avoid hardcoding secrets.
- Keep media next to the executable when required by native code (e.g., `dynamic_logo.gif`, `unread_logo.gif`).

## Platform Notes
- Windows floating window: frameless, transparent, draggable, top‑most; communicates with main app via IPC.
- macOS/Windows UI parity: avoid OS‑only features without graceful fallbacks.
- App icon: use `assets/static_logo.ico` for Windows runner.

