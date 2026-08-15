import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_app/models/shopping_item.dart';

void main() {
  final now = DateTime(2024, 6, 15);

  // Helper to build a ShoppingItem using the new `categories` constructor param.
  // The `category` getter returns the first element, preserving backward compat.
  ShoppingItem makeItem({
    String id = 'item-1',
    String listId = 'list-1',
    String name = 'Milk',
    List<String> categories = const ['Dairy'],
    String addedBy = 'u1',
    String addedByName = 'User One',
    DateTime? addedAt,
    bool completed = false,
    String? notes,
    int? quantity,
    String? unit,
  }) {
    return ShoppingItem(
      id: id,
      listId: listId,
      name: name,
      categories: categories,
      addedBy: addedBy,
      addedByName: addedByName,
      addedAt: addedAt ?? now,
      completed: completed,
      notes: notes,
      quantity: quantity,
      unit: unit,
    );
  }

  final item = makeItem(quantity: 2, unit: 'L', notes: 'Full fat');

  test('ITEM-01: fields stored', () {
    expect(item.id, 'item-1');
    expect(item.name, 'Milk');
    // category getter returns first element of categories list
    expect(item.category, 'Dairy');
    expect(item.categories, ['Dairy']);
    expect(item.quantity, 2);
    expect(item.unit, 'L');
    expect(item.completed, isFalse);
    expect(item.addedBy, 'u1');
    expect(item.addedAt, now);
    expect(item.notes, 'Full fat');
  });

  test('ITEM-02: default completed=false', () {
    expect(makeItem().completed, isFalse);
  });

  test('ITEM-03: notes nullable', () {
    expect(makeItem().notes, isNull);
  });

  test('ITEM-04: quantity nullable', () {
    expect(makeItem().quantity, isNull);
  });

  test('ITEM-05: unit nullable', () {
    expect(makeItem().unit, isNull);
  });

  test('ITEM-06: completedAt nullable', () {
    expect(makeItem().completedAt, isNull);
  });

  test('ITEM-07: copyWith overrides fields', () {
    final u = item.copyWith(name: 'Skim', quantity: 3, completed: true);
    expect(u.name, 'Skim');
    expect(u.quantity, 3);
    expect(u.completed, isTrue);
  });

  test('ITEM-08: copyWith preserves unchanged fields', () {
    final u = item.copyWith(name: 'X');
    expect(u.id, item.id);
    expect(u.category, item.category);
    expect(u.categories, item.categories);
    expect(u.addedBy, item.addedBy);
  });

  test('ITEM-09: copyWith immutable', () {
    item.copyWith(name: 'Other', completed: true);
    expect(item.name, 'Milk');
    expect(item.completed, isFalse);
  });

  test('ITEM-10: toggle completed', () {
    final c = item.copyWith(completed: true);
    expect(c.completed, isTrue);
    expect(c.copyWith(completed: false).completed, isFalse);
  });

  test('ITEM-11: copy notes', () {
    expect(item.copyWith(notes: 'Low fat').notes, 'Low fat');
  });

  test('ITEM-12: same id = equal', () {
    expect(
      item,
      equals(makeItem(id: 'item-1', listId: 'l2', name: 'X',
          categories: ['c'], addedBy: 'y', addedByName: 'Y')),
    );
  });

  test('ITEM-13: different id = not equal', () {
    expect(
      item,
      isNot(equals(makeItem(id: 'item-99', name: 'Milk',
          categories: ['Dairy'], addedBy: 'u1'))),
    );
  });

  test('ITEM-14: hashCode consistent', () {
    expect(
      item.hashCode,
      equals(makeItem(id: 'item-1', listId: 'l', name: 'X',
          categories: ['c'], addedBy: 'y', addedByName: 'Y').hashCode),
    );
  });

  // ── New tests for multi-category support ─────────────────────────────────────

  test('ITEM-15: multi-category stored correctly', () {
    final multi = makeItem(categories: ['Grocery', 'Health & Beauty']);
    expect(multi.categories, ['Grocery', 'Health & Beauty']);
    // category getter returns primary (first)
    expect(multi.category, 'Grocery');
  });

  test('ITEM-16: copyWith replaces categories', () {
    final updated = item.copyWith(categories: ['Electronics', 'Online']);
    expect(updated.categories, ['Electronics', 'Online']);
    expect(updated.category, 'Electronics');
  });

  test('ITEM-17: category getter returns first element', () {
    final i = makeItem(categories: ['Wearables', 'Other']);
    expect(i.category, 'Wearables');
  });

  test('ITEM-18: single category list behaves like old single category', () {
    final i = makeItem(categories: ['Grocery']);
    expect(i.category, 'Grocery');
    expect(i.categories.length, 1);
  });

  test('ITEM-19: toLocalMap encodes categories as CSV', () {
    final multi = makeItem(categories: ['Grocery', 'Health & Beauty']);
    final map = multi.toLocalMap();
    expect(map['categories'], 'Grocery,Health & Beauty');
    expect(map['category'], 'Grocery'); // legacy field
  });

  test('ITEM-20: fromMap decodes CSV categories', () {
    final map = {
      'id': 'x',
      'list_id': 'l',
      'name': 'Test',
      'categories': 'Grocery,Health & Beauty',
      'category': 'Grocery',
      'added_by': 'u',
      'added_by_name': 'U',
      'added_at': now.millisecondsSinceEpoch,
      'completed': 0,
    };
    final fromMap = ShoppingItem.fromMap(map);
    expect(fromMap.categories, ['Grocery', 'Health & Beauty']);
    expect(fromMap.category, 'Grocery');
  });

  test('ITEM-21: fromMap falls back to legacy category column', () {
    // Old row with no `categories` column (pre-migration)
    final map = {
      'id': 'x',
      'list_id': 'l',
      'name': 'Test',
      'category': 'Electronics',
      'added_by': 'u',
      'added_by_name': 'U',
      'added_at': now.millisecondsSinceEpoch,
      'completed': 0,
    };
    final fromMap = ShoppingItem.fromMap(map);
    expect(fromMap.categories, ['Electronics']);
    expect(fromMap.category, 'Electronics');
  });

  test('ITEM-22: inputMethod stored and retrievable', () {
    final item = ShoppingItem(
      id: 'item-22',
      listId: 'l',
      name: 'Eggs',
      categories: ['Grocery'],
      addedBy: 'u1',
      addedByName: 'Alice',
      addedAt: now,
      inputMethod: InputMethod.voice,
    );
    expect(item.inputMethod, InputMethod.voice);
  });

  test('ITEM-23: inputMethod null by default', () {
    expect(makeItem().inputMethod, isNull);
  });

  test('ITEM-24: completedByName stored and retrievable', () {
    final item = ShoppingItem(
      id: 'item-24',
      listId: 'l',
      name: 'Bread',
      categories: ['Grocery'],
      addedBy: 'u1',
      addedByName: 'Alice',
      addedAt: now,
      completedByName: 'Bob',
    );
    expect(item.completedByName, 'Bob');
  });

  test('ITEM-25: completedByName null by default', () {
    expect(makeItem().completedByName, isNull);
  });

  test('ITEM-26: toLocalMap round-trip preserves inputMethod and completedByName', () {
    final original = ShoppingItem(
      id: 'item-26',
      listId: 'list-rt',
      name: 'Butter',
      categories: ['Dairy'],
      addedBy: 'u2',
      addedByName: 'Carol',
      addedAt: now,
      inputMethod: InputMethod.manual,
      completedByName: 'Dave',
      completed: true,
      completedAt: now,
    );
    final map = original.toLocalMap();
    final restored = ShoppingItem.fromMap(map);
    expect(restored.inputMethod, InputMethod.manual);
    expect(restored.completedByName, 'Dave');
    expect(restored.completed, isTrue);
  });
}
