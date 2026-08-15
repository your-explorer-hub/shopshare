import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum MenuTab { myList, sharedList }
enum ViewMode { list, categorised, timeline }

class HomeScreenProvider extends ChangeNotifier {
  static const String _keyDefaultTab = 'home_default_tab';
  static const String _keyDefaultView = 'home_default_view';
  static const String _keyLastSharedListId = 'home_last_shared_list_id';

  // Default preferences
  MenuTab _defaultTab = MenuTab.myList;
  ViewMode _defaultView = ViewMode.list;

  // UI State
  MenuTab _activeTab = MenuTab.myList;
  ViewMode _viewMode = ViewMode.list;
  String _searchQuery = '';
  DateTime? _filterDate;
  bool _pendingSharedTab = false;
  String? _selectedSharedListId;
  final Set<String> _selectedIds = {};
  bool _preferencesLoaded = false;

  // Getters
  MenuTab get defaultTab => _defaultTab;
  ViewMode get defaultView => _defaultView;
  MenuTab get activeTab => _activeTab;
  ViewMode get viewMode => _viewMode;
  String get searchQuery => _searchQuery;
  DateTime? get filterDate => _filterDate;
  bool get pendingSharedTab => _pendingSharedTab;
  String? get selectedSharedListId => _selectedSharedListId;
  Set<String> get selectedIds => _selectedIds;
  bool get hasSelection => _selectedIds.isNotEmpty;
  bool get preferencesLoaded => _preferencesLoaded;

  // Constructor
  HomeScreenProvider() {
    _loadPreferences();
  }

  // Load saved preferences
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Load default tab
    final storedTab = prefs.getString(_keyDefaultTab);
    print('[HomeScreenProvider] Loading preferences...');
    print('[HomeScreenProvider] Stored tab: $storedTab');

    if (storedTab != null) {
      _defaultTab = MenuTab.values.firstWhere(
        (e) => e.name == storedTab,
        orElse: () => MenuTab.myList,
      );
      _activeTab = _defaultTab;
      print('[HomeScreenProvider] Set activeTab to: $_activeTab');
    }

    // Load default view
    final storedView = prefs.getString(_keyDefaultView);
    print('[HomeScreenProvider] Stored view: $storedView');

    if (storedView != null) {
      _defaultView = ViewMode.values.firstWhere(
        (e) => e.name == storedView,
        orElse: () => ViewMode.list,
      );
      _viewMode = _defaultView;
    }

    // Load last selected shared list ID
    final storedSharedListId = prefs.getString(_keyLastSharedListId);
    print('[HomeScreenProvider] Stored shared list ID: $storedSharedListId');

    if (storedSharedListId != null) {
      _selectedSharedListId = storedSharedListId;
    }

    _preferencesLoaded = true;
    print('[HomeScreenProvider] Preferences loaded. activeTab=$_activeTab, selectedSharedListId=$_selectedSharedListId');
    notifyListeners();
  }

  // Methods
  void selectTab(MenuTab tab, {bool clearStates = true}) {
    _activeTab = tab;
    if (clearStates) {
      _searchQuery = '';
      _filterDate = null;
      _selectedIds.clear();
    }
    notifyListeners();
  }

  void setViewMode(ViewMode mode) {
    _viewMode = mode;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilterDate(DateTime? date) {
    _filterDate = date;
    notifyListeners();
  }

  void toggleSelection(String itemId) {
    if (_selectedIds.contains(itemId)) {
      _selectedIds.remove(itemId);
    } else {
      _selectedIds.add(itemId);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedIds.clear();
    notifyListeners();
  }

  void setPendingSharedTab(bool pending) {
    _pendingSharedTab = pending;
    notifyListeners();
  }

  void setSelectedSharedListId(String? listId) {
    _selectedSharedListId = listId;
    print('[HomeScreenProvider] Setting selected shared list ID to: $listId');
    notifyListeners();

    // Save the selected shared list ID to preferences
    if (listId != null) {
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString(_keyLastSharedListId, listId);
        print('[HomeScreenProvider] Saved shared list ID: $listId');
      });
    }
  }

  // Default preference setters
  Future<void> setDefaultTab(MenuTab tab) async {
    _defaultTab = tab;
    print('[HomeScreenProvider] Setting default tab to: $tab');
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDefaultTab, tab.name);
    print('[HomeScreenProvider] Saved default tab: ${tab.name}');
  }

  Future<void> setDefaultView(ViewMode mode) async {
    _defaultView = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDefaultView, mode.name);
  }

  // Reset on dispose/navigation
  void reset() {
    _activeTab = _defaultTab;
    _viewMode = _defaultView;
    _searchQuery = '';
    _filterDate = null;
    _pendingSharedTab = false;
    _selectedSharedListId = null;
    _selectedIds.clear();
    notifyListeners();
  }
}
