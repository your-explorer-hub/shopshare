import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

class Member {
  final String id;
  final String listId;
  final String? userId;
  final String email;
  final String displayName;
  final String? photoUrl;
  final DateTime invitedAt;
  final String status; // pending, accepted, rejected
  final String invitedBy;
  final String invitedByName;

  const Member({
    required this.id,
    required this.listId,
    this.userId,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.invitedAt,
    this.status = MemberStatus.pending,
    required this.invitedBy,
    required this.invitedByName,
  });

  bool get isPending => status == MemberStatus.pending;
  bool get isAccepted => status == MemberStatus.accepted;

  factory Member.fromFirestore(DocumentSnapshot doc, String listId) {
    final data = doc.data() as Map<String, dynamic>;
    return Member(
      id: doc.id,
      listId: listId,
      userId: data['userId'] as String?,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      invitedAt: (data['invitedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] as String? ?? MemberStatus.pending,
      invitedBy: data['invitedBy'] as String? ?? '',
      invitedByName: data['invitedByName'] as String? ?? '',
    );
  }

  factory Member.fromMap(Map<String, dynamic> map) {
    return Member(
      id: map['id'] as String,
      listId: map['list_id'] as String? ?? '',
      userId: map['user_id'] as String?,
      email: map['email'] as String? ?? '',
      displayName: map['display_name'] as String? ?? '',
      photoUrl: map['photo_url'] as String?,
      invitedAt: map['invited_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['invited_at'] as int)
          : DateTime.now(),
      status: map['status'] as String? ?? MemberStatus.pending,
      invitedBy: map['invited_by'] as String? ?? '',
      invitedByName: map['invited_by_name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'invitedAt': Timestamp.fromDate(invitedAt),
        'status': status,
        'invitedBy': invitedBy,
        'invitedByName': invitedByName,
      };

  Map<String, dynamic> toLocalMap() => {
        'id': id,
        'list_id': listId,
        'user_id': userId,
        'email': email,
        'display_name': displayName,
        'photo_url': photoUrl,
        'invited_at': invitedAt.millisecondsSinceEpoch,
        'status': status,
        'invited_by': invitedBy,
        'invited_by_name': invitedByName,
      };

  Member copyWith({
    String? id,
    String? listId,
    String? userId,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? invitedAt,
    String? status,
    String? invitedBy,
    String? invitedByName,
  }) {
    return Member(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      invitedAt: invitedAt ?? this.invitedAt,
      status: status ?? this.status,
      invitedBy: invitedBy ?? this.invitedBy,
      invitedByName: invitedByName ?? this.invitedByName,
    );
  }

  @override
  String toString() => 'Member(id: $id, email: $email, status: $status)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Member && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}