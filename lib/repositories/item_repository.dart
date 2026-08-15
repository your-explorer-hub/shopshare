import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../models/shopping_item.dart';
import '../utils/constants.dart';
import 'base_repository.dart';

/// Repository for shopping item operations (CRUD, batch operations).
///
/// Handles all Firestore interactions for shopping items including
/// individual operations and batch writes. Maintains sync with local
/// SQLite cache for offline support.
class ItemRepository extends BaseRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAnalytics _analytics;
  final Uuid _uuid;

  ItemRepository(this._firestore, this._analytics, this._uuid);

  /// Watches all items in a shopping list, ordered by most recent first.
  ///
  /// Returns a stream that emits the complete list of items whenever
  /// any item in the list changes. Stream never completes.
  Stream<List<ShoppingItem>> watchItems(String listId) {
    validateNonEmpty(listId, 'listId');

    return _firestore
        .collection(AppConstants.shoppingListsCollection)
        .doc(listId)
        .collection(AppConstants.itemsSubCollection)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ShoppingItem.fromFirestore(doc, listId))
            .toList());
  }

  /// Adds a new shopping item to Firestore and the local SQLite cache.
  ///
  /// [category] — single category string (existing callers, free tier).
  /// [categories] — optional list for multi-category (paid feature, future UI).
  ///   When [categories] is provided and non-empty it takes precedence over
  ///   [category]. When omitted, [category] is wrapped in a single-element list.
  ///   Both the new `categories` array and the legacy `category` string are
  ///   written to Firestore so older app versions remain compatible.
  ///
  /// Returns the created [ShoppingItem] with generated ID and timestamp.
  Future<ShoppingItem> addItem({
    required String listId,
    required String name,
    required String category,
    required String addedBy,
    required String addedByName,
    String? notes,
    int? quantity,
    String? unit,
    String? inputMethod,
    List<String>? categories, // paid-feature: multi-category support
  }) async {
    validateNonEmpty(listId, 'listId');
    validateNonEmpty(name, 'name');
    validateNonEmpty(category, 'category');
    validateNonEmpty(addedBy, 'addedBy');
    validateNonEmpty(addedByName, 'addedByName');

    // Resolve the effective category list.
    // If caller supplies `categories` (paid tier, future UI), use it.
    // Otherwise fall back to the single `category` string (free tier / current UI).
    final resolvedCategories =
        (categories != null && categories.isNotEmpty) ? categories : [category];

    final id = _uuid.v4();
    final now = DateTime.now();
    final item = ShoppingItem(
      id: id,
      listId: listId,
      name: name,
      categories: resolvedCategories,
      addedBy: addedBy,
      addedByName: addedByName,
      addedAt: now,
      notes: notes,
      quantity: quantity,
      unit: unit,
      inputMethod: inputMethod ?? 'manual',
    );

    final itemData = item.toFirestore()
      ..['platform'] = defaultTargetPlatform.name; // android | iOS | windows | macOS | linux

    await _firestore
        .collection(AppConstants.shoppingListsCollection)
        .doc(listId)
        .collection(AppConstants.itemsSubCollection)
        .doc(id)
        .set(itemData);

    await AppDatabase.instance.upsertItem(item);

    _analytics.logEvent(name: 'item_added', parameters: {
      'category': item.category, // primary category for analytics
      'input_method': inputMethod ?? 'manual',
      'has_notes': notes != null ? 1 : 0,
      'has_quantity': quantity != null ? 1 : 0,
      'category_count': resolvedCategories.length,
      'platform': defaultTargetPlatform.name,
    }).catchError((_) {});

    return item;
  }

  /// Toggles the completion status of an item.
  ///
  /// Updates both Firestore and local SQLite cache. Sets/clears
  /// `completedAt` timestamp and `completedByName` accordingly.
  Future<void> toggleItemCompletion(
    ShoppingItem item, {
    required String completedByName,
  }) async {
    validateNonEmpty(completedByName, 'completedByName');

    final now = DateTime.now();
    final newCompleted = !item.completed;

    await _firestore
        .collection(AppConstants.shoppingListsCollection)
        .doc(item.listId)
        .collection(AppConstants.itemsSubCollection)
        .doc(item.id)
        .update({
      'completed': newCompleted,
      'completedAt': newCompleted ? Timestamp.fromDate(now) : null,
      'completedByName': newCompleted ? completedByName : null,
    });

    await AppDatabase.instance.updateItemCompletion(
      item.id,
      completed: newCompleted,
      completedAt: newCompleted ? now : null,
      completedByName: newCompleted ? completedByName : null,
    );
  }

  /// Deletes a single item from Firestore and local cache.
  Future<void> deleteItem(ShoppingItem item) async {
    await _firestore
        .collection(AppConstants.shoppingListsCollection)
        .doc(item.listId)
        .collection(AppConstants.itemsSubCollection)
        .doc(item.id)
        .delete();

    await AppDatabase.instance.deleteItem(item.id);
  }

  /// Deletes multiple items in a single Firestore batch write.
  ///
  /// More efficient than individual deletes for bulk operations.
  /// Local cache is updated after batch commit succeeds.
  Future<void> deleteItemsBatch(List<ShoppingItem> items) async {
    if (items.isEmpty) return;

    final batch = _firestore.batch();
    for (final item in items) {
      batch.delete(_firestore
          .collection(AppConstants.shoppingListsCollection)
          .doc(item.listId)
          .collection(AppConstants.itemsSubCollection)
          .doc(item.id));
    }

    await batch.commit();

    for (final item in items) {
      await AppDatabase.instance.deleteItem(item.id);
    }
  }

  /// Adds multiple items to [targetListId] in a single Firestore batch write.
  ///
  /// Used by move operations to replace N sequential addItem calls with
  /// one atomic commit. Local cache is updated after batch succeeds.
  Future<void> addItemsBatch({
    required List<ShoppingItem> items,
    required String targetListId,
    required String addedBy,
    required String addedByName,
  }) async {
    if (items.isEmpty) return;

    validateNonEmpty(targetListId, 'targetListId');
    validateNonEmpty(addedBy, 'addedBy');
    validateNonEmpty(addedByName, 'addedByName');

    final batch = _firestore.batch();
    final now = DateTime.now();
    final newItems = <ShoppingItem>[];

    for (final item in items) {
      final id = _uuid.v4();
      final newItem = ShoppingItem(
        id: id,
        listId: targetListId,
        name: item.name,
        categories: item.categories,
        addedBy: addedBy,
        addedByName: addedByName,
        addedAt: now,
        notes: item.notes,
        quantity: item.quantity,
        unit: item.unit,
      );

      batch.set(
        _firestore
            .collection(AppConstants.shoppingListsCollection)
            .doc(targetListId)
            .collection(AppConstants.itemsSubCollection)
            .doc(id),
        newItem.toFirestore(),
      );

      newItems.add(newItem);
    }

    await batch.commit();

    // Cache locally after the batch succeeds
    for (final item in newItems) {
      await AppDatabase.instance.upsertItem(item);
    }
  }

  /// Updates an existing item's properties.
  ///
  /// Writes to both Firestore and local SQLite cache.
  Future<void> updateItem(ShoppingItem item) async {
    await _firestore
        .collection(AppConstants.shoppingListsCollection)
        .doc(item.listId)
        .collection(AppConstants.itemsSubCollection)
        .doc(item.id)
        .update(item.toFirestore());

    await AppDatabase.instance.upsertItem(item);
  }
}
