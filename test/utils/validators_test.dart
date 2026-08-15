import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_app/utils/validators.dart';

void main() {
  group('Validators - isValidEmail', () {
    test('VAL-01: valid simple email', () {
      expect(Validators.isValidEmail('test@example.com'), isTrue);
    });

    test('VAL-02: valid email with subdomain', () {
      expect(Validators.isValidEmail('user@mail.example.com'), isTrue);
    });

    test('VAL-03: valid email with plus sign', () {
      expect(Validators.isValidEmail('user+tag@example.com'), isTrue);
    });

    test('VAL-04: valid email with dash', () {
      expect(Validators.isValidEmail('user-name@example.com'), isTrue);
    });

    test('VAL-05: valid email with dot in username', () {
      expect(Validators.isValidEmail('first.last@example.com'), isTrue);
    });

    test('VAL-06: valid email with underscore', () {
      expect(Validators.isValidEmail('user_name@example.com'), isTrue);
    });

    test('VAL-07: valid email with numbers', () {
      expect(Validators.isValidEmail('user123@example456.com'), isTrue);
    });

    test('VAL-08: valid email with long TLD', () {
      expect(Validators.isValidEmail('test@example.museum'), isTrue);
    });

    test('VAL-09: empty string is invalid', () {
      expect(Validators.isValidEmail(''), isFalse);
    });

    test('VAL-10: missing @ is invalid', () {
      expect(Validators.isValidEmail('userexample.com'), isFalse);
    });

    test('VAL-11: missing username is invalid', () {
      expect(Validators.isValidEmail('@example.com'), isFalse);
    });

    test('VAL-12: missing domain is invalid', () {
      expect(Validators.isValidEmail('user@'), isFalse);
    });

    test('VAL-13: missing TLD is invalid', () {
      expect(Validators.isValidEmail('user@example'), isFalse);
    });

    test('VAL-14: double @ is invalid', () {
      expect(Validators.isValidEmail('user@@example.com'), isFalse);
    });

    test('VAL-15: space in email is invalid', () {
      expect(Validators.isValidEmail('user name@example.com'), isFalse);
    });

    test('VAL-16: TLD with single character is invalid', () {
      expect(Validators.isValidEmail('user@example.c'), isFalse);
    });

    test('VAL-17: special chars in domain is invalid', () {
      expect(Validators.isValidEmail('user@exam!ple.com'), isFalse);
    });

    test('VAL-18: email with only whitespace is invalid', () {
      expect(Validators.isValidEmail('   '), isFalse);
    });
  });

  group('Validators - isValidItemName', () {
    test('VAL-19: valid simple item name', () {
      expect(Validators.isValidItemName('Milk'), isTrue);
    });

    test('VAL-20: valid item name with spaces', () {
      expect(Validators.isValidItemName('Whole Milk'), isTrue);
    });

    test('VAL-21: valid item name with numbers', () {
      expect(Validators.isValidItemName('Item 123'), isTrue);
    });

    test('VAL-22: valid item name with special characters', () {
      expect(Validators.isValidItemName('Item-Name_1'), isTrue);
    });

    test('VAL-23: valid item name with unicode', () {
      expect(Validators.isValidItemName('牛奶'), isTrue);
    });

    test('VAL-24: valid single character name', () {
      expect(Validators.isValidItemName('A'), isTrue);
    });

    test('VAL-25: name with leading/trailing spaces is trimmed and valid', () {
      expect(Validators.isValidItemName('  Milk  '), isTrue);
    });

    test('VAL-26: empty string is invalid', () {
      expect(Validators.isValidItemName(''), isFalse);
    });

    test('VAL-27: only whitespace is invalid', () {
      expect(Validators.isValidItemName('   '), isFalse);
    });

    test('VAL-28: name at max length is valid', () {
      // Max item name length is 100 (from constants)
      final maxName = 'a' * 100;
      expect(Validators.isValidItemName(maxName), isTrue);
    });

    test('VAL-29: name exceeding max length is invalid', () {
      final tooLong = 'a' * 101;
      expect(Validators.isValidItemName(tooLong), isFalse);
    });

    test('VAL-30: very long name is invalid', () {
      final veryLong = 'a' * 500;
      expect(Validators.isValidItemName(veryLong), isFalse);
    });
  });

  group('Validators - isValidDisplayName', () {
    test('VAL-31: valid simple display name', () {
      expect(Validators.isValidDisplayName('John'), isTrue);
    });

    test('VAL-32: valid display name with spaces', () {
      expect(Validators.isValidDisplayName('John Doe'), isTrue);
    });

    test('VAL-33: valid display name with numbers', () {
      expect(Validators.isValidDisplayName('User123'), isTrue);
    });

    test('VAL-34: valid display name with special characters', () {
      expect(Validators.isValidDisplayName('O\'Brien'), isTrue);
    });

    test('VAL-35: valid display name with unicode', () {
      expect(Validators.isValidDisplayName('张三'), isTrue);
    });

    test('VAL-36: valid single character name', () {
      expect(Validators.isValidDisplayName('A'), isTrue);
    });

    test('VAL-37: name with leading/trailing spaces is trimmed and valid', () {
      expect(Validators.isValidDisplayName('  John  '), isTrue);
    });

    test('VAL-38: empty string is invalid', () {
      expect(Validators.isValidDisplayName(''), isFalse);
    });

    test('VAL-39: only whitespace is invalid', () {
      expect(Validators.isValidDisplayName('   '), isFalse);
    });

    test('VAL-40: name at max length is valid', () {
      // Max display name length is 50 (from constants)
      final maxName = 'a' * 50;
      expect(Validators.isValidDisplayName(maxName), isTrue);
    });

    test('VAL-41: name exceeding max length is invalid', () {
      final tooLong = 'a' * 51;
      expect(Validators.isValidDisplayName(tooLong), isFalse);
    });

    test('VAL-42: very long name is invalid', () {
      final veryLong = 'a' * 200;
      expect(Validators.isValidDisplayName(veryLong), isFalse);
    });
  });

  group('Validators - Edge Cases & Integration', () {
    test('VAL-43: item name vs display name length limits differ', () {
      // Item name: 100 chars max, Display name: 50 chars max
      final name60 = 'a' * 60;
      expect(Validators.isValidItemName(name60), isTrue);
      expect(Validators.isValidDisplayName(name60), isFalse);
    });

    test('VAL-44: all validators handle null-like empty strings', () {
      expect(Validators.isValidEmail(''), isFalse);
      expect(Validators.isValidItemName(''), isFalse);
      expect(Validators.isValidDisplayName(''), isFalse);
    });

    test('VAL-45: all validators trim whitespace appropriately', () {
      // Email does not trim (space makes it invalid)
      expect(Validators.isValidEmail('  test@example.com  '), isFalse);

      // Item name and display name do trim
      expect(Validators.isValidItemName('  test  '), isTrue);
      expect(Validators.isValidDisplayName('  test  '), isTrue);
    });

    test('VAL-46: validators are independent', () {
      // Valid email but invalid as display name (too long)
      final longEmail = '${'a' * 45}@example.com'; // 57 chars total
      expect(Validators.isValidEmail(longEmail), isTrue);
      expect(Validators.isValidItemName(longEmail), isTrue); // Under 100
      expect(Validators.isValidDisplayName(longEmail), isFalse); // Over 50
    });

    test('VAL-47: unicode support across validators', () {
      expect(Validators.isValidEmail('测试@example.com'), isFalse); // Unicode in email not allowed by regex
      expect(Validators.isValidItemName('牛奶'), isTrue);
      expect(Validators.isValidDisplayName('张三'), isTrue);
    });

    test('VAL-48: emoji handling', () {
      expect(Validators.isValidItemName('🥛 Milk'), isTrue);
      expect(Validators.isValidDisplayName('John 😊'), isTrue);
      expect(Validators.isValidEmail('test😊@example.com'), isFalse);
    });
  });
}
