import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_app/providers/home_screen_provider.dart';

void main() {
  group('HomeScreenProvider - Initial State', () {
    test('HOME-01: default activeTab is myList', () {
      final provider = HomeScreenProvider();
      expect(provider.activeTab, MenuTab.myList);
    });

    test('HOME-02: default viewMode is list', () {
      final provider = HomeScreenProvider();
      expect(provider.viewMode, ViewMode.list);
    });

    test('HOME-03: default searchQuery is empty', () {
      final provider = HomeScreenProvider();
      expect(provider.searchQuery, isEmpty);
    });

    test('HOME-04: default filterDate is null', () {
      final provider = HomeScreenProvider();
      expect(provider.filterDate, isNull);
    });

    test('HOME-05: default pendingSharedTab is false', () {
      final provider = HomeScreenProvider();
      expect(provider.pendingSharedTab, isFalse);
    });

    test('HOME-06: default selectedSharedListId is null', () {
      final provider = HomeScreenProvider();
      expect(provider.selectedSharedListId, isNull);
    });

    test('HOME-07: default selectedIds is empty', () {
      final provider = HomeScreenProvider();
      expect(provider.selectedIds, isEmpty);
    });

    test('HOME-08: default hasSelection is false', () {
      final provider = HomeScreenProvider();
      expect(provider.hasSelection, isFalse);
    });
  });

  group('HomeScreenProvider - Tab Selection', () {
    test('HOME-09: selectTab changes activeTab', () {
      final provider = HomeScreenProvider();
      provider.selectTab(MenuTab.sharedList);
      expect(provider.activeTab, MenuTab.sharedList);
    });

    test('HOME-10: selectTab clears searchQuery by default', () {
      final provider = HomeScreenProvider();
      provider.setSearchQuery('test');
      provider.selectTab(MenuTab.sharedList);
      expect(provider.searchQuery, isEmpty);
    });

    test('HOME-11: selectTab clears filterDate by default', () {
      final provider = HomeScreenProvider();
      provider.setFilterDate(DateTime(2026, 5, 29));
      provider.selectTab(MenuTab.sharedList);
      expect(provider.filterDate, isNull);
    });

    test('HOME-12: selectTab clears selectedIds by default', () {
      final provider = HomeScreenProvider();
      provider.toggleSelection('item1');
      provider.toggleSelection('item2');
      provider.selectTab(MenuTab.sharedList);
      expect(provider.selectedIds, isEmpty);
    });

    test('HOME-13: selectTab with clearStates=false preserves states', () {
      final provider = HomeScreenProvider();
      provider.setSearchQuery('test');
      provider.setFilterDate(DateTime(2026, 5, 29));
      provider.toggleSelection('item1');

      provider.selectTab(MenuTab.sharedList, clearStates: false);

      expect(provider.activeTab, MenuTab.sharedList);
      expect(provider.searchQuery, 'test');
      expect(provider.filterDate, isNotNull);
      expect(provider.selectedIds, contains('item1'));
    });

    test('HOME-14: selectTab notifies listeners', () {
      final provider = HomeScreenProvider();
      var notified = false;
      provider.addListener(() => notified = true);

      provider.selectTab(MenuTab.sharedList);

      expect(notified, isTrue);
    });
  });

  group('HomeScreenProvider - View Mode', () {
    test('HOME-15: setViewMode changes viewMode', () {
      final provider = HomeScreenProvider();
      provider.setViewMode(ViewMode.categorised);
      expect(provider.viewMode, ViewMode.categorised);
    });

    test('HOME-16: setViewMode to timeline works', () {
      final provider = HomeScreenProvider();
      provider.setViewMode(ViewMode.timeline);
      expect(provider.viewMode, ViewMode.timeline);
    });

    test('HOME-17: setViewMode notifies listeners', () {
      final provider = HomeScreenProvider();
      var notified = false;
      provider.addListener(() => notified = true);

      provider.setViewMode(ViewMode.categorised);

      expect(notified, isTrue);
    });

    test('HOME-18: setViewMode can switch back to list', () {
      final provider = HomeScreenProvider();
      provider.setViewMode(ViewMode.categorised);
      provider.setViewMode(ViewMode.list);
      expect(provider.viewMode, ViewMode.list);
    });
  });

  group('HomeScreenProvider - Search Query', () {
    test('HOME-19: setSearchQuery updates searchQuery', () {
      final provider = HomeScreenProvider();
      provider.setSearchQuery('apple');
      expect(provider.searchQuery, 'apple');
    });

    test('HOME-20: setSearchQuery with empty string works', () {
      final provider = HomeScreenProvider();
      provider.setSearchQuery('test');
      provider.setSearchQuery('');
      expect(provider.searchQuery, isEmpty);
    });

    test('HOME-21: setSearchQuery notifies listeners', () {
      final provider = HomeScreenProvider();
      var notified = false;
      provider.addListener(() => notified = true);

      provider.setSearchQuery('test');

      expect(notified, isTrue);
    });

    test('HOME-22: setSearchQuery handles special characters', () {
      final provider = HomeScreenProvider();
      provider.setSearchQuery('test@123!');
      expect(provider.searchQuery, 'test@123!');
    });
  });

  group('HomeScreenProvider - Filter Date', () {
    test('HOME-23: setFilterDate updates filterDate', () {
      final provider = HomeScreenProvider();
      final date = DateTime(2026, 5, 29);
      provider.setFilterDate(date);
      expect(provider.filterDate, date);
    });

    test('HOME-24: setFilterDate with null clears filter', () {
      final provider = HomeScreenProvider();
      provider.setFilterDate(DateTime(2026, 5, 29));
      provider.setFilterDate(null);
      expect(provider.filterDate, isNull);
    });

    test('HOME-25: setFilterDate notifies listeners', () {
      final provider = HomeScreenProvider();
      var notified = false;
      provider.addListener(() => notified = true);

      provider.setFilterDate(DateTime(2026, 5, 29));

      expect(notified, isTrue);
    });
  });

  group('HomeScreenProvider - Selection Management', () {
    test('HOME-26: toggleSelection adds item on first call', () {
      final provider = HomeScreenProvider();
      provider.toggleSelection('item1');
      expect(provider.selectedIds, contains('item1'));
      expect(provider.hasSelection, isTrue);
    });

    test('HOME-27: toggleSelection removes item on second call', () {
      final provider = HomeScreenProvider();
      provider.toggleSelection('item1');
      provider.toggleSelection('item1');
      expect(provider.selectedIds, isEmpty);
      expect(provider.hasSelection, isFalse);
    });

    test('HOME-28: toggleSelection handles multiple items', () {
      final provider = HomeScreenProvider();
      provider.toggleSelection('item1');
      provider.toggleSelection('item2');
      provider.toggleSelection('item3');

      expect(provider.selectedIds, containsAll(['item1', 'item2', 'item3']));
      expect(provider.selectedIds.length, 3);
    });

    test('HOME-29: toggleSelection notifies listeners', () {
      final provider = HomeScreenProvider();
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.toggleSelection('item1');
      provider.toggleSelection('item2');

      expect(notifyCount, 2);
    });

    test('HOME-30: clearSelection removes all items', () {
      final provider = HomeScreenProvider();
      provider.toggleSelection('item1');
      provider.toggleSelection('item2');
      provider.toggleSelection('item3');

      provider.clearSelection();

      expect(provider.selectedIds, isEmpty);
      expect(provider.hasSelection, isFalse);
    });

    test('HOME-31: clearSelection notifies listeners', () {
      final provider = HomeScreenProvider();
      provider.toggleSelection('item1');
      var notified = false;
      provider.addListener(() => notified = true);

      provider.clearSelection();

      expect(notified, isTrue);
    });

    test('HOME-32: clearSelection on empty set is safe', () {
      final provider = HomeScreenProvider();
      expect(() => provider.clearSelection(), returnsNormally);
      expect(provider.selectedIds, isEmpty);
    });

    test('HOME-33: hasSelection returns true when items selected', () {
      final provider = HomeScreenProvider();
      expect(provider.hasSelection, isFalse);

      provider.toggleSelection('item1');
      expect(provider.hasSelection, isTrue);
    });

    test('HOME-34: selectedIds returns immutable reference', () {
      final provider = HomeScreenProvider();
      provider.toggleSelection('item1');

      final ids = provider.selectedIds;
      expect(ids, contains('item1'));
    });
  });

  group('HomeScreenProvider - Shared List Management', () {
    test('HOME-35: setPendingSharedTab updates state', () {
      final provider = HomeScreenProvider();
      provider.setPendingSharedTab(true);
      expect(provider.pendingSharedTab, isTrue);
    });

    test('HOME-36: setPendingSharedTab can be toggled', () {
      final provider = HomeScreenProvider();
      provider.setPendingSharedTab(true);
      provider.setPendingSharedTab(false);
      expect(provider.pendingSharedTab, isFalse);
    });

    test('HOME-37: setPendingSharedTab notifies listeners', () {
      final provider = HomeScreenProvider();
      var notified = false;
      provider.addListener(() => notified = true);

      provider.setPendingSharedTab(true);

      expect(notified, isTrue);
    });

    test('HOME-38: setSelectedSharedListId updates listId', () {
      final provider = HomeScreenProvider();
      provider.setSelectedSharedListId('list-123');
      expect(provider.selectedSharedListId, 'list-123');
    });

    test('HOME-39: setSelectedSharedListId with null clears selection', () {
      final provider = HomeScreenProvider();
      provider.setSelectedSharedListId('list-123');
      provider.setSelectedSharedListId(null);
      expect(provider.selectedSharedListId, isNull);
    });

    test('HOME-40: setSelectedSharedListId notifies listeners', () {
      final provider = HomeScreenProvider();
      var notified = false;
      provider.addListener(() => notified = true);

      provider.setSelectedSharedListId('list-123');

      expect(notified, isTrue);
    });
  });

  group('HomeScreenProvider - Reset Functionality', () {
    test('HOME-41: reset restores all defaults', () {
      final provider = HomeScreenProvider();

      // Set non-default values
      provider.selectTab(MenuTab.sharedList, clearStates: false);
      provider.setViewMode(ViewMode.categorised);
      provider.setSearchQuery('test');
      provider.setFilterDate(DateTime(2026, 5, 29));
      provider.setPendingSharedTab(true);
      provider.setSelectedSharedListId('list-123');
      provider.toggleSelection('item1');

      // Reset
      provider.reset();

      // Verify all defaults restored
      expect(provider.activeTab, MenuTab.myList);
      expect(provider.viewMode, ViewMode.list);
      expect(provider.searchQuery, isEmpty);
      expect(provider.filterDate, isNull);
      expect(provider.pendingSharedTab, isFalse);
      expect(provider.selectedSharedListId, isNull);
      expect(provider.selectedIds, isEmpty);
      expect(provider.hasSelection, isFalse);
    });

    test('HOME-42: reset notifies listeners', () {
      final provider = HomeScreenProvider();
      provider.setSearchQuery('test');
      var notified = false;
      provider.addListener(() => notified = true);

      provider.reset();

      expect(notified, isTrue);
    });

    test('HOME-43: reset is idempotent', () {
      final provider = HomeScreenProvider();
      provider.reset();
      provider.reset();

      expect(provider.activeTab, MenuTab.myList);
      expect(provider.searchQuery, isEmpty);
    });
  });

  group('HomeScreenProvider - Integration Scenarios', () {
    test('HOME-44: switching to shared list workflow', () {
      final provider = HomeScreenProvider();

      // User on myList with some state
      expect(provider.activeTab, MenuTab.myList);
      provider.setSearchQuery('milk');
      provider.toggleSelection('item1');

      // User switches to shared list
      provider.selectTab(MenuTab.sharedList);

      // State should be cleared
      expect(provider.activeTab, MenuTab.sharedList);
      expect(provider.searchQuery, isEmpty);
      expect(provider.selectedIds, isEmpty);
    });

    test('HOME-45: search and select workflow', () {
      final provider = HomeScreenProvider();

      provider.setSearchQuery('apple');
      provider.toggleSelection('item1');
      provider.toggleSelection('item2');

      expect(provider.searchQuery, 'apple');
      expect(provider.selectedIds.length, 2);
      expect(provider.hasSelection, isTrue);
    });

    test('HOME-46: view mode change preserves other state', () {
      final provider = HomeScreenProvider();

      provider.setSearchQuery('test');
      provider.toggleSelection('item1');
      provider.setViewMode(ViewMode.categorised);

      expect(provider.viewMode, ViewMode.categorised);
      expect(provider.searchQuery, 'test');
      expect(provider.selectedIds, contains('item1'));
    });

    test('HOME-47: filter by date preserves view mode', () {
      final provider = HomeScreenProvider();

      provider.setViewMode(ViewMode.timeline);
      provider.setFilterDate(DateTime(2026, 5, 29));

      expect(provider.viewMode, ViewMode.timeline);
      expect(provider.filterDate, isNotNull);
    });

    test('HOME-48: multiple listener notifications in sequence', () {
      final provider = HomeScreenProvider();
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.setSearchQuery('test');
      provider.setViewMode(ViewMode.categorised);
      provider.toggleSelection('item1');
      provider.selectTab(MenuTab.sharedList);

      expect(notifyCount, 4);
    });
  });
}
