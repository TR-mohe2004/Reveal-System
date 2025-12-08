Project: reveal_app (Flutter)

Purpose
- Help AI coding agents get productive quickly in this repository: a Flutter multi-platform app scaffolded with standard platform folders (`android/`, `ios/`, `windows/`, `linux/`, `macos/`).

Big picture
- Single Flutter app with platform folders for native builds. Entrypoint: `lib/main.dart`.
- App code is organized under `lib/` (look for `lib/app/` and `lib/core/` — UI, presentation layers live here).
- Assets: images live in `assets/images/` and are declared in `pubspec.yaml`.

Important files & dirs (quick reference)
- `lib/main.dart` — app entrypoint and DI/bootstrap.
- `lib/app/` — main app modules (UI, routes, presentation). Use this as the starting point for feature changes.
- `pubspec.yaml` — dependencies and asset declarations (`google_fonts` is used and `assets/images/` enabled).
- `android/` — Android Gradle Kotlin DSL (`build.gradle.kts`, `app/build.gradle.kts`) — native Android configuration.
- `ios/`, `macos/`, `windows/`, `linux/` — platform code and build artifacts. iOS/macOS builds require macOS host.

Build & run (developer workflows)
- Typical Flutter dev (cross-platform):
  - `flutter pub get`
  - `flutter run -d <deviceId>` (or run from VS Code / Android Studio)
  - `flutter build apk` (Android), `flutter build ios` (macOS host), `flutter build windows` (Windows).
- Android via Gradle (Windows):
  - `cd android; .\gradlew.bat assembleDebug` — useful when debugging native Gradle issues or CI.
- Tests: `flutter test` runs unit/widget tests in `test/`.

Debugging & tooling
- Use VS Code or Android Studio with the Flutter extension and Dart DevTools for UI inspection and profiling.
- For runtime attach: run on device then `flutter attach` to connect a debugger to an already-running app.
- Use `flutter pub outdated` / `flutter pub upgrade --major-versions` to inspect and upgrade deps.

Project-specific conventions
- Keep UI/presentation inside `lib/app/` and core/shared logic (models, services) under `lib/core/`.
- Assets: add image files under `assets/images/` and reference them in `pubspec.yaml`. Avoid placing large binaries in source.
- Gradle files use Kotlin DSL (`*.kts`) — when editing Android build scripts follow Kotlin DSL syntax.
- No code-generation tools are declared in `pubspec.yaml` (no `build_runner` entries). If adding codegen, update `pubspec.yaml` and document commands here.

Integration points & external dependencies
- `google_fonts` is used (declared in `pubspec.yaml`) — font loading happens via Flutter at runtime.
- Native plugins follow standard Flutter plugin structure; platform implementations live under each platform folder.

When editing or adding features
- Start from `lib/main.dart` to understand app bootstrap and routing.
- Add new UI under `lib/app/feature_name/` and register assets in `pubspec.yaml`.
- If you modify Android native config, prefer editing `android/app/build.gradle.kts` and test with `.
  \gradlew.bat assembleDebug` on Windows.

Examples (copyable)
- Install deps and run on default device:
  - `flutter pub get`
  - `flutter run`
- Build Android APK on Windows:
  - `flutter build apk`
  - or: `cd android; .\gradlew.bat assembleRelease`
- Run tests:
  - `flutter test`

Notes and gotchas
- iOS/macOS builds require a macOS build host (Xcode).
- The project targets Dart SDK `>=3.2.3 <4.0.0` (check `pubspec.yaml`); ensure test/dev environments match.
- Keep edits to Kotlin DSL Gradle files minimal unless you know Gradle Kotlin syntax — small mistakes can block CI/native builds.

If anything here is unclear or you want this file extended (CI steps, PR checklist, codegen tasks), tell me what to add and I will update it.
