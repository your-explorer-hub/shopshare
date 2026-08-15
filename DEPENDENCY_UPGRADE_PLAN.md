# Dependency Upgrade Plan: Update Flutter Packages to Latest Compatible Versions

## Context

**User Request:** "Check outdated library dependencies and plan to upgrade to higher possible versions"

**Current State:**
- **Flutter SDK:** 3.41.7 (stable channel)
- **Dart SDK:** 3.11.5
- **Total Dependencies:** 38 direct dependencies (19 production + 19 transitive critical paths)
- **Outdated Packages:** 64 packages with available updates
- **Critical Updates:** Major version upgrades available for Firebase, Google services, UI libraries

**Why This Matters:**
Keeping dependencies up to date provides:
- ✅ **Security patches** - Fix known vulnerabilities
- ✅ **Performance improvements** - Optimized implementations
- ✅ **Bug fixes** - Resolved issues from older versions
- ✅ **New features** - Access to latest APIs
- ✅ **Better compatibility** - Aligned with Flutter SDK updates
- ✅ **Reduced technical debt** - Easier future upgrades

**Expected Outcome:**
- All packages upgraded to latest compatible versions
- Breaking changes addressed with minimal code modifications
- Comprehensive testing to ensure stability
- Documentation of changes for future reference

---

## Critical Dependencies Analysis

### 🔴 HIGH PRIORITY - Major Version Updates (Breaking Changes Expected)

#### 1. **Firebase Ecosystem** (v5.x → v6.x / v4.x → v6.x)

| Package | Current | Latest | Change |
|---------|---------|--------|--------|
| `firebase_core` | 3.15.2 | **4.9.0** | +1 major |
| `firebase_auth` | 5.7.0 | **6.5.1** | +1 major |
| `cloud_firestore` | 5.6.12 | **6.4.1** | +1 major |
| `firebase_analytics` | 11.6.0 | **12.4.1** | +1 major |

**Breaking Changes:**
- Firebase core v4: New initialization patterns, updated platform interfaces
- Auth v6: Revised credential handling, updated error codes
- Firestore v6: Query API changes, updated transaction handling
- Analytics v12: Event naming conventions, parameter limits

**Migration Impact:** MEDIUM-HIGH
- Requires: Firebase initialization updates, auth flow testing, Firestore query updates
- Affected Files: `lib/firebase_options.dart`, `lib/services/*_service.dart`, `lib/repositories/*_repository.dart`
- Testing: Complete authentication flow, all Firestore operations

#### 2. **Google Sign-In** (v6.x → v7.x)

| Package | Current | Latest | Change |
|---------|---------|--------|--------|
| `google_sign_in` | 6.3.0 | **7.2.0** | +1 major |

**Breaking Changes:**
- New OAuth scope handling
- Updated sign-in flow with better error handling
- Platform-specific configuration changes

**Migration Impact:** MEDIUM
- Requires: Sign-in flow updates, scope configuration review
- Affected Files: `lib/services/auth_service.dart`, `lib/providers/auth_provider.dart`

#### 3. **Notifications** (v18.x → v21.x)

| Package | Current | Latest | Change |
|---------|---------|--------|--------|
| `flutter_local_notifications` | 18.0.1 | **21.0.0** | +3 major |

**Breaking Changes:**
- Android 14+ notification permissions
- iOS notification authorization flow changes
- Platform channel API updates

**Migration Impact:** MEDIUM
- Requires: Notification initialization updates, permission handling
- Affected Files: `lib/services/notification_service.dart`

#### 4. **Navigation (GoRouter)** (v13.x → v17.x)

| Package | Current | Latest | Change |
|---------|---------|--------|--------|
| `go_router` | 13.2.5 | **17.2.3** | +4 major |

**Breaking Changes:**
- Route configuration API changes
- Updated redirect logic
- New navigation context requirements

**Migration Impact:** MEDIUM-HIGH
- Requires: Route definitions update, navigation flow testing
- Affected Files: `lib/app.dart`, route configuration

#### 5. **UI Libraries**

| Package | Current | Latest | Change |
|---------|---------|--------|--------|
| `google_fonts` | 6.3.3 | **8.1.0** | +2 major |
| `flutter_lints` | 3.0.2 | **6.0.0** | +3 major |

**Breaking Changes:**
- google_fonts v8: Font loading API changes
- flutter_lints v6: New lint rules, stricter analysis

**Migration Impact:** LOW-MEDIUM
- Requires: Font initialization updates, code style fixes
- Affected Files: `lib/utils/theme.dart`, all source files (linting)

#### 6. **Internationalization**

| Package | Current | Latest | Change |
|---------|---------|--------|--------|
| `intl` | 0.19.0 | **0.20.2** | +0.1 minor (breaking for 0.x) |

**Breaking Changes:**
- Date formatting API changes
- Number formatting updates

**Migration Impact:** LOW
- Requires: Date/time formatting review
- Affected Files: `lib/utils/date_utils.dart`, timeline views

---

### 🟡 MEDIUM PRIORITY - Minor/Patch Updates (Low Risk)

#### Safe to Upgrade (No Breaking Changes)

| Package | Current | Latest | Type |
|---------|---------|--------|------|
| `app_links` | 6.4.1 | 7.1.1 | +1 major (minor changes) |
| `build_runner` | 2.13.1 | 2.15.0 | Patch |
| `cached_network_image` | 3.4.0 | 3.4.1 | Patch |
| `share_plus` | 13.0.0 | 13.1.0 | Patch |
| `speech_to_text` | 7.3.0 | 7.4.0 | Patch |
| `sqflite` | 2.4.2 | 2.4.2+1 | Patch |
| `mockito` | 5.6.4 | 5.7.0 | Patch |

**Migration Impact:** MINIMAL
- No code changes expected
- Update version constraints in pubspec.yaml

---

## Phased Upgrade Strategy

### Phase 1: Safe Updates (Day 1 - 2 hours)

**Packages to Upgrade:**
- All patch/minor version updates (23 packages)
- No breaking changes expected

**Steps:**
1. Update version constraints in `pubspec.yaml`
2. Run `flutter pub get`
3. Run existing test suite: `flutter test`
4. Manual smoke testing of core flows

**Risk:** ⭕ LOW

**Packages:**
```yaml
# Patch/Minor updates
build_runner: ^2.15.0           # 2.13.1 → 2.15.0
cached_network_image: ^3.4.1    # 3.4.0 → 3.4.1
share_plus: ^13.1.0             # 13.0.0 → 13.1.0
speech_to_text: ^7.4.0          # 7.3.0 → 7.4.0
sqflite: ^2.4.2+1               # 2.4.2 → 2.4.2+1
mockito: ^5.7.0                 # 5.6.4 → 5.7.0
# ... (17 more transitive patches)
```

---

### Phase 2: Google Fonts & Lints (Day 2 - 3 hours)

**Packages to Upgrade:**
- `google_fonts: ^8.1.0` (6.3.3 → 8.1.0)
- `flutter_lints: ^6.0.0` (3.0.2 → 6.0.0)

**Migration Tasks:**

**2.1 Google Fonts Update:**
```dart
// BEFORE (v6.x)
import 'package:google_fonts/google_fonts.dart';

final textTheme = GoogleFonts.robotoTextTheme();

// AFTER (v8.x) - No changes needed for basic usage
// API remains backward compatible for common use cases
```

**Testing:**
- Verify all fonts load correctly
- Check text theme consistency across app
- Test font fallbacks

**2.2 Flutter Lints Update:**
```yaml
# pubspec.yaml
include: package:flutter_lints/flutter.yaml

# analysis_options.yaml - Add new rules or suppressions
linter:
  rules:
    # New strict rules in v6.0
    - always_use_package_imports
    - avoid_redundant_argument_values
    - use_super_parameters
```

**Code Fixes Required:**
- Fix lint violations flagged by new rules
- Update import statements if needed
- Add `// ignore` comments for false positives

**Risk:** ⭕ LOW-MEDIUM

---

### Phase 3: Intl & App Links (Day 2-3 - 2 hours)

**Packages to Upgrade:**
- `intl: ^0.20.2` (0.19.0 → 0.20.2)
- `app_links: ^7.1.1` (6.4.1 → 7.1.1)

**Migration Tasks:**

**3.1 Intl Update:**
```dart
// Check date formatting calls
// lib/utils/date_utils.dart
import 'package:intl/intl.dart';

// BEFORE (v0.19)
final formatted = DateFormat.yMMMd().format(date);

// AFTER (v0.20) - Same API, verify behavior
final formatted = DateFormat.yMMMd().format(date);
```

**Testing:**
- Timeline view date formatting
- Item history dates
- Filter date displays

**3.2 App Links Update:**
- Verify deep link handling still works
- Test invite link flows

**Risk:** ⭕ LOW

---

### Phase 4: Firebase Ecosystem (Day 3-4 - 6-8 hours)

**Packages to Upgrade:**
- `firebase_core: ^4.9.0` (3.15.2 → 4.9.0)
- `firebase_auth: ^6.5.1` (5.7.0 → 6.5.1)
- `cloud_firestore: ^6.4.1` (5.6.12 → 6.4.1)
- `firebase_analytics: ^12.4.1` (11.6.0 → 12.4.1)

**Migration Tasks:**

**4.1 Firebase Core Initialization:**
```dart
// lib/main.dart
// BEFORE (v3.x)
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

// AFTER (v4.x) - Updated initialization
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}
// Note: API mostly unchanged, verify firebase_options.dart compatibility
```

**4.2 Firebase Auth Updates:**
```dart
// lib/services/auth_service.dart
// Check credential handling
// BEFORE (v5.x)
final credential = await auth.signInWithCredential(googleCredential);

// AFTER (v6.x) - Verify error codes
try {
  final credential = await auth.signInWithCredential(googleCredential);
} on FirebaseAuthException catch (e) {
  // Updated error codes in v6.x
  switch (e.code) {
    case 'user-not-found':  // Verify code names
    case 'wrong-password':
    // ...
  }
}
```

**4.3 Firestore Query API:**
```dart
// lib/repositories/*_repository.dart
// BEFORE (v5.x)
final query = collection
  .where('field', isEqualTo: value)
  .orderBy('timestamp', descending: true);

// AFTER (v6.x) - API mostly same, verify behavior
final query = collection
  .where('field', isEqualTo: value)
  .orderBy('timestamp', descending: true);
```

**4.4 Firebase Analytics:**
```dart
// lib/services/analytics_service.dart
// BEFORE (v11.x)
await analytics.logEvent(
  name: 'item_added',
  parameters: {'category': category},
);

// AFTER (v12.x) - Verify parameter limits and naming
await analytics.logEvent(
  name: 'item_added',
  parameters: {'category': category},
);
```

**Testing Requirements:**
- ✅ Login flow (email + Google Sign-In)
- ✅ User registration
- ✅ Password reset
- ✅ All Firestore CRUD operations
- ✅ Real-time listeners (shopping lists, items)
- ✅ Analytics event logging
- ✅ Offline persistence (SQLite + Firestore)

**Affected Files:**
- `lib/main.dart`
- `lib/firebase_options.dart`
- `lib/services/auth_service.dart`
- `lib/services/analytics_service.dart`
- `lib/repositories/item_repository.dart`
- `lib/repositories/list_repository.dart`
- `lib/repositories/invite_repository.dart`
- `lib/repositories/member_repository.dart`
- `lib/repositories/user_repository.dart`
- `lib/providers/auth_provider.dart`
- `lib/providers/shopping_provider.dart`

**Risk:** 🟠 MEDIUM-HIGH

---

### Phase 5: Google Sign-In (Day 4 - 2-3 hours)

**Packages to Upgrade:**
- `google_sign_in: ^7.2.0` (6.3.0 → 7.2.0)

**Migration Tasks:**

**5.1 Sign-In Flow Update:**
```dart
// lib/services/auth_service.dart
// BEFORE (v6.x)
final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

// AFTER (v7.x) - Enhanced error handling
try {
  final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
  if (googleUser == null) {
    // User cancelled sign-in
    return null;
  }
  // ... proceed with auth
} catch (error) {
  // Handle specific v7.x error types
  print('Google Sign-In error: $error');
}
```

**5.2 Scope Configuration:**
```dart
// Verify OAuth scopes are still valid
final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: [
    'email',
    'profile',
  ],
);
```

**Testing:**
- Google Sign-In flow (first time)
- Sign-In flow (returning user)
- Sign-Out
- Account switching
- Error scenarios (no network, cancelled)

**Affected Files:**
- `lib/services/auth_service.dart`
- `lib/providers/auth_provider.dart`
- `lib/screens/login_screen.dart`

**Risk:** 🟠 MEDIUM

---

### Phase 6: Notifications (Day 5 - 3-4 hours)

**Packages to Upgrade:**
- `flutter_local_notifications: ^21.0.0` (18.0.1 → 21.0.0)

**Migration Tasks:**

**6.1 Android Notification Updates:**
```dart
// lib/services/notification_service.dart
// BEFORE (v18.x)
const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

// AFTER (v21.x) - Updated for Android 14+
const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

// Android 13+ permission request
if (Platform.isAndroid) {
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();
}
```

**6.2 iOS Notification Updates:**
```dart
// AFTER (v21.x) - Updated authorization
final DarwinInitializationSettings initializationSettingsDarwin =
    DarwinInitializationSettings(
  requestAlertPermission: true,
  requestBadgePermission: true,
  requestSoundPermission: true,
);
```

**Testing:**
- Local notification display
- Notification tap handling
- Permission requests (Android 13+, iOS)
- Background notifications

**Affected Files:**
- `lib/services/notification_service.dart`
- `android/app/src/main/AndroidManifest.xml` (permission updates)

**Risk:** 🟠 MEDIUM

---

### Phase 7: GoRouter Navigation (Day 5-6 - 4-5 hours)

**Packages to Upgrade:**
- `go_router: ^17.2.3` (13.2.5 → 17.2.3)

**Migration Tasks:**

**7.1 Route Configuration Update:**
```dart
// lib/app.dart
// BEFORE (v13.x)
final GoRouter _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    // ...
  ],
  redirect: (context, state) {
    // Redirect logic
  },
);

// AFTER (v17.x) - Updated API
final GoRouter _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    // ...
  ],
  redirect: (BuildContext context, GoRouterState state) {
    // Updated redirect signature
  },
);
```

**7.2 Navigation Context Updates:**
- Verify `context.go()`, `context.push()` calls
- Update route parameter access if changed
- Test deep link navigation

**Testing:**
- All navigation flows
- Deep links (invite links)
- Authentication redirects
- Back button behavior
- Tab navigation

**Affected Files:**
- `lib/app.dart` (route definitions)
- All screens using navigation

**Risk:** 🟠 MEDIUM-HIGH

---

## Complete Updated pubspec.yaml

```yaml
name: shopping_app
description: Shared shopping list app with categories, family sharing, and timeline view.
publish_to: 'none'
version: 1.0.5+9

environment:
  sdk: '>=3.1.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # Firebase & Authentication (Phase 4-5)
  firebase_core: ^4.9.0              # 3.15.2 → 4.9.0 (MAJOR)
  firebase_auth: ^6.5.1              # 5.7.0 → 6.5.1 (MAJOR)
  cloud_firestore: ^6.4.1           # 5.6.12 → 6.4.1 (MAJOR)
  google_sign_in: ^7.2.0            # 6.3.0 → 7.2.0 (MAJOR)
  firebase_analytics: ^12.4.1       # 11.6.0 → 12.4.1 (MAJOR)

  # Local Database (Phase 1)
  sqflite: ^2.4.2+1                 # 2.4.2 → 2.4.2+1 (PATCH)
  sqflite_common_ffi_web: ^1.1.1   # No change
  path: ^1.9.0                      # No change

  # State Management
  provider: ^6.1.2                  # No change

  # UI & Design (Phase 2)
  google_fonts: ^8.1.0              # 6.3.3 → 8.1.0 (MAJOR)
  flutter_animate: ^4.5.0           # No change
  cached_network_image: ^3.4.1     # 3.4.0 → 3.4.1 (PATCH)
  shimmer: ^3.0.0                   # No change

  # Navigation (Phase 7)
  go_router: ^17.2.3                # 13.2.5 → 17.2.3 (MAJOR)

  # Voice input (Phase 1)
  speech_to_text: ^7.4.0           # 7.3.0 → 7.4.0 (PATCH)

  # Utilities
  intl: ^0.20.2                     # 0.19.0 → 0.20.2 (MINOR/BREAKING for 0.x)
  uuid: ^4.4.0                      # No change
  url_launcher: ^6.2.6              # No change
  share_plus: ^13.1.0              # 13.0.0 → 13.1.0 (PATCH)
  shared_preferences: ^2.2.3        # No change
  flutter_local_notifications: ^21.0.0  # 18.0.1 → 21.0.0 (MAJOR)
  in_app_review: ^2.0.9            # No change
  app_links: ^7.1.1                # 6.4.1 → 7.1.1 (MAJOR, minor changes)

  cupertino_icons: ^1.0.8          # No change

dev_dependencies:
  flutter_launcher_icons: ^0.14.3  # No change
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  flutter_lints: ^6.0.0            # 3.0.2 → 6.0.0 (MAJOR)
  mockito: ^5.7.0                  # 5.6.4 → 5.7.0 (PATCH)
  build_runner: ^2.15.0            # 2.13.1 → 2.15.0 (PATCH)

flutter:
  uses-material-design: true

  assets:
    - assets/images/
    - assets/icons/
    - assets/adi-registration.properties
    - assets/web_allowlist.txt

flutter_launcher_icons:
  android: "launcher_icon"
  ios: true
  image_path: "assets/icons/app_icon.png"
  min_sdk_android: 21
  adaptive_icon_background: "#4CAF50"
  adaptive_icon_foreground: "assets/icons/app_icon.png"
  web:
    generate: true
    image_path: "assets/icons/app_icon.png"
    background_color: "#4CAF50"
    theme_color: "#4CAF50"
```

---

## Migration Timeline

| Phase | Duration | Packages | Risk | Can Skip? |
|-------|----------|----------|------|-----------|
| **Phase 1: Safe Updates** | 2 hours | 23 packages | ⭕ LOW | No |
| **Phase 2: Fonts & Lints** | 3 hours | 2 packages | ⭕ LOW-MEDIUM | Optional |
| **Phase 3: Intl & App Links** | 2 hours | 2 packages | ⭕ LOW | Optional |
| **Phase 4: Firebase** | 6-8 hours | 4 packages | 🟠 MEDIUM-HIGH | No |
| **Phase 5: Google Sign-In** | 2-3 hours | 1 package | 🟠 MEDIUM | No |
| **Phase 6: Notifications** | 3-4 hours | 1 package | 🟠 MEDIUM | Optional |
| **Phase 7: GoRouter** | 4-5 hours | 1 package | 🟠 MEDIUM-HIGH | Optional |
| **TOTAL** | **22-27 hours** | **34 packages** | - | **~3-4 days** |

**Minimum Viable Upgrade (Phases 1, 4, 5):** ~12-15 hours (critical security & compatibility)

---

## Testing Strategy

### Automated Testing
```bash
# Run after each phase
flutter test                          # Unit tests
flutter test integration_test/        # Integration tests (if exist)
flutter analyze                       # Static analysis
```

### Manual Testing Checklist

**Phase 1 (After Safe Updates):**
- [ ] App launches successfully
- [ ] No runtime errors in logs
- [ ] All screens load

**Phase 4 (After Firebase):**
- [ ] Login with email/password
- [ ] Login with Google Sign-In
- [ ] User registration
- [ ] Password reset
- [ ] Create shopping list
- [ ] Add items to list
- [ ] Share list (send invite)
- [ ] Join shared list
- [ ] Real-time updates across devices
- [ ] Offline mode → sync when online
- [ ] Timeline view loads

**Phase 5 (After Google Sign-In):**
- [ ] Google Sign-In first time
- [ ] Google Sign-In returning user
- [ ] Sign out
- [ ] Account switching

**Phase 6 (After Notifications):**
- [ ] Local notification displays
- [ ] Notification tap opens correct screen
- [ ] Permission requests work

**Phase 7 (After GoRouter):**
- [ ] All navigation paths work
- [ ] Deep links open correct screens
- [ ] Back button behavior correct
- [ ] Authentication redirects work

---

## Rollback Plan

### Per-Phase Rollback
```bash
# If a phase fails, revert pubspec.yaml changes
git checkout pubspec.yaml
flutter pub get
flutter clean
flutter pub get
```

### Version Pinning (If Issues Found)
```yaml
# Lock to specific working version
firebase_core: 3.15.2  # Remove ^ to pin exact version
```

### Full Rollback
```bash
# Revert all changes
git checkout HEAD~1 pubspec.yaml
git checkout HEAD~1 pubspec.lock
flutter clean
flutter pub get
```

---

## Risk Mitigation

### Backup Before Starting
```bash
# Create backup branch
git checkout -b dependency-upgrade-backup
git checkout main

# Commit current working state
git add .
git commit -m "chore: backup before dependency upgrade"
```

### Incremental Approach
- ✅ Upgrade one phase at a time
- ✅ Test thoroughly after each phase
- ✅ Commit after successful phase
- ✅ Can stop and use partial upgrades

### Known Issues to Watch

**Firebase v4+:**
- Initialization timing issues → Ensure `WidgetsFlutterBinding.ensureInitialized()` called first
- Platform-specific errors → Test on both Android and Web

**GoRouter v17:**
- Context issues in redirect callbacks → Use updated `BuildContext` parameter
- Route parameter access changes → Review query params handling

**Notifications v21:**
- Android 13+ permissions → Add runtime permission requests
- Background notification handling → Test background scenarios

---

## Post-Upgrade Verification

### Sanity Checks
```bash
# 1. Clean build
flutter clean
rm -rf pubspec.lock
flutter pub get

# 2. Check for conflicts
flutter pub outdated

# 3. Build verification
flutter build apk --debug          # Android
flutter build web --release         # Web

# 4. Run all tests
flutter test --coverage

# 5. Static analysis
flutter analyze
```

### Regression Testing
- [ ] All 443 existing tests pass
- [ ] No new analyzer warnings
- [ ] App builds for Android
- [ ] App builds for Web
- [ ] Firebase connections work
- [ ] Authentication flows work
- [ ] Real-time sync works
- [ ] Offline mode works

---

## Documentation Updates

**Files to Update After Upgrade:**
1. `README.md` - Update dependency version table
2. `docs/guides/GETTING_STARTED.md` - Update setup instructions
3. `docs/guides/BUILD_INSTRUCTIONS.md` - Update build requirements
4. `CHANGELOG.md` - Document dependency upgrades

**Example Changelog Entry:**
```markdown
## [1.0.6] - 2026-05-29

### Changed
- **Dependencies:** Major version upgrades
  - Firebase Core: 3.15.2 → 4.9.0
  - Firebase Auth: 5.7.0 → 6.5.1
  - Cloud Firestore: 5.6.12 → 6.4.1
  - Google Sign-In: 6.3.0 → 7.2.0
  - GoRouter: 13.2.5 → 17.2.3
  - Notifications: 18.0.1 → 21.0.0
  - (23 additional minor/patch updates)

### Fixed
- Updated notification permissions for Android 13+
- Improved Firebase error handling
- Enhanced Google Sign-In reliability
```

---

## Success Criteria

| Criterion | Target | Verification |
|-----------|--------|--------------|
| **All tests pass** | 443/443 | `flutter test` |
| **No breaking changes in prod** | Zero runtime errors | Manual testing |
| **Build succeeds** | Android + Web | `flutter build` |
| **Firebase works** | All CRUD ops | Integration testing |
| **Auth works** | Email + Google | Login flows |
| **Performance maintained** | No regressions | App profiling |
| **Code analysis clean** | Zero errors/warnings | `flutter analyze` |

---

## Conclusion

This phased upgrade plan systematically updates 34 packages (19 direct dependencies + critical transitive) to their latest versions. The approach prioritizes safety through:

1. **Incremental phases** - Test after each phase
2. **Risk-based ordering** - Low-risk updates first, high-risk later
3. **Comprehensive testing** - Automated + manual verification
4. **Easy rollback** - Git-based revert strategy
5. **Clear documentation** - Migration guides for each breaking change

**Recommended Approach:**
- **Minimum:** Execute Phases 1, 4, 5 (critical security & compatibility) - 12-15 hours
- **Full Upgrade:** Execute all phases - 22-27 hours over 3-4 days
- **Optional Skips:** Phases 3, 6, 7 can be deferred if time-constrained

**Estimated Effort:** 3-4 days (full upgrade) | 2 days (minimum viable)
**Risk Level:** MEDIUM (mitigated by phased approach and comprehensive testing)
**Priority:** HIGH (security patches, long-term maintainability)
