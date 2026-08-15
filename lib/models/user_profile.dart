import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/subscription_limits.dart';

class UserProfile {
  final String id;
  final String? email;          // nullable — phone users have no email
  final String? phoneNumber;    // nullable — Google users have no phone
  final String displayName;
  final String? photoUrl;
  final String? listId;
  final String? gender; // 'male' | 'female' | 'other' | null
  final DateTime createdAt;
  final DateTime? lastSeen;
  /// Subscription tier — defaults to [SubscriptionTier.free] for all users.
  /// Set to 'family' or 'group' when the user upgrades (future billing).
  final SubscriptionTier subscriptionTier;

  const UserProfile({
    required this.id,
    this.email,
    this.phoneNumber,
    required this.displayName,
    this.photoUrl,
    this.listId,
    this.gender,
    required this.createdAt,
    this.lastSeen,
    this.subscriptionTier = SubscriptionTier.free,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      id: doc.id,
      email: data['email'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
      displayName: data['displayName'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      listId: data['listId'] as String?,
      gender: data['gender'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate(),
      subscriptionTier: SubscriptionLimits.fromString(
          data['subscriptionTier'] as String?),
    );
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      email: map['email'] as String?,
      phoneNumber: map['phone_number'] as String?,
      displayName: map['display_name'] as String? ?? '',
      photoUrl: map['photo_url'] as String?,
      listId: map['list_id'] as String?,
      gender: map['gender'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int)
          : DateTime.now(),
      lastSeen: map['last_seen'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_seen'] as int)
          : null,
      subscriptionTier: SubscriptionLimits.fromString(
          map['subscription_tier'] as String?),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'email': email,
        'phoneNumber': phoneNumber,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'listId': listId,
        'gender': gender,
        'createdAt': Timestamp.fromDate(createdAt),
        'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
        'subscriptionTier': SubscriptionLimits.tierToString(subscriptionTier),
      };

  Map<String, dynamic> toLocalMap() => {
        'id': id,
        'email': email,
        'phone_number': phoneNumber,
        'display_name': displayName,
        'photo_url': photoUrl,
        'list_id': listId,
        'gender': gender,
        'created_at': createdAt.millisecondsSinceEpoch,
        'last_seen': lastSeen?.millisecondsSinceEpoch,
        'subscription_tier': SubscriptionLimits.tierToString(subscriptionTier),
      };

  UserProfile copyWith({
    String? id,
    String? email,
    String? phoneNumber,
    String? displayName,
    String? photoUrl,
    String? listId,
    String? gender,
    DateTime? createdAt,
    DateTime? lastSeen,
    SubscriptionTier? subscriptionTier,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      listId: listId ?? this.listId,
      gender: gender ?? this.gender,
      createdAt: createdAt ?? this.createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
    );
  }

  /// Returns the first letter(s) for use as an avatar fallback.
  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  /// Returns display-friendly identifier: email if available, phone otherwise.
  String get identifier => email ?? phoneNumber ?? '';

  @override
  String toString() =>
      'UserProfile(id: $id, email: $email, phoneNumber: $phoneNumber, displayName: $displayName)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}