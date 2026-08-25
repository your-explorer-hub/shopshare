import 'dart:async';

import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import '../models/custom_category.dart';
import '../models/category_item.dart';
import '../services/firestore_service.dart';
import '../utils/subscription_limits.dart';

/// Provider for managing custom categories and their items.
/// Handles real-time sync, caching, and tier-based limits.
class CustomCategoriesProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService.instance;

  String? _userId;
  SubscriptionTier _userTier = SubscriptionTier.free;

  List<CustomCategory> _categories = [];
  Map<String, List<CategoryItem>> _itemsByCategory = {};

  StreamSubscription? _categoriesSubscription;
  final Map<String, StreamSubscription> _itemSubscriptions = {};

  bool _isLoading = false;
  String? _error;

  // ═══════════════════════════════════════════════════════════════════════════
  // Getters
  // ═══════════════════════════════════════════════════════════════════════════

  List<CustomCategory> get categories => _categories;
  List<CategoryItem> itemsForCategory(String categoryId) =>
      _itemsByCategory[categoryId] ?? [];
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get canCreateMore => _canCreateCategory();
  bool canAddMoreItems(String categoryId) => _canAddItem(categoryId);
  int get maxCategories => SubscriptionLimits.maxCustomCategories(_userTier);
  int get maxItemsPerCategory =>
      SubscriptionLimits.maxItemsPerCategory(_userTier);
  SubscriptionTier get tier => _userTier;

  // ═══════════════════════════════════════════════════════════════════════════
  // Initialization
  // ═══════════════════════════════════════════════════════════════════════════

  void initForUser(String userId, SubscriptionTier tier) {
    if (_userId == userId && _userTier == tier) return;

    _userId = userId;
    _userTier = tier;
    _categories = [];
    _itemsByCategory = {};
    _error = null;
    _isLoading = true;

    _categoriesSubscription?.cancel();
    _cancelAllItemSubscriptions();

    // Start watching categories
    _categoriesSubscription = _firestore.watchCustomCategories(userId).listen(
      (categories) {
        _categories = categories;
        _isLoading = false;
        _error = null;

        // Start watching items for each category
        for (final category in categories) {
          _watchCategoryItems(category.id);
        }

        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        _isLoading = false;
        debugPrint('Error watching categories: $error');
        notifyListeners();
      },
    );

    notifyListeners();
  }

  @override
  void dispose() {
    _categoriesSubscription?.cancel();
    _cancelAllItemSubscriptions();
    super.dispose();
  }

  void _cancelAllItemSubscriptions() {
    for (final sub in _itemSubscriptions.values) {
      sub.cancel();
    }
    _itemSubscriptions.clear();
  }

  void _watchCategoryItems(String categoryId) {
    if (_itemSubscriptions.containsKey(categoryId)) return;
    if (_userId == null) return;

    _itemSubscriptions[categoryId] =
        _firestore.watchCategoryItems(categoryId, _userId!).listen(
      (items) {
        _itemsByCategory[categoryId] = items;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error watching items for category $categoryId: $error');
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Category Operations
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> createCategory(String name) async {
    if (_userId == null) {
      _error = 'User not initialized';
      notifyListeners();
      return;
    }

    if (!_canCreateCategory()) {
      _error = 'Category limit reached for ${SubscriptionLimits.tierDisplayName(_userTier)}';
      notifyListeners();
      return;
    }

    try {
      await _firestore.createCustomCategory(
        _userId!,
        name,
        existingCount: _categories.length,
      );
      _error = null;
    } catch (e) {
      _error = 'Failed to create category: $e';
      debugPrint(_error);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateCategory(CustomCategory category) async {
    try {
      await _firestore.updateCustomCategory(category);
      _error = null;
    } catch (e) {
      _error = 'Failed to update category: $e';
      debugPrint(_error);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    if (_userId == null) {
      _error = 'User not initialized';
      notifyListeners();
      return;
    }

    try {
      // Cancel item subscription for this category
      _itemSubscriptions[categoryId]?.cancel();
      _itemSubscriptions.remove(categoryId);
      _itemsByCategory.remove(categoryId);

      await _firestore.deleteCustomCategory(categoryId, _userId!);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete category: $e';
      debugPrint(_error);
      notifyListeners();
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Item Operations
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> addItem({
    required String categoryId,
    required String name,
    String? notes,
    int? quantity,
    String? unit,
  }) async {
    if (_userId == null) {
      _error = 'User not initialized';
      notifyListeners();
      return;
    }

    if (!_canAddItem(categoryId)) {
      _error = 'Item limit reached for ${SubscriptionLimits.tierDisplayName(_userTier)}';
      notifyListeners();
      return;
    }

    try {
      await _firestore.addCategoryItem(
        categoryId: categoryId,
        userId: _userId!,
        name: name,
        notes: notes,
        quantity: quantity,
        unit: unit,
      );
      _error = null;
    } catch (e) {
      _error = 'Failed to add item: $e';
      debugPrint(_error);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateItem(CategoryItem item) async {
    try {
      await _firestore.updateCategoryItem(item);
      _error = null;
    } catch (e) {
      _error = 'Failed to update item: $e';
      debugPrint(_error);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteItem(String itemId, String categoryId) async {
    if (_userId == null) {
      _error = 'User not initialized';
      notifyListeners();
      return;
    }

    try {
      await _firestore.deleteCategoryItem(itemId, categoryId, _userId!);
      _error = null;
    } catch (e) {
      _error = 'Failed to delete item: $e';
      debugPrint(_error);
      notifyListeners();
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Copy to List
  // ═══════════════════════════════════════════════════════════════════════════

  Future<int> copyItemsToList({
    required List<CategoryItem> items,
    required String targetListId,
    required String displayName,
  }) async {
    if (_userId == null) {
      _error = 'User not initialized';
      notifyListeners();
      return 0;
    }

    try {
      final count = await _firestore.copyCategoryItemsToList(
        items: items,
        targetListId: targetListId,
        userId: _userId!,
        displayName: displayName,
      );
      _error = null;
      return count;
    } catch (e) {
      _error = 'Failed to copy items: $e';
      debugPrint(_error);
      notifyListeners();
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Private Helpers
  // ═══════════════════════════════════════════════════════════════════════════

  bool _canCreateCategory() {
    return _categories.length < SubscriptionLimits.maxCustomCategories(_userTier);
  }

  bool _canAddItem(String categoryId) {
    final items = _itemsByCategory[categoryId] ?? [];
    return items.length < SubscriptionLimits.maxItemsPerCategory(_userTier);
  }
}
