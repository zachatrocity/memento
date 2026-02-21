![Swell hero](docs/readme-hero.png)

# Swell (Flutter template)

Opinionated-but-simple Flutter starter optimized for quickly shipping client apps.

## What’s included

- **Riverpod** (minimal usage) for state & DI
- **go_router** for navigation
- **Dio** for networking
- **Environments**: `dev` / `stage` / `prod` via `--dart-define`
- Optional **Auth flow** with token persistence (secure storage)
- **API scaffolding** designed to later swap to an OpenAPI-generated client
- A small **vertical slice**:
  - No-auth: Home (list) → Detail → Settings
  - Auth enabled: Login → Home (list) → Detail → Settings (logout)
- Basic Material 3 theming
- GitHub Actions CI: `flutter analyze` + `flutter test`

## Quick start

### Prereqs

- Flutter (stable). This repo targets Flutter **3.41.x** (Dart **3.11**).

### Run (dev)

Dev defaults to a built-in **fake backend** (no real server required).

```bash
flutter pub get
flutter run --dart-define=APP_ENV=dev
```

### Auth vs no-auth mode

By default, this template runs **without authentication**.

Enable auth mode at build time:

```bash
flutter run --dart-define=ENABLE_AUTH=true
```

### Run (stage/prod)

Point at a real backend by overriding `API_BASE_URL`:

```bash
flutter run \
  --dart-define=APP_ENV=stage \
  --dart-define=API_BASE_URL=https://api.stage.example.com
```

## Environments

Environment selection is compile-time:

- `APP_ENV=dev|stage|prod`
- Optional `API_BASE_URL=...` override
- Optional `ENABLE_AUTH=true|false` (default: `false`)

Implementation: `lib/src/config/app_config.dart`.

## Architecture (high level)

- **UI**: feature screens under `lib/src/features/*/presentation`
- **State**: Riverpod providers/controllers near their feature
- **Data**:
  - `lib/src/data/api/*` → Dio configuration + interceptors
  - Feature APIs like `AuthApi` / `ItemsApi` define an interface boundary.

The intent is that when **fjords exposes OpenAPI**, you can replace `DioAuthApi`/`DioItemsApi` with a generated client adapter while keeping:

- controllers/notifiers
- repositories
- UI

## Folder structure

```text
lib/
  main.dart
  src/
    app/                # App widget, router, theme, shell
    config/             # env + app config
    core/               # cross-cutting helpers (errors, logging, storage, widgets)
    data/               # shared data layer (dio, interceptors)
    features/
      auth/
      items/
      settings/
```

## CI

GitHub Actions workflow lives at `.github/workflows/ci.yaml`.

It runs:

- `flutter analyze`
- `flutter test`

## Releasing

See [`docs/releasing.md`](docs/releasing.md) for:

- rolling `dev-latest` APK releases
- tagged `vX.Y.Z` Play Console Internal releases
- required GitHub Actions secrets

## TODOs / future integration points

- OpenAPI generated client wiring + models (fjords)
- Real auth (refresh tokens, session expiry, 401 handling)
- Deep links + universal links
- Push notifications
- Offline caching strategy
- App icon generation (e.g. `flutter_launcher_icons`)
