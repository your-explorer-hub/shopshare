import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/shopping_item.dart';
import '../providers/auth_provider.dart';
import '../providers/shopping_provider.dart';
import '../providers/home_screen_provider.dart';
import '../utils/list_formatter.dart';
import 'home/home_categorised_view.dart';
import 'home/home_list_view.dart';
import 'home/home_timeline_view.dart';
import 'home/widgets/delete_confirm_dialog.dart';
import 'home/widgets/home_app_bar.dart';
import 'home/widgets/home_floating_menu.dart';
import 'home/widgets/home_list_banners.dart';
import 'home/widgets/home_search_bar.dart';
import 'home/widgets/home_sticky_navigation.dart';
import 'home/widgets/home_view_toggle.dart';
import 'home/widgets/move_dialog.dart';
import 'home/widgets/share_items_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _hasInitialized = false;
  bool _listsLoadedAndInitialized = false;

  void _toggleSelect(String itemId) {
    context.read<HomeScreenProvider>().toggleSelection(itemId);
  }

  Future<void> _showMoveDialog() async {
    final homeState = context.read<HomeScreenProvider>();
    if (homeState.selectedIds.isEmpty) return;
    final shopping = context.read<ShoppingProvider>();
    final auth = context.read<AuthProvider>();
    final user = auth.userProfile;
    if (user == null) return;
    final selectedItems = shopping.filteredItems
        .where((i) => homeState.selectedIds.contains(i.id))
        .toList();
    if (selectedItems.isEmpty) return;
    await MoveDialog.show(
      context: context,
      selectedItems: selectedItems,
      shopping: shopping,
      userId: user.id,
      userName: user.displayName,
      onClearSelection: homeState.clearSelection,
    );
  }

  Future<void> _deleteCompleted() async {
    await DeleteConfirmDialog.showDeleteCompleted(
        context: context, shopping: context.read<ShoppingProvider>());
  }

  Future<void> _deleteSelected() async {
    final homeState = context.read<HomeScreenProvider>();
    await DeleteConfirmDialog.showDeleteSelected(
      context: context,
      shopping: context.read<ShoppingProvider>(),
      selectedIds: Set.from(homeState.selectedIds),
      onClearSelection: homeState.clearSelection,
    );
  }

  Future<void> _shareSelectedItems() async {
    final homeState = context.read<HomeScreenProvider>();
    final selectedIds = homeState.selectedIds;

    if (selectedIds.isEmpty) return;

    final shopping = context.read<ShoppingProvider>();

    // Get selected items
    final selectedItems = shopping.filteredItems
        .where((item) => selectedIds.contains(item.id))
        .toList();

    if (selectedItems.isEmpty) return;

    // Get current list name
    final currentList = shopping.availableLists
        .firstWhere((list) => list.id == shopping.listId);

    // Show dialog with formatted text
    await ShareItemsDialog.show(
      context: context,
      items: selectedItems,
      listName: currentList.name,
    );

    // Clear selection after dialog closes
    homeState.clearSelection();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final homeState = context.read<HomeScreenProvider>();
    final shopping = context.read<ShoppingProvider>();
    final auth = context.read<AuthProvider>();
    final userId = auth.userProfile?.id ?? '';

    // Wait for preferences to load before any initialization
    if (!homeState.preferencesLoaded) {
      return;
    }

    // Initialize only once when preferences AND lists are loaded
    if (!_listsLoadedAndInitialized && shopping.availableLists.isNotEmpty) {
      _listsLoadedAndInitialized = true;
      print('[HomeScreen] Initializing with activeTab=${homeState.activeTab}, selectedSharedListId=${homeState.selectedSharedListId}, listsCount=${shopping.availableLists.length}');

      // Validate default tab selection and handle shared list initialization
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        if (homeState.activeTab == MenuTab.sharedList) {
          final sharedLists = shopping.availableLists.where((l) => l.isShared).toList();
          print('[HomeScreen] Shared lists count: ${sharedLists.length}');

          // If no shared lists exist, fall back to My List
          if (sharedLists.isEmpty) {
            print('[HomeScreen] No shared lists, falling back to My List');
            homeState.selectTab(MenuTab.myList);
            return;
          }

          // If shared lists exist, switch to the saved list
          final savedListId = homeState.selectedSharedListId;
          if (savedListId != null) {
            // Check if saved list still exists
            final savedListExists = sharedLists.any((l) => l.id == savedListId);
            if (savedListExists) {
              print('[HomeScreen] Switching to saved shared list: $savedListId');
              if (shopping.listId != savedListId) {
                shopping.switchList(savedListId, userId);
              }
            } else {
              // Saved list no longer exists, show picker or auto-select
              print('[HomeScreen] Saved list no longer exists');
              if (sharedLists.length > 1) {
                _showSharedListPicker(context, shopping);
              } else {
                homeState.setSelectedSharedListId(sharedLists.first.id);
                shopping.switchList(sharedLists.first.id, userId);
              }
            }
          } else {
            // No saved list ID, show picker or auto-select
            print('[HomeScreen] No saved list ID');
            if (sharedLists.length > 1) {
              _showSharedListPicker(context, shopping);
            } else {
              homeState.setSelectedSharedListId(sharedLists.first.id);
              shopping.switchList(sharedLists.first.id, userId);
            }
          }
        } else if (homeState.activeTab == MenuTab.myList) {
          // Switch to personal list
          final personal = shopping.availableLists.where((l) => !l.isShared).toList();
          if (personal.isNotEmpty && shopping.listId != personal.first.id) {
            print('[HomeScreen] Switching to My List');
            shopping.switchList(personal.first.id, userId);
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSharedListPicker(BuildContext context, ShoppingProvider shopping) {
    final homeState = context.read<HomeScreenProvider>();
    final auth = context.read<AuthProvider>();
    final userId = auth.userProfile?.id ?? '';
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SharedListPickerSheet(
        lists: shopping.availableLists.where((l) => l.isShared).toList(),
        activeListId: shopping.listId,
        onSelect: (listId) {
          homeState.setSelectedSharedListId(listId);
          if (shopping.listId != listId) {
            shopping.switchList(listId, userId);
          }
          homeState.clearSelection();
        },
      ),
    );
  }

  void _selectTab(MenuTab tab) {
    final homeState = context.read<HomeScreenProvider>();
    final shopping = context.read<ShoppingProvider>();
    final auth = context.read<AuthProvider>();
    final userId = auth.userProfile?.id ?? '';

    homeState.selectTab(tab);
    _searchController.clear();

    if (tab == MenuTab.myList) {
      homeState.setSelectedSharedListId(null);
      final personal =
          shopping.availableLists.where((l) => !l.isShared).toList();
      if (personal.isNotEmpty && shopping.listId != personal.first.id) {
        shopping.switchList(personal.first.id, userId);
      }
    } else if (tab == MenuTab.sharedList) {
      final shared =
          shopping.availableLists.where((l) => l.isShared).toList();
      if (shared.isNotEmpty) {
        if (shared.length > 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _showSharedListPicker(context, shopping);
          });
        } else {
          homeState.setSelectedSharedListId(shared.first.id);
          if (shopping.listId != shared.first.id) {
            shopping.switchList(shared.first.id, userId);
          }
        }
        homeState.setPendingSharedTab(false);
      } else if (shopping.availableLists.isEmpty) {
        homeState.setPendingSharedTab(true);
      } else {
        homeState.setPendingSharedTab(false);
        homeState.selectTab(MenuTab.myList, clearStates: false);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No shared list yet.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeState = context.watch<HomeScreenProvider>();
    final shopping = context.watch<ShoppingProvider>();
    final auth = context.watch<AuthProvider>();
    final userName = auth.userProfile?.displayName ?? 'User';
    final hasSelection = homeState.hasSelection;
    final isSharedList = homeState.activeTab == MenuTab.sharedList;

    // Resolve pending shared-tab switch
    if (homeState.pendingSharedTab && shopping.availableLists.isNotEmpty) {
      final messenger = ScaffoldMessenger.of(context);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final shared =
            shopping.availableLists.where((l) => l.isShared).toList();
        if (shared.isNotEmpty) {
          _selectTab(MenuTab.sharedList);
        } else {
          homeState.setPendingSharedTab(false);
          homeState.selectTab(MenuTab.myList, clearStates: false);
          messenger.showSnackBar(
              const SnackBar(content: Text('No shared list yet.')));
        }
      });
    }

    // Filter items
    List<ShoppingItem> displayItems = shopping.filteredItems;
    if (homeState.searchQuery.isNotEmpty) {
      final q = homeState.searchQuery.toLowerCase();
      displayItems = displayItems
          .where((i) =>
              i.name.toLowerCase().contains(q) ||
              i.category.toLowerCase().contains(q))
          .toList();
    }
    if (homeState.filterDate != null) {
      displayItems = displayItems.where((item) {
        final d = item.addedAt;
        return d.year == homeState.filterDate!.year &&
            d.month == homeState.filterDate!.month &&
            d.day == homeState.filterDate!.day;
      }).toList();
    }

    return Scaffold(
      body: CustomScrollView(
        cacheExtent: 200.0, // Pre-render 200px above/below viewport for smooth scrolling
        slivers: [
          // ── App Bar ───────────────────────────────────────────────────
          HomeAppBar(
            userName: userName,
            hasSelection: hasSelection,
            selectedCount: homeState.selectedIds.length,
            onClearSelection: homeState.clearSelection,
            onDeleteCompleted: _deleteCompleted,
          ),

          // ── Sticky Navigation (Tab selector + List banner) ────────────
          HomeStickyNavigation(
            activeTab: homeState.activeTab,
            onSelectTab: _selectTab,
            onSharedBannerTap: () => _showSharedListPicker(context, shopping),
          ),

          // ── View filters (centered, no label) ────────────────────────────
          HomeViewToggle(
            viewMode: homeState.viewMode,
            onChanged: homeState.setViewMode,
          ),

          // ── Search bar ────────────────────────────────────────────────
          HomeSearchBar(
            controller: _searchController,
            searchQuery: homeState.searchQuery,
            onChanged: homeState.setSearchQuery,
            onClear: () {
              homeState.setSearchQuery('');
              _searchController.clear();
            },
          ),

          // ── Category chips removed per user feedback ──────────────────
          // Category filtering is still available via the shopping provider
          // but the UI chips have been removed for cleaner interface

          // ── List banner (history limit) ───────────────────────────────
          if (shopping.isHistoryLimited && shopping.hiddenByHistoryCount > 0)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${shopping.hiddenByHistoryCount} older item${shopping.hiddenByHistoryCount > 1 ? 's' : ''} hidden — upgrade to see full history',
                    style: TextStyle(
                        fontSize: 12, color: Colors.orange.shade800),
                  ),
                ),
              ),
            ),

          // ── Items body ────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: _buildBodySliver(
                displayItems, isSharedList, userName, shopping.isLoading),
          ),
        ],
      ),

      // ── Centered Floating Action Menu ────────────────────────────────
      floatingActionButton: HomeFloatingMenu(
        hasSelection: hasSelection,
        onMove: _showMoveDialog,
        onShare: _shareSelectedItems,
        onDelete: _deleteSelected,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildBodySliver(
      List<ShoppingItem> items, bool isSharedList, String userName, bool isLoading) {
    final homeState = context.read<HomeScreenProvider>();
    switch (homeState.viewMode) {
      case ViewMode.list:
        return HomeListView(
          items: items,
          isSharedList: isSharedList,
          selectedIds: homeState.selectedIds,
          userName: userName,
          isLoading: isLoading,
          onToggle: (item, name) =>
              context.read<ShoppingProvider>().toggleComplete(item, name),
          onDelete: (item) =>
              context.read<ShoppingProvider>().deleteItem(item),
          onSelectToggle: _toggleSelect,
        );
      case ViewMode.categorised:
        return HomeCategorisedView(
          items: items,
          isSharedList: isSharedList,
          selectedIds: homeState.selectedIds,
          userName: userName,
          isLoading: isLoading,
          onToggle: (item, name) =>
              context.read<ShoppingProvider>().toggleComplete(item, name),
          onDelete: (item) =>
              context.read<ShoppingProvider>().deleteItem(item),
          onSelectToggle: _toggleSelect,
        );
      case ViewMode.timeline:
        return HomeTimelineView(
          items: items,
          isSharedList: isSharedList,
          selectedIds: homeState.selectedIds,
          userName: userName,
          isLoading: isLoading,
          onToggle: (item, name) =>
              context.read<ShoppingProvider>().toggleComplete(item, name),
          onDelete: (item) =>
              context.read<ShoppingProvider>().deleteItem(item),
          onSelectToggle: _toggleSelect,
        );
    }
  }
}
