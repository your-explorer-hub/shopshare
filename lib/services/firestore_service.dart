import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/member.dart';
import '../models/shopping_item.dart';
import '../models/shopping_list.dart';
import '../models/custom_category.dart';
import '../models/category_item.dart';
import '../repositories/invite_repository.dart';
import '../repositories/item_repository.dart';
import '../repositories/list_repository.dart';
import '../repositories/member_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/custom_category_repository.dart';
import '../utils/subscription_limits.dart';

/// Facade for Firestore operations, delegating to domain-specific repositories.
///
/// This service maintains backward compatibility with existing code while
/// internally using the repository pattern for better separation of concerns.
/// All business logic has been moved to repositories.
///
/// **Architecture:**
/// - ItemRepository: Shopping item CRUD and batch operations
/// - MemberRepository: Member invitations, acceptance, removal
/// - ListRepository: List creation, deletion, membership
/// - UserRepository: User profiles and account management
/// - InviteRepository: Email and link invitation system
/// - CustomCategoryRepository: Custom category templates and items
class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final _uuid = const Uuid();

  // Repository instances (lazy initialization)
  late final ItemRepository _items = ItemRepository(_firestore, _analytics, _uuid);
  late final MemberRepository _members = MemberRepository(_firestore, _uuid);
  late final ListRepository _lists = ListRepository(_firestore, _analytics, _uuid);
  late final UserRepository _users = UserRepository(_firestore, _uuid, _lists);
  late final InviteRepository _invites = InviteRepository(_firestore, _uuid);
  late final CustomCategoryRepository _customCategories =
      CustomCategoryRepository(_firestore, _analytics, _uuid);

  // ═══════════════════════════════════════════════════════════════════════════
  // Item Operations (delegates to ItemRepository)
  // ═══════════════════════════════════════════════════════════════════════════

  Stream<List<ShoppingItem>> watchItems(String listId) =>
      _items.watchItems(listId);

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
    List<String>? categories,
  }) =>
      _items.addItem(
        listId: listId,
        name: name,
        category: category,
        addedBy: addedBy,
        addedByName: addedByName,
        notes: notes,
        quantity: quantity,
        unit: unit,
        inputMethod: inputMethod,
        categories: categories,
      );

  Future<void> toggleItemCompletion(
    ShoppingItem item, {
    required String completedByName,
  }) =>
      _items.toggleItemCompletion(item, completedByName: completedByName);

  Future<void> deleteItem(ShoppingItem item) => _items.deleteItem(item);

  Future<void> deleteItemsBatch(List<ShoppingItem> items) =>
      _items.deleteItemsBatch(items);

  Future<void> addItemsBatch({
    required List<ShoppingItem> items,
    required String targetListId,
    required String addedBy,
    required String addedByName,
  }) =>
      _items.addItemsBatch(
        items: items,
        targetListId: targetListId,
        addedBy: addedBy,
        addedByName: addedByName,
      );

  Future<void> updateItem(ShoppingItem item) => _items.updateItem(item);

  // ═══════════════════════════════════════════════════════════════════════════
  // Member Operations (delegates to MemberRepository)
  // ═══════════════════════════════════════════════════════════════════════════

  Stream<List<Member>> watchMembers(String listId) =>
      _members.watchMembers(listId);

  Future<Member> addMember({
    required String listId,
    required String email,
    required String displayName,
    required String invitedBy,
    required String invitedByName,
    SubscriptionTier ownerTier = SubscriptionTier.free,
    SubscriptionTier inviteeTier = SubscriptionTier.free,
    String? inviteeUserId,
  }) =>
      _members.addMember(
        listId: listId,
        email: email,
        displayName: displayName,
        invitedBy: invitedBy,
        invitedByName: invitedByName,
        ownerTier: ownerTier,
        inviteeTier: inviteeTier,
        inviteeUserId: inviteeUserId,
      );

  Future<void> removeMember(Member member) => _members.removeMember(member);

  Future<void> acceptInvitation({
    required String inviteCode,
    required String userId,
    required String displayName,
    required String? photoUrl,
  }) =>
      _members.acceptInvitation(
        inviteCode: inviteCode,
        userId: userId,
        displayName: displayName,
        photoUrl: photoUrl,
      );

  Future<void> joinListById({
    required String listId,
    required String userId,
    required String displayName,
    required String email,
    String? photoUrl,
    SubscriptionTier joinerTier = SubscriptionTier.free,
  }) =>
      _members.joinListById(
        listId: listId,
        userId: userId,
        displayName: displayName,
        email: email,
        photoUrl: photoUrl,
        joinerTier: joinerTier,
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // List Operations (delegates to ListRepository)
  // ═══════════════════════════════════════════════════════════════════════════

  Stream<List<ShoppingList>> watchUserLists(String userId) =>
      _lists.watchUserLists(userId);

  Future<ShoppingList> createSharedList({
    required String customName,
    required String ownerId,
    required String ownerName,
    required String ownerEmail,
    SubscriptionTier ownerTier = SubscriptionTier.free,
  }) =>
      _lists.createSharedList(
        customName: customName,
        ownerId: ownerId,
        ownerName: ownerName,
        ownerEmail: ownerEmail,
        ownerTier: ownerTier,
      );

  Future<String> deleteList(String listId, String callerId) =>
      _lists.deleteList(listId, callerId);

  Future<void> updateListName({
    required String listId,
    required String newName,
    required String callerId,
  }) =>
      _lists.updateListName(
        listId: listId,
        newName: newName,
        callerId: callerId,
      );

  Future<void> leaveList({
    required String listId,
    required String userId,
    required String memberId,
  }) =>
      _lists.leaveList(
        listId: listId,
        userId: userId,
        memberId: memberId,
      );

  Future<void> updateActiveList(String userId, String listId) =>
      _lists.updateActiveList(userId, listId);

  Future<List<ShoppingList>> getJoinedSharedLists(String userId) =>
      _lists.getJoinedSharedLists(userId);

  // ═══════════════════════════════════════════════════════════════════════════
  // User Profile Operations (delegates to UserRepository)
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> upsertUserProfile({
    required String userId,
    required String email,
    required String displayName,
    String? photoUrl,
  }) =>
      _users.upsertUserProfile(
        userId: userId,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
      );

  Future<Map<String, dynamic>?> getUserProfile(String userId) =>
      _users.getUserProfile(userId);

  Future<ShoppingList> ensurePersonalList({
    required String userId,
    required String displayName,
    required String email,
  }) =>
      _users.ensurePersonalList(
        userId: userId,
        displayName: displayName,
        email: email,
      );

  Future<void> deleteUserAccount(String userId) =>
      _users.deleteUserAccount(userId);

  // ═══════════════════════════════════════════════════════════════════════════
  // Invitation Operations (delegates to InviteRepository)
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> sendEmailInvite({
    required String listId,
    required String invitedByUid,
    required String invitedByName,
    required String invitedByEmail,
    required String recipientEmail,
    SubscriptionTier ownerTier = SubscriptionTier.free,
  }) =>
      _invites.sendEmailInvite(
        listId: listId,
        invitedByUid: invitedByUid,
        invitedByName: invitedByName,
        invitedByEmail: invitedByEmail,
        recipientEmail: recipientEmail,
        ownerTier: ownerTier,
      );

  Future<String> createLinkInvite({
    required String listId,
    required String invitedByUid,
    required String invitedByName,
    SubscriptionTier ownerTier = SubscriptionTier.free,
  }) =>
      _invites.createLinkInvite(
        listId: listId,
        invitedByUid: invitedByUid,
        invitedByName: invitedByName,
        ownerTier: ownerTier,
      );

  Future<Map<String, dynamic>?> getInviteByShortCode(String shortCode) =>
      _invites.getInviteByShortCode(shortCode);

  Future<List<Map<String, dynamic>>> getPendingInvitesForUser(
          String recipientEmail) =>
      _invites.getPendingInvitesForUser(recipientEmail);

  Stream<List<Map<String, dynamic>>> watchPendingInvitesForUser(
          String recipientEmail) =>
      _invites.watchPendingInvitesForUser(recipientEmail);

  Future<void> declineInvite(String inviteId) =>
      _invites.declineInvite(inviteId);

  // ═══════════════════════════════════════════════════════════════════════════
  // Custom Category Operations (delegates to CustomCategoryRepository)
  // ═══════════════════════════════════════════════════════════════════════════

  Stream<List<CustomCategory>> watchCustomCategories(String userId) =>
      _customCategories.watchCategories(userId);

  Future<CustomCategory> createCustomCategory(
    String userId,
    String name, {
    required int existingCount,
  }) =>
      _customCategories.createCategory(userId, name,
          existingCount: existingCount);

  Future<void> updateCustomCategory(CustomCategory category) =>
      _customCategories.updateCategory(category);

  Future<void> deleteCustomCategory(String categoryId, String userId) =>
      _customCategories.deleteCategory(categoryId, userId);

  Future<bool> canCreateCustomCategory(String userId, SubscriptionTier tier) =>
      _customCategories.canCreateCategory(userId, tier);

  // ── Category Items ──

  Stream<List<CategoryItem>> watchCategoryItems(
          String categoryId, String userId) =>
      _customCategories.watchCategoryItems(categoryId, userId);

  Future<CategoryItem> addCategoryItem({
    required String categoryId,
    required String userId,
    required String name,
    String? notes,
    int? quantity,
    String? unit,
  }) =>
      _customCategories.addItem(
        categoryId: categoryId,
        userId: userId,
        name: name,
        notes: notes,
        quantity: quantity,
        unit: unit,
      );

  Future<void> updateCategoryItem(CategoryItem item) =>
      _customCategories.updateItem(item);

  Future<void> deleteCategoryItem(
          String itemId, String categoryId, String userId) =>
      _customCategories.deleteItem(itemId, categoryId, userId);

  Future<bool> canAddCategoryItem(
          String categoryId, String userId, SubscriptionTier tier) =>
      _customCategories.canAddItem(categoryId, userId, tier);

  Future<int> copyCategoryItemsToList({
    required List<CategoryItem> items,
    required String targetListId,
    required String userId,
    required String displayName,
  }) =>
      _customCategories.copyItemsToList(
        items: items,
        targetListId: targetListId,
        userId: userId,
        displayName: displayName,
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // Legacy Method Support
  // ═══════════════════════════════════════════════════════════════════════════

  /// Legacy method for submitting feedback.
  /// Maintained for backward compatibility - consider moving to a FeedbackRepository.
  Future<void> submitFeedback({
    required String userId,
    required String userName,
    required String userEmail,
    required String category,
    required String feedback,
    int? rating,
  }) async {
    await _firestore.collection('feedback').add({
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'category': category,
      'feedback': feedback,
      'rating': rating,
      'createdAt': FieldValue.serverTimestamp(),
      'platform': TargetPlatform.values.firstWhere(
        (p) => p.name == defaultTargetPlatform.name,
        orElse: () => TargetPlatform.android,
      ).name,
    });
  }
}
