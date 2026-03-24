# Home Office Tracker

---

🇫🇷 [Version française](#version-française) | 🇬🇧 [English version](#english-version)

---

## Version française

Application mobile de suivi des jours de télétravail et de vérification de conformité aux accords de sécurité sociale applicables aux travailleurs frontaliers.

### Avertissement important

> **⚠ Cette application est un outil d'aide personnelle. Elle ne constitue en aucun cas un conseil juridique, fiscal ou administratif.**

#### Usage et responsabilité

Cette application est conçue pour un **usage strictement personnel**. Elle fonctionne **entièrement en local**, sans connexion internet, sans collecte de données et sans envoi d'information vers un quelconque serveur externe. Toutes les données restent sur l'appareil de l'utilisateur.

**Les règles de calcul implémentées dans cette application (quota de 40 %, règle des 45 jours, logique d'imputation des catégories, etc.) représentent l'interprétation personnelle de l'auteur** des textes et accords applicables. Ces interprétations peuvent être incomplètes, inexactes ou ne pas refléter la position officielle des administrations compétentes.

Il appartient à chaque utilisateur de :

- **Vérifier les règles de calcul** auprès des organismes compétents (CPAM, CLEISS, caisse de retraite, employeur, expert-comptable, etc.) avant de prendre toute décision basée sur les résultats affichés.
- **S'assurer que les accords bilatéraux de référence sont toujours en vigueur** et n'ont pas été modifiés, complétés ou remplacés depuis la mise à jour de cette application. Les accords de sécurité sociale entre États peuvent évoluer à tout moment.
- **Ne pas se fier exclusivement aux résultats de cette application** pour justifier sa situation auprès d'un employeur, d'une administration ou d'un organisme de sécurité sociale.

**L'auteur de cette application décline toute responsabilité** en cas d'erreur de calcul, d'interprétation erronée des règles, de modification des accords non répercutée dans l'application, ou de toute conséquence (administrative, financière, sociale) découlant de l'utilisation des résultats produits. Chaque utilisateur est seul responsable de l'usage qu'il fait de cet outil et des décisions qu'il en tire.

### Présentation

L'application permet de :

- Saisir et visualiser les jours de travail par catégorie (bureau, télétravail, déplacement, congé, etc.) sur un calendrier mensuel
- Calculer en temps réel la conformité au **quota de 40 %** de jours hors du pays d'emploi
- Intégrer la logique de l'**échange de 45 jours** issu de l'accord de 2005
- Générer un **rapport PDF trilingue** (FR / EN / DE) exportable via le partage Android
- Gérer plusieurs utilisateurs sur le même appareil

### Fonctionnement hors ligne

L'application ne nécessite **aucune connexion internet** à aucun moment. Toutes les données sont stockées localement dans le répertoire privé de l'application sur l'appareil. Aucune donnée n'est synchronisée, partagée ou transmise.

### Installation

#### Prérequis

- [Flutter SDK](https://docs.flutter.dev/get-started/install/windows) installé et dans le PATH
- Android Studio (SDK Android + émulateur) ou un téléphone Android avec le débogage USB activé

#### Première installation

```bash
# 1 — Se placer dans le dossier souhaité
cd path\to\your\folder

# 2 — Créer le projet Flutter
flutter create home_office_android --org com.yourname --project-name home_office_tracker

# 3 — Remplacer lib/ et pubspec.yaml par les fichiers de ce dépôt

# 4 — Installer les dépendances
cd home_office_android
flutter pub get

# 5 — Lancer l'application
flutter run
```

> `flutter devices` pour lister les appareils disponibles.

#### Générer un APK (installation directe sur téléphone)

```bash
flutter build apk --release
```

APK produit dans :
```
build/app/outputs/flutter-apk/app-release.apk
```

Transférer sur le téléphone et installer (activer « Sources inconnues » dans les paramètres Android).

### Structure du projet

```
lib/
├── main.dart                        # Point d'entrée + thème
├── constants.dart                   # Codes catégories, seuils, couleurs
├── models/
│   └── compliance_result.dart       # Modèle de résultat de conformité
├── services/
│   ├── data_store.dart              # Persistance JSON par utilisateur
│   ├── user_manager.dart            # Gestion de la liste d'utilisateurs
│   ├── compliance_engine.dart       # Logique quota 40 % + échange 45 jours
│   └── pdf_export.dart              # Génération PDF (package printing)
├── screens/
│   ├── home_screen.dart             # Scaffold principal, AppBar, navigation
│   ├── calendar_screen.dart         # Onglet calendrier mensuel
│   └── summary_screen.dart          # Onglet statistiques de conformité
└── widgets/
    ├── calendar_grid.dart           # Grille 7×6 jours
    └── category_picker_sheet.dart   # Sélecteur de catégorie (bottom sheet)
```

### Données

Stockées dans le répertoire privé de l'application (aucune permission de stockage externe requise) :

- `home_office_users.json` — liste des utilisateurs
- `home_office_<nom>.json` — données de jours par utilisateur

### Fonctionnalités

| Fonctionnalité | Détail |
|---|---|
| Calendrier | Grille mensuelle, tap sur un jour ouvré pour assigner une catégorie, glisser à droite pour effacer |
| Navigation | Flèches de navigation mensuelle + sélecteurs mois/année |
| Sélecteur d'année | Tap sur l'année dans l'AppBar |
| Conformité | Calcul temps réel quota 40 % + règle échange 45 jours (accord 2005) |
| Onglet récapitulatif | Bandeau de statut, barre de progression, décomptes par catégorie, détail d'imputation |
| Multi-utilisateur | Ajout / changement / suppression d'utilisateurs via l'icône 👤 |
| Export PDF | Rapport annuel trilingue (FR/EN/DE) partagé via le partage Android |
| Thème | Bascule clair / sombre |

---

## English version

Mobile application for tracking remote work days and checking compliance with social security agreements applicable to cross-border workers.

### Important disclaimer

> **⚠ This application is a personal assistance tool only. It does not constitute legal, tax, or administrative advice of any kind.**

#### Usage and liability

This application is designed for **strictly personal use**. It runs **entirely offline**, with no internet connection required, no data collection, and no transmission of any information to any external server. All data remains on the user's device.

**The calculation rules implemented in this application (40% quota, 45-day rule, category imputation logic, etc.) reflect the author's personal interpretation** of the applicable texts and agreements. These interpretations may be incomplete, inaccurate, or may not reflect the official position of the relevant authorities.

Each user is responsible for:

- **Verifying the calculation rules** with the competent bodies (social security funds, employer, accountant, relevant national authorities, etc.) before making any decision based on the results displayed by this application.
- **Confirming that the bilateral agreements used as a reference are still in force** and have not been amended, supplemented, or replaced since this application was last updated. Social security agreements between states can change at any time.
- **Not relying solely on the results of this application** to justify their situation to an employer, a public authority, or a social security body.

**The author of this application accepts no liability** for any calculation error, misinterpretation of the rules, unincorporated changes to applicable agreements, or any consequence (administrative, financial, social) arising from the use of the results produced. Each user is solely responsible for how they use this tool and for any decisions they make based on it.

### Overview

The application allows you to:

- Enter and visualise working days by category (office, remote work, travel, leave, etc.) on a monthly calendar
- Calculate real-time compliance with the **40% quota** of days worked outside the country of employment
- Apply the **45-day exchange rule** from the 2005 agreement
- Generate a **trilingual PDF report** (FR / EN / DE) shared via the Android share sheet
- Manage multiple users on the same device

### Offline operation

The application requires **no internet connection** at any time. All data is stored locally in the application's private directory on the device. No data is synchronised, shared, or transmitted.

### Installation

#### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install/windows) installed and in your PATH
- Android Studio (Android SDK + emulator) or a physical Android device with USB debugging enabled

#### First-time setup

```bash
# 1 — Navigate to your target folder
cd path\to\your\folder

# 2 — Create the Flutter project
flutter create home_office_android --org com.yourname --project-name home_office_tracker

# 3 — Replace lib/ and pubspec.yaml with the files from this repository

# 4 — Install dependencies
cd home_office_android
flutter pub get

# 5 — Run the application
flutter run
```

> Use `flutter devices` to list available devices.

#### Build a release APK (direct install on phone)

```bash
flutter build apk --release
```

APK location:
```
build/app/outputs/flutter-apk/app-release.apk
```

Transfer to your phone and install (enable "Install from unknown sources" in Android settings).

### Project structure

```
lib/
├── main.dart                        # App entry point + theme
├── constants.dart                   # Category codes, thresholds, colours
├── models/
│   └── compliance_result.dart       # Compliance result data class
├── services/
│   ├── data_store.dart              # Per-user JSON persistence
│   ├── user_manager.dart            # User list management
│   ├── compliance_engine.dart       # 40% quota + 45-day exchange logic
│   └── pdf_export.dart              # PDF generation (printing package)
├── screens/
│   ├── home_screen.dart             # Main scaffold, AppBar, bottom nav
│   ├── calendar_screen.dart         # Monthly calendar tab
│   └── summary_screen.dart          # Compliance stats tab
└── widgets/
    ├── calendar_grid.dart           # 7×6 day grid widget
    └── category_picker_sheet.dart   # Category picker bottom sheet
```

### Data files

Stored in the app's private documents directory (no external storage permission required):

- `home_office_users.json` — user list
- `home_office_<name>.json` — per-user day data

### Features

| Feature | Details |
|---|---|
| Calendar | Monthly grid — tap a weekday to assign a category, swipe right to clear |
| Navigation | Month navigation arrows + month/year picker dialogs |
| Year selector | Tap the year in the AppBar |
| Compliance | Real-time 40% quota + 45-day exchange rule (2005 agreement) |
| Summary tab | Status banner, progress bar, category counts, imputation breakdown |
| Multi-user | Add / switch / delete users via the 👤 icon in the AppBar |
| PDF export | Full-year trilingual report (FR/EN/DE) shared via Android share sheet |
| Theme | Light / dark mode toggle |
