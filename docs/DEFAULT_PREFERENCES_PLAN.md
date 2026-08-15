# User-Configurable Default List & View Preferences

## Context

**Problem:**
Currently, the ShopShare app always initializes to "My List" and "List" view on every launch. Users who primarily use shared lists or prefer Category/Timeline views must manually switch every time they open the app, which creates friction and a poor user experience.

**Goal:**
Add user-configurable default preferences for:
1. **Default List Selection**: My List or Shared
2. **Default View Mode**: List, Category, or Timeline

These preferences should:
- Persist across app restarts
- Be configurable in Settings screen (before "Appearance" section)
- Initialize the home screen accordingly on app launch

## Requirements Summary

Based on user clarifications:
- ✅ "Shared" default with multiple lists → Show picker modal (current behavior)
- ✅ "Shared" default with no shared lists → Fall back to "My List" automatically
- ✅ Settings labels → Match home screen exactly: "My List" and "Shared"

## Current State Analysis

### State Management
**File:** `lib/providers/home_screen_provider.dart`

Current defaults (hardcoded):
```dart
MenuTab _activeTab = MenuTab.myList;      // Always My List
ViewMode _viewMode = ViewMode.list;       // Always List view
```

**Problem:** These reset to hardcoded defaults on every app restart because there's no persistence layer.

### Settings Screen Structure
**File:** `lib/screens/settings_screen.dart`

Current sections:
1. Account (line 29)
2. **[INSERT HERE]** ← New "Preferences" section
3. Appearance (line 69)
4. Notifications (line 74)
5. Data (line 79)
6. About (line 102)
7. Support (line 143)

### Existing Persistence Pattern
**File:** `lib/providers/theme_provider.dart`

Pattern to follow:
```dart
class ThemeProvider extends ChangeNotifier {
  static const _key = 'app_theme_choice';
  AppThemeChoice _choice = AppThemeChoice.system;
  
  ThemeProvider() { _load(); }  // Load in constructor
  
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    if (stored != null) {
      _choice = AppThemeChoice.values.firstWhere(
        (e) => e.name == stored,
        orElse: () => AppThemeChoice.system,
      );
      notifyListeners();
    }
  }
  
  Future<void> setChoice(AppThemeChoice choice) async {
    _choice = choice;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, choice.name);
  }
}
```

## Implementation Plan

### Phase 1: Add Persistence to HomeScreenProvider

**File:** `lib/providers/home_screen_provider.dart`

**Changes:**

1. **Add import:**
   ```dart
   import 'package:shared_preferences/shared_preferences.dart';
   ```

2. **Add static keys (after line 5):**
   ```dart
   static const String _keyDefaultTab = 'home_default_tab';
   static const String _keyDefaultView = 'home_default_view';
   ```

3. **Add default preference fields (after line 7):**
   ```dart
   MenuTab _defaultTab = MenuTab.myList;
   ViewMode _defaultView = ViewMode.list;
   ```

4. **Add getters:**
   ```dart
   MenuTab get defaultTab => _defaultTab;
   ViewMode get defaultView => _defaultView;
   ```

5. **Update constructor to load preferences:**
   ```dart
   HomeScreenProvider() {
     _loadPreferences();
   }
   ```

6. **Add load method (after constructor):**
   ```dart
   Future<void> _loadPreferences() async {
     final prefs = await SharedPreferences.getInstance();
     
     // Load default tab
     final storedTab = prefs.getString(_keyDefaultTab);
     if (storedTab != null) {
       _defaultTab = MenuTab.values.firstWhere(
         (e) => e.name == storedTab,
         orElse: () => MenuTab.myList,
       );
       _activeTab = _defaultTab;
     }
     
     // Load default view
     final storedView = prefs.getString(_keyDefaultView);
     if (storedView != null) {
       _defaultView = ViewMode.values.firstWhere(
         (e) => e.name == storedView,
         orElse: () => ViewMode.list,
       );
       _viewMode = _defaultView;
     }
     
     notifyListeners();
   }
   ```

7. **Add setter methods (before `reset()` method):**
   ```dart
   Future<void> setDefaultTab(MenuTab tab) async {
     _defaultTab = tab;
     notifyListeners();
     final prefs = await SharedPreferences.getInstance();
     await prefs.setString(_keyDefaultTab, tab.name);
   }
   
   Future<void> setDefaultView(ViewMode mode) async {
     _defaultView = mode;
     notifyListeners();
     final prefs = await SharedPreferences.getInstance();
     await prefs.setString(_keyDefaultView, mode.name);
   }
   ```

8. **Update `reset()` method to use saved defaults:**
   ```dart
   void reset() {
     _activeTab = _defaultTab;          // Use saved default instead of hardcoded
     _viewMode = _defaultView;          // Use saved default instead of hardcoded
     _searchQuery = '';
     _filterDate = null;
     _selectedIds.clear();
     notifyListeners();
   }
   ```

### Phase 2: Handle Edge Case in HomeScreen

**File:** `lib/screens/home_screen.dart`

**Issue:** When user sets "Shared" as default but has no shared lists, we need to fall back to "My List" automatically.

**Solution:** Add validation in home screen initialization (likely in `initState` or when provider is first accessed).

**Implementation:**
Add after provider initialization in home screen widget:
```dart
// Validate default tab selection
WidgetsBinding.instance.addPostFrameCallback((_) {
  final homeState = context.read<HomeScreenProvider>();
  final shopping = context.read<ShoppingProvider>();
  
  // If Shared is default but no shared lists exist, switch to My List
  if (homeState.activeTab == MenuTab.sharedList) {
    final sharedLists = shopping.availableLists.where((l) => l.isShared).toList();
    if (sharedLists.isEmpty) {
      homeState.selectTab(MenuTab.myList);
    }
  }
});
```

### Phase 3: Add Preferences Section to Settings

**File:** `lib/screens/settings_screen.dart`

**Location:** Insert at line 66 (between Account and Appearance sections)

**Code to add:**

```dart
const _SectionHeader(label: 'PREFERENCES'),

// Default List Tile
Consumer<HomeScreenProvider>(
  builder: (context, homeState, _) {
    final currentTab = homeState.defaultTab;
    final label = currentTab == MenuTab.myList ? 'My List' : 'Shared';
    
    return _SettingsTile(
      leading: const Icon(Icons.home_rounded),
      title: 'Default List',
      subtitle: label,
      onTap: () => _showDefaultListPicker(context, homeState),
    );
  },
),

const SizedBox(height: 4),

// Default View Tile
Consumer<HomeScreenProvider>(
  builder: (context, homeState, _) {
    String viewLabel;
    switch (homeState.defaultView) {
      case ViewMode.list:
        viewLabel = 'List';
        break;
      case ViewMode.categorised:
        viewLabel = 'Category';
        break;
      case ViewMode.timeline:
        viewLabel = 'Timeline';
        break;
    }
    
    return _SettingsTile(
      leading: const Icon(Icons.view_list_rounded),
      title: 'Default View',
      subtitle: viewLabel,
      onTap: () => _showDefaultViewPicker(context, homeState),
    );
  },
),

const SizedBox(height: 24),
```

**Add picker methods** (add to `_SettingsScreenState` class):

```dart
void _showDefaultListPicker(BuildContext context, HomeScreenProvider homeState) {
  showModalBottomSheet(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Text(
            'Default List',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.person_rounded),
            title: const Text('My List'),
            trailing: homeState.defaultTab == MenuTab.myList
                ? const Icon(Icons.check_rounded, color: AppTheme.primaryPurple)
                : null,
            onTap: () {
              homeState.setDefaultTab(MenuTab.myList);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.group_rounded),
            title: const Text('Shared'),
            trailing: homeState.defaultTab == MenuTab.sharedList
                ? const Icon(Icons.check_rounded, color: AppTheme.primaryPurple)
                : null,
            onTap: () {
              homeState.setDefaultTab(MenuTab.sharedList);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}

void _showDefaultViewPicker(BuildContext context, HomeScreenProvider homeState) {
  showModalBottomSheet(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Text(
            'Default View',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.list_rounded),
            title: const Text('List'),
            trailing: homeState.defaultView == ViewMode.list
                ? const Icon(Icons.check_rounded, color: AppTheme.primaryPurple)
                : null,
            onTap: () {
              homeState.setDefaultView(ViewMode.list);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.category_rounded),
            title: const Text('Category'),
            trailing: homeState.defaultView == ViewMode.categorised
                ? const Icon(Icons.check_rounded, color: AppTheme.primaryPurple)
                : null,
            onTap: () {
              homeState.setDefaultView(ViewMode.categorised);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.timeline_rounded),
            title: const Text('Timeline'),
            trailing: homeState.defaultView == ViewMode.timeline
                ? const Icon(Icons.check_rounded, color: AppTheme.primaryPurple)
                : null,
            onTap: () {
              homeState.setDefaultView(ViewMode.timeline);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}
```

## Testing Checklist

### Persistence Testing
1. ✅ Set "Shared" as default → Close app → Reopen → Verify it opens to Shared tab
2. ✅ Set "Category" as default view → Close app → Reopen → Verify it opens to Category view
3. ✅ Test all 6 combinations (My List/Shared × List/Category/Timeline)

### Edge Cases
4. ✅ Set "Shared" default with no shared lists → Verify falls back to "My List"
5. ✅ Set "Shared" default with multiple shared lists → Verify picker modal appears
6. ✅ Manual switching during session still works (doesn't get overridden by defaults)

### UI/UX
7. ✅ Settings tiles show current selection correctly
8. ✅ Picker modals show check mark on selected option
9. ✅ Changes in settings immediately affect next app launch
10. ✅ Settings section appears before "Appearance" section

### Regression Testing
11. ✅ Existing users without saved preferences get original defaults (My List + List view)
12. ✅ Home screen behavior unchanged except for initial launch state
13. ✅ No impact on other features (search, filtering, batch operations)

## Files to Modify

1. **`lib/providers/home_screen_provider.dart`**
   - Add SharedPreferences import
   - Add static keys for preferences
   - Add default preference fields and getters
   - Add `_loadPreferences()` method in constructor
   - Add `setDefaultTab()` and `setDefaultView()` setter methods
   - Update `reset()` to use saved defaults

2. **`lib/screens/home_screen.dart`**
   - Add edge case validation for "Shared" default with no lists
   - Add `addPostFrameCallback` to validate default tab on init

3. **`lib/screens/settings_screen.dart`**
   - Add "Preferences" section header at line 66
   - Add "Default List" tile with Consumer<HomeScreenProvider>
   - Add "Default View" tile with Consumer<HomeScreenProvider>
   - Add `_showDefaultListPicker()` method
   - Add `_showDefaultViewPicker()` method
   - Import `home_screen_provider.dart`

## Safety Guarantees

✅ **Backwards compatible** - Existing users get original defaults  
✅ **Fail-safe deserialization** - Uses `firstWhere` with `orElse`  
✅ **No database migration** - Uses SharedPreferences only  
✅ **Edge case handled** - Falls back gracefully when Shared has no lists  
✅ **Non-blocking** - Loads preferences asynchronously in constructor  
✅ **Atomic operations** - Each preference saved independently  
✅ **Type-safe** - Uses enum serialization via `enum.name`  
✅ **Manual override preserved** - Users can still switch during session  

## Estimated Impact

- **User benefit:** One-time configuration eliminates repetitive manual switching
- **Files modified:** 3 files
- **Lines of code:** ~150 lines added
- **Complexity:** Low (follows existing ThemeProvider pattern)
- **Risk:** Minimal (isolated to home screen initialization)
