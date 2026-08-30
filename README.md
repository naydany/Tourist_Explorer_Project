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

Organised by layer rather than by feature: the app has a single domain
(destinations), so a feature split would add nesting without separating
anything.

```
lib/
  main.dart                     entry point only
  core/
    app.dart                    root widget: theme + routing
    constants/                  app-wide constants
    router/app_router.dart      named routes
    theme/app_theme.dart        light/dark ColorScheme + component themes
  models/                       data classes + JSON parsing
  datasources/                  where data comes from (bundled asset, API)
  repositories/                 chooses a datasource, exposes queries
  providers/                    state shared across screens
  views/                        screens
  widgets/                      widgets reused across screens
assets/data/db.json             seed catalogue
test/                           mirrors lib/ structure
```

Add a screen by creating it under `lib/views/`, then registering a route in
`AppRoutes` + `AppRouter.routes`.

## Checks

```bash
flutter analyze          # static analysis (strict; see analysis_options.yaml)
dart format --set-exit-if-changed lib test
flutter test
```
