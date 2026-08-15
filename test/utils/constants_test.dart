import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_app/utils/constants.dart';

void main() {
  group('AppConstants', () {
    test('appName is ShopShare', () => expect(AppConstants.appName, 'ShopShare'));
    test('listIdLength is positive', () => expect(AppConstants.listIdLength, greaterThan(0)));
    test('maxItemNameLength is positive', () => expect(AppConstants.maxItemNameLength, greaterThan(0)));
    test('maxNotesLength is positive', () => expect(AppConstants.maxNotesLength, greaterThan(0)));
    test('maxDisplayNameLength is positive', () => expect(AppConstants.maxDisplayNameLength, greaterThan(0)));
    test('route constants are non-empty strings', () {
      expect(AppConstants.routeSplash, isNotEmpty);
      expect(AppConstants.routeLogin, isNotEmpty);
      expect(AppConstants.routeHome, isNotEmpty);
      expect(AppConstants.routeAddItem, isNotEmpty);
      expect(AppConstants.routeProfile, isNotEmpty);
      expect(AppConstants.routeSettings, isNotEmpty);
      expect(AppConstants.routeInvite, isNotEmpty);
    });
  });

  group('Validators', () {
    test('isValidEmail accepts valid emails', () {
      expect(Validators.isValidEmail('user@example.com'), isTrue);
      expect(Validators.isValidEmail('user+tag@sub.domain.org'), isTrue);
    });
    test('isValidEmail rejects invalid emails', () {
      expect(Validators.isValidEmail('not-an-email'), isFalse);
      expect(Validators.isValidEmail('missing@'), isFalse);
      expect(Validators.isValidEmail('@nodomain.com'), isFalse);
      expect(Validators.isValidEmail(''), isFalse);
    });
    test('isValidItemName accepts non-empty names within limit', () {
      expect(Validators.isValidItemName('Whole Milk'), isTrue);
      expect(Validators.isValidItemName('A'), isTrue);
    });
    test('isValidItemName rejects empty or whitespace-only names', () {
      expect(Validators.isValidItemName(''), isFalse);
      expect(Validators.isValidItemName('   '), isFalse);
    });
    test('isValidItemName rejects names exceeding max length', () {
      final tooLong = 'x' * (AppConstants.maxItemNameLength + 1);
      expect(Validators.isValidItemName(tooLong), isFalse);
    });
    test('isValidItemName accepts name exactly at max length', () {
      final exactMax = 'x' * AppConstants.maxItemNameLength;
      expect(Validators.isValidItemName(exactMax), isTrue);
    });
    test('isValidDisplayName accepts valid names', () {
      expect(Validators.isValidDisplayName('Alice'), isTrue);
      expect(Validators.isValidDisplayName('Alice Smith'), isTrue);
      expect(Validators.isValidDisplayName('A'), isTrue);
    });
    test('isValidDisplayName rejects empty or whitespace-only names', () {
      expect(Validators.isValidDisplayName(''), isFalse);
      expect(Validators.isValidDisplayName('   '), isFalse);
    });
    test('isValidDisplayName rejects names exceeding max length', () {
      final tooLong = 'x' * (AppConstants.maxDisplayNameLength + 1);
      expect(Validators.isValidDisplayName(tooLong), isFalse);
    });
    test('isValidDisplayName accepts name exactly at max length', () {
      final exactMax = 'x' * AppConstants.maxDisplayNameLength;
      expect(Validators.isValidDisplayName(exactMax), isTrue);
    });
  });

  group('ItemCategory', () {
    test('all has 9 categories', () => expect(ItemCategory.all.length, 9));
    test('allWithAll has 10 entries (All + 9 categories)', () {
      expect(ItemCategory.allWithAll.length, 10);
      expect(ItemCategory.allWithAll.first, 'All');
    });
    test('emoji returns non-empty string for every category', () {
      for (final cat in ItemCategory.all) {
        expect(ItemCategory.emoji(cat), isNotEmpty);
      }
    });
    test('emoji returns package emoji for unknown category', () => expect(ItemCategory.emoji('unknown'), '\u{1F4E6}'));
    test('known category constants match expected values', () {
      expect(ItemCategory.grocery, 'Grocery');
      expect(ItemCategory.online, 'Online');
      expect(ItemCategory.physical, 'Physical');
      expect(ItemCategory.electronics, 'Electronics');
      expect(ItemCategory.other, 'Other');
    });
    test('allWithAll contains all categories from all', () {
      for (final cat in ItemCategory.all) {
        expect(ItemCategory.allWithAll.contains(cat), isTrue);
      }
    });
  });

  group('MemberStatus', () {
    test('pending constant is correct', () => expect(MemberStatus.pending, 'pending'));
    test('accepted constant is correct', () => expect(MemberStatus.accepted, 'accepted'));
    test('rejected constant is correct', () => expect(MemberStatus.rejected, 'rejected'));
    test('declined constant is correct', () => expect(MemberStatus.declined, 'declined'));
    test('all four statuses are distinct strings', () {
      final statuses = {
        MemberStatus.pending,
        MemberStatus.accepted,
        MemberStatus.rejected,
        MemberStatus.declined,
      };
      expect(statuses.length, 4);
    });
  });
}
