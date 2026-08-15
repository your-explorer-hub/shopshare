import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../models/member.dart';
import '../utils/constants.dart';
import '../utils/subscription_limits.dart';
import 'base_repository.dart';

/// Repository for member management operations.
///
/// Handles member invitations, acceptance, removal, and watches
/// member changes for shared lists. Enforces subscription tier limits.
class MemberRepository extends BaseRepository {
  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  MemberRepository(this._firestore, this._uuid);

  /// Watches all members of a shared list.
  ///
  /// Returns a stream that emits the complete list of members whenever
  /// any member changes. Deduplicates by email (case-insensitive).
  Stream<List<Member>> watchMembers(String listId) {
    validateNonEmpty(listId, 'listId');

    return _firestore
        .collection(AppConstants.shoppingListsCollection)
        .doc(listId)
        .collection('members')
        .snapshots()
        .map((snap) {
      final seen = <String>{};
      final result = <Member>[];
      for (final doc in snap.docs) {
        final member = Member.fromFirestore(doc, listId);
        if (seen.add(member.email.toLowerCase())) result.add(member);
      }
      return result;
    });
  }

  /// Adds a new member invitation to a shared list.
  ///
  /// Validates:
  /// - Only list owner can invite
  /// - Owner hasn't exceeded member limit for their tier
  /// - Invitee hasn't exceeded joined list limit for their tier
  /// - Email not already invited/member
  ///
  /// Creates both a member document (pending status) and an invitation record.
  Future<Member> addMember({
    required String listId,
    required String email,
    required String displayName,
    required String invitedBy,
    required String invitedByName,
    SubscriptionTier ownerTier = SubscriptionTier.free,
    SubscriptionTier inviteeTier = SubscriptionTier.free,
    String? inviteeUserId,
  }) async {
    validateNonEmpty(listId, 'listId');
    validateNonEmpty(email, 'email');
    validateNonEmpty(displayName, 'displayName');
    validateNonEmpty(invitedBy, 'invitedBy');
    validateNonEmpty(invitedByName, 'invitedByName');

    final listDoc = await _firestore
        .collection(AppConstants.shoppingListsCollection)
        .doc(listId)
        .get();

    if (!listDoc.exists) throw Exception('List not found.');

    final ownerId = listDoc.data()!['ownerId'] as String? ?? '';
    if (invitedBy != ownerId) {
      throw Exception('Only the list owner can invite new members.');
    }

    // Check owner's member limit
    final maxMembers = SubscriptionLimits.maxMembersPerList(ownerTier);
    final currentMembers = await _firestore
        .collection(AppConstants.shoppingListsCollection)
        .doc(listId)
        .collection('members')
        .get();

    if (currentMembers.docs.length >= maxMembers) {
      throw Exception(
          'This list already has $maxMembers members, which is the limit for the '
          '${SubscriptionLimits.tierDisplayName(ownerTier)}. '
          'Upgrade your plan to add more members.');
    }

    // Check invitee's joined list limit (if userId known)
    if (inviteeUserId != null) {
      final maxJoined = SubscriptionLimits.maxJoinedSharedLists(inviteeTier);
      final joined = await _firestore
          .collection(AppConstants.shoppingListsCollection)
          .where('type', isEqualTo: 'shared')
          .where('memberIds', arrayContains: inviteeUserId)
          .get();

      final nonOwner = joined.docs
          .where((d) => (d.data()['ownerId'] as String?) != inviteeUserId)
          .length;

      if (nonOwner >= maxJoined) {
        throw Exception(
            'This person has already joined $maxJoined shared lists, '
            'which is the limit for the '
            '${SubscriptionLimits.tierDisplayName(inviteeTier)}.');
      }
    }

    // Check if already invited/member
    final existing = await _firestore
        .collection(AppConstants.shoppingListsCollection)
        .doc(listId)
        .collection('members')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception(
          'This person is already a member of (or has a pending invite to) this list.');
    }

    final id = _uuid.v4();
    final member = Member(
      id: id,
      listId: listId,
      email: email,
      displayName: displayName,
      invitedAt: DateTime.now(),
      invitedBy: invitedBy,
      invitedByName: invitedByName,
    );

    await _firestore
        .collection(AppConstants.shoppingListsCollection)
        .doc(listId)
        .collection('members')
        .doc(id)
        .set(member.toFirestore());

    final listName = listDoc.data()!['name'] as String? ?? '';
    final normalizedEmail = email.trim().toLowerCase();

    await _firestore
        .collection(AppConstants.invitationsCollection)
        .doc(id)
        .set({
      'listId': listId,
      'listName': listName,
      'invitedBy': invitedBy,
      'invitedByName': invitedByName,
      'inviteEmail': normalizedEmail,
      'recipientEmail': normalizedEmail,
      'inviteCode': id,
      'status': MemberStatus.pending,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await AppDatabase.instance.upsertMember(member);

    return member;
  }

  /// Removes a member from a shared list.
  ///
  /// Deletes the member document and removes userId from list's memberIds array.
  /// Updates both Firestore and local cache.
  Future<void> removeMember(Member member) async {
    final batch = _firestore.batch();

    batch.delete(_firestore
        .collection(AppConstants.shoppingListsCollection)
        .doc(member.listId)
        .collection('members')
        .doc(member.id));

    if (member.userId != null) {
      batch.update(
        _firestore
            .collection(AppConstants.shoppingListsCollection)
            .doc(member.listId),
        {'memberIds': FieldValue.arrayRemove([member.userId])},
      );
    }

    await batch.commit();
    await AppDatabase.instance.deleteMember(member.id);
  }

  /// Accepts a pending invitation to join a shared list.
  ///
  /// Updates invitation status to accepted, creates/updates member document
  /// with user details, and adds userId to list's memberIds array.
  ///
  /// Note: Does NOT update user's active listId - user remains on personal list.
  Future<void> acceptInvitation({
    required String inviteCode,
    required String userId,
    required String displayName,
    required String? photoUrl,
  }) async {
    validateNonEmpty(inviteCode, 'inviteCode');
    validateNonEmpty(userId, 'userId');
    validateNonEmpty(displayName, 'displayName');

    final inviteDoc = await _firestore
        .collection(AppConstants.invitationsCollection)
        .doc(inviteCode)
        .get();

    if (!inviteDoc.exists) throw Exception('Invitation not found');

    final inviteData = inviteDoc.data()!;
    final listId = inviteData['listId'] as String;
    final invitedByName = inviteData['invitedByName'] as String? ?? '';
    final invitedByUid = inviteData['invitedByUid'] as String?
        ?? inviteData['invitedBy'] as String?
        ?? '';
    final recipientEmail = inviteData['recipientEmail'] as String?
        ?? inviteData['inviteEmail'] as String?
        ?? '';

    final batch = _firestore.batch();

    // Mark invitation as accepted
    batch.update(
        _firestore
            .collection(AppConstants.invitationsCollection)
            .doc(inviteCode),
        {'status': MemberStatus.accepted});

    // Create or update member document
    batch.set(
        _firestore
            .collection(AppConstants.shoppingListsCollection)
            .doc(listId)
            .collection('members')
            .doc(inviteCode),
        {
          'id': inviteCode,
          'listId': listId,
          'userId': userId,
          'email': recipientEmail,
          'displayName': displayName,
          'photoUrl': photoUrl,
          'status': MemberStatus.accepted,
          'invitedAt': FieldValue.serverTimestamp(),
          'invitedBy': invitedByUid,
          'invitedByName': invitedByName,
        },
        SetOptions(merge: true));

    // Add userId to list's memberIds array
    batch.update(
        _firestore
            .collection(AppConstants.shoppingListsCollection)
            .doc(listId),
        {'memberIds': FieldValue.arrayUnion([userId])});

    await batch.commit();
  }

  /// Joins a shared list by direct list ID (used for deep links).
  ///
  /// Validates user hasn't exceeded their joined list limit.
  /// Creates a new member document with accepted status.
  Future<void> joinListById({
    required String listId,
    required String userId,
    required String displayName,
    required String email,
    String? photoUrl,
    SubscriptionTier joinerTier = SubscriptionTier.free,
  }) async {
    validateNonEmpty(listId, 'listId');
    validateNonEmpty(userId, 'userId');
    validateNonEmpty(displayName, 'displayName');
    validateNonEmpty(email, 'email');

    final listDoc = await _firestore
        .collection(AppConstants.shoppingListsCollection)
        .doc(listId)
        .get();

    if (!listDoc.exists) {
      throw Exception('List not found. Check the ID and try again.');
    }

    // Check joiner's list limit
    final maxJoined = SubscriptionLimits.maxJoinedSharedLists(joinerTier);
    final alreadyIn = await _firestore
        .collection(AppConstants.shoppingListsCollection)
        .where('type', isEqualTo: 'shared')
        .where('memberIds', arrayContains: userId)
        .get();

    final joinedAsNonOwner = alreadyIn.docs
        .where((d) => (d.data()['ownerId'] as String?) != userId)
        .length;

    if (joinedAsNonOwner >= maxJoined) {
      throw Exception(
          'You have already joined $maxJoined shared lists, which is the limit '
          'for the ${SubscriptionLimits.tierDisplayName(joinerTier)}. '
          'Upgrade your plan to join more.');
    }

    // Check if already a member
    final existingByUid = await _firestore
        .collection(AppConstants.shoppingListsCollection)
        .doc(listId)
        .collection('members')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (existingByUid.docs.isNotEmpty) {
      throw Exception('You are already a member of this list.');
    }

    final memberId = _uuid.v4();
    final member = Member(
      id: memberId,
      listId: listId,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      userId: userId,
      status: MemberStatus.accepted,
      invitedAt: DateTime.now(),
      invitedBy: '',
      invitedByName: 'Direct Join',
    );

    final batch = _firestore.batch();

    batch.set(
      _firestore
          .collection(AppConstants.shoppingListsCollection)
          .doc(listId)
          .collection('members')
          .doc(memberId),
      member.toFirestore(),
    );

    batch.update(
      _firestore
          .collection(AppConstants.shoppingListsCollection)
          .doc(listId),
      {'memberIds': FieldValue.arrayUnion([userId])},
    );

    await batch.commit();
    await AppDatabase.instance.upsertMember(member);
  }
}
