import 'package:cloud_firestore/cloud_firestore.dart';

/// Constants for how an item was added — used for telemetry.
class InputMethod {
  InputMethod._();
  static const String manual = 'manual';
  static const String voice = 'voice';
}

class ShoppingItem {
  final String id;
  final String listId;
  final String name;

  /// Multi-category support (paid feature).
  /// Always contains at least one entry.
  /// Free-tier items will have exactly one category.
  final List<String> categories;

  final String addedBy;
  final String addedByName;
  final DateTime addedAt;
  final bool completed;
  final DateTime? completedAt;
  final String? completedByName;
  final String? notes;
  final int? quantity;
  final String? unit;

  /// How the item was added: 'manual' | 'voice'. Null for pre-existing items.
  final String? inputMethod;

  const ShoppingItem({
    required this.id,
    required this.listId,
    required this.name,
    required this.categories,
    required this.addedBy,
    required this.addedByName,
    required this.addedAt,
    this.completed = false,
    this.completedAt,
    this.completedByName,
    this.notes,
    this.quantity,
    this.unit,
    this.inputMethod,
  });

  /// Backward-compatible single-category getter.
  /// Returns the primary (first) category.
  /// All existing UI code that reads `item.category` continues to work unchanged.
  String get category => categories.isNotEmpty ? categories.first : 'Other';

  // ─── Firestore deserialization ───────────────────────────────────────────────

  factory ShoppingItem.fromFirestore(DocumentSnapshot doc, String listId) {
    final data = doc.data() as Map<String, dynamic>;

    // Prefer new `categories` array (multi-category); fall back to legacy
    // `category` string for documents written before this migration.
    final List<String> cats = _parseCategoriesFromFirestore(data);

    return ShoppingItem(
      id: doc.id,
      listId: listId,
      name: data['name'] as String? ?? '',
      categories: cats,
      addedBy: data['addedBy'] as String? ?? '',
      addedByName: data['addedByName'] as String? ?? '',
      addedAt: (data['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completed: data['completed'] as bool? ?? false,
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      completedByName: data['completedByName'] as String?,
      notes: data['notes'] as String?,
      quantity: data['quantity'] as int?,
      unit: data['unit'] as String?,
      inputMethod: data['inputMethod'] as String?,
    );
  }

  // ─── SQLite deserialization ──────────────────────────────────────────────────

  factory ShoppingItem.fromMap(Map<String, dynamic> map) {
    // Prefer new `categories` CSV column; fall back to legacy `category` column.
    final List<String> cats = _parseCategoriesFromMap(map);

    return ShoppingItem(
      id: map['id'] as String,
      listId: map['list_id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      categories: cats,
      addedBy: map['added_by'] as String? ?? '',
      addedByName: map['added_by_name'] as String? ?? '',
      addedAt: map['added_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['added_at'] as int)
          : DateTime.now(),
      completed: (map['completed'] as int? ?? 0) == 1,
      completedAt: map['completed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completed_at'] as int)
          : null,
      completedByName: map['completed_by_name'] as String?,
      notes: map['notes'] as String?,
      quantity: map['quantity'] as int?,
      unit: map['unit'] as String?,
      inputMethod: map['input_method'] as String?,
    );
  }

  // ─── Firestore serialization ─────────────────────────────────────────────────

  Map<String, dynamic> toFirestore() => {
        'name': name,
        // New field: array of categories (multi-category support).
        'categories': categories,
        // Legacy field: kept for backward compatibility with older app versions
        // that read only `category`. Always set to the primary category.
        'category': category,
        'addedBy': addedBy,
        'addedByName': addedByName,
        'addedAt': Timestamp.fromDate(addedAt),
        'completed': completed,
        'completedAt':
            completedAt != null ? Timestamp.fromDate(completedAt!) : null,
        'completedByName': completedByName,
        'notes': notes,
        'quantity': quantity,
        'unit': unit,
        'inputMethod': inputMethod,
      };

  // ─── SQLite serialization ────────────────────────────────────────────────────

  Map<String, dynamic> toLocalMap() => {
        'id': id,
        'list_id': listId,
        'name': name,
        // New column: comma-separated categories (e.g. "Grocery,Health & Beauty").
        'categories': categories.join(','),
        // Legacy column: kept for apps on old DB version.
        'category': category,
        'added_by': addedBy,
        'added_by_name': addedByName,
        'added_at': addedAt.millisecondsSinceEpoch,
        'completed': completed ? 1 : 0,
        'completed_at': completedAt?.millisecondsSinceEpoch,
        'completed_by_name': completedByName,
        'notes': notes,
        'quantity': quantity,
        'unit': unit,
        'input_method': inputMethod,
      };

  // ─── copyWith ────────────────────────────────────────────────────────────────

  ShoppingItem copyWith({
    String? id,
    String? listId,
    String? name,
    List<String>? categories,
    String? addedBy,
    String? addedByName,
    DateTime? addedAt,
    bool? completed,
    DateTime? completedAt,
    String? completedByName,
    String? notes,
    int? quantity,
    String? unit,
    String? inputMethod,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      name: name ?? this.name,
      categories: categories ?? this.categories,
      addedBy: addedBy ?? this.addedBy,
      addedByName: addedByName ?? this.addedByName,
      addedAt: addedAt ?? this.addedAt,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
      completedByName: completedByName ?? this.completedByName,
      notes: notes ?? this.notes,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      inputMethod: inputMethod ?? this.inputMethod,
    );
  }

  // ─── Private helpers ─────────────────────────────────────────────────────────

  /// Parses categories from a Firestore document map.
  /// Prefers the new `categories` array field; falls back to the legacy
  /// `category` string for documents written before this migration.
  static List<String> _parseCategoriesFromFirestore(
      Map<String, dynamic> data) {
    final raw = data['categories'];
    if (raw != null && raw is List && raw.isNotEmpty) {
      return List<String>.from(raw);
    }
    final legacy = data['category'] as String?;
    return [legacy ?? 'Other'];
  }

  /// Parses categories from a SQLite row map.
  /// Prefers the new `categories` CSV column; falls back to the legacy
  /// `category` column for rows written before this migration.
  static List<String> _parseCategoriesFromMap(Map<String, dynamic> map) {
    final raw = map['categories'] as String?;
    if (raw != null && raw.isNotEmpty) {
      return raw.split(',').where((s) => s.isNotEmpty).toList();
    }
    final legacy = map['category'] as String?;
    return [legacy ?? 'Other'];
  }

  // ─── Object overrides ────────────────────────────────────────────────────────

  @override
  String toString() =>
      'ShoppingItem(id: $id, name: $name, categories: $categories, inputMethod: $inputMethod)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShoppingItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}