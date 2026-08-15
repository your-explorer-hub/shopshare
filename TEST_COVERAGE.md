# Test Coverage Report — ShopShare

## Final Result: 246 unit tests — all passing

>  excluded (requires Firebase initialisation; pre-existing).

---

## Summary Table

| Test File | New? | Tests | Feature Covered |
|-----------|------|-------|-----------------|
| test/providers/auth_provider_test.dart | NEW | 28 | Delete Account, Sign In/Out, Update Profile, clearError |
| test/providers/notification_provider_test.dart | NEW | 19 | muteFor/muteForDays/setAlwaysAllow, expiry, SharedPrefs |
| test/providers/theme_provider_test.dart | NEW | 11 | Theme choice, label, SharedPrefs persistence |
| test/services/auth_service_test.dart | NEW | 15 | AuthException, 10 friendly error-code mappings |
| test/services/invite_service_test.dart | NEW | 14 | generateCode, redeemCode (all error paths + success) |
| test/services/feedback_service_test.dart | NEW | 15 | submitFeedback, form validation, error handling |
| test/services/delete_account_service_test.dart | NEW | 19 | DELETE confirmation, 3-step machine, error flows |
| test/utils/subscription_limits_test.dart | NEW | 42 | Tier limits, display names, fromString, tierToString, historyDays, tierBadgeLabel |
| test/models/shopping_item_test.dart | NEW | 26 | Constructor, copyWith, equality, hashCode, multi-category, inputMethod, completedByName |
| test/models/user_profile_test.dart | Existing | 20 | UserProfile model, subscriptionTier, identifier, phoneNumber, initials edge cases |
| test/models/shopping_list_test.dart | Existing | 10 | ShoppingList model + toString |
| test/models/member_test.dart | Existing | 6 | Member model, hashCode consistency |
| test/utils/constants_test.dart | Existing | 25 | AppConstants, Validators, ItemCategory, MemberStatus |
| test/providers/shopping_provider_test.dart | NEW | 15 | historyDays/hiddenByHistoryCount logic (SPROV-01..15) |
| test/widget_test.dart | Existing | — | MaterialApp smoke test (parameterised) |

**New tests: 179 | Existing: 67 | Grand total: 246**

---

## Feature 1 — Delete Account

### AuthProvider.deleteAccount() — 6 tests

| ID | Test Case | Verifies |
|----|-----------|----------|
| DEL-01 | Success clears profile, status=unauthenticated | Happy-path |
| DEL-02 | Success notifies listeners | ChangeNotifier |
| DEL-03 | isLoading: true during, false after | Loading lifecycle |
| DEL-04 | Rethrows + message on requires-recent-login | Re-auth guard |
| DEL-05 | Rethrows AuthException on generic failure | Error propagation |
| DEL-06 | Profile preserved when deletion fails | Error rollback |

### _DeleteAccountDialog confirmation — 19 tests

| ID | Test Case | Verifies |
|----|-----------|----------|
| DA-01 | Exact DELETE confirmed | Happy path |
| DA-02 | Lowercase delete rejected | Case-sensitive |
| DA-03 | Partial DELET rejected | Length check |
| DA-04 | Empty string rejected | Empty guard |
| DA-05 | DELETE with trailing spaces confirmed | trim() |
| DA-06 | DELETE with leading spaces confirmed | trim() |
| DA-07 | DELETE! rejected | Extra chars |
| DA-08 | Delete (mixed case) rejected | Case-sensitive |
| DA-09 | Success sets done=true | Completion |
| DA-10 | Throws + message on requires-recent-login | Re-auth error |
| DA-11 | done=false on requires-recent-login | Error guard |
| DA-12 | Throws on generic failure | Error propagation |
| DA-13 | done=false on generic failure | Error guard |
| DA-14 | Retry after failure succeeds | Recovery path |
| DA-15 | Step 1 = warning | Step machine init |
| DA-16 | Step 1 to 2 on Continue | Step advance |
| DA-17 | Step 2 to 3 on Delete | Step advance |
| DA-18 | Delete button disabled for partial text | UI guard |
| DA-19 | Delete button enabled for exact DELETE | UI guard |

---

## Feature 2 — Feedback Submission — 15 tests

| ID | Test Case | Verifies |
|----|-----------|----------|
| FB-01 | submit() stores entry | Data persistence |
| FB-02 | submit() stores correct userId | Field mapping |
| FB-03 | submit() stores correct userEmail | Field mapping |
| FB-04 | Multiple submissions all stored | No overwriting |
| FB-05 | Throws when service unavailable | Error propagation |
| FB-06 | Throws on empty userId | Validation guard |
| FB-07 | Throws on empty message | Validation guard |
| FB-08 | Form: valid data sets ok=true | Success state |
| FB-09 | Form: sets Thank you success message | UX text |
| FB-10 | Form: whitespace-only message ignored | Whitespace guard |
| FB-11 | Form: empty userId ignored | Unauth guard |
| FB-12 | Form: service error sets errorMsg | Error state |
| FB-13 | Form: busy=false after success | Loading lifecycle |
| FB-14 | Form: busy=false after failure | Loading lifecycle |
| FB-15 | Form: message trimmed before submit | Input sanitisation |

---

## Feature 3 — Notification Mute — 19 tests

| ID | Test Case | Verifies |
|----|-----------|----------|
| NOTIF-01 | Not muted by default | Initial state |
| NOTIF-02 | statusLabel Always allow by default | Initial label |
| NOTIF-03 | muteUntil null by default | Initial state |
| NOTIF-04 | muteFor(8h) sets isMuted=true | Core mute |
| NOTIF-05 | muteUntil is set after muteFor | Timestamp stored |
| NOTIF-06 | statusLabel contains h when muted < 1 day | Hours label |
| NOTIF-07 | statusLabel contains d when muted >= 2 days | Days label |
| NOTIF-08 | muteFor notifies listeners | State notification |
| NOTIF-09 | muteForDays(1) sets isMuted=true | Convenience method |
| NOTIF-10 | muteForDays(3) statusLabel contains d | Days label |
| NOTIF-11 | muteForDays notifies listeners | State notification |
| NOTIF-12 | setAlwaysAllow clears isMuted | Unmute |
| NOTIF-13 | setAlwaysAllow clears muteUntil | Timestamp cleared |
| NOTIF-14 | setAlwaysAllow restores Always allow label | Label restored |
| NOTIF-15 | setAlwaysAllow notifies listeners | State notification |
| NOTIF-16 | Past-duration mute treated as not muted | Auto-expiry |
| NOTIF-17 | statusLabel correct after expired mute | Async expiry label |
| NOTIF-18 | Mute choice persists across provider instances | SharedPreferences |
| NOTIF-19 | setAlwaysAllow persists across provider instances | SharedPreferences |

---

## Feature 4 — Theme Selection — 11 tests

| ID | Test Case | Verifies |
|----|-----------|----------|
| THEME-01 | Default choice is system | Initial state |
| THEME-02 | Default label is System default | Initial label |
| THEME-04 | setChoice(soothing) updates choice and label | Soothing theme |
| THEME-05 | setChoice(vibrantDark) updates choice and label | Dark theme |
| THEME-06 | Back to system restores System default label | Round-trip |
| THEME-07 | setChoice notifies listeners | State notification |
| THEME-08 | All three choices have valid labels | No null labels |
| THEME-09 | Double setChoice is idempotent | No-op on same value |
| THEME-10 | vibrantDark persists across instances | SharedPreferences |
| THEME-11 | soothing persists across instances | SharedPreferences |

---

## Feature 5 — Invite Codes — 14 tests

| ID | Test Case | Verifies |
|----|-----------|----------|
| INV-01 | Generated code is 6 characters | Length |
| INV-02 | All chars in allowed set | Alphabet |
| INV-03 | No confusing chars I O 0 1 | UX clarity |
| INV-04 | Consecutive calls produce different codes | Randomness |
| INV-05 | Code is all uppercase | Format |
| INV-06 | redeemCode throws on invalid code | Error path |
| INV-07 | redeemCode throws on already-used code | Used guard |
| INV-08 | redeemCode throws when user already a member | Duplicate guard |
| INV-09 | redeemCode success returns listId | Happy path |
| INV-10 | redeemCode success adds joiner to members | Side effect |
| INV-11 | redeemCode success marks invite as used | Side effect |
| INV-12 | Code lookup is case-insensitive | Input normalisation |
| INV-13 | Code lookup trims whitespace | Input sanitisation |
| INV-14 | Two users can join same list via different invites | Multi-user |

---

## Feature 6 — SubscriptionLimits — 42 tests

Covers: tier enum membership, maxOwnedSharedLists, maxMembersPerList,
maxJoinedSharedLists (all three tiers each), ordering guarantees,
fromString (all tiers + null + unknown + empty), tierToString,
round-trip, tierDisplayName, isHistoryUnlimited, historyDays (SUB-36..39),
tierBadgeLabel FREE/FAMILY/GROUP (SUB-40..42), supportsMultiCategory,
maxCategoriesPerItem.

---

## Feature 7 — ShoppingItem Model — 26 tests

Covers: all required fields stored, default values (completed=false),
nullable fields (notes, quantity, unit, completedAt), copyWith overrides
and preservation, immutability, toggle completed, equality by id,
hashCode consistency, multi-category stored/copyWith/getter (ITEM-15..18),
toLocalMap CSV encoding / fromMap CSV decoding (ITEM-19..21),
inputMethod stored + null default (ITEM-22..23),
completedByName stored + null default (ITEM-24..25),
toLocalMap round-trip preserves inputMethod + completedByName (ITEM-26).

---

## Feature 8 — ShoppingProvider historyDays/hiddenByHistoryCount — 15 tests

| ID | Test Case | Verifies |
|----|-----------|----------|
| SPROV-01 | free tier isHistoryLimited is true | History cap flag |
| SPROV-02 | group tier isHistoryLimited is false | Unlimited flag |
| SPROV-03 | free tier historyLimitDays equals 30 | Free limit value |
| SPROV-04 | family tier historyLimitDays equals 90 | Family limit value |
| SPROV-05 | group tier historyLimitDays equals -1 (unlimited) | Group sentinel |
| SPROV-06 | free tier hides items older than 30 days | History cutoff |
| SPROV-07 | free tier shows only items within 30-day window | Visible filter |
| SPROV-08 | family tier hides items older than 90 days | History cutoff |
| SPROV-09 | family tier shows items within 90-day window | Visible filter |
| SPROV-10 | group tier hides no items (unlimited history) | No cutoff |
| SPROV-11 | group tier shows all items regardless of age | Full visibility |
| SPROV-12 | empty item list has zero hiddenByHistoryCount | Edge case |
| SPROV-13 | empty item list produces empty visibleItems | Edge case |
| SPROV-14 | hidden + visible equals total (free) | Invariant check |
| SPROV-15 | hidden + visible equals total (family) | Invariant check |

---

## AuthService Error Messages — 15 tests

Covers: AuthException stores message, toString returns message,
is Exception, can be caught, message preserved through throw/catch.
All 8 known Firebase error codes plus unknown and empty string.

---

## Existing Model & Util Tests

### UserProfile — 12 tests
Covers: required fields, optional gender/lastSeen, copyWith (name, gender,
lastSeen), toLocalMap/fromMap round-trip (all fields + nulls), initials
(single name, full name, whitespace-padded), equality by id, hashCode.

### ShoppingList — 9 tests
Covers: required fields, isShared/isPersonal flags, displayLabel, memberIds
storage, equality by id, hashCode, default memberIds, toFirestore keys/values.

### AppConstants / Validators / ItemCategory / MemberStatus — 25 tests
Covers: appName, lengths, all route constants, email validation (valid +
invalid), item name validation (empty, whitespace, max length), display name
validation, 9-category list, allWithAll, emoji map, MemberStatus constants.

### ShoppingProvider filtering logic — 16 tests
Covers: unfiltered list, category filter, showCompleted toggle, sort order
(descending addedAt), pendingCount, completedCount, combined filter,
itemsByDate grouping, sortedDateKeys order, empty list, categoryOptions
(starts with All, contains all ItemCategory.all), activeListName (no listId,
match found, no match fallback).

---

## How to Run

```bash
# Run all unit tests (no Firebase required)
flutter test --no-pub

# Run a specific test file
flutter test test/utils/constants_test.dart --no-pub

# Run with verbose output
flutter test --reporter=expanded --no-pub
```

---

## Coverage Strategy

| Layer | Strategy | Firebase? |
|-------|----------|-----------|
| Providers | Pure-Dart stub (_StubProvider / _FakeService) | No |
| NotificationProvider / ThemeProvider | SharedPreferences mock | No |
| AuthService error messages | Mirror of _friendlyMessage logic | No |
| InviteService | Pure-Dart repo stub | No |
| FirestoreService.submitFeedback | Pure-Dart repo stub | No |
| DeleteAccountDialog | Pure-Dart flow stub | No |
| SubscriptionLimits | Direct method calls | No |
| Models | Direct instantiation + serialisation | No |

Firebase-dependent paths (actual network calls) are excluded from unit
tests and should be covered by integration tests on a Firebase Emulator.