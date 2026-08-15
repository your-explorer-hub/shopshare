import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../models/shopping_list.dart';
import '../utils/constants.dart';
import '../utils/subscription_limits.dart';
import 'base_repository.dart';

/// Repository for shopping list operations (create, delete, leave).
///
/// Handles list lifecycle management including subscription tier limits,
/// owner validation, and cascade deletes of items/members.
class ListRepository extends BaseRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAnalytics _analytics;
  final Uuid _uuid;

  ListRepository(this._firestore, this._analytics, this._uuid);

  /// Watches all lists where the user is a member.
  ///
  /// Returns personal list first, then shared lists alphabetically.
  Stream<List<ShoppingList>> watchUserLists(String userId) {
    validateNonEmpty(userId, 'userId');

    return _firestore
        .collection(AppConstants.shoppingListsCollection)
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ShoppingList.fromFirestore(d))
            .toList()
          ..sort((a, b) {
            if (a.isPersonal != b.isPersonal) return a.isPersonal ? -1 : 1;
            return a.name.compareTo(b.name);
          }));
  }

  /// Creates a new shared list.
  ///
  /// Validates owner hasn't exceeded their tier's list limit.
  /// Creates list document, owner member record, and updates user's active list.
  Future<ShoppingList> createSharedList({
    required String customName,
    required String ownerId,
    required String ownerName,
    required String ownerEmail,
    SubscriptionTier ownerTier = SubscriptionTier.free,
  }) async {
    validateNonEmpty(customName, 'customName');
    validateNonEmpty(ownerId, 'ownerId');
    validateNonEmpty(ownerName, 'ownerName');
    validateNonEmpty(ownerEmail, 'ownerEmail');

    final maxOwned = SubscriptionLimits.maxOwnedSharedLists(ownerTier);
    final existing = await _firestore
        .collection(AppConstants.shoppingListsCollection)
        .where('ownerId', isEqualTo: ownerId)
        .where('type', isEqualTo: 'shared')
        .get();

    if (existing.docs.length >= maxOwned) {
      throw Exception(
          'You already own $maxOwned shared list(s), the limit for '
          '${SubscriptionLimits.tierDisplayName(ownerTier)}. Upgrade to create more.');
    }

    final listId = _uuid.v4();
    final now = DateTime.now();
    final list = ShoppingList(
      id: listId,
      name: customName,
      ownerId: ownerId,
      ownerName: ownerName,
      memberIds: [ownerId],
      createdAt: now,
      type: 'shared',
    );

    final batch = _firestore.batch();

    batch.set(
        _firestore
            .collection(AppConstants.shoppingListsCollection)
            .doc(listId),
        list.toFirestore());

    batch.set(
        _firestore
            .collection(AppConstants.shoppingListsCollection)
            .doc(listId)
            .collection('members')
            .doc(ownerId),
        {
          'userId': ownerId,
          'email': ownerEmail,
          'displayName': ownerName,
          'role': 'owner',
          'status': MemberStatus.accepted,
          'invitedAt': Timestamp.fromDate(now),
          'invitedBy': ownerId,
          'invitedByName': ownerName,
        });

    batch.update(
        _firestore.collection(AppConstants.usersCollection).doc(ownerId),
        {'listId': listId});

    await batch.commit();

    _analytics.logEvent(name: 'shared_list_created').catchError((_) {});

    return list;
  }

  /// Deletes a shared list owned by the caller.
  ///
  /// Validates:
  /// - List exists
  /// - Caller is the owner
  /// - List type is 'shared' (personal lists cannot be deleted)
  ///
  /// Cascade deletes:
  /// - Items subcollection
  /// - Members subcollection
  /// - Invitations in top-level collection
  /// - User active list references
  /// - List document
  /// - Local SQLite cache (items, members, invitations)
  ///
  /// Returns the deleted list's owner ID for active list switching logic.
  /// Throws Exception if validation fails.
  Future<String> deleteList(String listId, String callerId) async {
    validateNonEmpty(listId, 'listId');
    validateNonEmpty(callerId, 'callerId');

    // Fetch list document and validate
    final listDoc = await _firestore
        .collection(AppConstants.shoppingListsCollection)
        .doc(listId)
        .get();

    if (!listDoc.exists) {
      throw Exception('List not found');
    }

    final listData = listDoc.data()!;
    final ownerId = listData['ownerId'] as String;
    final type = listData['type'] as String;

    // Ownership validation
    if (callerId != ownerId) {
      throw Exception('Only the list owner can delete this list');
    }

    // Personal list protection
    if (type == 'personal') {
      throw Exception('Personal lists cannot be deleted');
    }

    // Parallel fetch for performance (4 queries)
    final results = await Future.wait([
      _firestore
          .collection(AppConstants.shoppingListsCollection)
          .doc(listId)
          .collection(AppConstants.itemsSubCollection)
          .get(),
      _firestore
          .collection(AppConstants.shoppingListsCollection)
          .doc(listId)
          .collection('members')
          .get(),
      _firestore
          .collection(AppConstants.invitationsCollection)
          .where('listId', isEqualTo: listId)
          .get(),
      _firestore
          .collection(AppConstants.usersCollection)
          .where('listId', isEqualTo: listId)
          .get(),
    ]);

    final itemsSnap = results[0];
    final membersSnap = results[1];
    final invitationsSnap = results[2];
    final usersWithThisListSnap = results[3];

    final batch = _firestore.batch();

    // Delete all items
    for (final doc in itemsSnap.docs) {
      batch.delete(doc.reference);
    }

    // Delete all members
    for (final doc in membersSnap.docs) {
      batch.delete(doc.reference);
    }

    // Delete all invitations (FIXES ORPHAN ISSUE #1)
    for (final doc in invitationsSnap.docs) {
      batch.delete(doc.reference);
    }

    // Clear listId from user profiles (FIXES ORPHAN ISSUE #2)
    for (final doc in usersWithThisListSnap.docs) {
      batch.update(doc.reference, {'listId': null});
    }

    // Delete the list itself
    batch.delete(listDoc.reference);

    await batch.commit();

    // Clean up local SQLite - ALL related data
    await AppDatabase.instance.deleteAllItemsForList(listId);
    await AppDatabase.instance.deleteMembersForList(listId);
    await AppDatabase.instance.deleteInvitationsForList(listId);
    await AppDatabase.instance.clearAll();

    return ownerId;
  }

  /// Updates the name of a shared list.
  ///
  /// Validates:
  /// - List exists
  /// - Caller is the owner
  /// - New name is not empty
  ///
  /// Returns void on success.
  /// Throws Exception if validation fails.
  Future<void> updateListName({
    required String listId,
    required String newName,
    required String callerId,
  }) async {
    validateNonEmpty(listId, 'listId');
    validateNonEmpty(newName, 'newName');
    validateNonEmpty(callerId, 'callerId');

    // Fetch list document and validate
    final listDoc = await _firestore
        .collection(AppConstants.shoppingListsCollection)
        .doc(listId)
        .get();

    if (!listDoc.exists) {
      throw Exception('List not found');
    }

    final listData = listDoc.data()!;
    final ownerId = listData['ownerId'] as String;

    // Ownership validation
    if (callerId != ownerId) {
      throw Exception('Only the list owner can rename this list');
    }

    // Update Firestore
    await _firestore
        .collection(AppConstants.shoppingListsCollection)
        .doc(listId)
        .update({'name': newName});

    // Analytics
    _analytics.logEvent(name: 'list_renamed').catchError((_) {});
  }

  /// Removes the user from a shared list.
  ///
  /// Deletes member record and removes userId from list's memberIds array.
  Future<void> leaveList({
    required String listId,
    required String userId,
    required String memberId,
  }) async {
    validateNonEmpty(listId, 'listId');
    validateNonEmpty(userId, 'userId');
    validateNonEmpty(memberId, 'memberId');

    final batch = _firestore.batch();

    batch.delete(_firestore
        .collection(AppConstants.shoppingListsCollection)
        .doc(listId)
        .collection('members')
        .doc(memberId));

    batch.update(
        _firestore
            .collection(AppConstants.shoppingListsCollection)
            .doc(listId),
        {'memberIds': FieldValue.arrayRemove([userId])});

    await batch.commit();
    await AppDatabase.instance.deleteMember(memberId);
  }

  /// Updates the user's currently active list.
  ///
  /// Sets the user's listId field in Firestore users collection.
  Future<void> updateActiveList(String userId, String listId) async {
    validateNonEmpty(userId, 'userId');
    validateNonEmpty(listId, 'listId');

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({'listId': listId});
  }

  /// Gets all shared lists where user is a non-owner member.
  ///
  /// Used for checking subscription tier limits.
  Future<List<ShoppingList>> getJoinedSharedLists(String userId) async {
    validateNonEmpty(userId, 'userId');

    final snap = await _firestore
        .collection(AppConstants.shoppingListsCollection)
        .where('type', isEqualTo: 'shared')
        .where('memberIds', arrayContains: userId)
        .get();

    return snap.docs
        .map((d) => ShoppingList.fromFirestore(d))
        .where((list) => list.ownerId != userId)
        .toList();
  }
}
