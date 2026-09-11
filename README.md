# Tourist Explorer

Flutter app for discovering and planning visits to places worth the trip.

Destinations are served by a separate REST API:
**https://github.com/naydany/Turist_Explorer_API**

## Requirements

- Flutter 3.44.4 (stable), Dart 3.12.2
- Android Studio / Xcode toolchains for the platforms you target
- The [Tourist Explorer API](https://github.com/naydany/Turist_Explorer_API)
  running locally on port 8000

## Getting started

**1. Start the API first** — the app has no bundled data and will show an
error state without it. Follow the setup in that repository, then confirm it
answers:

```bash
curl http://127.0.0.1:8000/destinations
```

**2. Run the app:**

```bash
flutter pub get
flutter run
```

### Pointing at a different backend

`lib/core/config/api_config.dart` picks a base URL automatically:

| Target                | Base URL used            |
| --------------------- | ------------------------ |
| Android emulator      | `http://10.0.2.2:8000`   |
| Web, desktop, iOS sim | `http://127.0.0.1:8000`  |

A **physical device** cannot reach either, so pass your machine's LAN address
at build time:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.5:8000
```

That override also targets a deployed backend; it wins over the defaults above.

## Project layout

Organised by layer rather than by feature: the app has a single domain
(destinations), so a feature split would add nesting without separating
anything.

```
lib/
  main.dart                     entry point: builds dependencies, runs the app
  core/
    app.dart                    root widget: theme + routing
    config/api_config.dart      backend base URL + timeouts
    config/map_config.dart      map tile source + camera defaults
    constants/                  app-wide constants
    network/api_client.dart     HTTP, status handling, JSON decoding
    network/api_exception.dart  sealed error types the UI can switch on
    router/app_router.dart      named routes
    theme/app_theme.dart        light/dark ColorScheme + component themes
  models/                       data classes + JSON parsing
  datasources/                  endpoint paths, JSON -> models
  repositories/                 caching, paging, queries over the API
  stores/                       shared state screens listen to (favorites)
  views/                        screens, with a widgets/ folder per feature
test/                           mirrors lib/ structure
```

Data flows one way, each layer knowing only the one below it:

```
Screen -> Repository -> Datasource -> ApiClient -> API
              |             |             |
           caching    paths + JSON   HTTP + errors
```

Favorites take the other path: `FavoritesStore` is a `ChangeNotifier` backed by
`shared_preferences`, so saved places survive a restart and every screen
listening to it rebuilds when one is added or removed.

Add a screen by creating it under `lib/views/`, then registering a route in
`AppRoutes` + `AppRouter.routes`.

## Checks

```bash
dart format --set-exit-if-changed lib test
flutter test             # all 55 tests; needs the API running on :8000
flutter test -x live     # 46 tests; widget + unit only, no backend needed
```

Nine tests in `test/destination_repository_live_test.dart` exercise the real
API and are tagged `live`, so `-x live` skips them. Everything else uses
inline fixtures and fake datasources.
