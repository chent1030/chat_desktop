# Repository Guidelines

This guide helps contributors work efficiently on the Chat Desktop (Flutter) app. Keep changes focused, small, and testable.

## Project Structure & Module Organization
- `lib/` — main source code
  - `main.dart`, `app.dart`, `mini_window_entry.dart`
  - `models/` (data classes, generated `*.g.dart`)
  - `providers/` (state via Provider)
  - `services/` (API, MQTT, AI adapters, storage, logging)
  - `screens/`, `widgets/`, `utils/`
- `assets/` — images, animations, static files
- `test/` — `unit_test/`, `widget_test/`, `integration_test/`
- Platform: `macos/`, `windows/`
- Config: `.env` (copy from `.env.example`, do not commit secrets)

## Build, Test, and Development Commands
- Install deps: `flutter pub get`
- Run (auto‑detect device): `flutter run`
- Run macOS: `flutter run -d macos`
- Run Windows: `flutter run -d windows`
- Analyze lints: `flutter analyze`
- Format: `dart format .`
- Tests: `flutter test`
- Coverage: `flutter test --coverage`
- Release builds: `flutter build macos --release` or `flutter build windows --release`

## Coding Style & Naming Conventions
- Dart style, 2‑space indent, single quotes preferred.
- Follow `analysis_options.yaml` (enabled rules include: `prefer_single_quotes`, `prefer_const_*`, `avoid_print`, `prefer_relative_imports`, etc.).
- Naming: `UpperCamelCase` classes, `lowerCamelCase` methods/vars, `SCREAMING_SNAKE_CASE` consts.
- Prefer relative imports inside `lib/`.

## Testing Guidelines
- Framework: `flutter_test`; place tests under `test/` with `*_test.dart` names.
- Keep tests fast and deterministic; mock external services (e.g., MQTT, HTTP, AI adapters).
- Aim to cover providers, services, and critical widgets.
- Run `flutter test` locally before opening a PR.

## Commit & Pull Request Guidelines
- Commits: short imperative summary (≤ 50 chars), optional body for rationale; English or Chinese OK, be consistent. Reference issues (e.g., `Fixes #123`).
- PRs must include:
  - Purpose and scope, notable design decisions
  - How to test (commands, steps, target platform)
  - Screenshots/GIFs for UI changes
  - Linked issues and risk/rollback notes

## Security & Configuration Tips
- Never commit secrets. Use `.env` and document required keys in `.env.example`.
- Avoid `print`; use `services/log_service.dart`.
- Network/API keys should be read via `services/config_service.dart`.

