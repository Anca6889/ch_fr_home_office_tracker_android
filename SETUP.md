# Setup — Home Office Tracking (Android)

## Prerequisites

1. **Install Flutter SDK** — https://docs.flutter.dev/get-started/install/windows
   - Add Flutter to your PATH
   - Run `flutter doctor` and fix any issues

2. **Install Android Studio** (for the Android SDK and an emulator)
   - Or connect a real Android phone with USB debugging enabled

---

## First-time setup

```bash
# 1 — Go to the folder where you want to create the project
cd path\to\your\folder

# 2 — Create a new Flutter project in this folder
flutter create home_office_android --org com.yourname --project-name home_office_tracker

# 3 — Replace the generated lib/ and pubspec.yaml with the provided files
#     (the files in this folder already contain the full source code)
#     The flutter create command will NOT overwrite existing files, so:
#     - If lib/main.dart was overwritten, copy it back from this folder

# 4 — Install dependencies
cd home_office_android
flutter pub get

# 5 — Run on a connected device or emulator
flutter run
```

> **Tip:** To list available devices: `flutter devices`

---

## Build a release APK

```bash
flutter build apk --release
```

The APK will be at:
```
build/app/outputs/flutter-apk/app-release.apk
```

Transfer it to your phone and install it (enable "Install from unknown sources" in Android settings).

---

## Project structure

```
lib/
├── main.dart                        # App entry point + theme
├── constants.dart                   # Category codes, thresholds, theme colours
├── models/
│   └── compliance_result.dart       # Result data class
├── services/
│   ├── data_store.dart              # Per-user JSON persistence
│   ├── user_manager.dart            # User list management
│   ├── compliance_engine.dart       # 40% quota + 45-day exchange logic
│   └── pdf_export.dart             # PDF generation (via printing package)
├── screens/
│   ├── home_screen.dart             # Main scaffold, AppBar, bottom nav
│   ├── calendar_screen.dart         # Monthly calendar tab
│   └── summary_screen.dart          # Compliance stats tab
└── widgets/
    ├── calendar_grid.dart           # 7×6 day grid widget
    └── category_picker_sheet.dart   # Bottom sheet for day assignment
```

---

## Data files

Stored in the app's private documents directory (no storage permissions needed):

- `home_office_users.json` — user list
- `home_office_<name>.json` — per-user day data

**Same JSON format as the desktop app** — you can copy data files between desktop and Android.

---

## Features

| Feature | Details |
|---|---|
| Calendar | Monthly grid, tap weekday to assign category, right-swipe to clear |
| Navigation | Month navigation arrows + month/year picker dialogs |
| Year selector | Tap the year in the AppBar to switch |
| Compliance | Real-time 40% quota + 45-day 2005 exchange check |
| Summary tab | Status banner, progress bar, category counts, imputation details |
| Multi-user | Add/switch/delete users via the 👤 icon in the AppBar |
| PDF export | Full-year report shared via Android share sheet (no storage permission needed) |
