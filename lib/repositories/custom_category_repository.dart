import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../models/custom_category.dart';
import '../models/category_item.dart';
import '../utils/subscription_limits.dart';

/// Repository for custom category and category item operations.
/// Handles Firestore sync, SQLite caching, and business logic.
class CustomCategoryRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAnalytics _analytics;
  final Uuid _uuid;
  final AppDatabase _database = AppDatabase.instance;

  CustomCategoryRepository(this._firestore, this._analytics, this._uuid);

  // ═══════════════════════════════════════════════════════════════════════════
  // Custom Category Operations
  // ═══════════════════════════════════════════════════════════════════════════

  /// Watch all custom categories for a user (real-time stream).
  Stream<List<CustomCategory>> watchCategories(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('custom_categories')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final categories =
          snapshot.docs.map((doc) => CustomCategory.fromFirestore(doc)).toList();

      // Cache to SQLite in background
      _cacheCategories(categories);

      return categories;
    });
  }

  /// Create a new custom category with auto-assigned emoji and color.
  Future<CustomCategory> createCategory(
    String userId,
    String name, {
    required int existingCount,
  }) async {
    final categoryId = _uuid.v4();
    final now = DateTime.now();

    // Auto-assign emoji and color based on existing count
    final emoji = _assignEmoji(existingCount);
    final colorHex = _assignColor(existingCount);

    final category = CustomCategory(
      id: categoryId,
      userId: userId,
      name: name,
      emoji: emoji,
      colorHex: colorHex,
      createdAt: now,
      itemCount: 0,
    );

    // Write to Firestore
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('custom_categories')
        .doc(categoryId)
        .set(category.toFirestore());

    // Cache to SQLite
    await _database.upsertCustomCategory(category);

    // Analytics
    await _analytics.logEvent(
      name: 'custom_category_created',
      parameters: {'category_name': name},
    );

    return category;
  }

  /// Update a custom category (rename).
  Future<void> updateCategory(CustomCategory category) async {
    final updated = category.copyWith(updatedAt: DateTime.now());

    await _firestore
        .collection('users')
        .doc(category.userId)
        .collection('custom_categories')
        .doc(category.id)
        .update(updated.toFirestore());

    await _database.upsertCustomCategory(updated);
  }

  /// Delete a custom category and all its items (cascade).
  Future<void> deleteCategory(String categoryId, String userId) async {
    // Delete from Firestore (subcollection items are NOT auto-deleted, must delete manually)
    final categoryRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('custom_categories')
        .doc(categoryId);

    // Delete all items in subcollection
    final itemsSnapshot = await categoryRef.collection('items').get();
    final batch = _firestore.batch();
    for (final doc in itemsSnapshot.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(categoryRef);
    await batch.commit();

    // Delete from SQLite (cascade delete via foreign key)
    await _database.deleteCustomCategory(categoryId);

    // Analytics
    await _analytics.logEvent(
      name: 'custom_category_deleted',
      parameters: {'item_count': itemsSnapshot.docs.length},
    );
  }

  /// Check if user can create another category (tier limit).
  Future<bool> canCreateCategory(String userId, SubscriptionTier tier) async {
    final categories = await _database.getCustomCategoriesForUser(userId);
    return categories.length < SubscriptionLimits.maxCustomCategories(tier);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Category Item Operations
  // ═══════════════════════════════════════════════════════════════════════════

  /// Watch all items in a category (real-time stream).
  Stream<List<CategoryItem>> watchCategoryItems(
      String categoryId, String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('custom_categories')
        .doc(categoryId)
        .collection('items')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map((doc) => CategoryItem.fromFirestore(doc, categoryId, userId))
          .toList();

      // Cache to SQLite in background
      _cacheItems(items);

      // Update category item count
      _updateCategoryItemCount(categoryId, userId, items.length);

      return items;
    });
  }

  /// Add a new item to a category.
  Future<CategoryItem> addItem({
    required String categoryId,
    required String userId,
    required String name,
    String? notes,
    int? quantity,
    String? unit,
  }) async {
    final itemId = _uuid.v4();
    final now = DateTime.now();

    final item = CategoryItem(
      id: itemId,
      categoryId: categoryId,
      userId: userId,
      name: name,
      notes: notes,
      quantity: quantity,
      unit: unit,
      createdAt: now,
    );

    // Write to Firestore
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('custom_categories')
        .doc(categoryId)
        .collection('items')
        .doc(itemId)
        .set(item.toFirestore());

    // Cache to SQLite
    await _database.upsertCategoryItem(item);

    // Update item count
    final count = await _database.getCategoryItemCount(categoryId);
    await _database.updateCustomCategoryItemCount(categoryId, count);

    // Analytics
    await _analytics.logEvent(name: 'category_item_added');

    return item;
  }

  /// Update a category item.
  Future<void> updateItem(CategoryItem item) async {
    await _firestore
        .collection('users')
        .doc(item.userId)
        .collection('custom_categories')
        .doc(item.categoryId)
        .collection('items')
        .doc(item.id)
        .update(item.toFirestore());

    await _database.upsertCategoryItem(item);
  }

  /// Delete a category item.
  Future<void> deleteItem(String itemId, String categoryId, String userId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('custom_categories')
        .doc(categoryId)
        .collection('items')
        .doc(itemId)
        .delete();

    await _database.deleteCategoryItem(itemId);

    // Update item count
    final count = await _database.getCategoryItemCount(categoryId);
    await _database.updateCustomCategoryItemCount(categoryId, count);
  }

  /// Check if user can add another item to category (tier limit).
  Future<bool> canAddItem(
      String categoryId, String userId, SubscriptionTier tier) async {
    final items = await _database.getCategoryItems(categoryId);
    return items.length < SubscriptionLimits.maxItemsPerCategory(tier);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Batch Operations (Copy to Shopping List)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Copy category items to a shopping list.
  /// Returns the number of items copied.
  Future<int> copyItemsToList({
    required List<CategoryItem> items,
    required String targetListId,
    required String userId,
    required String displayName,
  }) async {
    if (items.isEmpty) return 0;

    final batch = _firestore.batch();
    final now = DateTime.now();

    for (final item in items) {
      final newItemId = _uuid.v4();
      final itemRef = _firestore
          .collection('shopping_lists')
          .doc(targetListId)
          .collection('items')
          .doc(newItemId);

      batch.set(itemRef, {
        'name': item.name,
        'category': 'Other', // Default category
        'categories': ['Other'], // Default category array
        'notes': item.notes,
        'quantity': item.quantity,
        'unit': item.unit,
        'addedBy': userId,
        'addedByName': displayName,
        'addedAt': Timestamp.fromDate(now),
        'completed': false,
        'completedAt': null,
        'completedByName': null,
        'inputMethod': 'manual',
      });
    }

    await batch.commit();

    // Analytics
    await _analytics.logEvent(
      name: 'category_items_copied',
      parameters: {'item_count': items.length, 'target_list': targetListId},
    );

    return items.length;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Private Helpers
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _cacheCategories(List<CustomCategory> categories) async {
    for (final category in categories) {
      await _database.upsertCustomCategory(category);
    }
  }

  Future<void> _cacheItems(List<CategoryItem> items) async {
    for (final item in items) {
      await _database.upsertCategoryItem(item);
    }
  }

  Future<void> _updateCategoryItemCount(
      String categoryId, String userId, int count) async {
    // Update Firestore
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('custom_categories')
        .doc(categoryId)
        .update({
      'itemCount': count,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });

    // Update SQLite cache
    await _database.updateCustomCategoryItemCount(categoryId, count);
  }

  /// Auto-assign emoji based on category index.
  String _assignEmoji(int index) {
    const emojis = [
      '🎄', '🪔', '🎂', '🎉', '🎁',
      '🏖️', '🏡', '🚗', '✈️', '🏥',
      '🎓', '⚽', '🎵', '📚', '🍕',
    ];
    return emojis[index % emojis.length];
  }

  /// Auto-assign color based on category index.
  String _assignColor(int index) {
    const colors = [
      '#9C27B0', // Purple
      '#00897B', // Teal
      '#E91E63', // Pink
      '#3F51B5', // Indigo
      '#FF5722', // Deep Orange
      '#009688', // Teal (darker)
      '#673AB7', // Deep Purple
      '#FF9800', // Orange
      '#4CAF50', // Green
      '#F44336', // Red
    ];
    return colors[index % colors.length];
  }
}
