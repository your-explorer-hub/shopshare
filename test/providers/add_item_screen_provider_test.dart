import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_app/providers/add_item_screen_provider.dart';
import 'package:shopping_app/utils/constants.dart';

void main() {
  group('AddItemScreenProvider - Initial State', () {
    test('ADD-PROV-01: default itemName is empty', () {
      final provider = AddItemScreenProvider();
      expect(provider.itemName, isEmpty);
    });

    test('ADD-PROV-02: default selectedCategory is grocery', () {
      final provider = AddItemScreenProvider();
      expect(provider.selectedCategory, ItemCategory.grocery);
    });

    test('ADD-PROV-03: default quantity is 1', () {
      final provider = AddItemScreenProvider();
      expect(provider.quantity, 1);
    });

    test('ADD-PROV-04: default selectedUnit is pcs', () {
      final provider = AddItemScreenProvider();
      expect(provider.selectedUnit, 'pcs');
    });

    test('ADD-PROV-05: default isSubmitting is false', () {
      final provider = AddItemScreenProvider();
      expect(provider.isSubmitting, isFalse);
    });

    test('ADD-PROV-06: default categoryAutoDetected is false', () {
      final provider = AddItemScreenProvider();
      expect(provider.categoryAutoDetected, isFalse);
    });
  });

  group('AddItemScreenProvider - Item Name', () {
    test('ADD-PROV-07: setItemName updates itemName', () {
      final provider = AddItemScreenProvider();
      provider.setItemName('Milk');
      expect(provider.itemName, 'Milk');
    });

    test('ADD-PROV-08: setItemName with empty string', () {
      final provider = AddItemScreenProvider();
      provider.setItemName('Test');
      provider.setItemName('');
      expect(provider.itemName, isEmpty);
    });

    test('ADD-PROV-09: setItemName notifies listeners', () {
      final provider = AddItemScreenProvider();
      var notified = false;
      provider.addListener(() => notified = true);

      provider.setItemName('Apple');

      expect(notified, isTrue);
    });

    test('ADD-PROV-10: setItemName handles special characters', () {
      final provider = AddItemScreenProvider();
      provider.setItemName('Test-Item_123 @home');
      expect(provider.itemName, 'Test-Item_123 @home');
    });

    test('ADD-PROV-11: setItemName handles unicode', () {
      final provider = AddItemScreenProvider();
      provider.setItemName('牛奶');
      expect(provider.itemName, '牛奶');
    });
  });

  group('AddItemScreenProvider - Category', () {
    test('ADD-PROV-12: setCategory updates selectedCategory', () {
      final provider = AddItemScreenProvider();
      provider.setCategory(ItemCategory.electronics);
      expect(provider.selectedCategory, ItemCategory.electronics);
    });

    test('ADD-PROV-13: setCategory with autoDetected false', () {
      final provider = AddItemScreenProvider();
      provider.setCategory(ItemCategory.wearables);
      expect(provider.selectedCategory, ItemCategory.wearables);
      expect(provider.categoryAutoDetected, isFalse);
    });

    test('ADD-PROV-14: setCategory with autoDetected true', () {
      final provider = AddItemScreenProvider();
      provider.setCategory(ItemCategory.grocery, autoDetected: true);
      expect(provider.selectedCategory, ItemCategory.grocery);
      expect(provider.categoryAutoDetected, isTrue);
    });

    test('ADD-PROV-15: setCategory notifies listeners', () {
      final provider = AddItemScreenProvider();
      var notified = false;
      provider.addListener(() => notified = true);

      provider.setCategory(ItemCategory.home);

      expect(notified, isTrue);
    });

    test('ADD-PROV-16: manual category selection clears autoDetected', () {
      final provider = AddItemScreenProvider();
      provider.setCategory(ItemCategory.grocery, autoDetected: true);
      provider.setCategory(ItemCategory.electronics, autoDetected: false);
      expect(provider.categoryAutoDetected, isFalse);
    });

    test('ADD-PROV-17: can set all category types', () {
      final provider = AddItemScreenProvider();

      provider.setCategory(ItemCategory.grocery);
      expect(provider.selectedCategory, ItemCategory.grocery);

      provider.setCategory(ItemCategory.electronics);
      expect(provider.selectedCategory, ItemCategory.electronics);

      provider.setCategory(ItemCategory.wearables);
      expect(provider.selectedCategory, ItemCategory.wearables);

      provider.setCategory(ItemCategory.home);
      expect(provider.selectedCategory, ItemCategory.home);
    });
  });

  group('AddItemScreenProvider - Quantity', () {
    test('ADD-PROV-18: setQuantity updates quantity', () {
      final provider = AddItemScreenProvider();
      provider.setQuantity(5);
      expect(provider.quantity, 5);
    });

    test('ADD-PROV-19: setQuantity with minimum value 1', () {
      final provider = AddItemScreenProvider();
      provider.setQuantity(1);
      expect(provider.quantity, 1);
    });

    test('ADD-PROV-20: setQuantity with large value', () {
      final provider = AddItemScreenProvider();
      provider.setQuantity(999);
      expect(provider.quantity, 999);
    });

    test('ADD-PROV-21: setQuantity notifies listeners', () {
      final provider = AddItemScreenProvider();
      var notified = false;
      provider.addListener(() => notified = true);

      provider.setQuantity(10);

      expect(notified, isTrue);
    });

    test('ADD-PROV-22: setQuantity allows decrement', () {
      final provider = AddItemScreenProvider();
      provider.setQuantity(5);
      provider.setQuantity(3);
      expect(provider.quantity, 3);
    });
  });

  group('AddItemScreenProvider - Unit', () {
    test('ADD-PROV-23: setUnit updates selectedUnit', () {
      final provider = AddItemScreenProvider();
      provider.setUnit('kg');
      expect(provider.selectedUnit, 'kg');
    });

    test('ADD-PROV-24: setUnit with various units', () {
      final provider = AddItemScreenProvider();

      provider.setUnit('kg');
      expect(provider.selectedUnit, 'kg');

      provider.setUnit('L');
      expect(provider.selectedUnit, 'L');

      provider.setUnit('pcs');
      expect(provider.selectedUnit, 'pcs');
    });

    test('ADD-PROV-25: setUnit notifies listeners', () {
      final provider = AddItemScreenProvider();
      var notified = false;
      provider.addListener(() => notified = true);

      provider.setUnit('L');

      expect(notified, isTrue);
    });
  });

  group('AddItemScreenProvider - Submission State', () {
    test('ADD-PROV-26: setSubmitting(true) sets isSubmitting', () {
      final provider = AddItemScreenProvider();
      provider.setSubmitting(true);
      expect(provider.isSubmitting, isTrue);
    });

    test('ADD-PROV-27: setSubmitting(false) sets isSubmitting to false', () {
      final provider = AddItemScreenProvider();
      provider.setSubmitting(true);
      provider.setSubmitting(false);
      expect(provider.isSubmitting, isFalse);
    });

    test('ADD-PROV-28: setSubmitting notifies listeners', () {
      final provider = AddItemScreenProvider();
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.setSubmitting(true);
      provider.setSubmitting(false);

      expect(notifyCount, 2);
    });
  });

  group('AddItemScreenProvider - Reset Functionality', () {
    test('ADD-PROV-29: reset restores all defaults', () {
      final provider = AddItemScreenProvider();

      // Set non-default values
      provider.setItemName('Test Item');
      provider.setCategory(ItemCategory.electronics, autoDetected: true);
      provider.setQuantity(10);
      provider.setUnit('kg');
      provider.setSubmitting(true);

      // Reset
      provider.reset();

      // Verify all defaults restored
      expect(provider.itemName, isEmpty);
      expect(provider.selectedCategory, ItemCategory.grocery);
      expect(provider.quantity, 1);
      expect(provider.selectedUnit, 'pcs');
      expect(provider.isSubmitting, isFalse);
      expect(provider.categoryAutoDetected, isFalse);
    });

    test('ADD-PROV-30: reset notifies listeners', () {
      final provider = AddItemScreenProvider();
      provider.setItemName('Test');
      var notified = false;
      provider.addListener(() => notified = true);

      provider.reset();

      expect(notified, isTrue);
    });

    test('ADD-PROV-31: reset is idempotent', () {
      final provider = AddItemScreenProvider();
      provider.reset();
      provider.reset();

      expect(provider.itemName, isEmpty);
      expect(provider.quantity, 1);
    });
  });

  group('AddItemScreenProvider - Form Workflow Scenarios', () {
    test('ADD-PROV-32: complete form fill workflow', () {
      final provider = AddItemScreenProvider();

      // User fills form
      provider.setItemName('Apple iPhone');
      provider.setCategory(ItemCategory.electronics);
      provider.setQuantity(2);
      provider.setUnit('pcs');

      // Verify state
      expect(provider.itemName, 'Apple iPhone');
      expect(provider.selectedCategory, ItemCategory.electronics);
      expect(provider.quantity, 2);
      expect(provider.selectedUnit, 'pcs');
      expect(provider.isSubmitting, isFalse);
    });

    test('ADD-PROV-33: auto-detect category workflow', () {
      final provider = AddItemScreenProvider();

      // User types item name
      provider.setItemName('milk');

      // Auto-detection triggers
      provider.setCategory(ItemCategory.grocery, autoDetected: true);

      expect(provider.itemName, 'milk');
      expect(provider.selectedCategory, ItemCategory.grocery);
      expect(provider.categoryAutoDetected, isTrue);
    });

    test('ADD-PROV-34: user overrides auto-detected category', () {
      final provider = AddItemScreenProvider();

      // Auto-detection sets category
      provider.setItemName('apple');
      provider.setCategory(ItemCategory.grocery, autoDetected: true);

      // User manually changes category
      provider.setCategory(ItemCategory.electronics);

      expect(provider.selectedCategory, ItemCategory.electronics);
      expect(provider.categoryAutoDetected, isFalse);
    });

    test('ADD-PROV-35: submission workflow', () {
      final provider = AddItemScreenProvider();

      // User fills form
      provider.setItemName('Laptop');
      provider.setCategory(ItemCategory.electronics);
      provider.setQuantity(1);

      // User submits
      provider.setSubmitting(true);
      expect(provider.isSubmitting, isTrue);

      // Submission completes
      provider.setSubmitting(false);
      expect(provider.isSubmitting, isFalse);
    });

    test('ADD-PROV-36: submission then reset workflow', () {
      final provider = AddItemScreenProvider();

      // User fills and submits
      provider.setItemName('Milk');
      provider.setCategory(ItemCategory.grocery);
      provider.setQuantity(2);
      provider.setSubmitting(true);
      provider.setSubmitting(false);

      // Reset for next item
      provider.reset();

      // Verify ready for new input
      expect(provider.itemName, isEmpty);
      expect(provider.selectedCategory, ItemCategory.grocery);
      expect(provider.quantity, 1);
      expect(provider.isSubmitting, isFalse);
    });

    test('ADD-PROV-37: quantity adjustment workflow', () {
      final provider = AddItemScreenProvider();

      // User starts with default
      expect(provider.quantity, 1);

      // Increases quantity
      provider.setQuantity(5);
      expect(provider.quantity, 5);

      // Decreases quantity
      provider.setQuantity(3);
      expect(provider.quantity, 3);
    });

    test('ADD-PROV-38: unit selection workflow', () {
      final provider = AddItemScreenProvider();

      // Start with default
      expect(provider.selectedUnit, 'pcs');

      // Change to weight
      provider.setUnit('kg');
      expect(provider.selectedUnit, 'kg');

      // Change to volume
      provider.setUnit('L');
      expect(provider.selectedUnit, 'L');
    });

    test('ADD-PROV-39: multiple listener notifications in form fill', () {
      final provider = AddItemScreenProvider();
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.setItemName('Item');
      provider.setCategory(ItemCategory.grocery);
      provider.setQuantity(2);
      provider.setUnit('kg');

      expect(notifyCount, 4);
    });

    test('ADD-PROV-40: preserves state during submission', () {
      final provider = AddItemScreenProvider();

      // Set form state
      provider.setItemName('Test Item');
      provider.setCategory(ItemCategory.electronics);
      provider.setQuantity(3);
      provider.setUnit('pcs');

      // Start submission
      provider.setSubmitting(true);

      // Form state should be preserved
      expect(provider.itemName, 'Test Item');
      expect(provider.selectedCategory, ItemCategory.electronics);
      expect(provider.quantity, 3);
      expect(provider.selectedUnit, 'pcs');
      expect(provider.isSubmitting, isTrue);
    });
  });
}
