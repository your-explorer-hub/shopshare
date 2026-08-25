import 'package:cloud_firestore/cloud_firestore.dart';

/// Template item stored in a custom category.
/// Unlike ShoppingItem, CategoryItem:
/// - Has no completion status (templates are never "completed")
/// - Has no multi-category support (belongs to one category)
/// - Has no listId (not part of a shopping list)
class CategoryItem {
  final String id;
  final String categoryId;
  final String userId;
  final String name;
  final String? notes;
  final int? quantity;
  final String? unit;
  final DateTime createdAt;

  const CategoryItem({
    required this.id,
    required this.categoryId,
    required this.userId,
    required this.name,
    this.notes,
    this.quantity,
    this.unit,
    required this.createdAt,
  });

  // ─── Firestore deserialization ───────────────────────────────────────────────

  factory CategoryItem.fromFirestore(
      DocumentSnapshot doc, String categoryId, String userId) {
    final data = doc.data() as Map<String, dynamic>;
    return CategoryItem(
      id: doc.id,
      categoryId: categoryId,
      userId: userId,
      name: data['name'] as String? ?? '',
      notes: data['notes'] as String?,
      quantity: data['quantity'] as int?,
      unit: data['unit'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // ─── SQLite deserialization ──────────────────────────────────────────────────

  factory CategoryItem.fromMap(Map<String, dynamic> map) {
    return CategoryItem(
      id: map['id'] as String,
      categoryId: map['category_id'] as String? ?? '',
      userId: map['user_id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      notes: map['notes'] as String?,
      quantity: map['quantity'] as int?,
      unit: map['unit'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int)
          : DateTime.now(),
    );
  }

  // ─── Firestore serialization ─────────────────────────────────────────────────

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'notes': notes,
        'quantity': quantity,
        'unit': unit,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  // ─── SQLite serialization ────────────────────────────────────────────────────

  Map<String, dynamic> toLocalMap() => {
        'id': id,
        'category_id': categoryId,
        'user_id': userId,
        'name': name,
        'notes': notes,
        'quantity': quantity,
        'unit': unit,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  // ─── copyWith ────────────────────────────────────────────────────────────────

  CategoryItem copyWith({
    String? id,
    String? categoryId,
    String? userId,
    String? name,
    String? notes,
    int? quantity,
    String? unit,
    DateTime? createdAt,
  }) {
    return CategoryItem(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ─── Object overrides ────────────────────────────────────────────────────────

  @override
  String toString() =>
      'CategoryItem(id: $id, name: $name, quantity: $quantity, unit: $unit)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
