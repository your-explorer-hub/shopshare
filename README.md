# ShopShare — Collaborative Shopping List App

A Flutter Android app that lets households share a real-time shopping list powered by Firebase. Family members can add items, check them off, and invite others — all synced instantly.

---

## ⚠️ Setup Required Before Running

This app requires Firebase configuration files that are **not** included in version control for security.

### 1. Firebase Configuration

**For Android:**
1. Download `google-services.json` from [Firebase Console](https://console.firebase.google.com)
2. Place it at `android/app/google-services.json`
3. See `android/app/google-services.json.template` for structure

**For all platforms:**
1. Copy `lib/firebase_options.dart.template` to `lib/firebase_options.dart`
2. Fill in your Firebase project values from Firebase Console > Project Settings
3. Or run `flutterfire configure` to auto-generate

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Run the App

```bash
flutter run
```

The app will fail to build without proper Firebase configuration files.

---

## Features

| Feature | Details |
|---|---|
| 🔐 Authentication | Google Sign-In + email/password via Firebase Auth |
| 🛒 Shared list | Real-time Firestore sync across all household members |
| 📦 Item management | Add items with name, category, quantity, unit and notes |
| ✅ Check-off | Mark items complete; filter by pending/completed |
| 🏷️ Categories | Grocery, Produce, Dairy, Bakery, Meat, Frozen, Beverages, Snacks, Electronics, Household, Personal Care, Other |
| 👥 Invite members | Invite by email or share the list ID |
| 👤 Profile | Edit display name, view stats, copy list ID |
| ⚙️ Settings | Light/dark theme toggle, notification preferences, sign-out |
| 💾 Offline cache | SQLite (`sqflite`) local cache — works without network |
| 🎨 Material 3 | Purple/teal accent palette, adaptive light & dark themes |

---

## Project Structure

```
lib/
├── main.dart                  # Entry point — Firebase init + ProviderScope
├── app.dart                   # GoRouter config + MaterialApp
├── firebase_options.dart      # Firebase platform configs (replace with real values)
├── theme/
│   └── app_theme.dart         # Material 3 ThemeData (light + dark)
├── models/
│   ├── shopping_item.dart     # ShoppingItem entity + copyWith + Firestore/SQLite maps
│   ├── member.dart            # Member entity (household members)
│   └── user_profile.dart      # UserProfile entity
├── providers/
│   ├── auth_provider.dart     # AuthProvider (ChangeNotifier) — sign-in/out, profile
│   └── shopping_provider.dart # ShoppingProvider — items, members, filtering
├── services/
│   ├── auth_service.dart      # Firebase Auth wrapper
│   ├── firestore_service.dart # Firestore CRUD
│   └── invite_service.dart    # Invitation logic
├── database/
│   └── app_database.dart      # SQLite schema & queries
├── screens/
│   ├── splash_screen.dart     # Auth-state routing
│   ├── login_screen.dart      # Sign-in UI
│   ├── home_screen.dart       # Item list with date groups + filters
│   ├── add_item_screen.dart   # Add-item form
│   ├── invite_screen.dart     # Invite by email + list ID share
│   ├── profile_screen.dart    # User profile & stats
│   └── settings_screen.dart   # App settings
├── widgets/
│   ├── item_card_widget.dart
│   ├── category_chip_widget.dart
│   └── profile_menu_widget.dart
└── utils/
    └── constants.dart         # ItemCategory, AppConstants, Validators
```

---

## Firebase Setup (required before the app connects to Firebase)

1. **Create a Firebase project** at [console.firebase.google.com](https://console.firebase.google.com)

2. **Register an Android app** with package name `com.shopshare.app`

3. **Download `google-services.json`** from *Project Settings → Your apps* and replace  
   `android/app/google-services.json` with the downloaded file

4. **Enable Authentication** methods:
   - Email/Password
   - Google Sign-In

5. **Create a Firestore database** in Native mode (any region)

6. **Add Firestore Security Rules** (starter rules):
   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /lists/{listId}/{document=**} {
         allow read, write: if request.auth != null;
       }
       match /users/{userId} {
         allow read, write: if request.auth.uid == userId;
       }
     }
   }
   ```

7. **Replace placeholder values** in `lib/firebase_options.dart` with the real SDK config  
   (or run `flutterfire configure` to auto-generate this file)

---

## Build & Run

### Prerequisites

| Tool | Minimum version |
|---|---|
| Flutter SDK | 3.19.0+ |
| Dart | 3.3.0+ |
| Android Studio / SDK | API 21+ (Android 5.0) |
| Java | 11+ |

### Run in development

```bash
flutter pub get
flutter run
```

### Build a release APK (sideload on Android phone)

```bash
flutter build apk --release
```

The APK is output to:
```
build/app/outputs/flutter-apk/app-release.apk
```

Install directly on a device (with USB debugging or via file transfer):
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

Or transfer the APK file to the Android device and open it (requires *Install unknown apps* permission enabled in Settings).

### Build an Android App Bundle (for Google Play)

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

---

## Signing (for production / Play Store)

The current release build uses the **debug keystore** (`~/.android/debug.keystore`), which is fine for testing/sideloading but **not** accepted by the Play Store.

To set up a production keystore:

1. Generate a keystore:
   ```bash
   keytool -genkey -v -keystore android/app/shopshare-release.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias shopshare
   ```

2. Create `android/key.properties`:
   ```properties
   storePassword=<your-store-password>
   keyPassword=<your-key-password>
   keyAlias=shopshare
   storeFile=shopshare-release.jks
   ```

3. Update `android/app/build.gradle` to reference `key.properties` in the `signingConfigs` block.

> ⚠️ Never commit `key.properties` or `*.jks` to version control.

---

## Running Tests

```bash
flutter test
```

Tests cover:
- `test/models/` — `ShoppingItem`, `Member`, `UserProfile` entity tests
- `test/providers/shopping_provider_test.dart` — filtering/counting logic (no Firebase deps)
- `test/utils/constants_test.dart` — `AppConstants`, `Validators`, `ItemCategory`

---

## Android Build Configuration

| Setting | Value |
|---|---|
| Package name | `com.shopshare.app` |
| Min SDK | 21 (Android 5.0 Lollipop) |
| Target / Compile SDK | Flutter default (36) |
| AGP | 8.9.1 |
| Gradle | 8.11.1 |
| Kotlin | 2.1.0 |
| Java compatibility | 11 |
| Core library desugaring | Enabled |
| Multidex | Enabled |
| ProGuard / R8 | Enabled in release builds |

---

## Dependencies

### Runtime
| Package | Purpose |
|---|---|
| `firebase_core` | Firebase initialisation |
| `firebase_auth` | Authentication |
| `cloud_firestore` | Real-time database |
| `google_sign_in` | Google OAuth |
| `provider` | State management |
| `go_router` | Navigation |
| `sqflite` | Local SQLite cache |
| `shared_preferences` | Lightweight key-value store |
| `flutter_local_notifications` | Push notifications |
| `share_plus` | Share list ID / invite links |
| `intl` | Date/number formatting |
| `uuid` | Unique ID generation |

### Dev / Test
| Package | Purpose |
|---|---|
| `flutter_test` | Widget + unit testing |
| `mockito` | Mock objects |
| `build_runner` | Code generation |

---

## Changelog

### v1.0.0 (initial)
- Full CRUD shopping list with real-time Firestore sync
- Google Sign-In + email/password authentication
- Category chips, quantity+unit fields, item notes
- Offline SQLite cache
- Invite by email + shareable list ID
- Profile screen with stats
- Light/dark Material 3 theme
- Unit tests for all models, providers, and utilities
- Android build upgraded to AGP 8.9.1 / Gradle 8.11.1 / Kotlin 2.1.0
- AndroidX + core library desugaring enabled