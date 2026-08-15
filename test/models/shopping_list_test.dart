import 'package:flutter_test/flutter_test.dart';

import 'package:shopping_app/models/shopping_list.dart';

void main() {
  group('ShoppingList', () {
    ShoppingList makeList({
      String id = 'list-1',
      String name = 'FamilyList_Smiths',
      String type = 'shared',
      String ownerId = 'uid-1',
      String ownerName = 'Alice',
      List<String> memberIds = const [],
    }) {
      return ShoppingList(
        id: id,
        name: name,
        type: type,
        ownerId: ownerId,
        ownerName: ownerName,
        memberIds: memberIds,
        createdAt: DateTime(2024, 1, 1),
      );
    }

    test('creates with required fields', () {
      final list = makeList();

      expect(list.id, 'list-1');
      expect(list.name, 'FamilyList_Smiths');
      expect(list.type, 'shared');
      expect(list.ownerId, 'uid-1');
      expect(list.ownerName, 'Alice');
      expect(list.memberIds, isEmpty);
    });

    test('isShared is true for shared type', () {
      final list = makeList(type: 'shared');
      expect(list.isShared, isTrue);
      expect(list.isPersonal, isFalse);
    });

    test('isPersonal is true for personal type', () {
      final list = makeList(type: 'personal');
      expect(list.isPersonal, isTrue);
      expect(list.isShared, isFalse);
    });

    test('displayLabel returns the list name', () {
      final list = makeList(name: 'MyList_Alice');
      expect(list.displayLabel, 'MyList_Alice');
    });

    test('memberIds are stored correctly', () {
      final list = makeList(memberIds: ['uid-2', 'uid-3']);
      expect(list.memberIds.length, 2);
      expect(list.memberIds, contains('uid-2'));
      expect(list.memberIds, contains('uid-3'));
    });

    test('equality is based on id', () {
      final a = makeList(id: 'same');
      final b = makeList(id: 'same', name: 'Different Name');
      final c = makeList(id: 'different');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('hashCode is consistent with equality', () {
      final a = makeList(id: 'same');
      final b = makeList(id: 'same', name: 'Other Name');

      expect(a.hashCode, b.hashCode);
    });

    test('default memberIds is empty', () {
      final list = ShoppingList(
        id: 'list-x',
        name: 'Test',
        type: 'personal',
        ownerId: 'uid-1',
        ownerName: 'Bob',
        createdAt: DateTime(2024, 1, 1),
      );
      expect(list.memberIds, isEmpty);
    });

    test('toFirestore contains all required keys', () {
      final list = makeList(memberIds: ['uid-2']);
      final map = list.toFirestore();

      expect(map.containsKey('name'), isTrue);
      expect(map.containsKey('type'), isTrue);
      expect(map.containsKey('ownerId'), isTrue);
      expect(map.containsKey('ownerName'), isTrue);
      expect(map.containsKey('memberIds'), isTrue);
      expect(map.containsKey('createdAt'), isTrue);
      expect(map['name'], 'FamilyList_Smiths');
      expect(map['type'], 'shared');
    });

    test('toString contains id, name and type', () {
      final list = makeList(id: 'list-99', name: 'MyList_Bob', type: 'personal');
      final s = list.toString();
      expect(s, contains('list-99'));
      expect(s, contains('MyList_Bob'));
      expect(s, contains('personal'));
    });
  });
}
