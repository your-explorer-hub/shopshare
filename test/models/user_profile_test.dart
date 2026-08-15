import 'package:flutter_test/flutter_test.dart';

import 'package:shopping_app/models/user_profile.dart';
import 'package:shopping_app/utils/subscription_limits.dart';

void main() {
  group('UserProfile', () {
    UserProfile makeProfile({
      String id = 'uid-1',
      String? email = 'alice@example.com',
      String? phoneNumber,
      String displayName = 'Alice',
      String? listId = 'list-abc',
      String? photoUrl,
      String? gender,
      DateTime? lastSeen,
      SubscriptionTier subscriptionTier = SubscriptionTier.free,
    }) {
      return UserProfile(
        id: id,
        email: email,
        phoneNumber: phoneNumber,
        displayName: displayName,
        listId: listId,
        photoUrl: photoUrl,
        gender: gender,
        createdAt: DateTime(2024, 1, 1),
        lastSeen: lastSeen,
        subscriptionTier: subscriptionTier,
      );
    }

    test('creates with required fields', () {
      final profile = makeProfile();

      expect(profile.id, 'uid-1');
      expect(profile.email, 'alice@example.com');
      expect(profile.displayName, 'Alice');
      expect(profile.listId, 'list-abc');
      expect(profile.photoUrl, isNull);
      expect(profile.gender, isNull);
      expect(profile.lastSeen, isNull);
    });

    test('creates with optional gender and lastSeen', () {
      final now = DateTime(2024, 6, 15);
      final profile = makeProfile(gender: 'female', lastSeen: now);

      expect(profile.gender, 'female');
      expect(profile.lastSeen, now);
    });

    test('copyWith updates only specified fields', () {
      final original = makeProfile();
      final updated = original.copyWith(displayName: 'Alice Smith');

      expect(updated.displayName, 'Alice Smith');
      expect(updated.email, 'alice@example.com');
      expect(updated.id, 'uid-1');
    });

    test('copyWith updates gender', () {
      final original = makeProfile(gender: 'female');
      final updated = original.copyWith(gender: 'other');

      expect(updated.gender, 'other');
      expect(updated.id, original.id);
    });

    test('copyWith updates lastSeen', () {
      final now = DateTime(2025, 3, 10);
      final original = makeProfile();
      final updated = original.copyWith(lastSeen: now);

      expect(updated.lastSeen, now);
      expect(updated.id, original.id);
    });

    test('toLocalMap / fromMap round-trip preserves all fields', () {
      final lastSeen = DateTime(2025, 1, 20, 10, 30);
      final profile = makeProfile(
        id: 'uid-2',
        email: 'bob@example.com',
        displayName: 'Bob',
        listId: 'list-xyz',
        photoUrl: 'https://example.com/photo.jpg',
        gender: 'male',
        lastSeen: lastSeen,
      );

      final map = profile.toLocalMap();
      final restored = UserProfile.fromMap(map);

      expect(restored.id, profile.id);
      expect(restored.email, profile.email);
      expect(restored.displayName, profile.displayName);
      expect(restored.listId, profile.listId);
      expect(restored.photoUrl, profile.photoUrl);
      expect(restored.gender, profile.gender);
      expect(restored.lastSeen?.millisecondsSinceEpoch,
          profile.lastSeen?.millisecondsSinceEpoch);
    });

    test('toLocalMap / fromMap preserves null gender and lastSeen', () {
      final profile = makeProfile(id: 'uid-3');

      final map = profile.toLocalMap();
      final restored = UserProfile.fromMap(map);

      expect(restored.gender, isNull);
      expect(restored.lastSeen, isNull);
    });

    test('initials returns first letter for single name', () {
      final profile = makeProfile(displayName: 'Alice');
      expect(profile.initials, 'A');
    });

    test('initials returns two letters for full name', () {
      final profile = makeProfile(displayName: 'Alice Smith');
      expect(profile.initials, 'AS');
    });

    test('initials handles whitespace-padded name', () {
      final profile = makeProfile(displayName: '  Bob   Jones  ');
      expect(profile.initials, 'BJ');
    });

    test('equality is based on id', () {
      final a = makeProfile(id: 'same');
      final b = makeProfile(id: 'same', displayName: 'Other');
      final c = makeProfile(id: 'different');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('hashCode is consistent with equality', () {
      final a = makeProfile(id: 'same');
      final b = makeProfile(id: 'same', displayName: 'Other');

      expect(a.hashCode, b.hashCode);
    });

    test('subscriptionTier defaults to free', () {
      final profile = makeProfile();
      expect(profile.subscriptionTier, SubscriptionTier.free);
    });

    test('subscriptionTier can be set to family', () {
      final profile = makeProfile(subscriptionTier: SubscriptionTier.family);
      expect(profile.subscriptionTier, SubscriptionTier.family);
    });

    test('subscriptionTier round-trips through toLocalMap/fromMap', () {
      final profile = makeProfile(
        id: 'uid-tier',
        subscriptionTier: SubscriptionTier.group,
      );
      final restored = UserProfile.fromMap(profile.toLocalMap());
      expect(restored.subscriptionTier, SubscriptionTier.group);
    });

    test('identifier returns email when email is set', () {
      final profile = makeProfile(email: 'carol@example.com');
      expect(profile.identifier, 'carol@example.com');
    });

    test('identifier returns phoneNumber when email is null', () {
      final profile = makeProfile(email: null, phoneNumber: '+919876543210');
      expect(profile.identifier, '+919876543210');
    });

    test('identifier returns empty string when both email and phone are null', () {
      final profile = makeProfile(email: null, phoneNumber: null);
      expect(profile.identifier, '');
    });

    test('phoneNumber is stored and round-trips via toLocalMap/fromMap', () {
      final profile = makeProfile(
        id: 'uid-phone',
        email: null,
        phoneNumber: '+441234567890',
      );
      final restored = UserProfile.fromMap(profile.toLocalMap());
      expect(restored.phoneNumber, '+441234567890');
      expect(restored.email, isNull);
    });

    test("initials returns '?' for empty display name", () {
      final profile = makeProfile(displayName: '');
      expect(profile.initials, '?');
    });
  });
}
