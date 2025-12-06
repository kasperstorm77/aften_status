# Copilot Instructions for Aften Status

## Project Overview

Aften Status (Evening Status) is a Flutter app for daily evening check-ins with customizable fields. It syncs data to Google Drive and supports iOS as the primary platform.

## Technology Stack

- **Framework:** Flutter with `flutter_modular` for DI and routing
- **Local Storage:** Hive with generated type adapters
- **Cloud Sync:** Google Drive API via `googleapis` and `google_sign_in`
- **Localization:** Flutter's ARB-based l10n (English + Danish)
- **State Management:** ChangeNotifier-based controllers

## Project Structure

```
lib/
├── main.dart              # App entry point
├── app_module.dart        # Flutter Modular bindings and routes
├── models/                # Data models with Hive adapters
│   ├── evening_status.dart
│   ├── field_definition.dart
│   └── app_settings.dart
├── services/              # Business logic and controllers
│   ├── storage_service.dart
│   ├── settings_service.dart
│   ├── field_definition_service.dart
│   ├── evening_status_drive_service.dart
│   ├── home_controller.dart
│   ├── add_entry_controller.dart
│   └── settings_controller.dart
├── pages/                 # UI pages
│   ├── home_page.dart
│   ├── add_entry_page.dart
│   ├── settings_page.dart
│   ├── google_drive_sync_page.dart
│   └── widgets/           # Reusable UI components
├── shared/                # Shared infrastructure
│   ├── services/google_drive/  # Google Drive API services
│   └── utils/             # Platform helpers
└── l10n/                  # Localization files
    ├── app_en.arb         # English strings (source)
    ├── app_da.arb         # Danish strings
    └── app_localizations*.dart  # Generated
```

## Key Patterns

### Dependency Injection
Use `Modular.get<T>()` to retrieve services:
```dart
final storage = Modular.get<StorageService>();
final controller = Modular.get<HomeController>();
```

### Hive Models
Models use `@HiveType` and `@HiveField` annotations:
```dart
@HiveType(typeId: 0)
class EveningStatus extends HiveObject {
  @HiveField(0)
  late String id;
  // ...
}
```

After modifying models, regenerate adapters:
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Localization
Add strings to both `.arb` files, then regenerate:
```bash
flutter gen-l10n
```

Use in code:
```dart
final l10n = AppLocalizations.of(context)!;
Text(l10n.appTitle);
```

### Google Drive Sync
- `EveningStatusDriveService` - App-specific sync logic (singleton)
- `MobileDriveService` - iOS/Android authentication
- `WindowsDriveServiceWrapper` - Desktop authentication
- `GoogleDriveCrudClient` - CRUD operations on Drive files

## Important Files

| File | Purpose |
|------|---------|
| `app_module.dart` | All service registrations and routes |
| `storage_service.dart` | Hive initialization and adapter registration |
| `evening_status_drive_service.dart` | Google Drive sync for entries |
| `mobile_google_auth_service.dart` | iOS OAuth client ID (SECRET) |
| `desktop_oauth_config.dart` | Desktop OAuth credentials (SECRET) |

## Secrets (Gitignored)

These files contain secrets and must NOT be committed:
- `docs/local_setup_aften_ritual.md` - All credentials and setup instructions
- `lib/shared/services/google_drive/desktop_oauth_config.dart`
- `lib/shared/services/google_drive/mobile_google_auth_service.dart`
- `ios/Runner/Info.plist` - Contains OAuth client ID

Templates exist for secret files (`.template` suffix).

## Common Commands

```bash
# Run on connected device
flutter run

# Build iOS (debug, no signing)
flutter build ios --no-codesign --debug

# Analyze code
flutter analyze

# Regenerate Hive adapters
dart run build_runner build --delete-conflicting-outputs

# Regenerate localizations
flutter gen-l10n

# Regenerate iOS platform folder
flutter create --platforms=ios .
```

## iOS Configuration

- **Bundle ID:** `dk.stormstyrken.aften-status`
- **Team ID:** `MHFZJT5QM4`
- **Minimum iOS:** 12.0

---

## ⚠️ CRITICAL RULES

### 1. NO GIT OPERATIONS WITHOUT EXPLICIT PERMISSION
**NEVER** perform any git operations (commit, push, pull, branch, merge, etc.) unless the user explicitly asks for it. This includes:
- `git add`
- `git commit`
- `git push`
- `git pull`
- `git checkout`
- `git branch`
- `git merge`
- `git rebase`
- Any other git command

### 2. Protect Secrets
Never output or display contents of secret files. Always use templates for examples.

### 3. Hive Adapter Order
Register adapters in `StorageService.init()` before opening boxes. Order matters - register `FieldTypeAdapter` before `FieldDefinitionAdapter`.

### 4. Singleton Services
`EveningStatusDriveService` uses singleton pattern - access via `.instance`, not constructor.

### 5. Localization
Always add strings to BOTH `app_en.arb` and `app_da.arb` when adding new UI text.
