import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/shopping_list.dart';
import '../utils/constants.dart';
import 'base_repository.dart';
import 'list_repository.dart';

/// Repository for user profile operations.
///
/// Handles user document creation, retrieval, updates, and account deletion.
/// Ensures every user has a personal shopping list.
class UserRepository extends BaseRepository {
  final FirebaseFirestore _firestore;
  final Uuid _uuid;
  final ListRepository _listRepository;

  UserRepository(this._firestore, this._uuid, this._listRepository);

  /// Creates or updates a user profile document.
  ///
  /// Merges new data with existing document, preserving other fields.
  /// Tracks platform and update timestamp.
  Future<void> upsertUserProfile({
    required String userId,
    required String email,
    required String displayName,
    String? photoUrl,
  }) async {
    validateNonEmpty(userId, 'userId');
    validateNonEmpty(email, 'email');
    validateNonEmpty(displayName, 'displayName');

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .set({
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'platform': defaultTargetPlatform.name,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Retrieves a user's profile document.
  ///
  /// Returns null if user document doesn't exist.
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    validateNonEmpty(userId, 'userId');

    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .get();

    return doc.data();
  }

  /// Ensures user has a personal list, creating one if needed.
  ///
  /// Checks for existing personal list first. If none exists, creates
  /// a new personal list with owner member record and updates user's listId.
  ///
  /// Returns the personal list (existing or newly created).
  Future<ShoppingList> ensurePersonalList({
    required String userId,
    required String displayName,
    required String email,
  }) async {
    validateNonEmpty(userId, 'userId');
    validateNonEmpty(displayName, 'displayName');
    validateNonEmpty(email, 'email');

    final existing = await _firestore
        .collection(AppConstants.shoppingListsCollection)
        .where('ownerId', isEqualTo: userId)
        .where('type', isEqualTo: 'personal')
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return ShoppingList.fromFirestore(existing.docs.first);
    }

    final listId = _uuid.v4();
    final now = DateTime.now();
    final list = ShoppingList(
      id: listId,
      name: 'My List',
      ownerId: userId,
      ownerName: displayName,
      memberIds: [userId],
      createdAt: now,
      type: 'personal',
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
            .doc(userId),
        {
          'userId': userId,
          'email': email,
          'displayName': displayName,
          'role': 'owner',
          'status': MemberStatus.accepted,
          'invitedAt': Timestamp.fromDate(now),
          'invitedBy': userId,
          'invitedByName': displayName,
        });

    batch.update(
        _firestore.collection(AppConstants.usersCollection).doc(userId),
        {'listId': listId});

    await batch.commit();

    return list;
  }

  /// Deletes a user account and all associated data.
  ///
  /// Cascade deletes:
  /// - All lists owned by user (items + members)
  /// - User's membership in shared lists
  /// - Pending invitations sent to user's email
  /// - User profile document
  ///
  /// WARNING: Permanent deletion with no undo.
  Future<void> deleteUserAccount(String userId) async {
    validateNonEmpty(userId, 'userId');

    // Delete all lists owned by user
    final ownedLists = await _firestore
        .collection(AppConstants.shoppingListsCollection)
        .where('ownerId', isEqualTo: userId)
        .get();

    for (final listDoc in ownedLists.docs) {
      await _listRepository.deleteList(listDoc.id, userId);
    }

    // Remove user from shared lists they're a member of
    final joinedLists = await _firestore
        .collection(AppConstants.shoppingListsCollection)
        .where('memberIds', arrayContains: userId)
        .get();

    for (final listDoc in joinedLists.docs) {
      final membersSnap = await listDoc.reference
          .collection('members')
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();

      for (final memberDoc in membersSnap.docs) {
        batch.delete(memberDoc.reference);
      }

      batch.update(
        listDoc.reference,
        {'memberIds': FieldValue.arrayRemove([userId])},
      );

      await batch.commit();
    }

    // Delete user profile document
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .delete();
  }
}
