import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../firebase_options.dart';
import '../models/user_profile.dart';
import '../utils/constants.dart';
import '../database/app_database.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // On web, the OAuth client ID must be provided explicitly.
  // On Android/iOS it is read from google-services.json / GoogleService-Info.plist.
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? DefaultFirebaseOptions.webClientId : null,
  );

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // ─── Google Sign-In ─────────────────────────────────────────────────────────

  Future<UserProfile?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User cancelled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential result =
          await _auth.signInWithCredential(credential);
      final User? user = result.user;
      if (user == null) return null;

      // Create or update user profile in Firestore
      final profile = await _createOrUpdateUserProfile(user);

      // Cache locally
      await AppDatabase.instance.upsertUser(profile);

      return profile;
    } catch (e) {
      throw AuthException(_friendlyAuthError(e));
    }
  }

  // ─── Sign Out ────────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      await AppDatabase.instance.clearAll();
    } catch (e) {
      throw AuthException('Sign-out failed: ${e.toString()}');
    }
  }

  // ─── Profile management ──────────────────────────────────────────────────────

  Future<UserProfile?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    // Try local cache first
    final cached = await AppDatabase.instance.getUser(user.uid);
    if (cached != null) return cached;

    // Fetch from Firestore
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .get();

    if (!doc.exists) return null;

    final profile = UserProfile.fromFirestore(doc);
    await AppDatabase.instance.upsertUser(profile);
    return profile;
  }

  Future<UserProfile> updateUserProfile({
    required String userId,
    String? displayName,
    String? photoUrl,
    String? gender,
    bool clearGender = false,
  }) async {
    final updates = <String, dynamic>{};
    if (displayName != null) updates['displayName'] = displayName;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;
    // Always write gender so that setting it (or clearing it) persists.
    // The caller passes the current _selectedGender value (null = not set).
    updates['gender'] = gender;
    updates['lastSeen'] = FieldValue.serverTimestamp();

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update(updates);

    if (displayName != null) {
      await _auth.currentUser?.updateDisplayName(displayName);
    }

    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .get();

    final profile = UserProfile.fromFirestore(doc);
    await AppDatabase.instance.upsertUser(profile);
    return profile;
  }

  // ─── Account deletion ───────────────────────────────────────────────────────

  /// Phase 1 hard delete:
  /// 1. Delete all owned lists + their items sub-collections
  /// 2. Remove user from any shared lists they're a member of
  /// 3. Delete the user Firestore document
  /// 4. Delete the Firebase Auth account
  /// 5. Clear local SQLite cache
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw AuthException('No authenticated user found.');

    final uid = user.uid;

    try {
      // ── Step 1: Get all lists owned by this user ──────────────────────
      final ownedLists = await _firestore
          .collection(AppConstants.shoppingListsCollection)
          .where('ownerId', isEqualTo: uid)
          .get();

      for (final listDoc in ownedLists.docs) {
        final listId = listDoc.id;

        // For Phase 1: delete everything (simple approach).
        // Delete all items in this list
        final items = await _firestore
            .collection(AppConstants.shoppingListsCollection)
            .doc(listId)
            .collection(AppConstants.itemsSubCollection)
            .get();
        for (final item in items.docs) {
          await item.reference.delete();
        }

        // Delete all members in this list
        final members = await _firestore
            .collection(AppConstants.shoppingListsCollection)
            .doc(listId)
            .collection('members')
            .get();
        for (final member in members.docs) {
          await member.reference.delete();
        }

        // Delete the list document itself
        await listDoc.reference.delete();
      }

      // ── Step 2: Remove user from shared lists they joined (non-owner) ──
      final joinedLists = await _firestore
          .collection(AppConstants.shoppingListsCollection)
          .where('memberIds', arrayContains: uid)
          .get();

      for (final listDoc in joinedLists.docs) {
        final ownerId = listDoc.data()['ownerId'] as String? ?? '';
        if (ownerId == uid) continue; // already deleted above

        final batch = _firestore.batch();

        // Remove from memberIds array
        batch.update(listDoc.reference, {
          'memberIds': FieldValue.arrayRemove([uid]),
        });

        // Delete their member record from the sub-collection
        final memberQuery = await listDoc.reference
            .collection('members')
            .where('userId', isEqualTo: uid)
            .get();
        for (final m in memberQuery.docs) {
          batch.delete(m.reference);
        }

        await batch.commit();
      }

      // ── Step 3: Delete invitations created by this user ────────────────
      final invites = await _firestore
          .collection(AppConstants.invitationsCollection)
          .where('invitedBy', isEqualTo: uid)
          .get();
      for (final inv in invites.docs) {
        await inv.reference.delete();
      }

      // ── Step 4: Delete user Firestore document ──────────────────────────
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .delete();

      // ── Step 5: Clear local SQLite cache ────────────────────────────────
      await AppDatabase.instance.clearAll();
      await AppDatabase.instance.deleteUser(uid);

      // ── Step 6: Delete Firebase Auth account ────────────────────────────
      // Must be last — once deleted, we can't make authenticated Firestore calls
      await user.delete();

      // Sign out Google session
      await _googleSignIn.signOut();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw AuthException(
          'For security, please sign out and sign back in before deleting your account.',
        );
      }
      throw AuthException('Account deletion failed: ${e.message}');
    } catch (e) {
      throw AuthException('Account deletion failed: ${e.toString()}');
    }
  }

  // ─── Private helpers ─────────────────────────────────────────────────────────

  Future<UserProfile> _createOrUpdateUserProfile(User user) async {
    final docRef = _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid);

    final doc = await docRef.get();

    if (!doc.exists) {
      // New user — create profile + personal shopping list with human-readable name.
      // Name format: MyList_FirstName_LastName (spaces → underscores).
      final listId = 'list_${user.uid}';
      final rawName = user.displayName ?? 'User';
      final safeName = rawName.trim().replaceAll(RegExp(r'\s+'), '_');
      final listName = 'MyList_$safeName';

      final profile = UserProfile(
        id: user.uid,
        email: user.email ?? '',
        displayName: rawName,
        photoUrl: user.photoURL,
        listId: listId,
        createdAt: DateTime.now(),
      );

      // Batch write: user profile + personal shopping list
      final batch = _firestore.batch();

      batch.set(docRef, profile.toFirestore());

      batch.set(
        _firestore
            .collection(AppConstants.shoppingListsCollection)
            .doc(listId),
        {
          'name': listName,
          'type': 'personal',
          'ownerId': user.uid,
          'ownerName': rawName,
          'memberIds': [user.uid],
          'createdAt': FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();
      return profile;
    } else {
      // Existing user — update last seen
      await docRef.update({'lastSeen': FieldValue.serverTimestamp()});
      return UserProfile.fromFirestore(doc);
    }
  }

  // ─── Error helpers ────────────────────────────────────────────────────────────

  static String _friendlyAuthError(Object e) {
    final msg = e.toString();
    if (msg.contains('ClientID not set') || msg.contains('appClientId')) {
      return 'Google Sign-In is not configured for web.\n'
          'Set your Web OAuth Client ID in firebase_options.dart → webClientId '
          'and web/index.html → google-signin-client_id meta tag.';
    }
    if (msg.contains('network_error') || msg.contains('SocketException')) {
      return 'No internet connection. Please check your network and try again.';
    }
    if (msg.contains('invalid-api-key') || msg.contains('API key not valid')) {
      return 'Firebase is not configured. Run "flutterfire configure" to '
          'generate real credentials in firebase_options.dart.';
    }
    return 'Sign-in failed: $msg';
  }
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}