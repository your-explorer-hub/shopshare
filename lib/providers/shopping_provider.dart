import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/shopping_item.dart';
import '../models/shopping_list.dart';
import '../models/member.dart';
import '../services/firestore_service.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';
import '../utils/subscription_limits.dart';

class ShoppingProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService.instance;

  List<ShoppingItem> _allItems = [];
  List<Member> _members = [];
  List<ShoppingList> _availableLists = [];
  String _selectedCategory = 'All';
  bool _showCompleted = true;
  bool _isLoading = false;
  bool _initialLoad = true;
  String? _errorMessage;
  String? _listId;
  String? _userId;

  SubscriptionTier _userTier = SubscriptionTier.free;

  // ── Stream subscriptions (stored to cancel on re-subscribe / dispose) ────
  StreamSubscription<List<ShoppingItem>>? _itemsSub;
  StreamSubscription<List<Member>>? _membersSub;
  StreamSubscription<List<ShoppingList>>? _listsSub;

  // ── InviteScreen members subscription (separate from global _membersSub) ─
  StreamSubscription<List<Member>>? _inviteScreenMembersSub;

  // ── Invite state ─────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _pendingInvites = [];
  List<ShoppingList> _joinedSharedLists = [];
  bool _invitesLoading = false;
  StreamSubscription<List<Map<String, dynamic>>>? _inviteStreamSub;

  List<ShoppingItem> get allItems => _allItems;
  List<Member> get members => _members;
  List<ShoppingList> get availableLists => _availableLists;
  String get selectedCategory => _selectedCategory;
  bool get showCompleted => _showCompleted;
  bool get isLoading => _isLoading;
  bool get initialLoad => _initialLoad;
  String? get errorMessage => _errorMessage;
  String? get listId => _listId;
  SubscriptionTier get userTier => _userTier;

  List<Map<String, dynamic>> get pendingInvites =>
      List.unmodifiable(_pendingInvites);
  List<ShoppingList> get joinedSharedLists =>
      List.unmodifiable(_joinedSharedLists);
  int get pendingInviteCount => _pendingInvites.length;
  bool get invitesLoading => _invitesLoading;

  bool get isHistoryLimited => !SubscriptionLimits.isHistoryUnlimited(_userTier);
  int get historyLimitDays => SubscriptionLimits.historyDays(_userTier);

  void setUserTier(SubscriptionTier tier) {
    if (_userTier == tier) return;
    _userTier = tier;
    notifyListeners();
  }

  String get activeListName {
    if (_listId == null) return 'My List';
    final match = _availableLists.where((l) => l.id == _listId);
    if (match.isNotEmpty) return match.first.name;
    return _listId!;
  }

  ShoppingList? get activeList {
    if (_listId == null) return null;
    final matches = _availableLists.where((l) => l.id == _listId);
    return matches.isEmpty ? null : matches.first;
  }

  DateTime? get _historyCutoff {
    final days = SubscriptionLimits.historyDays(_userTier);
    if (days == -1) return null;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).subtract(Duration(days: days));
  }

  List<ShoppingItem> get filteredItems {
    final cutoff = _historyCutoff;
    var items = _allItems.where((item) {
      if (!_showCompleted && item.completed) return false;
      if (_selectedCategory != 'All' && item.category != _selectedCategory) {
        return false;
      }
      if (cutoff != null && item.addedAt.isBefore(cutoff)) return false;
      return true;
    }).toList();

    items.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return items;
  }

  int get hiddenByHistoryCount {
    final cutoff = _historyCutoff;
    if (cutoff == null) return 0;
    return _allItems.where((item) => item.addedAt.isBefore(cutoff)).length;
  }

  Map<String, List<ShoppingItem>> get itemsByDate {
    final map = <String, List<ShoppingItem>>{};
    for (final item in filteredItems) {
      final key = AppDateUtils.dateKey(item.addedAt);
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }

  List<String> get sortedDateKeys {
    return itemsByDate.keys.toList()..sort((a, b) => b.compareTo(a));
  }

  int get pendingCount => _allItems.where((i) => !i.completed).length;
  int get completedCount => _allItems.where((i) => i.completed).length;

  void initForUser(String userId, String activeListId) {
    if (_userId != userId) {
      _userId = userId;
      _subscribeToUserLists(userId);
    }
    init(activeListId);
  }

  void init(String listId) {
    if (_listId == listId) return;
    _listId = listId;
    _allItems = [];
    _members = [];
    _selectedCategory = 'All';
    _initialLoad = true;
    _subscribeToItems(listId);
    _subscribeToMembers(listId);
  }

  void _subscribeToUserLists(String userId) {
    _listsSub?.cancel();
    _listsSub = _service.watchUserLists(userId).listen(
      (lists) {
        _availableLists = lists;
        notifyListeners();
      },
      onError: (_) {},
    );
  }

  void _subscribeToItems(String listId) {
    _itemsSub?.cancel();
    _itemsSub = _service.watchItems(listId).listen(
      (items) {
        _allItems = items;
        _initialLoad = false;
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = 'Failed to load items: $e';
        notifyListeners();
      },
    );
  }

  void _subscribeToMembers(String listId) {
    _membersSub?.cancel();
    _membersSub = _service.watchMembers(listId).listen(
      (members) {
        _members = members;
        notifyListeners();
      },
      onError: (_) {},
    );
  }

  Future<void> switchList(String listId, String userId) async {
    if (_listId == listId) return;
    _listId = null;
    init(listId);
    notifyListeners();
    try {
      await _service.updateActiveList(userId, listId);
    } catch (_) {}
  }

  Future<String?> createSharedList({
    required String customName,
    required String ownerId,
    required String ownerName,
    required String ownerEmail,
    SubscriptionTier ownerTier = SubscriptionTier.free,
  }) async {
    _setLoading(true);
    try {
      final list = await _service.createSharedList(
        customName: customName,
        ownerId: ownerId,
        ownerName: ownerName,
        ownerEmail: ownerEmail,
        ownerTier: ownerTier,
      );
      _listId = null;
      init(list.id);
      await _service.updateActiveList(ownerId, list.id);
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    } finally {
      _setLoading(false);
    }
  }

  /// Deletes a shared list owned by the current user.
  ///
  /// Handles:
  /// - Ownership validation (delegated to repository)
  /// - Active list switching if deleted list is currently active
  /// - UI loading state
  /// - Error message display
  ///
  /// Returns null on success, error message string on failure.
  Future<String?> deleteSharedList({
    required String listId,
    required String userId,
  }) async {
    _setLoading(true);
    try {
      // Delete the list (repository validates ownership)
      await _service.deleteList(listId, userId);

      // If deleted list was active, switch to another list
      if (_listId == listId) {
        // Find next available list (personal list takes priority)
        final remaining =
            _availableLists.where((l) => l.id != listId).toList();

        if (remaining.isNotEmpty) {
          // Switch to first available list
          final nextListId = remaining.first.id;
          _listId = null;
          init(nextListId);
          await _service.updateActiveList(userId, nextListId);
        } else {
          // Edge case: No lists remaining
          _listId = null;
          _allItems = [];
          _members = [];
        }
      }

      return null; // Success
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    } finally {
      _setLoading(false);
    }
  }

  /// Renames a list owned by the current user.
  ///
  /// Handles:
  /// - Ownership validation (delegated to repository)
  /// - UI loading state
  /// - Error message display
  ///
  /// Returns null on success, error message string on failure.
  Future<String?> renameList({
    required String listId,
    required String newName,
    required String userId,
  }) async {
    _setLoading(true);
    try {
      await _service.updateListName(
        listId: listId,
        newName: newName,
        callerId: userId,
      );
      return null; // Success
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    } finally {
      _setLoading(false);
    }
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void toggleShowCompleted() {
    _showCompleted = !_showCompleted;
    notifyListeners();
  }

  Future<bool> addItem({
    required String name,
    required String category,
    required String addedBy,
    required String addedByName,
    String? notes,
    int? quantity,
    String? unit,
    String? inputMethod,
  }) async {
    try {
      await _service.addItem(
        listId: _listId!,
        name: name,
        category: category,
        addedBy: addedBy,
        addedByName: addedByName,
        notes: notes,
        quantity: quantity,
        unit: unit,
        inputMethod: inputMethod,
      );
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add item.';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> toggleComplete(ShoppingItem item, String userName) async {
    try {
      await _service.toggleItemCompletion(item, completedByName: userName);
    } catch (e) {
      _errorMessage = 'Failed to update item.';
      notifyListeners();
    }
  }

  Future<void> deleteItem(ShoppingItem item) async {
    try {
      await _service.deleteItem(item);
    } catch (e) {
      _errorMessage = 'Failed to delete item.';
      notifyListeners();
    }
  }

  Future<void> updateItemQuantity(ShoppingItem item, int quantity, String unit) async {
    try {
      await _service.updateItem(item.copyWith(quantity: quantity, unit: unit));
    } catch (e) {
      _errorMessage = 'Failed to update item.';
      notifyListeners();
    }
  }

  Future<void> deleteItemsBatch(List<String> ids) async {
    final toDelete = _allItems.where((i) => ids.contains(i.id)).toList();
    if (toDelete.isEmpty) return;
    _setLoading(true);
    try {
      await _service.deleteItemsBatch(toDelete);
    } catch (e) {
      _errorMessage = 'Failed to delete items.';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Move items to another list using a single Firestore batch write per
  /// operation (add batch + delete batch) instead of N×2 sequential writes.
  Future<String?> moveItemsToList({
    required List<String> itemIds,
    required String targetListId,
    required String movedBy,
    required String movedByName,
  }) async {
    final toMove = _allItems.where((i) => itemIds.contains(i.id)).toList();
    if (toMove.isEmpty) return null;
    _setLoading(true);
    try {
      await _service.addItemsBatch(
        items: toMove,
        targetListId: targetListId,
        addedBy: movedBy,
        addedByName: movedByName,
      );
      await _service.deleteItemsBatch(toMove);
      return null;
    } catch (e) {
      _errorMessage = 'Failed to move items.';
      notifyListeners();
      return e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ── Invite Members ────────────────────────────────────────────────────────

  Future<bool> inviteMember({
    required String email,
    required String displayName,
    required String invitedBy,
    required String invitedByName,
    SubscriptionTier ownerTier = SubscriptionTier.free,
  }) async {
    if (_listId == null) return false;
    _setLoading(true);
    try {
      await _service.addMember(
        listId: _listId!,
        email: email,
        displayName: displayName,
        invitedBy: invitedBy,
        invitedByName: invitedByName,
        ownerTier: ownerTier,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Subscribes the InviteScreen members stream to a specific list ID.
  /// Stores the subscription so it can be cancelled on re-call, preventing
  /// a memory leak. Overwrites [_members] so the InviteScreen card shows
  /// the correct member list for the expanded card.
  void subscribeToMembersForList(String listId) {
    _inviteScreenMembersSub?.cancel();
    _inviteScreenMembersSub = _service.watchMembers(listId).listen(
      (members) {
        _members = members;
        notifyListeners();
      },
      onError: (_) {},
    );
  }

  /// Cancels the InviteScreen members subscription and re-subscribes to
  /// the active list's members. Call this when InviteScreen is closed so
  /// [_members] reverts to the correct data for the active shopping list.
  void cancelInviteScreenMembersSubscription() {
    _inviteScreenMembersSub?.cancel();
    _inviteScreenMembersSub = null;
    if (_listId != null) {
      _subscribeToMembers(_listId!);
    }
  }

  Future<void> removeMember(Member member) async {
    try {
      await _service.removeMember(member);
    } catch (e) {
      _errorMessage = 'Failed to remove member.';
      notifyListeners();
    }
  }

  Future<String?> joinListById(
    String listId, {
    required String userId,
    required String displayName,
    required String email,
    String? photoUrl,
    SubscriptionTier joinerTier = SubscriptionTier.free,
  }) async {
    _setLoading(true);
    try {
      await _service.joinListById(
        listId: listId,
        userId: userId,
        displayName: displayName,
        email: email,
        photoUrl: photoUrl,
        joinerTier: joinerTier,
      );
      _listId = null;
      init(listId);
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  List<String> get categoryOptions => ['All', ...ItemCategory.all];

  // ── Invite methods ────────────────────────────────────────────────────────

  /// Starts a real-time stream of pending invites for [recipientEmail].
  /// Call once after login; the badge count updates automatically.
  void initInviteStream(String recipientEmail) {
    _inviteStreamSub?.cancel();
    _inviteStreamSub = _service
        .watchPendingInvitesForUser(recipientEmail)
        .listen(
      (invites) {
        _pendingInvites = invites;
        notifyListeners();
      },
      onError: (_) {},
    );
  }

  /// Cancels the invite stream. Call on logout / dispose.
  void disposeInviteStream() {
    _inviteStreamSub?.cancel();
    _inviteStreamSub = null;
    _pendingInvites = [];
    _joinedSharedLists = [];
  }

  /// Sends an email invitation from the current list owner.
  Future<String?> sendEmailInvite({
    required String listId,
    required String invitedByUid,
    required String invitedByName,
    required String invitedByEmail,
    required String recipientEmail,
    SubscriptionTier ownerTier = SubscriptionTier.free,
  }) async {
    _invitesLoading = true;
    notifyListeners();
    try {
      await _service.sendEmailInvite(
        listId: listId,
        invitedByUid: invitedByUid,
        invitedByName: invitedByName,
        invitedByEmail: invitedByEmail,
        recipientEmail: recipientEmail,
        ownerTier: ownerTier,
      );
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    } finally {
      _invitesLoading = false;
      notifyListeners();
    }
  }

  /// Accepts a pending invitation by inviteCode.
  Future<String?> acceptInvite({
    required String inviteCode,
    required String userId,
    required String displayName,
    String? photoUrl,
  }) async {
    _invitesLoading = true;
    notifyListeners();
    try {
      await _service.acceptInvitation(
        inviteCode: inviteCode,
        userId: userId,
        displayName: displayName,
        photoUrl: photoUrl,
      );
      _pendingInvites.removeWhere((i) => i['id'] == inviteCode);
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    } finally {
      _invitesLoading = false;
      notifyListeners();
    }
  }

  /// Declines a pending invitation.
  Future<String?> declineInvite(String inviteId) async {
    _invitesLoading = true;
    notifyListeners();
    try {
      await _service.declineInvite(inviteId);
      _pendingInvites.removeWhere((i) => i['id'] == inviteId);
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    } finally {
      _invitesLoading = false;
      notifyListeners();
    }
  }

  /// Loads shared lists the user has joined (is a member but not owner).
  Future<void> loadJoinedSharedLists(String userId) async {
    try {
      _joinedSharedLists = await _service.getJoinedSharedLists(userId);
      notifyListeners();
    } catch (_) {}
  }

  @override
  void dispose() {
    _itemsSub?.cancel();
    _membersSub?.cancel();
    _listsSub?.cancel();
    _inviteStreamSub?.cancel();
    _inviteScreenMembersSub?.cancel();
    super.dispose();
  }
}
