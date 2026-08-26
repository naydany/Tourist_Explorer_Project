# Tourist Explorer

Flutter app for discovering and planning visits to places worth the trip.

## Requirements

- Flutter 3.44.4 (stable), Dart 3.12.2
- Android Studio / Xcode toolchains for the platforms you target

## Getting started

```bash
flutter pub get
flutter run
```

## Project layout

```
lib/
  main.dart                     entry point only
  app/app.dart                  root widget: theme + routing
  core/
    constants/                  app-wide constants
    router/app_router.dart      named routes
    theme/app_theme.dart        light/dark ColorScheme + component themes
  features/<feature>/
    data/                       models, API clients, repositories
    presentation/               screens and feature widgets
  shared/widgets/               widgets reused across features
test/                           mirrors lib/ structure
```

Add a screen by creating it under `lib/features/<feature>/presentation/`,
then registering a route in `AppRoutes` + `AppRouter.routes`.

## Checks

```bash
flutter analyze          # static analysis (strict; see analysis_options.yaml)
dart format --set-exit-if-changed lib test
flutter test
```
