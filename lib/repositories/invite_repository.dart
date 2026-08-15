import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../utils/constants.dart';
import '../utils/subscription_limits.dart';
import 'base_repository.dart';

/// Repository for invitation and short-link operations.
///
/// Handles email invitations, shareable link generation, invitation lookup,
/// and invitation lifecycle (accept/decline). Supports both email-specific
/// and multi-use link invitations.
class InviteRepository extends BaseRepository {
  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  InviteRepository(this._firestore, this._uuid);

  /// Sends an email-based invitation with 6 validation checks.
  ///
  /// Validates:
  /// 1. List exists
  /// 2. Only owner can invite
  /// 3. No self-invite
  /// 4. Member count < tier limit
  /// 5. Recipient not already member
  /// 6. No pending invite exists
  /// 7. Recipient account exists
  ///
  /// Creates invitation record and caches locally for offline badge count.
  Future<void> sendEmailInvite({
    required String listId,
    required String invitedByUid,
    required String invitedByName,
    required String invitedByEmail,
    required String recipientEmail,
    SubscriptionTier ownerTier = SubscriptionTier.free,
  }) async {
    validateNonEmpty(listId, 'listId');
    validateNonEmpty(invitedByUid, 'invitedByUid');
    validateNonEmpty(invitedByName, 'invitedByName');
    validateNonEmpty(invitedByEmail, 'invitedByEmail');
    validateNonEmpty(recipientEmail, 'recipientEmail');

    final normalizedRecipient = recipientEmail.trim().toLowerCase();

    // 1. List exists
    final listDoc = await _firestore
        .collection(AppConstants.shoppingListsCollection)
        .doc(listId)
        .get();

    if (!listDoc.exists) throw Exception('List not found.');

    final data = listDoc.data()!;
    final ownerId = data['ownerId'] as String? ?? '';
    final listName = data['name'] as String? ?? '';

    // 2. Only owner can invite
    if (invitedByUid != ownerId) {
      throw Exception('Only the list owner can send invitations.');
    }

    // 3. No self-invite
    if (invitedByEmail.trim().toLowerCase() == normalizedRecipient) {
      throw Exception('You cannot invite yourself.');
    }

    // 4. Member count < max
    final membersSnap = await _firestore
        .collection(AppConstants.shoppingListsCollection)
        .doc(listId)
        .collection('members')
        .get();

    final maxMembers = SubscriptionLimits.maxMembersPerList(ownerTier);
    if (membersSnap.docs.length >= maxMembers) {
      throw Exception(
          'This list already has $maxMembers members, the limit for '
          '${SubscriptionLimits.tierDisplayName(ownerTier)}. Upgrade to add more.');
    }

    // 5. Recipient not already member
    final memberByEmail = membersSnap.docs
        .where((d) =>
            (d.data()['email'] as String? ?? '').toLowerCase() ==
            normalizedRecipient)
        .toList();

    if (memberByEmail.isNotEmpty) {
      throw Exception('This person is already a member of the list.');
    }

    // 6. No pending invite exists
    final existingInvite = await _firestore
        .collection(AppConstants.invitationsCollection)
        .where('listId', isEqualTo: listId)
        .where('recipientEmail', isEqualTo: normalizedRecipient)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (existingInvite.docs.isNotEmpty) {
      throw Exception('A pending invitation already exists for this email.');
    }

    // 7. Recipient account exists
    final userByEmail = await _firestore
        .collection(AppConstants.usersCollection)
        .where('email', isEqualTo: normalizedRecipient)
        .limit(1)
        .get();

    if (userByEmail.docs.isEmpty) {
      throw Exception(
          'No ShopShare account found for $recipientEmail. '
          'Ask them to sign up first.');
    }

    // All checks passed — create invitation
    final inviteId = _uuid.v4();
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(days: 15));

    final inviteData = {
      'inviteId': inviteId,
      'listId': listId,
      'listName': listName,
      'invitedByUid': invitedByUid,
      'invitedByName': invitedByName,
      'recipientEmail': normalizedRecipient,
      'status': MemberStatus.pending,
      'createdAt': Timestamp.fromDate(now),
      'expiresAt': Timestamp.fromDate(expiresAt),
    };

    await _firestore
        .collection(AppConstants.invitationsCollection)
        .doc(inviteId)
        .set(inviteData);

    // Cache locally for offline badge count
    await AppDatabase.instance.upsertInvitation({
      'id': inviteId,
      'list_id': listId,
      'list_name': listName,
      'invited_by_name': invitedByName,
      'recipient_email': normalizedRecipient,
      'status': MemberStatus.pending,
      'created_at': now.millisecondsSinceEpoch,
      'expires_at': expiresAt.millisecondsSinceEpoch,
    });
  }

  /// Generates a cryptographically safe 6-character short code.
  ///
  /// Uses Random.secure() and ensures uniqueness by checking Firestore.
  /// Excludes ambiguous characters (I/O/0/1).
  /// Attempts 10 times, then falls back to timestamp-based code.
  Future<String> generateUniqueShortCode() async {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();

    for (var attempt = 0; attempt < 10; attempt++) {
      final buf = StringBuffer();
      for (var i = 0; i < 6; i++) {
        buf.write(chars[rng.nextInt(chars.length)]);
      }

      final code = buf.toString();
      final existing = await _firestore
          .collection(AppConstants.invitationsCollection)
          .where('shortCode', isEqualTo: code)
          .limit(1)
          .get();

      if (existing.docs.isEmpty) return code;
    }

    // Fallback: timestamp-based (extremely unlikely to be needed)
    return DateTime.now()
        .millisecondsSinceEpoch
        .toRadixString(36)
        .toUpperCase()
        .substring(0, 6);
  }

  /// Creates a multi-use shareable link invitation.
  ///
  /// Validates owner permissions and member limits.
  /// Returns the generated short code for building share URL.
  Future<String> createLinkInvite({
    required String listId,
    required String invitedByUid,
    required String invitedByName,
    SubscriptionTier ownerTier = SubscriptionTier.free,
  }) async {
    validateNonEmpty(listId, 'listId');
    validateNonEmpty(invitedByUid, 'invitedByUid');
    validateNonEmpty(invitedByName, 'invitedByName');

    // Validate list exists and caller is owner
    final listDoc = await _firestore
        .collection(AppConstants.shoppingListsCollection)
        .doc(listId)
        .get();

    if (!listDoc.exists) throw Exception('List not found.');

    final data = listDoc.data()!;
    final ownerId = data['ownerId'] as String? ?? '';
    final listName = data['name'] as String? ?? '';

    if (invitedByUid != ownerId) {
      throw Exception('Only the list owner can create invite links.');
    }

    // Check member limit
    final membersSnap = await _firestore
        .collection(AppConstants.shoppingListsCollection)
        .doc(listId)
        .collection('members')
        .get();

    final maxMembers = SubscriptionLimits.maxMembersPerList(ownerTier);
    if (membersSnap.docs.length >= maxMembers) {
      throw Exception(
          'This list already has $maxMembers members, the limit for '
          '${SubscriptionLimits.tierDisplayName(ownerTier)}. Upgrade to add more.');
    }

    final shortCode = await generateUniqueShortCode();
    final inviteId = _uuid.v4();
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(days: 15));

    await _firestore
        .collection(AppConstants.invitationsCollection)
        .doc(inviteId)
        .set({
      'inviteId': inviteId,
      'shortCode': shortCode,
      'listId': listId,
      'listName': listName,
      'invitedByUid': invitedByUid,
      'invitedByName': invitedByName,
      'recipientEmail': '', // multi-use: no specific recipient
      'status': MemberStatus.pending,
      'createdAt': Timestamp.fromDate(now),
      'expiresAt': Timestamp.fromDate(expiresAt),
    });

    return shortCode;
  }

  /// Resolves a short code to invitation data.
  ///
  /// Returns null if:
  /// - Code not found
  /// - Invitation expired
  /// - Status is declined or cancelled
  Future<Map<String, dynamic>?> getInviteByShortCode(String shortCode) async {
    validateNonEmpty(shortCode, 'shortCode');

    final snap = await _firestore
        .collection(AppConstants.invitationsCollection)
        .where('shortCode', isEqualTo: shortCode.toUpperCase())
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;

    final doc = snap.docs.first;
    final data = {'id': doc.id, ...doc.data()};

    // Check expiry
    final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
    if (expiresAt != null && DateTime.now().isAfter(expiresAt)) return null;

    // Declined/cancelled links are invalid
    final status = data['status'] as String? ?? '';
    if (status == MemberStatus.declined || status == 'cancelled') return null;

    return data;
  }

  /// One-time fetch of pending, non-expired invites for a user.
  Future<List<Map<String, dynamic>>> getPendingInvitesForUser(
      String recipientEmail) async {
    validateNonEmpty(recipientEmail, 'recipientEmail');

    final normalized = recipientEmail.trim().toLowerCase();
    final now = Timestamp.fromDate(DateTime.now());

    final snap = await _firestore
        .collection(AppConstants.invitationsCollection)
        .where('recipientEmail', isEqualTo: normalized)
        .where('status', isEqualTo: MemberStatus.pending)
        .where('expiresAt', isGreaterThan: now)
        .get();

    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  /// Real-time stream of pending invites for badge count.
  ///
  /// Queries both recipientEmail (new) and inviteEmail (legacy) fields
  /// to catch all pending invites. Merges both streams and deduplicates.
  Stream<List<Map<String, dynamic>>> watchPendingInvitesForUser(
      String recipientEmail) {
    validateNonEmpty(recipientEmail, 'recipientEmail');

    final normalized = recipientEmail.trim().toLowerCase();

    // Track latest snapshots from each stream
    List<Map<String, dynamic>> primaryLatest = [];
    List<Map<String, dynamic>> legacyLatest = [];

    late StreamController<List<Map<String, dynamic>>> controller;
    controller = StreamController<List<Map<String, dynamic>>>.broadcast();

    // Merge and deduplicate
    List<Map<String, dynamic>> merged() {
      final seen = <String>{};
      final result = <Map<String, dynamic>>[];

      for (final item in [...primaryLatest, ...legacyLatest]) {
        final id = item['id'] as String;
        if (seen.add(id)) result.add(item);
      }

      return result;
    }

    // Primary stream: recipientEmail field
    final primarySub = _firestore
        .collection(AppConstants.invitationsCollection)
        .where('recipientEmail', isEqualTo: normalized)
        .where('status', isEqualTo: MemberStatus.pending)
        .snapshots()
        .listen((snap) {
      primaryLatest = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      if (!controller.isClosed) controller.add(merged());
    }, onError: (_) {});

    // Legacy stream: inviteEmail field
    final legacySub = _firestore
        .collection(AppConstants.invitationsCollection)
        .where('inviteEmail', isEqualTo: normalized)
        .where('status', isEqualTo: MemberStatus.pending)
        .snapshots()
        .listen((snap) {
      legacyLatest = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      if (!controller.isClosed) controller.add(merged());
    }, onError: (_) {});

    // Cleanup on cancel
    controller.onCancel = () {
      primarySub.cancel();
      legacySub.cancel();
      controller.close();
    };

    return controller.stream;
  }

  /// Declines an invitation.
  ///
  /// Sets status to declined and removes pending member document if exists.
  Future<void> declineInvite(String inviteId) async {
    validateNonEmpty(inviteId, 'inviteId');

    final inviteDoc = await _firestore
        .collection(AppConstants.invitationsCollection)
        .doc(inviteId)
        .get();

    if (!inviteDoc.exists) throw Exception('Invitation not found.');

    final inviteData = inviteDoc.data()!;
    final listId = inviteData['listId'] as String? ?? '';

    final batch = _firestore.batch();

    // Mark invitation as declined
    batch.update(
        _firestore
            .collection(AppConstants.invitationsCollection)
            .doc(inviteId),
        {'status': MemberStatus.declined});

    // Remove pending member document if it exists
    final memberDoc = await _firestore
        .collection(AppConstants.shoppingListsCollection)
        .doc(listId)
        .collection('members')
        .doc(inviteId)
        .get();

    if (memberDoc.exists) {
      batch.delete(memberDoc.reference);
    }

    await batch.commit();
  }
}
