import 'package:cloud_firestore/cloud_firestore.dart';

/// Custom category for storing template shopping lists.
/// Categories are private to each user and persist indefinitely until deleted.
/// Examples: "Christmas", "Diwali", "Birthday Party"
class CustomCategory {
  final String id;
  final String userId;
  final String name;
  final String emoji;
  final String colorHex;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int itemCount;

  const CustomCategory({
    required this.id,
    required this.userId,
    required this.name,
    required this.emoji,
    required this.colorHex,
    required this.createdAt,
    this.updatedAt,
    this.itemCount = 0,
  });

  // ─── Firestore deserialization ───────────────────────────────────────────────

  factory CustomCategory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CustomCategory(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      emoji: data['emoji'] as String? ?? '📦',
      colorHex: data['colorHex'] as String? ?? '#9C27B0',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      itemCount: data['itemCount'] as int? ?? 0,
    );
  }

  // ─── SQLite deserialization ──────────────────────────────────────────────────

  factory CustomCategory.fromMap(Map<String, dynamic> map) {
    return CustomCategory(
      id: map['id'] as String,
      userId: map['user_id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      emoji: map['emoji'] as String? ?? '📦',
      colorHex: map['color_hex'] as String? ?? '#9C27B0',
      createdAt: map['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int)
          : null,
      itemCount: map['item_count'] as int? ?? 0,
    );
  }

  // ─── Firestore serialization ─────────────────────────────────────────────────

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'name': name,
        'emoji': emoji,
        'colorHex': colorHex,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt':
            updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
        'itemCount': itemCount,
      };

  // ─── SQLite serialization ────────────────────────────────────────────────────

  Map<String, dynamic> toLocalMap() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'emoji': emoji,
        'color_hex': colorHex,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt?.millisecondsSinceEpoch,
        'item_count': itemCount,
      };

  // ─── copyWith ────────────────────────────────────────────────────────────────

  CustomCategory copyWith({
    String? id,
    String? userId,
    String? name,
    String? emoji,
    String? colorHex,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? itemCount,
  }) {
    return CustomCategory(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      itemCount: itemCount ?? this.itemCount,
    );
  }

  // ─── Object overrides ────────────────────────────────────────────────────────

  @override
  String toString() =>
      'CustomCategory(id: $id, name: $name, emoji: $emoji, itemCount: $itemCount)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomCategory &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
