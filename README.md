# Aften Status (Evening Status)

A Flutter app for daily evening check-ins with customizable tracking fields. Track your mood, energy, symptoms, and more with personalized metrics that sync to Google Drive.

## App Icon

The app icon source is `icon.png` in the project root. To regenerate iOS icons after modifying it:

```bash
dart run flutter_launcher_icons
```

This uses the `flutter_launcher_icons` package configured in `pubspec.yaml`.

## Features

- **Customizable Fields**: Create and manage your own tracking fields (sliders, toggles, text)
- **Daily Check-ins**: Quick evening status entries with intuitive UI
- **Visual Analytics**: Interactive line chart showing trends over time (up to 20 entries)
- **Google Drive Sync**: Automatic backup and sync across devices
- **Multi-language**: English and Danish localization
- **Field Legend**: Toggle visibility of individual fields in the graph view
- **Dark/Light Theme**: Follows system theme preferences

## Screenshots

The app includes:
- Home page with entry list and score bar charts
- Add/Edit entry page with dynamic field widgets
- Graph page with interactive line charts (landscape mode)
- Settings page for field management and data sync

## Tech Stack

- **Framework**: Flutter
- **State Management**: ChangeNotifier-based controllers
- **DI & Routing**: flutter_modular
- **Local Storage**: Hive with type adapters
- **Cloud Sync**: Google Drive API (googleapis, google_sign_in)
- **Charts**: fl_chart
- **Localization**: Flutter ARB-based l10n

## Getting Started

### Prerequisites

- Flutter SDK (3.0+)
- iOS 12.0+ / Android 5.0+
- Google Cloud project with Drive API enabled (for sync features)

### Installation

1. Clone the repository
2. Copy secret template files and add your credentials:
   - `lib/shared/services/google_drive/desktop_oauth_config.dart.template`
   - `lib/shared/services/google_drive/mobile_google_auth_service.dart.template`
3. Run:
   ```bash
   flutter pub get
   flutter gen-l10n
   flutter run
   ```

### Building

```bash
# iOS (debug, no signing)
flutter build ios --no-codesign --debug

# Regenerate Hive adapters
dart run build_runner build --delete-conflicting-outputs

# Regenerate localizations
flutter gen-l10n
```

## Project Structure

```
lib/
├── main.dart              # App entry point
├── app_module.dart        # Flutter Modular bindings and routes
├── models/                # Data models with Hive adapters
├── services/              # Business logic and controllers
├── pages/                 # UI pages and widgets
├── shared/                # Shared infrastructure (Google Drive, utils)
└── l10n/                  # Localization files (EN, DA)
```

## Debug Features

In debug mode, additional buttons are available in Settings:
- **Generate 20 Sample Entries**: Create random test data
- **Clear All Backups**: Remove all Google Drive backup files

## License

This project is private and not licensed for public use.
