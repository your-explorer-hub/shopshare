import 'package:cloud_firestore/cloud_firestore.dart';

class ShoppingList {
  final String id; // UUID — the Firestore document ID
  final String name; // "MyList_John_Doe" | "FamilyList_Smiths"
  final String type; // 'personal' | 'shared'
  final String ownerId;
  final String ownerName;
  final List<String> memberIds;
  final DateTime createdAt;

  const ShoppingList({
    required this.id,
    required this.name,
    required this.type,
    required this.ownerId,
    required this.ownerName,
    this.memberIds = const [],
    required this.createdAt,
  });

  bool get isPersonal => type == 'personal';
  bool get isShared => type == 'shared';

  /// Human-friendly label shown in the dropdown / UI.
  String get displayLabel => name;

  factory ShoppingList.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShoppingList(
      id: doc.id,
      name: data['name'] as String? ?? doc.id,
      type: data['type'] as String? ?? 'personal',
      ownerId: data['ownerId'] as String? ?? '',
      ownerName: data['ownerName'] as String? ?? '',
      memberIds: List<String>.from(data['memberIds'] as List? ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'type': type,
        'ownerId': ownerId,
        'ownerName': ownerName,
        'memberIds': memberIds,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  @override
  String toString() => 'ShoppingList(id: $id, name: $name, type: $type)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShoppingList && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}