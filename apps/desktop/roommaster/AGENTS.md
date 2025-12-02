# Repository Guidelines

## Project Structure & Module Organization
- `lib/` contains the Flutter application code; `main.dart` hosts the dashboard UI and helper widgets.  
- Platform shells live in `ios/`, `android/`, `macos/`, `web/`, and `windows/`; macOS builds rely on `macos/Runner.xcodeproj`.  
- Assets such as fonts or images belong in `assets/` (referenced via `pubspec.yaml`).  
- Tests sit in `test/`, mirroring the structure of `lib/` for easy discovery.

## Build, Test, and Development Commands
- `flutter pub get` — sync dependencies after editing `pubspec.yaml`.  
- `flutter run -d macos` — launch the macOS desktop app in debug mode.  
- `flutter test` — execute the Dart/Flutter unit test suite.  
- `flutter build macos --release` — generate an optimized macOS bundle (ensure Xcode signing is configured).  
- For Xcode-only troubleshooting: `cd macos && xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Debug build`.

## Coding Style & Naming Conventions
- Follow Dart’s official style: 2‑space indentation, `lowerCamelCase` for variables/functions, `UpperCamelCase` for types.  
- Run `dart format .` (or rely on `flutter format`) before pushing.  
- Organize widgets logically; extract large UI sections (e.g., `_FuturisticStatCard`) into dedicated widgets.  
- Keep string literals localized or grouped for future i18n work.

## Testing Guidelines
- Use Flutter’s `test` package; files in `test/` should mirror their `lib/` counterparts (e.g., `lib/services/foo.dart` → `test/services/foo_test.dart`).  
- Name tests with clear intent: `group('Dashboard metrics', () { ... })`.  
- Aim to cover new logic with unit/widget tests; ensure `flutter test` passes before opening a PR.

## Commit & Pull Request Guidelines
- Write imperative, scoped commit messages: `Fix overflow in stat cards`, `Add macOS build script`.  
- Each PR should include: summary of changes, screenshots/GIFs for UI tweaks, and links to related issues.  
- Keep PRs focused; update docs (like this file) when workflows change.  
- Confirm `flutter analyze` and all tests succeed before requesting review.

## Additional Notes
- macOS builds may need extended-attribute cleanup; rerun `flutter build macos` if codesign errors appear.  
- Store secrets (API keys, tokens) outside the repo—use environment variables or secure storage.
